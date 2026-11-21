unit uImageKit;
{ 
  图像解码与位图处理公共单元
  1 优先使用 Windows WIC (TWICImage) 按内容嗅探解码, 支持系统已安装的 JPG/PNG/GIF/BMP/TIFF/WebP/AVIF/HEIC/ICO/DDS 等格式;
  2 WIC 失败时回退到 VCL 的 TPicture (WMF/EMF/QOI 等);
  3 缩放与缩略图使用 WIC 的 HighQualityCubic 插值
}

interface

uses Winapi.Windows, Winapi.ShellAPI, System.SysUtils, System.Classes, System.Math, System.Types, System.Threading, System.IOUtils,
     Vcl.Graphics, Vcl.Imaging.jpeg, Vcl.Imaging.pngimage, Vcl.Imaging.QOI, TurboJpeg.Static, TurboJpeg.Bitmap;

const
  { 缩略图底色 / 查看器底色: 深色主题的基调 }
  THUMB_BG        = $002C2C2C;
  VIEWER_BG       = $00202020;
  IMAGE_EXTS      = ';jpg;jpeg;jpe;jfif;png;gif;bmp;dib;rle;tif;tiff;qoi;webp;avif;heic;heif;hif;ico;cur;jxr;wdp;wmp;dds;emf;wmf;';
  IMAGE_WILDCARDS = '*.jpg;*.jpeg;*.jpe;*.jfif;*.png;*.gif;*.bmp;*.dib;*.rle;' +
                    '*.tif;*.tiff;*.qoi;*.webp;*.avif;*.heic;*.heif;*.hif;*.ico;*.cur;' +
                    '*.jxr;*.wdp;*.wmp;*.dds;*.emf;*.wmf';

function IsImageFile(const AFileName: string): Boolean;
function ImageOpenFilter: string;
function ImageSaveFilter: string;

{ 打开一个图像文件, 同时返回 32 位位图与 WIC 源对象。 AWic 可能为 nil (WIC 不支持该格式时), 调用方负责释放两者。 }
procedure LoadImageFile(const AFileName: string; out ABitmap: TBitmap; out AWic: TWICImage);

{ WIC 不支持的格式 (如 QOI): 走 TPicture 解码, 失败返回 nil }
function DecodeViaPicture(const AFileName: string): TBitmap;

{ 生成 ASize x ASize 的缩略图 (居中、留边、不改变纵横比) }
function MakeThumbBitmap(const AFileName: string; ASize: Integer): TBitmap;

{ 生成 ASize x ASize 的文件夹图标位图: 图标占满与缩略图相同的内容区, 且始终使用标准文件夹图标 (盘符根目录也不会变成磁盘图标) }
function MakeFolderIconBitmap(ASize: Integer; const AFolder: string): TBitmap;

{ 生成 ASize x ASize 的"硬盘"图标位图: 本机磁盘列表里的盘符用它 }
function MakeDriveIconBitmap(ASize: Integer): TBitmap;

{ 生成 ASize x ASize 的"上一级目录"图标位图: 文件夹上叠一个向上箭头 }
function MakeUpIconBitmap(ASize: Integer): TBitmap;

{ 生成不超过 AMaxW x AMaxH 的等比预览图 (不留边) }
function MakePreviewBitmap(const AFileName: string; AMaxW, AMaxH: Integer): TBitmap;

{ 占位图 (加载中 / 无法解码); ADrawGlyph=False 时只画底板 }
function PlaceholderBitmap(ASize: Integer; ADrawGlyph: Boolean = True): TBitmap;

function ScaleBitmap(const ASrc: TBitmap; AWidth, AHeight: Integer): TBitmap;
function RotateBitmap(const ASrc: TBitmap; AQuarters: Integer): TBitmap;
function FormatFileSize(ASize: Int64): string;

implementation

type
  { TRow/PRow: 按 32 位整数行访问像素 (旋转用), 范围检查关闭时按整行使用 }
  TRow = array[0..0] of Integer;
  PRow = ^TRow;
  { TPixRow: 按字节访问 32 位像素 (BGRA), 只取 alpha 字节 }
  TPixRow = array[0..3] of Byte;
  PPixRow = ^TPixRow;

function IsImageFile(const AFileName: string): Boolean;
begin
  var E := LowerCase(ExtractFileExt(AFileName));
  if (E <> '') and (E[1] = '.') then Delete(E, 1, 1);
  Result := Pos(';' + E + ';', IMAGE_EXTS) > 0;
end;

function ImageOpenFilter: string;
begin
  Result := '常用图像|*.jpg;*.jpeg;*.jpe;*.jfif;*.png;*.gif;*.bmp;*.dib;*.tif;*.tiff;*.webp;*.qoi|全部支持的格式|' + IMAGE_WILDCARDS + '|所有文件 (*.*)|*.*';
end;

function ImageSaveFilter: string;
begin
  Result := 'PNG 图像 (*.png)|*.png|JPEG 图像 (*.jpg)|*.jpg|Windows 位图 (*.bmp)|*.bmp';
end;

function LoadWicImage(const AFileName: string): TWICImage;
begin
  Result := TWICImage.Create;
  try
    Result.LoadFromFile(AFileName);
    if (Result.Width < 1) or (Result.Height < 1) then raise Exception.Create('图像尺寸无效');
  except
    Result.Free;
    raise;
  end;
end;

procedure NormalizeBitmap(ABitmap: TBitmap);
begin
  if ABitmap.PixelFormat <> pf32bit then ABitmap.PixelFormat := pf32bit;
  if (ABitmap.Width < 1) or (ABitmap.Height < 1) then raise Exception.Create('图像尺寸无效');
end;

{ 把位图的所有像素强制设为不透明: 缩略图画到深色底板时不会出现黑边 }
procedure ForceOpaqueBitmap(ABitmap: TBitmap);
begin
  if (ABitmap = nil) or (ABitmap.Width < 1) or (ABitmap.Height < 1) then Exit;

  if ABitmap.PixelFormat <> pf32bit then ABitmap.PixelFormat := pf32bit;
  var StartScanLine := NativeInt(ABitmap.ScanLine[0]);
  var bmpWidthBytes := NativeInt(ABitmap.ScanLine[1]) - NativeInt(ABitmap.ScanLine[0]);
  TParallel.For(0, ABitmap.Height - 1,
    procedure(Y: Integer)
    var
      pColor: PRGBQuad;
    begin
      pColor := PRGBQuad(StartScanLine + Y * bmpWidthBytes);
      for var X := 0 to ABitmap.Width - 1 do
      begin
        pColor^.rgbReserved := $FF;
        Inc(pColor);
      end;
    end);
end;

{ TPicture 解码: WIC 不认识的格式 (QOI/WMF/EMF 等) 走这里 }
function DecodeViaPicture(const AFileName: string): TBitmap;
begin
  Result := nil;
  var Pic := TPicture.Create;
  try
    try
      Pic.LoadFromFile(AFileName);
      if (Pic.Graphic = nil) or Pic.Graphic.Empty then Exit;
      Result := TBitmap.Create;
      try
        Result.Assign(Pic.Graphic);
        NormalizeBitmap(Result);
      except
        FreeAndNil(Result);
        raise;
      end;
    except
      FreeAndNil(Result);
    end;
  finally
    Pic.Free;
  end;
end;

function LoadJpegFileWithTurboJpegDec(const AFileName : string; out ABitmap : TBitmap) : Boolean;
begin
  Result := True;
  var Data := TFile.ReadAllBytes(AFileName);
  try
    TjDecodeToBitmap(Data, ABitmap);
  except
    Result := False;
  end;
end;

procedure LoadImageFile(const AFileName: string; out ABitmap: TBitmap; out AWic: TWICImage);
begin
  if SameText(ExtractFileExt(AFileName), '.jpg') then
  begin
   if LoadJpegFileWithTurboJpegDec(AFileName, ABitmap) then Exit;
  end;

  ABitmap := nil;
  AWic    := nil;
  try
    try
      AWic    := LoadWicImage(AFileName);
      ABitmap := TBitmap.Create;
      ABitmap.Assign(AWic);
    except
      FreeAndNil(AWic);
      FreeAndNil(ABitmap);
      ABitmap := DecodeViaPicture(AFileName);
      if ABitmap = nil then raise Exception.Create('无法识别的图像格式');
    end;
    NormalizeBitmap(ABitmap);
  except
    FreeAndNil(AWic);
    FreeAndNil(ABitmap);
    raise;
  end;
end;

{ Shell 图标解析失败时的替代: 画一个统一风格的文件夹 }
procedure DrawFolderGlyph(C: TCanvas; const R: TRect);
var
  Pts: array[0..3] of TPoint;
begin
  var W := R.Right - R.Left;
  var H := R.Bottom - R.Top;
  var TabW := W * 2 div 5;
  var TabH := Max(3, H div 8);
  C.Pen.Width := 1;
  C.Brush.Style := bsSolid;
  { 文件夹标签 }
  C.Brush.Color := $0038A0E0;
  C.Pen.Color := $002878B0;
  C.RoundRect(R.Left, R.Top, R.Left + TabW, R.Top + TabH * 2, Max(2, W div 30), Max(2, H div 30));
  { 主体 }
  C.Brush.Color := $0050B8F0;
  C.Pen.Color := $003080C0;
  C.RoundRect(R.Left, R.Top + TabH, R.Right, R.Bottom - H div 12, Max(2, W div 24), Max(2, H div 24));
  { 前沿高光 }
  C.Brush.Color := $0078D8FF;
  C.Pen.Color := $0048A8E0;
  Pts[0] := Point(R.Left + W div 24, R.Top + TabH + H div 9);
  Pts[1] := Point(R.Right - W div 24, R.Top + TabH + H div 9);
  Pts[2] := Point(R.Right - W div 18, R.Bottom - H div 10);
  Pts[3] := Point(R.Left + W div 24, R.Bottom - H div 10);
  C.Polygon(Pts);
end;

function PlaceholderBitmap(ASize: Integer; ADrawGlyph: Boolean): TBitmap;
begin
  Result := TBitmap.Create;
  Result.PixelFormat := pf32bit;
  Result.SetSize(ASize, ASize);
  var C         := Result.Canvas;
  C.Brush.Color := $002C2C2C;
  C.FillRect(Rect(0, 0, ASize, ASize));
  var R         := Rect(6, 6, ASize - 6, ASize - 6);
  C.Pen.Color   := $003C4043;
  C.Pen.Width   := 1;
  C.Brush.Style := bsClear;
  C.Rectangle(R);
  if ADrawGlyph then
  begin
    C.Brush.Color := $00383838;
    C.Pen.Color   := $00454545;
    C.Ellipse(R.Left + ASize div 8, R.Top + ASize div 8, R.Left + ASize div 4, R.Top + ASize div 4);
    C.Brush.Style := bsClear;
    C.Pen.Color   := $00505050;
    C.MoveTo(R.Left  + 4, R.Bottom - 6);
    C.LineTo(R.Left  + ASize div 3, R.Top + ASize div 2);
    C.LineTo(R.Left  + ASize div 2, R.Bottom - ASize div 5);
    C.LineTo(R.Right - ASize div 4, R.Bottom - 6);
    C.Brush.Style := bsSolid;
  end;
end;

function MakeThumbBitmap(const AFileName: string; ASize: Integer): TBitmap;
var
  W, S: TWICImage;
  Tmp, Src: TBitmap;
  OW, OH, TW, TH, X, Y: Integer;
  K: Double;
begin
  Result := PlaceholderBitmap(ASize);
  W      := nil;
  S      := nil;
  Tmp    := nil;
  Src    := nil;
  try
    W  := LoadWicImage(AFileName);
    OW := W.Width;
    OH := W.Height;
    if (OW < 1) or (OH < 1) then Exit;
    K := Min((ASize - 10) / OW, (ASize - 10) / OH);
    if K > 1 then K := 1;
    TW  := Max(1, Round(OW * K));
    TH  := Max(1, Round(OH * K));
    S   := W.CreateScaledCopy(TW, TH, wipmHighQualityCubic);
    Tmp := TBitmap.Create;
    Tmp.Assign(S);
    X := (ASize - TW) div 2;
    Y := (ASize - TH) div 2;
    Result.Canvas.Draw(X, Y, Tmp);
  except
    { WIC 不支持的格式 (QOI): 走 TPicture 解码, HALFTONE 缩放 }
    FreeAndNil(W);
    FreeAndNil(S);
    FreeAndNil(Tmp);
    Src := DecodeViaPicture(AFileName);
    if Src = nil then Exit;
    var Clean := TBitmap.Create;
    try
      Clean.PixelFormat := pf32bit;
      Clean.SetSize(ASize, ASize);
      Clean.Canvas.Brush.Color := THUMB_BG;
      Clean.Canvas.FillRect(Rect(0, 0, ASize, ASize));
      K := Min((ASize - 10) / Src.Width, (ASize - 10) / Src.Height);
      if K > 1 then K := 1;
      TW := Max(1, Round(Src.Width * K));
      TH := Max(1, Round(Src.Height * K));
      SetStretchBltMode(Clean.Canvas.Handle, HALFTONE);
      X := (ASize - TW) div 2;
      Y := (ASize - TH) div 2;
      Clean.Canvas.StretchDraw(Rect(X, Y, X + TW, Y + TH), Src);
      Result.Canvas.Draw(0, 0, Clean);
    finally
      FreeAndNil(Clean);
    end;
  end;
  FreeAndNil(Src);
  FreeAndNil(Tmp);
  FreeAndNil(S);
  FreeAndNil(W);
end;

var
  GFolderIconCache    : TBitmap = nil;
  GFolderIconCacheSize: Integer = 0;

{ 生成 ASize x ASize 的文件夹图标位图: 图标占满与缩略图相同的内容区, 且始终使用标准文件夹图标 (盘符根目录也不会变成磁盘图标) }
function MakeFolderIconBitmap(ASize: Integer; const AFolder: string): TBitmap;
var
  S, X, Y: Integer;
begin
  if ASize < 16 then ASize := 16;
  { 同一线程只画一次: 缓存住, 后续同级目录直接复用 }
  if (GFolderIconCache <> nil) and (GFolderIconCacheSize = ASize) then
  begin
    Result := TBitmap.Create;
    Result.Assign(GFolderIconCache);
    Exit;
  end;
  
  Result := PlaceholderBitmap(ASize, False);
  try
    S := ASize - 10;
    if S < 16  then S := 16;
    if S > 256 then S := 256;
    X := (ASize - S) div 2;
    Y := (ASize - S) div 2;
    { Use the built-in glyph only. SHGetFileInfo loads shell extensions
      (Dokan / network providers) on the UI thread and can hang for seconds
      on virtual drives such as F:. }
    DrawFolderGlyph(Result.Canvas, Rect(X, Y, X + S, Y + S));
    ForceOpaqueBitmap(Result);
    FreeAndNil(GFolderIconCache);
    GFolderIconCache := TBitmap.Create;
    GFolderIconCache.Assign(Result);
    GFolderIconCacheSize := ASize;
  except
    FreeAndNil(Result);
    raise;
  end;
end;

{ 生成 ASize x ASize 的硬盘图标位图 }
function MakeDriveIconBitmap(ASize: Integer): TBitmap;
var
  C: TCanvas;
  I, S, CX, CY, RX, RY, TH : Integer;
begin
  if ASize < 16 then ASize := 16;
  Result := PlaceholderBitmap(ASize, False);
  C := Result.Canvas;
  S := ASize - 8;
  if S < 16 then S := 16;
  if S > 256 then S := 256;
  var X := (ASize - S) div 2;
  var Y := (ASize - S) div 2;
  C.Brush.Style := bsSolid;
  C.Pen.Width := 1;

  { 机身: 深色圆角方块 }
  C.Brush.Color := $002A3038;
  C.Pen.Color := $0020262C;
  C.RoundRect(X, Y, X + S, Y + S, Max(4, S div 6), Max(4, S div 6));

  { 立体盘片: 侧壁 + 顶面椭圆 }
  CX := X + S div 2;
  CY := Y + S div 2;
  RX := S div 3;
  RY := Max(4, S div 7);
  TH := Max(4, S div 7);
  C.Brush.Color := $006E7681;
  C.Pen.Color := $0020262C;
  C.Rectangle(CX - RX, CY, CX + RX, CY + TH);
  C.Brush.Color := $00313943;
  C.Ellipse(CX - RX, CY + TH - RY, CX + RX, CY + TH + RY);
  C.Brush.Color := $00A2AAB4;
  C.Pen.Color := $0020262C;
  C.Ellipse(CX - RX, CY - RY, CX + RX, CY + RY);

  { 盘片内圈 }
  C.Brush.Style := bsClear;
  C.Pen.Color := $00545C66;
  C.Pen.Width := Max(1, S div 48);
  C.Ellipse(CX - RX + S div 8, CY - RY + S div 14, CX + RX - S div 8, CY + RY - S div 14);
  C.Brush.Style := bsSolid;

  { 轴心 }
  I := Max(2, S div 22);
  C.Brush.Color := $00D0D0C6;
  C.Pen.Color := $0020262C;
  C.Ellipse(CX - I, CY - I, CX + I, CY + I);

  { 磁头臂 }
  C.Pen.Color := $00B4B09A;
  C.Pen.Width := Max(1, S div 32);
  C.MoveTo(CX, CY);
  C.LineTo(CX + S div 4, CY - S div 6);

  { 指示灯 }
  I := Max(2, S div 26);
  C.Brush.Color := $00FAC85A;
  C.Pen.Color   := $00523E18;
  C.Ellipse(X + S - S div 5, Y + S - S div 5, X + S - S div 5 + I * 2, Y + S - S div 5 + I * 2);

  ForceOpaqueBitmap(Result);
end;

{ 上一级目录图标: 文件夹 + 向上箭头 }
function MakeUpIconBitmap(ASize: Integer): TBitmap;
var
  Pts: array[0..2] of TPoint;
begin
  if ASize < 16 then ASize := 16;
  Result := PlaceholderBitmap(ASize, False);
  var C := Result.Canvas;
  var S := ASize - 10;
  if S < 16 then S := 16;
  if S > 256 then S := 256;
  var R := Rect((ASize - S) div 2, (ASize - S) div 2, (ASize - S) div 2 + S, (ASize - S) div 2 + S);
  DrawFolderGlyph(C, R);
  { 向上箭头压在文件夹正中: 深色描边 + 近白填充 }
  var CX        := (R.Left + R.Right) div 2;
  var CY        := (R.Top + R.Bottom) div 2;
  var HW        := Max(6, S div 6);
  var HH        := Max(8, S div 5);
  var Stem      := Max(2, HW div 3);
  C.Pen.Width   := 2;
  C.Pen.Color   := $00202830;
  C.Brush.Color := $00F0F4F8;
  C.Brush.Style := bsSolid;
  { 箭杆 }
  C.Rectangle(CX - Stem, CY - HH div 4, CX + Stem, CY + HH div 2);
  { 箭头 }
  Pts[0] := Point(CX, CY - HH);
  Pts[1] := Point(CX + HW, CY - HH div 4);
  Pts[2] := Point(CX - HW, CY - HH div 4);
  C.Polygon(Pts);
  ForceOpaqueBitmap(Result);
end;

function MakePreviewBitmap(const AFileName: string; AMaxW, AMaxH: Integer): TBitmap;
var
  W, S: TWICImage;
  Tmp: TBitmap;
  OW, OH, TW, TH: Integer;
  K: Double;
begin
  Result := nil;
  W      := nil;
  S      := nil;
  Tmp    := nil;
  try
    AMaxW := Max(1, AMaxW);
    AMaxH := Max(1, AMaxH);
    try
      W := LoadWicImage(AFileName);
      OW := W.Width;
      OH := W.Height;
      K  := Min(AMaxW / OW, AMaxH / OH);
      if K > 1 then K := 1;
      TW := Max(1, Round(OW * K));
      TH := Max(1, Round(OH * K));
      S  := W.CreateScaledCopy(TW, TH, wipmHighQualityCubic);
    except
      FreeAndNil(W);
      FreeAndNil(S);
      Tmp := DecodeViaPicture(AFileName);
      if Tmp = nil then Exit;
      OW := Tmp.Width;
      OH := Tmp.Height;
      K  := Min(AMaxW / OW, AMaxH / OH);
      if K > 1 then K := 1;
      TW := Max(1, Round(OW * K));
      TH := Max(1, Round(OH * K));
      Result := TBitmap.Create;
      Result.PixelFormat := pf32bit;
      Result.SetSize(TW, TH);
      SetStretchBltMode(Result.Canvas.Handle, HALFTONE);
      Result.Canvas.StretchDraw(Rect(0, 0, TW, TH), Tmp);
    end;
  finally
    FreeAndNil(Tmp);
    FreeAndNil(S);
    FreeAndNil(W);
  end;
end;

function ScaleBitmap(const ASrc: TBitmap; AWidth, AHeight: Integer): TBitmap;
begin
  Result := TBitmap.Create;
  Result.PixelFormat := pf32bit;
  Result.SetSize(Max(1, AWidth), Max(1, AHeight));
  Result.AlphaFormat := ASrc.AlphaFormat;
  SetStretchBltMode(Result.Canvas.Handle, HALFTONE);
  Result.Canvas.StretchDraw(Rect(0, 0, Result.Width, Result.Height), ASrc);
end;

function RotateBitmap(const ASrc: TBitmap; AQuarters: Integer): TBitmap;
var
  Q, W, H, DW, DH, X, Y, DX, DY, I: Integer;
  SrcRows, DstRows: array of PRow;
  Norm, S: TBitmap;
begin
  Q := ((AQuarters mod 4) + 4) mod 4;
  Result := TBitmap.Create;
  try
    if Q = 0 then
    begin
      Result.Assign(ASrc);
      Exit;
    end;

    Norm := nil;
    S := ASrc;
    if ASrc.PixelFormat <> pf32bit then
    begin
      Norm := TBitmap.Create;
      Norm.Assign(ASrc);
      Norm.PixelFormat := pf32bit;
      S := Norm;
    end;
    try
      W := S.Width;
      H := S.Height;
      if (Q = 1) or (Q = 3) then
      begin
        DW := H;
        DH := W;
      end
      else
      begin
        DW := W;
        DH := H;
      end;

      Result.PixelFormat := pf32bit;
      Result.SetSize(DW, DH);
      Result.AlphaFormat := ASrc.AlphaFormat;

      SetLength(SrcRows, H);
      SetLength(DstRows, DH);
      for I := 0 to H - 1 do
        SrcRows[I] := PRow(S.ScanLine[I]);
      for I := 0 to DH - 1 do
        DstRows[I] := PRow(Result.ScanLine[I]);

      for Y := 0 to H - 1 do
        for X := 0 to W - 1 do
        begin
          case Q of
            1: begin DX := H - 1 - Y; DY := X; end;
            2: begin DX := W - 1 - X; DY := H - 1 - Y; end;
            else begin DX := Y; DY := W - 1 - X; end;
          end;
          DstRows[DY]^[DX] := SrcRows[Y]^[X];
        end;
    finally
      Norm.Free;
    end;
  except
    Result.Free;
    raise;
  end;
end;

function FormatFileSize(ASize: Int64): string;
begin
  if ASize < 1024 then
    Result := Format('%d B', [ASize])
  else if ASize < Int64(1024) * 1024 then
    Result := Format('%.1f KB', [ASize / 1024])
  else if ASize < Int64(1024) * 1024 * 1024 then
    Result := Format('%.1f MB', [ASize / (1024 * 1024)])
  else
    Result := Format('%.2f GB', [ASize / (1024 * 1024 * 1024)]);
end;

end.
