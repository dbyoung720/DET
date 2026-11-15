unit uImage;

interface

uses
  Winapi.Windows, Winapi.GDIPOBJ, Winapi.GDIPAPI, Winapi.ActiveX, System.Types, System.Diagnostics, System.SysUtils, System.Classes, System.Math, System.Threading,
  Vcl.Forms, Vcl.Graphics, Vcl.Imaging.GIFImg, Vcl.Imaging.jpeg, Vcl.Imaging.QOI, Vcl.Imaging.pngimage, Vcl.Dialogs, uAdjust;

type
  TdbImage = class
  private
    Fbmp32  : TBitmap;
    FbmpTemp: TBitmap;
    procedure BackupBitmap(bmp: TBitmap);
    function CreateTempBmp(bmp: TBitmap): TBitmap;
    procedure GetGrayAlpha(const iPos: Integer; var alpha: TAlpha; var grays: TGrays);
    procedure InitContrastTable;
    procedure InitSaturationTable;
    procedure BrightnessProc(const bmpSrc: TBitmap; bmpDst: TBitmap; const iPos: Integer; RefreshImage: TAdjustFunc);
    procedure ContrastProc(const bmpSrc: TBitmap; bmpDst: TBitmap; const iPos: Integer; RefreshImage: TAdjustFunc);
    procedure SaturationProc(const bmpSrc: TBitmap; bmpDst: TBitmap; const iPos: Integer; RefreshImage: TAdjustFunc);
    procedure BlendProc(const bmpBlend: TBitmap; bmpDst: TBitmap; const iPos: Integer; RefreshImage: TAdjustFunc);
    procedure Rotate90Optimized(bmp: TBitmap);
    procedure Rotate270Optimized(bmp: TBitmap);
    procedure Rotate90LineSSE2(BaseSrc, BaseDst: PByte; const iHeight, iWidth: NativeInt); inline;
    procedure Rotate270LineSSE2(BaseSrc, BaseDst: PByte; const iHeight, iWidth: NativeInt); inline;
    procedure RotateProc(bmpSrc, bmpDst: TBitmap; const RotaryAngle: double; const CenterX, CenterY, MoveX, MoveY: Integer; const ras: Integer = 0; rac: Integer = 0);
  public
    constructor Create;
    destructor Destroy; override;
    { 加载图像文件 }
    function LoadImage(var bmp: TBitmap; var iSpendTIme: Integer; const bBackup: Boolean = False): Boolean; virtual;
    { 恢复 }
    procedure Restore(bmp: TBitmap); virtual;
    { 反色 }
    procedure Invert(bmp: TBitmap); virtual;
    { 灰度图 }
    procedure Gray(bmp: TBitmap); virtual;
    { 水平镜像 }
    procedure HorizMirror(bmp: TBitmap); virtual;
    { 垂直镜像 }
    procedure VertiMirror(bmp: TBitmap); virtual;
    { 转置 }
    procedure HAndVMirror(bmp: TBitmap); virtual;
    { 旋转 }
    procedure Rotate(bmp: TBitmap; const iAngle: Integer; var iSpeedTime: Integer); virtual;
    { 调节亮度 }
    procedure Brightness(bmp: TBitmap; RefreshImage: TAdjustFunc); virtual;
    { 调节对比度 }
    procedure Contrast(bmp: TBitmap; RefreshImage: TAdjustFunc); virtual;
    { 调节饱和度 }
    procedure Saturation(bmp: TBitmap; RefreshImage: TAdjustFunc); virtual;
    { 两幅图片进行透明叠加 }
    procedure Blend(bmpBlend, bmp: TBitmap; RefreshImage: TAdjustFunc); virtual;
    { 曝光 }
    procedure Exposure(bmp: TBitmap); virtual;
    { 浮雕 }
    procedure Emboss(bmp: TBitmap); virtual;
    { 雕刻 }
    procedure Engrave(bmp: TBitmap); virtual;
  end;

implementation

{$I uColor.inc}
{$I uImage.inc}

procedure TdbImage.InitContrastTable;
var
  kValue          : Integer;
  kCoeff          : Single;
  intContrastValue: Integer;
  byeColor        : Byte;
begin
  for intContrastValue := -255 to 255 do
  begin
    kValue       := IfThen(intContrastValue < 0, 255, 128);
    kCoeff       := intContrastValue / kValue;
    for byeColor := 0 to 255 do
    begin
      FContrastTable[intContrastValue, byeColor] := EnsureRange(byeColor + Round(((byeColor - 128) * kCoeff)), 0, 255);
    end;
  end;
end;

procedure TdbImage.InitSaturationTable;
var
  alpha: TAlpha;
  grays: TGrays;
  J    : Integer;
  I    : Integer;
  Gray : Integer;
  Color: Integer;
begin
  for J := 0 to 510 do
  begin
    GetGrayAlpha(J, alpha, grays);
    for Color := 0 to 765 do
    begin
      for I := 0 to 255 do
      begin
        Gray                          := grays[Color];
        FSaturationTable[J, Color, I] := Max(0, Min(255, Gray + alpha[I]));
      end;
    end;
  end;
end;

constructor TdbImage.Create;
begin
 // InitGDIPLUS;
  InitContrastTable;
  InitSaturationTable;
end;

function TdbImage.CreateTempBmp(bmp: TBitmap): TBitmap;
begin
  if FbmpTemp = nil then
    FbmpTemp           := TBitmap.Create;
  FbmpTemp.PixelFormat := bmp.PixelFormat;
  FbmpTemp.Width       := bmp.Width;
  FbmpTemp.Height      := bmp.Height;
  FbmpTemp.Canvas.Draw(0, 0, bmp);
  Result := FbmpTemp;
end;

destructor TdbImage.Destroy;
begin
  if Fbmp32 <> nil then
    Fbmp32.Free;

  if FbmpTemp <> nil then
    FbmpTemp.Free;

  // FreeGDIPLUS;
  inherited;
end;

{ 灰度图 }
procedure TdbImage.Gray(bmp: TBitmap);
var
  StartScanLine: NativeInt;
  bmpWidthBytes: NativeInt;
begin
  StartScanLine := NativeInt(bmp.ScanLine[0]);
  bmpWidthBytes := NativeInt(bmp.ScanLine[1]) - NativeInt(bmp.ScanLine[0]);
  TParallel.For(0, bmp.Height - 1,
    procedure(Y: Integer)
    var
      pColor: PByte;
    begin
      pColor := PByte(StartScanLine + Y * bmpWidthBytes);
      GrayLineSSE2(pColor, bmp.Width);
    end);
end;

{ 水平镜像 }
procedure TdbImage.HorizMirror(bmp: TBitmap);
var
  StartScanLine: NativeInt;
  bmpWidthBytes: NativeInt;
begin
  StartScanLine := NativeInt(bmp.ScanLine[0]);
  bmpWidthBytes := NativeInt(bmp.ScanLine[1]) - NativeInt(bmp.ScanLine[0]);
  TParallel.For(0, bmp.Height - 1,
    procedure(Y: Integer)
    var
      X: Integer;
      swpColor: DWORD;
      pColor01: PDWORD;
      pColor02: PDWORD;
    begin
      pColor01 := PDWORD(StartScanLine + Y * bmpWidthBytes);
      pColor02 := PDWORD(StartScanLine + Y * bmpWidthBytes + 4 * (bmp.Width - 1));
      for X := 0 to bmp.Width div 2 - 1 do
      begin
        swpColor := pColor02^;
        pColor02^ := pColor01^;
        pColor01^ := swpColor;
        Inc(pColor01);
        Dec(pColor02);
      end;
    end);
end;

{ 垂直镜像 }
procedure TdbImage.VertiMirror(bmp: TBitmap);
var
  StartScanLineSrc: PByte;
  StartScanLineDst: PByte;
  bmpWidthBytes   : NativeInt;
  iStep           : Integer;
begin
  StartScanLineSrc := bmp.ScanLine[0];
  StartScanLineDst := bmp.ScanLine[bmp.Height - 1];
  bmpWidthBytes    := NativeInt(bmp.ScanLine[1]) - NativeInt(bmp.ScanLine[0]);
  iStep            := bmp.Width div 4;

  TParallel.For(0, bmp.Height div 2 - 1,
    procedure(Y: Integer)
    var
      pColorSrc, pColorDst: PByte;
    begin
      pColorSrc := StartScanLineSrc + Y * bmpWidthBytes;
      pColorDst := StartScanLineDst - Y * bmpWidthBytes;
      VertiLineSSE2(pColorSrc, pColorDst, iStep);
    end);
end;

{ 转置 }
procedure TdbImage.HAndVMirror(bmp: TBitmap);
begin
  HorizMirror(bmp);
  VertiMirror(bmp);
end;

{ 反色 }
procedure TdbImage.Invert(bmp: TBitmap);
var
  StartScanLine: NativeInt;
  bmpWidthBytes: NativeInt;
begin
  StartScanLine := NativeInt(bmp.ScanLine[0]);
  bmpWidthBytes := NativeInt(bmp.ScanLine[1]) - NativeInt(bmp.ScanLine[0]);
  TParallel.For(0, bmp.Height - 1,
    procedure(Y: Integer)
    var
      LScanLine: PDWORD;
      X: Integer;
    begin
      LScanLine := PDWORD(StartScanLine + Y * bmpWidthBytes);
      for X := 0 to bmp.Width - 1 do
      begin
        LScanLine^ := not LScanLine^;
        Inc(LScanLine);
      end;
    end);
end;

procedure TdbImage.BackupBitmap(bmp: TBitmap);
begin
  if Fbmp32 = nil then
    Fbmp32 := TBitmap.Create;

  Fbmp32.PixelFormat := bmp.PixelFormat;
  Fbmp32.Width       := bmp.Width;
  Fbmp32.Height      := bmp.Height;
  Fbmp32.Canvas.Draw(0, 0, bmp);
end;

var
  FObject  : Pointer;
  FbmpTimer: TBitmap;

procedure TimerProc(hWnd: THandle; uMsg, idEvent: UINT; dwTime: DWORD); stdcall;
begin
  KillTimer(0, idEvent);
  TdbImage(FObject).Restore(FbmpTimer);
end;

{ 加载图像文件 }
function TdbImage.LoadImage(var bmp: TBitmap; var iSpendTIme: Integer; const bBackup: Boolean = False): Boolean;
var
  hFile      : THandle;
  Buffer     : array [0 .. 15] of AnsiChar;
  bJpeg      : Boolean;
  pic        : TPicture;
  jpg        : TGPImage;
  gpg        : TGPGraphics;
  strFileName: string;
begin
  Result      := False;
  bJpeg       := False;
  strFileName := '';

  with TOpenDialog.Create(nil) do
  begin
    Filter := '所有图像文件(*.BMP;*.JPG;*.PNG;*.QOI;*.GIF;*.PSD)|(*.BMP;*.JPG;*.PNG;*.QOI;*.GIF;*.PSD)';
    if Execute then
    begin
      strFileName := FileName;
      hFile       := FileOpen(strFileName, fmOpenRead);
      try
        FileRead(hFile, Buffer, 16);
        bJpeg := PDWORD(@Buffer[6])^ = $4649464A;
      finally
        FileClose(hFile);
      end;
    end;
    Free;
  end;

  if strFileName = '' then
    Exit;

  with TStopWatch.StartNew do
  begin
    if bJpeg then
    begin
      jpg := TGPImage.Create(strFileName);
      bmp := TBitmap.Create;
      try
        bmp.PixelFormat := pf32bit;
        bmp.SetSize(jpg.GetWidth - jpg.GetWidth mod 4, jpg.GetHeight - jpg.GetHeight mod 4);
        gpg := TGPGraphics.Create(bmp.Canvas.Handle);
        try
          gpg.DrawImage(jpg, 0, 0, bmp.Width, bmp.Height);
          Result := True;
        finally
          gpg.Free;
        end;
      finally
        jpg.Free;
      end;
    end
    else
    begin
      pic := TPicture.Create;
      try
        pic.LoadFromFile(strFileName);
        bmp             := TBitmap.Create;
        bmp.PixelFormat := pf32bit;
        bmp.Width       := pic.Graphic.Width - pic.Graphic.Width mod 4;
        bmp.Height      := pic.Graphic.Height - pic.Graphic.Height mod 4;
        bmp.Canvas.Draw(0, 0, pic.Graphic);
        Result := True;
      finally
        pic.Free;
      end;
    end;

    iSpendTIme := ElapsedMilliseconds;
  end;

  if Result and bBackup then
  begin
    BackupBitmap(bmp);
    FObject   := Self;
    FbmpTimer := bmp;
    SetTimer(0, 1000, 10, @TimerProc);
  end;
end;

{ 恢复 }
procedure TdbImage.Restore(bmp: TBitmap);
begin
  bmp.Width  := Fbmp32.Width;
  bmp.Height := Fbmp32.Height;
  bmp.Canvas.Draw(0, 0, Fbmp32);
end;

procedure RoateLineSSE2(const srcBits: PRGBQuadArray; dstBits: PRGBQuadArray; const krx, kry, intOffset: Integer; const rac, ras: Integer; const dstWidth, srcWidth, srcHeight: Integer); inline;
var
  dstX      : Integer;
  srcX, srcY: Integer;
begin
  for dstX := 0 to dstWidth - 1 do
  begin
    srcX := (dstX * rac - krx) shr 8;
    srcY := (dstX * ras - kry) shr 8;
    if (srcX >= 0) and (srcY >= 0) and (srcX < srcWidth) and (srcY < srcHeight) then
    begin
      dstBits[intOffset + dstX] := srcBits[srcWidth * srcY + srcX];
    end;
  end;
end;

procedure TdbImage.RotateProc(bmpSrc, bmpDst: TBitmap; const RotaryAngle: double; const CenterX, CenterY, MoveX, MoveY: Integer; const ras: Integer = 0; rac: Integer = 0);
var
  srcBits  : PRGBQuadArray;
  dstBits  : PRGBQuadArray;
  cxc, cxs : Integer;
  cyc, cys : Integer;
  kcx, kcy : Integer;
  dstWidth : Integer;
  dstHeight: Integer;
  srcWidth : Integer;
  srcHeight: Integer;
begin
  srcBits   := TBitmapImageAccess(TBMPAccess(bmpSrc).FImage).FDIB.dsBm.bmBits;
  dstBits   := TBitmapImageAccess(TBMPAccess(bmpDst).FImage).FDIB.dsBm.bmBits;
  dstWidth  := bmpDst.Width;
  dstHeight := bmpDst.Height;
  srcWidth  := bmpSrc.Width;
  srcHeight := bmpSrc.Height;
  cxc       := (CenterX + MoveX) * rac;
  cxs       := (CenterX + MoveX) * ras;
  cys       := (CenterY + MoveY) * ras;
  cyc       := (CenterY + MoveY) * rac;
  kcx       := cxc - cys - CenterX * (1 shl 8);
  kcy       := cxs + cyc - CenterY * (1 shl 8);

  TParallel.For(0, dstHeight - 1,
    procedure(dstY: Integer)
    var
      krx, kry, intOffset: Integer;
    begin
      krx := kcx + dstY * ras;
      kry := kcy - dstY * rac;
      intOffset := dstY * dstWidth;
      RoateLineSSE2(srcBits, dstBits, krx, kry, intOffset, rac, ras, dstWidth, srcWidth, srcHeight);
    end);
end;

procedure TdbImage.Rotate90LineSSE2(BaseSrc, BaseDst: PByte; const iHeight, iWidth: NativeInt);
var
  X, NewOffset, OldOffset: Integer;
begin
  for X := 0 to iHeight - 1 do
  begin
    NewOffset                       := X * 4;                           // 计算新图偏移 (y行, x列)
    OldOffset                       := X * 4 * iWidth;                  // 计算原图偏移 (x行, W-1-y列)
    PCardinal(BaseDst + NewOffset)^ := PCardinal(BaseSrc + OldOffset)^; // 直接复制32位像素数据
  end;
end;

procedure TdbImage.Rotate270LineSSE2(BaseSrc, BaseDst: PByte; const iHeight, iWidth: NativeInt);
var
  X, NewOffset, OldOffset: Integer;
begin
  for X := 0 to iHeight - 1 do
  begin
    NewOffset                       := X * 4;                           // 计算新图偏移 (y行, x列)
    OldOffset                       := X * 4 * iWidth;                  // 计算原图偏移 (x行, W-1-y列)
    PCardinal(BaseDst + NewOffset)^ := PCardinal(BaseSrc - OldOffset)^; // 直接复制32位像素数据
  end;
end;

procedure TdbImage.Rotate90Optimized(bmp: TBitmap);
var
  W, H                              : Integer;
  BmpRoate90                        : TBitmap;
  StartScanLineSrc, StartScanLineDst: NativeInt;
  bmpWidthBytesSrc, bmpWidthBytesDst: NativeInt;
  OldOffsetY                        : NativeInt;
begin
  W          := bmp.Width;
  H          := bmp.Height;
  BmpRoate90 := TBitmap.Create;
  try
    // 创建目标位图（宽高互换）
    BmpRoate90.PixelFormat := pf32bit;
    BmpRoate90.SetSize(H, W);

    // 获取内存首地址和步长
    bmp.HandleType   := bmDIB;
    StartScanLineSrc := NativeInt(bmp.ScanLine[0]);
    bmpWidthBytesSrc := NativeInt(bmp.ScanLine[1]) - NativeInt(bmp.ScanLine[0]);
    OldOffsetY       := (H - 1) * bmpWidthBytesSrc;

    BmpRoate90.HandleType := bmDIB;
    StartScanLineDst      := NativeInt(BmpRoate90.ScanLine[0]);
    bmpWidthBytesDst      := NativeInt(BmpRoate90.ScanLine[1]) - NativeInt(BmpRoate90.ScanLine[0]);

    // 并行处理新图的每一行
    TParallel.For(0, W - 1,
      procedure(Y: Integer)
      var
        NewY, OldY: Integer;
        BaseSrc, BaseDst: PByte;
      begin
        NewY := Y * bmpWidthBytesDst;
        OldY := OldOffsetY + Y * 4;
        BaseSrc := PByte(StartScanLineSrc + OldY);
        BaseDst := PByte(StartScanLineDst + NewY);
        Rotate90LineSSE2(BaseSrc, BaseDst, H, W);
      end);

    bmp.Assign(BmpRoate90);
  finally
    BmpRoate90.Free;
  end;
end;

procedure TdbImage.Rotate270Optimized(bmp: TBitmap);
var
  W, H                              : Integer;
  BmpRoate270                       : TBitmap;
  StartScanLineSrc, StartScanLineDst: NativeInt;
  bmpWidthBytesDst                  : NativeInt;
  OldOffsetY                        : NativeInt;
begin
  W           := bmp.Width;
  H           := bmp.Height;
  BmpRoate270 := TBitmap.Create;
  try
    // 创建目标位图（宽高互换）
    BmpRoate270.PixelFormat := pf32bit;
    BmpRoate270.SetSize(H, W);

    // 获取内存首地址和步长
    bmp.HandleType   := bmDIB;
    StartScanLineSrc := NativeInt(bmp.ScanLine[0]);
    OldOffsetY       := (W - 1) * 4;

    BmpRoate270.HandleType := bmDIB;
    StartScanLineDst       := NativeInt(BmpRoate270.ScanLine[0]);
    bmpWidthBytesDst       := Integer(BmpRoate270.ScanLine[1]) - Integer(BmpRoate270.ScanLine[0]);

    // 并行处理新图的每一行
    TParallel.For(0, W - 1,
      procedure(Y: Integer)
      var
        NewY, OldY: Integer;
        BaseSrc, BaseDst: PByte;
      begin
        NewY := Y * bmpWidthBytesDst;
        OldY := OldOffsetY - 4 * Y;
        BaseSrc := PByte(StartScanLineSrc + OldY);
        BaseDst := PByte(StartScanLineDst + NewY);
        Rotate270LineSSE2(BaseSrc, BaseDst, H, W);
      end);

    bmp.Assign(BmpRoate270);
  finally
    BmpRoate270.Free;
  end;
end;

{ 旋转 }
procedure TdbImage.Rotate(bmp: TBitmap; const iAngle: Integer; var iSpeedTime: Integer);
var
  bmpDst          : TBitmap;
  RotaryAngle     : double;
  CenterX, CenterY: Integer;
  MoveX, MoveY    : Integer;
  srac, sras      : Single;
  rac, ras        : Integer;
begin
  bmp.Width  := Fbmp32.Width;
  bmp.Height := Fbmp32.Height;
  bmp.Canvas.Draw(0, 0, Fbmp32);

  with TStopWatch.StartNew do
  begin
    if iAngle mod 360 = 0 then
    begin
      { 旋转 360 度，直接恢复原图 }
      iSpeedTime := ElapsedMilliseconds;
      Exit;
    end
    else if iAngle mod 270 = 0 then
    begin
      { 旋转 270 度，单独处理 }
      Rotate270Optimized(bmp);
      iSpeedTime := ElapsedMilliseconds;
      Exit;
    end
    else if iAngle mod 180 = 0 then
    begin
      { 旋转 180 度，图像转置 }
      HAndVMirror(bmp);
      iSpeedTime := ElapsedMilliseconds;
      Exit;
    end
    else if iAngle mod 90 = 0 then
    begin
      { 旋转 90 度，单独处理 }
      Rotate90Optimized(bmp);
      iSpeedTime := ElapsedMilliseconds;
      Exit;
    end;

    RotaryAngle := (iAngle mod 360) * PI / 180;
    SinCos(RotaryAngle, sras, srac);
    rac := Trunc(srac * (1 shl 8));
    ras := Trunc(sras * (1 shl 8));

    { 这里必须修改 Vcl.Graphics.pas，否则创建大尺寸位图时比较耗时。注释掉 8087 行代码：PatBlt(NewImageDC, 0, 0, bmWidth, bmHeight, WHITENESS); }
    bmpDst := TBitmap.Create;
    try
      bmpDst.PixelFormat := pf32bit;
      bmpDst.Width       := Round(Abs(bmp.Width * srac) + Abs(bmp.Height * sras));
      bmpDst.Height      := Round(Abs(bmp.Width * sras) + Abs(bmp.Height * srac));
      MoveX              := (bmpDst.Width - bmp.Width) div 2;
      MoveY              := (bmpDst.Height - bmp.Height) div 2;
      CenterX            := bmp.Width div 2;
      CenterY            := bmp.Height div 2;
      RotateProc(bmp, bmpDst, RotaryAngle, CenterX, CenterY, MoveX, MoveY, ras, rac);
      bmp.Width  := bmpDst.Width;
      bmp.Height := bmpDst.Height;
      bmp.Canvas.Draw(0, 0, bmpDst);
    finally
      bmpDst.Free;
    end;

    iSpeedTime := ElapsedMilliseconds;
  end;
end;

procedure TdbImage.BrightnessProc(const bmpSrc: TBitmap; bmpDst: TBitmap; const iPos: Integer; RefreshImage: TAdjustFunc);
var
  StartScanLineSrc, StartScanLineDst: NativeInt;
  bmpWidthBytes                     : NativeInt;
  iSpeedTime                        : Int64;
begin
  With TStopWatch.StartNew do
  begin
    StartScanLineSrc := NativeInt(bmpSrc.ScanLine[0]);
    StartScanLineDst := NativeInt(bmpDst.ScanLine[0]);
    bmpWidthBytes    := NativeInt(bmpSrc.ScanLine[1]) - NativeInt(bmpSrc.ScanLine[0]);
    TParallel.For(0, bmpSrc.Height - 1,
      procedure(Y: Integer)
      var
        pColor01, pColor02: PRGBQuad;
      begin
        pColor01 := PRGBQuad(StartScanLineSrc + Y * bmpWidthBytes);
        pColor02 := PRGBQuad(StartScanLineDst + Y * bmpWidthBytes);
        BrightnessLineSSE2(pColor01, pColor02, bmpSrc.Width, iPos);
      end);
    iSpeedTime := ElapsedMilliseconds;
    RefreshImage(iSpeedTime);
  end;
end;

{ 调节亮度 }
procedure TdbImage.Brightness(bmp: TBitmap; RefreshImage: TAdjustFunc);
begin
  FbmpTemp := CreateTempBmp(bmp);
  ShowAdjustForm('亮度：', -255, 255, 0, FbmpTemp, bmp, BrightnessProc, RefreshImage);
end;

procedure ContrastLineSSE2(pColorSrc, pColorDst: PRGBQuad; const bmpWidth: Integer; const iPos: Integer); inline;
var
  X: Integer;
begin
  for X := 0 to bmpWidth - 1 do
  begin
    pColorDst^.R := FContrastTable[iPos, pColorSrc^.R];
    pColorDst^.g := FContrastTable[iPos, pColorSrc^.g];
    pColorDst^.B := FContrastTable[iPos, pColorSrc^.B];
    Inc(pColorSrc);
    Inc(pColorDst);
  end;
end;

procedure TdbImage.ContrastProc(const bmpSrc: TBitmap; bmpDst: TBitmap; const iPos: Integer; RefreshImage: TAdjustFunc);
var
  StartScanLineSrc: NativeInt;
  StartScanLineDst: NativeInt;
  bmpWidthBytes   : NativeInt;
  iSpeedTime      : Int64;
begin
  With TStopWatch.StartNew do
  begin
    StartScanLineSrc := NativeInt(bmpSrc.ScanLine[0]);
    StartScanLineDst := NativeInt(bmpDst.ScanLine[0]);
    bmpWidthBytes    := NativeInt(bmpSrc.ScanLine[1]) - NativeInt(bmpSrc.ScanLine[0]);
    TParallel.For(0, bmpSrc.Height - 1,
      procedure(Y: Integer)
      var
        pColorSrc, pColorDst: PRGBQuad;
      begin
        pColorSrc := PRGBQuad(StartScanLineSrc + Y * bmpWidthBytes);
        pColorDst := PRGBQuad(StartScanLineDst + Y * bmpWidthBytes);
        ContrastLineSSE2(pColorSrc, pColorDst, bmpSrc.Width, iPos);
      end);
    iSpeedTime := ElapsedMilliseconds;
    RefreshImage(iSpeedTime);
  end;
end;

{ 调节对比度 }
procedure TdbImage.Contrast(bmp: TBitmap; RefreshImage: TAdjustFunc);
begin
  FbmpTemp := CreateTempBmp(bmp);
  ShowAdjustForm('对比度：', -255, 255, 0, FbmpTemp, bmp, ContrastProc, RefreshImage);
end;

procedure TdbImage.GetGrayAlpha(const iPos: Integer; var alpha: TAlpha; var grays: TGrays);
var
  X   : Integer;
  I   : Integer;
  Gray: Integer;
begin
  for I := 0 to 255 do
  begin
    alpha[I] := (I * iPos) shr 8;
  end;
  X     := 0;
  for I := 0 to 255 do
  begin
    Gray     := I - alpha[I];
    grays[X] := Gray;
    Inc(X);
    grays[X] := Gray;
    Inc(X);
    grays[X] := Gray;
    Inc(X);
  end;
end;

{ 调节饱和度 }
procedure TdbImage.Saturation(bmp: TBitmap; RefreshImage: TAdjustFunc);
begin
  FbmpTemp := CreateTempBmp(bmp);
  ShowAdjustForm('饱和度：', 0, 510, 255, FbmpTemp, bmp, SaturationProc, RefreshImage);
end;

procedure SaturationLineSSE2(pColorSrc, pColorDst: PRGBQuad; const bmpWidth: Integer; const iPos: Integer); inline;
var
  X     : Integer;
  iValue: Integer;
begin
  for X := 0 to bmpWidth - 1 do
  begin
    iValue       := pColorSrc^.R + pColorSrc^.g + pColorSrc^.B;
    pColorDst^.R := FSaturationTable[iPos, iValue, pColorSrc^.R];
    pColorDst^.g := FSaturationTable[iPos, iValue, pColorSrc^.g];
    pColorDst^.B := FSaturationTable[iPos, iValue, pColorSrc^.B];
    Inc(pColorSrc);
    Inc(pColorDst);
  end;
end;

procedure TdbImage.SaturationProc(const bmpSrc: TBitmap; bmpDst: TBitmap; const iPos: Integer; RefreshImage: TAdjustFunc);
var
  StartScanLineSrc: NativeInt;
  StartScanLineDst: NativeInt;
  bmpWidthBytes   : NativeInt;
  iSpeedTime      : Int64;
begin
  With TStopWatch.StartNew do
  begin
    StartScanLineSrc := NativeInt(bmpSrc.ScanLine[0]);
    StartScanLineDst := NativeInt(bmpDst.ScanLine[0]);
    bmpWidthBytes    := NativeInt(bmpSrc.ScanLine[1]) - NativeInt(bmpSrc.ScanLine[0]);
    TParallel.For(0, bmpSrc.Height - 1,
      procedure(Y: Integer)
      var
        pColorSrc, pColorDst: PRGBQuad;
      begin
        pColorSrc := PRGBQuad(StartScanLineSrc + Y * bmpWidthBytes);
        pColorDst := PRGBQuad(StartScanLineDst + Y * bmpWidthBytes);
        SaturationLineSSE2(pColorSrc, pColorDst, bmpSrc.Width, iPos);
      end);
    iSpeedTime := ElapsedMilliseconds;
    RefreshImage(iSpeedTime);
  end;
end;

{ 两幅图片进行透明叠加 }
procedure TdbImage.Blend(bmpBlend, bmp: TBitmap; RefreshImage: TAdjustFunc);
begin
  FbmpTemp := CreateTempBmp(bmp);
  ShowAdjustForm('透明度：', 0, 256, 0, bmpBlend, bmp, BlendProc, RefreshImage);
end;

procedure TdbImage.BlendProc(const bmpBlend: TBitmap; bmpDst: TBitmap; const iPos: Integer; RefreshImage: TAdjustFunc);
var
  iLeft, iTop     : Integer;
  bmpWidthBytesSrc: NativeInt;
  bmpWidthBytesDst: NativeInt;
  StartScanLineDst: NativeInt;
  StartScanLineSrc: NativeInt;
  iSpeedTime      : Int64;
begin
  if bmpBlend.Width > bmpDst.Width then
    Exit;

  if bmpBlend.Height > bmpDst.Height then
    Exit;

  With TStopWatch.StartNew do
  begin
    bmpDst.Canvas.Draw(0, 0, FbmpTemp);

    iTop             := (bmpDst.Height - bmpBlend.Height) div 2;
    iLeft            := (bmpDst.Width - bmpBlend.Width) div 2;
    StartScanLineSrc := NativeInt(bmpBlend.ScanLine[0]);
    StartScanLineDst := NativeInt(bmpDst.ScanLine[iTop]);
    bmpWidthBytesSrc := NativeInt(bmpBlend.ScanLine[1]) - NativeInt(bmpBlend.ScanLine[0]);
    bmpWidthBytesDst := NativeInt(bmpDst.ScanLine[1]) - NativeInt(bmpDst.ScanLine[0]);
    TParallel.For(0, bmpBlend.Height - 1,
      procedure(Y: Integer)
      var
        pColorDst: PRGBQuad;
        pColorSrc: PRGBQuad;
      begin
        pColorDst := PRGBQuad(StartScanLineDst + Y * bmpWidthBytesDst);
        pColorSrc := PRGBQuad(StartScanLineSrc + Y * bmpWidthBytesSrc);
        Inc(pColorDst, iLeft);
        BlendLineSSE2(pColorSrc, pColorDst, bmpBlend.Width, iPos);
      end);
    iSpeedTime := ElapsedMilliseconds;
    RefreshImage(iSpeedTime);
  end;
end;

{ 曝光 }
procedure TdbImage.Exposure(bmp: TBitmap);
var
  StartScanLine: NativeInt;
  bmpWidthBytes: NativeInt;
begin
  StartScanLine := NativeInt(bmp.ScanLine[0]);
  bmpWidthBytes := NativeInt(bmp.ScanLine[1]) - NativeInt(bmp.ScanLine[0]);

  TParallel.For(0, bmp.Height - 1,
    procedure(Y: Integer)
    var
      pColor: PRGBQuad;
    begin
      pColor := PRGBQuad(StartScanLine + Y * bmpWidthBytes);
      ExposureLineSSE2(pColor, bmp.Width);
    end);
end;

{ 浮雕 }
procedure TdbImage.Emboss(bmp: TBitmap);
var
  StartScanLineSrc: NativeInt;
  StartScanLineDst: NativeInt;
  bmpWidthBytes   : NativeInt;
begin
  StartScanLineSrc := NativeInt(Fbmp32.ScanLine[0]);
  StartScanLineDst := NativeInt(bmp.ScanLine[0]);
  bmpWidthBytes    := NativeInt(Fbmp32.ScanLine[1]) - NativeInt(Fbmp32.ScanLine[0]);

  TParallel.For(0, Fbmp32.Height - 2,
    procedure(Y: Integer)
    var
      pColor001: PRGBQuad;
      pColor002: PRGBQuad;
      pColorDst: PRGBQuad;
    begin
      pColor001 := PRGBQuad(StartScanLineSrc + (Y + 0) * bmpWidthBytes);
      pColor002 := PRGBQuad(StartScanLineSrc + (Y + 1) * bmpWidthBytes);
      pColorDst := PRGBQuad(StartScanLineDst + (Y + 0) * bmpWidthBytes);
      EmbossLineSSE2(pColor001, pColor002, pColorDst, Fbmp32.Width);
    end);
end;

{ 雕刻 }
procedure TdbImage.Engrave(bmp: TBitmap);
var
  StartScanLineSrc: NativeInt;
  StartScanLineDst: NativeInt;
  bmpWidthBytes   : NativeInt;
begin
  StartScanLineSrc := NativeInt(Fbmp32.ScanLine[0]);
  StartScanLineDst := NativeInt(bmp.ScanLine[0]);
  bmpWidthBytes    := NativeInt(Fbmp32.ScanLine[1]) - NativeInt(Fbmp32.ScanLine[0]);

  TParallel.For(0, Fbmp32.Height - 2,
    procedure(Y: Integer)
    var
      pColor001: PRGBQuad;
      pColor002: PRGBQuad;
      pColorDst: PRGBQuad;
    begin
      pColor001 := PRGBQuad(StartScanLineSrc + (Y + 0) * bmpWidthBytes);
      pColor002 := PRGBQuad(StartScanLineSrc + (Y + 1) * bmpWidthBytes);
      pColorDst := PRGBQuad(StartScanLineDst + (Y + 0) * bmpWidthBytes);
      EngraveLineSSE2(pColor001, pColor002, pColorDst, Fbmp32.Width);
    end);
end;

end.
