unit uThumbEngine;

{$POINTERMATH ON}

interface

uses Winapi.Windows, Winapi.ActiveX, System.SysUtils, System.Classes, System.SyncObjs, System.IOUtils, System.DateUtils, System.Generics.Collections, System.Math,
     Vcl.Graphics, TurboJpeg.Bitmap, uImageKit;

type
  TThumbRequest = record
    Gen: Int64;
    Index: Integer;
    Size: Integer;
    Path: string;
  end;

  TThumbResult = record
    Gen: Int64;
    Index: Integer;
    Size: Integer;
    Pixels: TBytes;
  end;
  TThumbResultArray = TArray<TThumbResult>;

  { 跨目录、跨尺寸存活的缩略图像素缓存。
    键 = 尺寸 + 文件大小 + 修改时间 + 路径, 文件被覆盖后不会命中旧图。
    纯 LRU 淘汰, 有字节与条数上限, 不会无限吃内存。 }
  TThumbCache = class
  private
    FLock: TCriticalSection;
    FMap: TDictionary<string, TBytes>;
    FOrder: TList<string>;
    FBytes: Int64;
    FMaxBytes: Int64;
    FMaxItems: Integer;
  public
    constructor Create;
    destructor Destroy; override;
    function KeyOf(const APath: string; ASize: Integer): string;
    function TryGet(const AKey: string; out APixels: TBytes): Boolean;
    procedure Put(const AKey: string; const APixels: TBytes);
  end;


  { 后台 GDI+ 缩略图引擎: 主线程只提交请求与取回像素, 解码全部在工作线程。
    1) 解码线程, 多张同时解, 首屏出图时间大致按线程数缩短。
    2) 按 "尺寸 + 文件" 索引的像素缓存。翻看过的目录再回来,或在 64/96/128 之间来回切, 命中缓存的图不再重新解码。缓存键含文件大小与修改时间, 文件被替换不会命中旧图。
    2) 滚动时 ClearRequests 丢弃过期任务, 只保留当前可见范围, 边滚动边绘制。 
  }
  TThumbEngine = class
  private
    FLock: TCriticalSection;
    FWake: TEvent;
    FWorkers: array of TThread;
    FRequests: TList<TThumbRequest>;
    FResults: TList<TThumbResult>;
    FCache: TThumbCache;
    FGen: Int64;
    FStopping: Boolean;
    FCacheHits: Int64;
    function PopJob(out AJob: TThumbRequest): Boolean;
    function CacheKeyOf(const APath: string; ASize: Integer): string;
    function TryCache(const AKey: string; out APixels: TBytes): Boolean;
    procedure AddCache(const AKey: string; const APixels: TBytes);
    procedure PushResult(const ARes: TThumbResult);
    function GetWorkerCount: Integer;
  public
    constructor Create;
    destructor Destroy; override;
    procedure Reset;
    procedure ClearRequests;
    function Generation: Int64;
    function IsStopping: Boolean;
    procedure Submit(AGen: Int64; AIndex, ASize: Integer; const APath: string);
    { 每轮最多取回 AMax 张 (AMax < 0 表示不限)。缓存命中时一批几十张会同时到货, 上限让主线程分几轮消化, 不会被一次批量应用拖住。 }
    function FetchResults(out AResults: TThumbResultArray; AMax: Integer = -1): Boolean;
    function PendingCount: Integer;
    function CacheHits: Int64;
    property WorkerCount: Integer read GetWorkerCount;
  end;

function GdipReady: Boolean;
function MakeThumbPixels(const AFileName: string; ASize: Integer): TBytes;
function PixelsToBitmap(const APixels: TBytes; ASize: Integer): TBitmap;

implementation

const
  PixelFormat32bppARGB                = $0026200A;
  ImageLockModeRead                   = 1;
  InterpolationModeHighQualityBicubic = 7;
  GDIP_OK                             = 0;
  BG_BYTE                             = $2C;

type
  TGdiplusStartupInput = record
    Version: Cardinal;
    DebugCallback: Pointer;
    SuppressBackgroundThread: LongBool;
    SuppressExternalCodecs: LongBool;
  end;

  TBitmapData = record
    Width: Cardinal;
    Height: Cardinal;
    Stride: Integer;
    PixelFormat: Integer;
    Scan0: Pointer;
    Reserved: Pointer;
  end;

  TGDIP_Startup = function(Token: PCardinal; Input, Output: Pointer): Integer; stdcall;
  TGDIP_Shutdown = procedure(Token: Cardinal); stdcall;
  TGDIP_CreateFromFile = function(FileName: PWideChar; out Bitmap: Pointer): Integer; stdcall;
  TGDIP_GetThumbnail = function(Image: Pointer; W, H: Cardinal; out Thumb: Pointer; Callback, Data: Pointer): Integer; stdcall;
  TGDIP_GetDim = function(Image: Pointer; out Dim: Cardinal): Integer; stdcall;
  TGDIP_CreateFromScan0 = function(W, H, Stride, Format: Integer; Scan0: Pointer; out Bitmap: Pointer): Integer; stdcall;
  TGDIP_GetGraphics = function(Image: Pointer; out Graphics: Pointer): Integer; stdcall;
  TGDIP_SetInterp = function(Graphics: Pointer; Mode: Integer): Integer; stdcall;
  TGDIP_Clear = function(Graphics: Pointer; Color: Cardinal): Integer; stdcall;
  TGDIP_DrawRectI = function(Graphics, Image: Pointer; X, Y, W, H: Integer): Integer; stdcall;
  TGDIP_LockBits = function(Bitmap: Pointer; R: Pointer; Flags: Cardinal; Format: Integer; out Data: TBitmapData): Integer; stdcall;
  TGDIP_UnlockBits = function(Bitmap: Pointer; var Data: TBitmapData): Integer; stdcall;
  TGDIP_Dispose = function(Image: Pointer): Integer; stdcall;
  TGDIP_DeleteGraphics = function(Graphics: Pointer): Integer; stdcall;

var
  GLock: TCriticalSection = nil;
  GLib: HMODULE = 0;
  GToken: Cardinal = 0;
  GReady: Boolean = False;
  GRefCount: Integer = 0;
  GStartup: TGDIP_Startup = nil;
  GShutdown: TGDIP_Shutdown = nil;
  GCreateFromFile: TGDIP_CreateFromFile = nil;
  GGetThumbnail: TGDIP_GetThumbnail = nil;
  GGetWidth: TGDIP_GetDim = nil;
  GGetHeight: TGDIP_GetDim = nil;
  GCreateFromScan0: TGDIP_CreateFromScan0 = nil;
  GGetGraphics: TGDIP_GetGraphics = nil;
  GSetInterp: TGDIP_SetInterp = nil;
  GClear: TGDIP_Clear = nil;
  GDrawRectI: TGDIP_DrawRectI = nil;
  GLockBits: TGDIP_LockBits = nil;
  GUnlockBits: TGDIP_UnlockBits = nil;
  GDispose: TGDIP_Dispose = nil;
  GDeleteGraphics: TGDIP_DeleteGraphics = nil;

procedure InitGdiPlus;
var
  SI: TGdiplusStartupInput;
begin
  if GLock = nil then Exit;

  GLock.Enter;
  try
    if GRefCount > 0 then
    begin
      Inc(GRefCount);
      Exit;
    end;

    GLib := LoadLibraryW('gdiplus.dll');
    if GLib = 0 then Exit;

    GStartup := TGDIP_Startup(GetProcAddress(GLib, 'GdiplusStartup'));
    GShutdown := TGDIP_Shutdown(GetProcAddress(GLib, 'GdiplusShutdown'));
    GCreateFromFile := TGDIP_CreateFromFile(GetProcAddress(GLib, 'GdipCreateBitmapFromFile'));
    GGetThumbnail := TGDIP_GetThumbnail(GetProcAddress(GLib, 'GdipGetImageThumbnail'));
    GGetWidth := TGDIP_GetDim(GetProcAddress(GLib, 'GdipGetImageWidth'));
    GGetHeight := TGDIP_GetDim(GetProcAddress(GLib, 'GdipGetImageHeight'));
    GCreateFromScan0 := TGDIP_CreateFromScan0(GetProcAddress(GLib, 'GdipCreateBitmapFromScan0'));
    GGetGraphics := TGDIP_GetGraphics(GetProcAddress(GLib, 'GdipGetImageGraphicsContext'));
    GSetInterp := TGDIP_SetInterp(GetProcAddress(GLib, 'GdipSetInterpolationMode'));
    GClear := TGDIP_Clear(GetProcAddress(GLib, 'GdipGraphicsClear'));
    GDrawRectI := TGDIP_DrawRectI(GetProcAddress(GLib, 'GdipDrawImageRectI'));
    GLockBits := TGDIP_LockBits(GetProcAddress(GLib, 'GdipBitmapLockBits'));
    GUnlockBits := TGDIP_UnlockBits(GetProcAddress(GLib, 'GdipBitmapUnlockBits'));
    GDispose := TGDIP_Dispose(GetProcAddress(GLib, 'GdipDisposeImage'));
    GDeleteGraphics := TGDIP_DeleteGraphics(GetProcAddress(GLib, 'GdipDeleteGraphics'));
    if not Assigned(GStartup) or not Assigned(GCreateFromFile) or
       not Assigned(GGetThumbnail) or not Assigned(GCreateFromScan0) or
       not Assigned(GGetGraphics) or not Assigned(GDrawRectI) or
       not Assigned(GLockBits) or not Assigned(GDispose) then
      Exit;
    FillChar(SI, SizeOf(SI), 0);
    SI.Version := 1;
    if GStartup(@GToken, @SI, nil) = GDIP_OK then
    begin
      GReady := True;
      Inc(GRefCount);
    end;
  finally
    GLock.Leave;
  end;
end;

procedure ShutdownGdiPlus;
begin
  if GLock = nil then Exit;
  GLock.Enter;
  try
    if GRefCount > 0 then
      Dec(GRefCount);
    if (GRefCount = 0) and GReady and Assigned(GShutdown) then
    begin
      GShutdown(GToken);
      GToken := 0;
      GReady := False;
    end;
    if (GRefCount = 0) and (GLib <> 0) then
    begin
      FreeLibrary(GLib);
      GLib := 0;
    end;
  finally
    GLock.Leave;
  end;
end;

function GdipReady: Boolean;
begin
  InitGdiPlus;
  Result := GReady;
end;

{ 把半透明像素合成到灰底, 并强制 alpha=255。
  ILC_COLOR32 的 ImageList 直接采用位图 alpha, 混有 alpha=0 会出现"空位"。 }
procedure CompositeOpaque(var P: TBytes; ASize: Integer);
var
  I, A, O: Integer;
begin
  for I := 0 to ASize * ASize - 1 do
  begin
    O := I * 4;
    A := P[O + 3];
    if A < 255 then
    begin
      P[O]     := (P[O]     * A + BG_BYTE * (255 - A)) div 255;
      P[O + 1] := (P[O + 1] * A + BG_BYTE * (255 - A)) div 255;
      P[O + 2] := (P[O + 2] * A + BG_BYTE * (255 - A)) div 255;
      P[O + 3] := 255;
    end;
  end;
end;

procedure DrawFrame(var P: TBytes; ASize: Integer);

  procedure Put(AX, AY: Integer);
  var O: Integer;
  begin
    if (AX < 0) or (AY < 0) or (AX >= ASize) or (AY >= ASize) then Exit;

    O := (AY * ASize + AX) * 4;
    P[O] := $64; P[O + 1] := $64; P[O + 2] := $64; P[O + 3] := 255;
  end;

begin
  if ASize < 20 then Exit;

  for var X := 6 to ASize - 7 do
  begin
    Put(X, 6);
    Put(X, ASize - 7);
  end;
  for var Y := 6 to ASize - 7 do
  begin
    Put(6, Y);
    Put(ASize - 7, Y);
  end;
end;

{ GDI+ 不支持的格式 (WebP/AVIF 等) 退回 WIC, 仍在后台线程执行 }
function WicThumbPixels(const AFileName: string; ASize: Integer): TBytes;
var
  B: TBitmap;
  Y: Integer;
begin
  SetLength(Result, 0);
  B := nil;
  try
    B := MakeThumbBitmap(AFileName, ASize);
    if (B = nil) or (B.Width <> ASize) or (B.Height <> ASize) then Exit;
    if B.PixelFormat <> pf32bit then B.PixelFormat := pf32bit;
    SetLength(Result, ASize * ASize * 4);
    for Y := 0 to ASize - 1 do Move(PByte(B.ScanLine[Y])^, Result[Y * ASize * 4], ASize * 4);
    CompositeOpaque(Result, ASize);
    DrawFrame(Result, ASize);
  except
    SetLength(Result, 0);
  end;
  FreeAndNil(B);
end;

{ GDI+ 对某些格式会返回成功但解出空图像 (QOI), 这类格式必须走 uImageKit.MakeThumbBitmap -> TPicture 已注册的 Graphic 类解码。 }
function NeedsVclDecode(const AFileName: string): Boolean;
var
  E: string;
begin
  E := LowerCase(ExtractFileExt(AFileName));
  Result := (E = '.qoi');
end;

type
  TBMPAccess         = class(TBitmap);
  TBitmapImageAccess = class(TBitmapImage);

{ 使用 TurboJpeg 创建缩略图 }
function MakeThumbPixelsWithTurboJpeg(const AFileName : string; ASize : Integer; var Buffer: TBytes): Boolean;
var
  bmp              : TBitmap;
  AWidth , AHeight : Integer;
begin
  var Data := TFile.ReadAllBytes(AFileName);
  Result := TjDecodeToBitmapScaled(Data, ASize, ASize, bmp, AWidth, AHeight);
  if Result then
  begin
    SetLength(Buffer, ASize * ASize * 4);
    Move(TBitmapImageAccess(TBMPAccess(bmp).FImage).FDIB.dsBm.bmBits^, Buffer[0], AWidth * AHeight * 4);
    bmp.Free;
  end;
end;

{ 用 GDI+ 缩略图技术生成 ASize x ASize 的 32bpp BGRA 像素。
  GdipGetImageThumbnail 对带内嵌缩略图的 JPEG 可直接取缩略图, 无需全图解码; 其余格式由 GDI+ 内部快速缩放, 再用双三次插值绘制到灰底画布上
}
function MakeThumbPixels(const AFileName: string; ASize: Integer): TBytes;
var
  Src, Thumb, CanvasBmp, Gfx, DrawSrc: Pointer;
  SW, SH: Cardinal;
  K: Double;
  TW, TH, X, Y : Integer;
  BD: TBitmapData;
  OwnThumb, Locked: Boolean;
begin
  { 使用 TurboJpeg 创建缩略图 }
  if MakeThumbPixelsWithTurboJpeg(AFileName, ASize, Result) then
  begin
    Exit;
  end;

  SetLength(Result, 0);
  if (ASize < 16) or (AFileName = '') then Exit;

  if NeedsVclDecode(AFileName) then
  begin
    Result := WicThumbPixels(AFileName, ASize);
    Exit;
  end;

  InitGdiPlus;
  if not GReady then
  begin
    Result := WicThumbPixels(AFileName, ASize);
    Exit;
  end;

  Src       := nil;
  Thumb     := nil;
  CanvasBmp := nil;
  Gfx       := nil;
  OwnThumb  := False;
  Locked    := False;
  try
    try
      if GCreateFromFile(PWideChar(AFileName), Src) <> GDIP_OK then
      begin
        Result := WicThumbPixels(AFileName, ASize);
        Exit;
      end;

      if (GGetWidth(Src, SW) <> GDIP_OK) or (GGetHeight(Src, SH) <> GDIP_OK) or (SW = 0) or (SH = 0) then
      begin
        Result := WicThumbPixels(AFileName, ASize);
        Exit;
      end;

      K := Min((ASize - 10) / SW, (ASize - 10) / SH);
      if K > 1 then K := 1;
      TW := Max(1, Round(SW * K));
      TH := Max(1, Round(SH * K));
      if (GGetThumbnail(Src, TW, TH, Thumb, nil, nil) = GDIP_OK) and (Thumb <> nil) then
      begin
        DrawSrc  := Thumb;
        OwnThumb := True;
      end
      else
        DrawSrc := Src;
      if (GCreateFromScan0(ASize, ASize, ASize * 4, PixelFormat32bppARGB, nil, CanvasBmp) <> GDIP_OK) or (CanvasBmp = nil) or (GGetGraphics(CanvasBmp, Gfx) <> GDIP_OK) then
      begin
        Result := WicThumbPixels(AFileName, ASize);
        Exit;
      end;

      GSetInterp(Gfx, InterpolationModeHighQualityBicubic);
      GClear(Gfx, $FF2C2C2C);
      X := (ASize - TW) div 2;
      Y := (ASize - TH) div 2;
      if GDrawRectI(Gfx, DrawSrc, X, Y, TW, TH) <> GDIP_OK then
      begin
        Result := WicThumbPixels(AFileName, ASize);
        Exit;
      end;

      if (GLockBits(CanvasBmp, nil, ImageLockModeRead, PixelFormat32bppARGB, BD) <> GDIP_OK) or (BD.Scan0 = nil) then
      begin
        Result := WicThumbPixels(AFileName, ASize);
        Exit;
      end;

      Locked := True;
      SetLength(Result, ASize * ASize * 4);

//      const BLOCK = 16;
//      var pOut : PByte  := Pointer(Result);
//      var StartScanLine := NativeInt(BD.Scan0);
//      var bmpWidthBytes := BD.Stride;
//      TParallel.For(0, (ASize + BLOCK - 1) div BLOCK - 1,
//          procedure(B: Integer)
//          var
//            A, T: Integer;
//          begin
//            for var RY := B * BLOCK to ((B + 1) * BLOCK - 1) do
//            begin
//              if RY < ASize then
//              begin
//                var P := PByte(StartScanLine + NativeInt(RY) * bmpWidthBytes);
//                var Q := PByte(NativeInt(pOut) + RY * ASize * 4);
//                for var X := 0 to ASize - 1 do
//                begin
//                  A := P[3];
//                  if A >= 255 then
//                  begin
//                    PDWord(Q)^ := PDWord(P)^ or $FF000000
//                  end
//                  else
//                  begin
//                    T := P[0] * A + BG_BYTE * (255 - A);  Q[0] := T div 255;
//                    T := P[1] * A + BG_BYTE * (255 - A);  Q[1] := T div 255;
//                    T := P[2] * A + BG_BYTE * (255 - A);  Q[2] := T div 255;
//                    Q[3] := 255;
//                  end;
//                  Inc(P, 4); Inc(Q, 4);
//                end;
//              end;
//            end;
//          end);


      for var RY := 0 to ASize - 1 do
      begin
        var Row := PByte(NativeUInt(BD.Scan0) + Cardinal(RY * BD.Stride));
        for var CX := 0 to ASize - 1 do
        begin
          var S := PByte(NativeUInt(Row) + Cardinal(CX * 4));
          var O := (RY * ASize + CX) * 4;
          var A := S[3];
          if A >= 255 then
          begin
            Result[O + 0] := S[0];
            Result[O + 1] := S[1];
            Result[O + 2] := S[2];
          end
          else
          begin
            Result[O + 0] := (S[0] * A + BG_BYTE * (255 - A)) shr 8; // div 255;
            Result[O + 1] := (S[1] * A + BG_BYTE * (255 - A)) shr 8; // div 255;
            Result[O + 2] := (S[2] * A + BG_BYTE * (255 - A)) shr 8; // div 255;
          end;
          Result[O + 3] := 255;
        end;
      end;

      GUnlockBits(CanvasBmp, BD);
      Locked := False;
      DrawFrame(Result, ASize);
    except
      SetLength(Result, 0);
    end;
  finally
    if Locked then GUnlockBits(CanvasBmp, BD);
    if OwnThumb and (Thumb <> nil) then GDispose(Thumb);
    if Gfx <> nil then GDeleteGraphics(Gfx);
    if CanvasBmp <> nil then GDispose(CanvasBmp);
    if Src <> nil then GDispose(Src);
  end;
end;

function PixelsToBitmap(const APixels: TBytes; ASize: Integer): TBitmap;
begin
  Result := nil;
  if (ASize < 16) or (Length(APixels) <> ASize * ASize * 4) then Exit;

  Result := TBitmap.Create;
  try
    Result.PixelFormat := pf32bit;
    Result.SetSize(ASize, ASize);
    for var Y := 0 to ASize - 1 do Move(APixels[Y * ASize * 4], PByte(Result.ScanLine[Y])^, ASize * 4);
  except
    FreeAndNil(Result);
  end;
end;

{ TThumbCache }

constructor TThumbCache.Create;
begin
  inherited Create;
  FLock := TCriticalSection.Create;
  FMap := TDictionary<string, TBytes>.Create;
  FOrder := TList<string>.Create;
  FMaxBytes := 64 * 1024 * 1024;
  FMaxItems := 2000;
end;

destructor TThumbCache.Destroy;
begin
  FreeAndNil(FOrder);
  FreeAndNil(FMap);
  FreeAndNil(FLock);
  inherited Destroy;
end;

function TThumbCache.KeyOf(const APath: string; ASize: Integer): string;
var
  FSize: Int64;
  Stamp: Int64;
begin
  FSize := 0;
  Stamp := 0;
  try
    FSize := TFile.GetSize(APath);
    Stamp := DateTimeToUnix(TFile.GetLastWriteTimeUtc(APath));
  except
    { 取不到元数据就退化成 0, 缓存仍可用, 只是文件被换掉后可能短时命中旧图 }
  end;
  Result := IntToStr(ASize) + '|' + IntToStr(FSize) + '|' + IntToStr(Stamp) +
    '|' + LowerCase(APath);
end;

function TThumbCache.TryGet(const AKey: string; out APixels: TBytes): Boolean;
var
  P: TBytes;
begin
  Result := False;
  APixels := nil;
  FLock.Enter;
  try
    if FMap.TryGetValue(AKey, P) then
    begin
      FOrder.Remove(AKey);
      FOrder.Insert(0, AKey);
      APixels := P;
      Result := True;
    end;
  finally
    FLock.Leave;
  end;
end;

procedure TThumbCache.Put(const AKey: string; const APixels: TBytes);
var
  Old: TBytes;
  Key: string;
begin
  if Length(APixels) = 0 then Exit;
  FLock.Enter;
  try
    if FMap.TryGetValue(AKey, Old) then
    begin
      Dec(FBytes, Length(Old));
      FMap[AKey] := APixels;
      Inc(FBytes, Length(APixels));
      FOrder.Remove(AKey);
      FOrder.Insert(0, AKey);
    end
    else
    begin
      FMap.Add(AKey, APixels);
      FOrder.Insert(0, AKey);
      Inc(FBytes, Length(APixels));
    end;
    while (FOrder.Count > 0) and
          ((FBytes > FMaxBytes) or (FOrder.Count > FMaxItems)) do
    begin
      Key := FOrder[FOrder.Count - 1];
      FOrder.Delete(FOrder.Count - 1);
      if FMap.TryGetValue(Key, Old) then
      begin
        Dec(FBytes, Length(Old));
        FMap.Remove(Key);
      end;
    end;
  finally
    FLock.Leave;
  end;
end;

{ TThumbWorker }

type
  TThumbWorker = class(TThread)
  private
    FEngine: TThumbEngine;
  protected
    procedure Execute; override;
  public
    constructor Create(AEngine: TThumbEngine);
  end;

constructor TThumbWorker.Create(AEngine: TThumbEngine);
begin
  FEngine := AEngine;
  inherited Create(False);
  FreeOnTerminate := False;
end;

{ 每个工作线程独立跑一张图: 取任务 -> 查缓存 -> 解码 -> 写缓存 -> 交结果。 线程内自己 CoInitialize, 回退到 WIC 解码时需要 COM。 }
procedure TThumbWorker.Execute;
var
  E: TThumbEngine;
  Job: TThumbRequest;
  Res: TThumbResult;
  Key: string;
  Pixels: TBytes;
begin
  CoInitialize(nil);
  E := FEngine;
  try
    while not Terminated do
    begin
      if not E.PopJob(Job) then
      begin
        { 队列空: 先清残留信号再复查一次, 避免丢唤醒; 带超时等待, 退出时不会被卡住。 }
        E.FWake.ResetEvent;
        if E.IsStopping then Break;
        if not E.PopJob(Job) then
        begin
          E.FWake.WaitFor(400);
          Continue;
        end;
      end;

      Pixels := nil;
      try
        try
          Key := E.CacheKeyOf(Job.Path, Job.Size);
          if not E.TryCache(Key, Pixels) then
          begin
            Pixels := MakeThumbPixels(Job.Path, Job.Size);
            if Length(Pixels) > 0 then E.AddCache(Key, Pixels);
          end;
          if Terminated or E.IsStopping then Break;
          Res.Gen    := Job.Gen;
          Res.Index  := Job.Index;
          Res.Size   := Job.Size;
          Res.Pixels := Pixels;
          E.PushResult(Res);
        except
          { 单张解码异常只丢这一张, 线程继续服务后面的任务 }
        end;
      finally
        Pixels := nil;
      end;
    end;
  finally
    CoUninitialize;
  end;
end;

{ TThumbEngine }

const
  WORKER_MIN = 2;
  WORKER_MAX = 4;

{ 线程数按核数取, 但不拉满: 解码是 CPU + 磁盘混合负载, 线程太多会抢主线程的 CPU 和磁盘带宽, 反而拖慢滚动 }
function TThumbEngine.GetWorkerCount: Integer;
begin
  Result := System.Math.Max(WORKER_MIN, System.Math.Min(WORKER_MAX, TThread.ProcessorCount div 3));
end;

function TThumbEngine.PopJob(out AJob: TThumbRequest): Boolean;
begin
  Result := False;
  FLock.Enter;
  try
    if FStopping then Exit;
    if FRequests.Count > 0 then
    begin
      { 先进先出: 界面按可见区从上到下提交, 顺序取任务才能让屏幕上方先出图。滚动时旧队列由 ClearRequests 整体丢掉, 不需要靠后进先出追新, 也不会去解刚滚走的内容 }
      AJob := FRequests[0];
      FRequests.Delete(0);
      Result := AJob.Gen = FGen;
    end;
  finally
    FLock.Leave;
  end;
end;

procedure TThumbEngine.PushResult(const ARes: TThumbResult);
begin
  FLock.Enter;
  try
    if (not FStopping) and (ARes.Gen = FGen) then FResults.Add(ARes);
  finally
    FLock.Leave;
  end;
end;

function TThumbEngine.CacheKeyOf(const APath: string; ASize: Integer): string;
begin
  Result := FCache.KeyOf(APath, ASize);
end;

function TThumbEngine.TryCache(const AKey: string; out APixels: TBytes): Boolean;
begin
  Result := FCache.TryGet(AKey, APixels);
  if Result then
  begin
    FLock.Enter;
    try
      Inc(FCacheHits);
    finally
      FLock.Leave;
    end;
  end;
end;

procedure TThumbEngine.AddCache(const AKey: string; const APixels: TBytes);
begin
  FCache.Put(AKey, APixels);
end;

constructor TThumbEngine.Create;
var
  I, N: Integer;
begin
  inherited Create;
  FLock := TCriticalSection.Create;
  { 手工重置事件: 多个工作线程一起等, 一次提交要能把它们全部唤醒。 }
  FWake := TEvent.Create(nil, True, False, '');
  FRequests  := TList<TThumbRequest>.Create;
  FResults   := TList<TThumbResult>.Create;
  FCache     := TThumbCache.Create;
  FGen       := 0;
  FStopping  := False;
  FCacheHits := 0;
  InitGdiPlus;
  N := GetWorkerCount;
  SetLength(FWorkers, N);
  for I := 0 to N - 1 do FWorkers[I] := TThumbWorker.Create(Self);
end;

destructor TThumbEngine.Destroy;
var
  I: Integer;
begin
  FLock.Enter;
  try
    FStopping := True;
    FRequests.Clear;
    FResults.Clear;
  finally
    FLock.Leave;
  end;
  for I := 0 to High(FWorkers) do
    if FWorkers[I] <> nil then FWorkers[I].Terminate;
  FWake.SetEvent;
  for I := 0 to High(FWorkers) do
    if FWorkers[I] <> nil then
    begin
      FWorkers[I].WaitFor;
      FreeAndNil(FWorkers[I]);
    end;
  SetLength(FWorkers, 0);
  FreeAndNil(FCache);
  FreeAndNil(FWake);
  FreeAndNil(FResults);
  FreeAndNil(FRequests);
  FreeAndNil(FLock);
  ShutdownGdiPlus;
  inherited Destroy;
end;

procedure TThumbEngine.Reset;
begin
  FLock.Enter;
  try
    Inc(FGen);
    FRequests.Clear;
    FResults.Clear;
  finally
    FLock.Leave;
  end;
end;

procedure TThumbEngine.ClearRequests;
begin
  FLock.Enter;
  try
    FRequests.Clear;
  finally
    FLock.Leave;
  end;
end;

function TThumbEngine.Generation: Int64;
begin
  FLock.Enter;
  try
    Result := FGen;
  finally
    FLock.Leave;
  end;
end;

function TThumbEngine.IsStopping: Boolean;
begin
  FLock.Enter;
  try
    Result := FStopping;
  finally
    FLock.Leave;
  end;
end;

procedure TThumbEngine.Submit(AGen: Int64; AIndex, ASize: Integer; const APath: string);
var
  Job: TThumbRequest;
begin
  Job.Gen := AGen;
  Job.Index := AIndex;
  Job.Size := ASize;
  Job.Path := APath;
  FLock.Enter;
  try
    if FStopping or (AGen <> FGen) then Exit;
    if FRequests.Count > 512 then FRequests.DeleteRange(0, FRequests.Count - 256);
    FRequests.Add(Job);
  finally
    FLock.Leave;
  end;
  FWake.SetEvent;
end;

function TThumbEngine.FetchResults(out AResults: TThumbResultArray; AMax: Integer): Boolean;
begin
  SetLength(AResults, 0);
  FLock.Enter;
  try
    var N := FResults.Count;
    if (AMax >= 0) and (N > AMax) then N := AMax;
    if N > 0 then
    begin
      SetLength(AResults, N);
      for var I := 0 to N - 1 do AResults[I] := FResults[I];
      FResults.DeleteRange(0, N);
    end;
  finally
    FLock.Leave;
  end;
  Result := Length(AResults) > 0;
end;

function TThumbEngine.PendingCount: Integer;
begin
  FLock.Enter;
  try
    Result := FRequests.Count + FResults.Count;
  finally
    FLock.Leave;
  end;
end;

function TThumbEngine.CacheHits: Int64;
begin
  FLock.Enter;
  try
    Result := FCacheHits;
  finally
    FLock.Leave;
  end;
end;

initialization
  GLock := TCriticalSection.Create;

finalization
  ShutdownGdiPlus;
  FreeAndNil(GLock);

end.
