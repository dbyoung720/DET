unit uCommon;
{$WARN SYMBOL_PLATFORM OFF}

interface

uses
  Winapi.Windows, Winapi.Messages, Winapi.IpTypes, Winapi.IpHlpApi, Winapi.PsAPI, Winapi.GDIPOBJ, Winapi.GDIPAPI, Winapi.ActiveX, Winapi.ShellAPI,
  System.Win.ComObj, System.Variants, System.Math, System.Classes, System.SysUtils, System.Threading, IOUtils,
  Vcl.Forms, Vcl.Graphics, {$I ffhead.inc}, DSUtil;

const
  c_intMaxFrame = 4;
  c_intRightSHT = 2;

type
  TarrBmp  = array [0 .. c_intMaxFrame - 1] of TBitmap;
  TArrFace = array [0 .. 127] of TRect;

  {
    硬件加速编码
    hwNone   : 不使用硬件加速编码
    hwIntel  : 使用 Intel  视频卡硬件加速编码 <Intel  630 以上显卡>
    hwNvidia : 使用 Nvidia 视频卡硬件加速编码 <Nvidia Geforce 1030 以上显卡> <https://developer.nvidia.com/video-encode-and-decode-gpu-support-matrix-new>
  }
  THardwareAccel = (hwNone, hwIntel, hwNvidia);

  PVideoTYStyle       = ^TVideoTYStyle;
  PVideo_Text         = ^TVideo_Text;         // 0  视频上画文字
  PVideo_Circle       = ^TVideo_Circle;       // 1  视频上画圆
  PVideo_Ellipse      = ^TVideo_Ellipse;      // 2  视频上画椭圆
  PVideo_Square       = ^TVideo_Square;       // 3  视频上画正方形
  PVideo_Rectangle    = ^TVideo_Rectangle;    // 4  视频上画长方形
  PVideo_Polygon      = ^TVideo_Polygon;      // 5  视频上画多边形 <首尾连接>
  PVideo_Line         = ^TVideo_Line;         // 6  视频上画直线
  PVideo_Curve        = ^TVideo_Curve;        // 7  视频上画曲线
  PVideo_MulLine      = ^TVideo_MulLine;      // 8  视频上画折线/线段
  PVideo_MulCurve     = ^TVideo_MulCurve;     // 9  视频上画多点曲线
  PVideo_SpecialPoint = ^TVideo_SpecialPoint; // 10 视频上画红心
  PVideo_Point        = ^TVideo_Point;        // 11 视频上画点
  PVideo_Any          = ^TVideo_Any;          // 12 视频上画任意线 <相连两点线段连接>

  TVideoTYStyle = record
    intIndex: Integer;
    tyStyle: Pointer;
  end;

  { 0: 视频上画文字 }
  TVideo_Text = record
    pt: TPoint;
    text: array [0 .. 255] of AnsiChar;
    fontName: array [0 .. 9] of AnsiChar;
    fontsize: Integer;
    fontColor: TColor;
  end;

  { 1: 视频上画圆 }
  TVideo_Circle = record
    ptStart, ptEnd: TPoint;
    color: TColor;
    size: Integer;
    fill: Boolean;
    style: Integer;
  end;

  { 2: 视频上画椭圆 }
  TVideo_Ellipse = record
    ptStart, ptEnd: TPoint;
    color: TColor;
    size: Integer;
    fill: Boolean;
    style: Integer;
  end;

  { 4: 视频上画长方形 }
  TVideo_Rectangle = record
    ptStart, ptEnd: TPoint;
    color: TColor;
    size: Integer;
    fill: Boolean;
    style: Integer;
  end;

  { 3: 视频上画正方形 }
  TVideo_Square = TVideo_Rectangle;

  { 5: 视频上画多边形 <首尾连接> }
  TVideo_Polygon = record
    pt: array of TGPPoint;
    count: Integer;
    color: TColor;
    size: Integer;
    fill: Boolean;
    style: Integer;
    bEnd: Boolean;
  end;

  { 6: 视频上画直线 }
  TVideo_Line = record
    ptStart, ptEnd: TPoint; // 起始、结束坐标
    color: TColor;          // 颜色
    size: Integer;          // 线宽
    style: Integer;         // 0:虚线、1:实线
  end;

  { 7: 视频上画曲线 }
  TVideo_Curve = record
    pt: array [0 .. 2] of TGPPoint;
    color: TColor;
    size: Integer;
    style: Integer; // 0:虚线、1:实线
    bEnd: Boolean;
  end;

  { 8: 视频上画折线/线段 }
  TVideo_MulLine = record
    pt: array of TPoint;
    count: Integer;
    color: TColor;
    size: Integer;
    style: Integer;
    bEnd: Boolean;
  end;

  { 9: 视频上画多点曲线 }
  TVideo_MulCurve = record
    pt: array of TGPPoint;
    count: Integer;
    color: TColor;
    size: Integer;
    style: Integer;
    fill: Boolean;
    bEnd: Boolean;
  end;

  { 10: 视频上画红心 }
  TVideo_SpecialPoint = record
    pt: TPoint;
    fontColor: TColor;
    fontsize: Integer;
    text: UnicodeString; // WideChar;
  end;

  { 11: 视频上画点 }
  TVideo_Point = record
    pt: TPoint;
    color: TColor;
    size: Integer;
  end;

  { 12: 视频上画任意线 <相连两点线段连接> }
  TVideo_Any = record
    pt: array of TPoint;
    count: Integer;
    color: TColor;
    size: Integer;
    style: Integer;
  end;

  TVideoDrawUI = procedure(hVideo: THandle; pBuffer: Pointer; const BufferLen: Integer);

procedure LogErr(const strTemp: string);

{ 格式化当前时间 }
function GetFormatCurrentTime: String;

{ 水平翻转 并行模式 }
procedure HorizMirror(bmp: TBitmap);

{ 图片垂直镜像 }
procedure VertiMirror(bmp: TBitmap);

{ 转置翻转 并行模式 }
procedure HAndVMirror(bmp: TBitmap);

{ 灰度 }
procedure dbImageGray(bmp: TBitmap);

{ 获取本机网卡列表信息 }
function GetAdapterInfo(var lst: TList): Boolean;

{ 清除视频涂鸦列表 }
procedure FreeVideoTYList(const bFree: Boolean = False);

{ 获取进程路径 }
function GetProcessPath: String;

{ 截图保存 }
procedure SnapBmp(const hForm: THandle; bmp: TBitmap; bSnapHD: Boolean = False);

{ 叠加降噪 }
procedure HDBmp32(const bmp: array of TBitmap; var bmpResult: TBitmap);

{ 检查系统是否是中文操作系统 }
function CheckChineseUI: Boolean;

{ 时间有效期 }
function CheckTimeLimited: Boolean;

{ 获取本机 IP }
function GetNativeIP: PAnsiChar;

{ 检测 CPU 支持的指令集 <Check CPU support instruction set> }
procedure CheckCPU(var bMMX, bSSE1, bSSE2, bSSE3, bSSEE3, bSSE41, bSSE42, bAES, bFMA, bAVX1, bAVX2, bAVX512: Boolean);

{ 0 绘制文字 }
procedure DrawTY_Text(bmp: TBitmap; tyvs: TVideo_Text);

{ 1 绘制圆 }
procedure DrawTY_Circle(bmp: TBitmap; tyvs: TVideo_Circle);

{ 2 绘制椭圆 }
procedure DrawTY_Ellipse(bmp: TBitmap; tyvs: TVideo_Ellipse);

{ 3 绘制正方形 }
procedure DrawTY_Square(bmp: TBitmap; tyvs: TVideo_Square);

{ 4 绘制矩形 }
procedure DrawTY_Rectangle(bmp: TBitmap; tyvs: TVideo_Rectangle);

{ 5 绘制多边形 }
procedure DrawTY_Polygon(bmp: TBitmap; tyvs: TVideo_Polygon);

{ 6 绘制直线 }
procedure DrawTY_Line(bmp: TBitmap; tyvs: TVideo_Line);

{ 7 绘制曲线 }
procedure DrawTY_Curve(bmp: TBitmap; tyvs: TVideo_Curve);

{ 8 绘制多点线段 }
procedure DrawTY_MulLine(bmp: TBitmap; tyvs: TVideo_MulLine);

{ 9 绘制多点曲线 }
procedure DrawTY_MulCurve(bmp: TBitmap; tyvs: TVideo_MulCurve);

{ 10 绘制红心 }
procedure DrawTY_RedHeart(bmp: TBitmap; tyvs: TVideo_SpecialPoint);

{ 11 绘制任意 }
procedure DrawTY_Any(bmp: TBitmap; tyvs: TVideo_Any);

procedure DeNoisesPlus(bmp: TarrBmp; var bmpResult: TBitmap);

procedure InitSDK;
procedure FreeSDK;

{ CPU 人脸检测 }
function CheckFace(hbmp: HBITMAP; const strTempModelFileName: PAnsiChar; rct: TArrFace; var count: Integer; var iTime: Integer; const scale: Double = 5.0): Boolean; cdecl; external 'dbFace.dll';

{ ROI 感兴趣获取 }
function CheckROI(hbmp: HBITMAP;                                                //
  var iTime: Integer;                                                           // 耗时
  var Perimeter: Double;                                                        // 面积
  var Area: Double;                                                             // 周长
  const lowerR: Byte = 000; const lowerG: Byte = 000; const lowerB: Byte = 100; //
  const upperR: Byte = 255; const upperG: Byte = 255; const upperB: Byte = 120): Boolean; cdecl; external 'dbFace.dll';

const
  WM_DRAWTEXT                                      = WM_USER + $1000;
  c_strVirtualDesktopName                          = 'dbVideoSDK Virtual Desktop';
  c_arrAccFormat: array [0 .. 2] of AnsiString     = ('libopenh264', 'h264_qsv', 'h264_nvenc');
  c_arrVideoType: array [0 .. 2] of TAVPixelFormat = (AV_PIX_FMT_YUV420P, AV_PIX_FMT_NV12, AV_PIX_FMT_YUV420P);

var
  g_lstVideoTY: TList = nil;

implementation

function GetNativeIP: PAnsiChar;
var
  lstAdapter  : TList;
  I           : Integer;
  AdapterInfoX: PIP_ADAPTER_INFO;
  strGatewayIP: String;
  strNative_IP: String;
begin
  Result := '';

  lstAdapter := TList.Create;
  try
    GetAdapterInfo(lstAdapter);
    if lstAdapter.count <= 0 then
      Exit;

    for I := 0 to lstAdapter.count - 1 do
    begin
      AdapterInfoX := PIP_ADAPTER_INFO(lstAdapter.Items[I]);
      strGatewayIP := string(AdapterInfoX^.GatewayList.IpAddress.S);
      strNative_IP := string(AdapterInfoX^.IpAddressList.IpAddress.S);
      if (not SameText(strGatewayIP, '0.0.0.0')) and (not SameText(strNative_IP, '0.0.0.0')) then
      begin
        Result := PAnsiChar(AnsiString(strNative_IP));
        Break;
      end;
    end;
  finally
    lstAdapter.Free;
  end;
end;

{ 检测 CPU 支持的指令集 <Check CPU support instruction set> }
procedure CheckCPU(var bMMX, bSSE1, bSSE2, bSSE3, bSSEE3, bSSE41, bSSE42, bAES, bFMA, bAVX1, bAVX2, bAVX512: Boolean);
begin
  bMMX    := GetCPUID(1).EDX and (1 shl 23) = (1 shl 23);
  bSSE1   := GetCPUID(1).EDX and (1 shl 25) = (1 shl 25);
  bSSE2   := GetCPUID(1).EDX and (1 shl 26) = (1 shl 26);
  bSSE3   := GetCPUID(1).ECX and (1 shl 00) = (1 shl 00);
  bSSEE3  := GetCPUID(1).ECX and (1 shl 09) = (1 shl 09);
  bSSE41  := GetCPUID(1).ECX and (1 shl 19) = (1 shl 19);
  bSSE42  := GetCPUID(1).ECX and (1 shl 20) = (1 shl 20);
  bAES    := GetCPUID(1).ECX and (1 shl 25) = (1 shl 25);
  bAVX1   := GetCPUID(1).ECX and (1 shl 28) = (1 shl 28);
  bFMA    := GetCPUID(1).ECX and (1 shl 12) = (1 shl 12);
  bAVX2   := GetCPUID(7).EBX and (1 shl 05) = (1 shl 05);
  bAVX512 := GetCPUID(7).EBX and (1 shl 16) = (1 shl 16);
end;

{ 检查系统是否是中文操作系统 }
function CheckChineseUI: Boolean;
begin
  Result := GetUserDefaultUILanguage = $0804; // (GetSystemDefaultLangID = $0804) and (GetUserDefaultLangID = $0804);
end;

{ 时间有效期 }
function CheckTimeLimited: Boolean;
var
  dtltd: TDateTime;
begin
  dtltd  := VarToDateTime('2023-10-01 00:00:00');
  Result := Now >= dtltd;
end;

{ 格式化当前时间 }
function GetFormatCurrentTime: String;
  function CheckLength(const strValue: string): string;
  begin
    Result := strValue;
    if length(strValue) = 1 then
      Result := '0' + strValue;
  end;

var
  ttt: SYSTEMTIME;
begin
  GetSystemTime(ttt);
  Result := IntToStr(ttt.wYear) + '-' +                                                      //
    CheckLength(IntToStr(ttt.wMonth)) + '-' +                                                //
    CheckLength(IntToStr(ifthen(8 + ttt.wHour > 24, ttt.wDay + 1, ttt.wDay))) + ' ' +        //
    CheckLength(IntToStr(ifthen(8 + ttt.wHour > 24, ttt.wHour - 16, 8 + ttt.wHour))) + ':' + //
    CheckLength(IntToStr(ttt.wMinute)) + ':' +                                               //
    CheckLength(IntToStr(ttt.wSecond));
end;

{ 获取进程路径 }
function GetProcessPath: String;
var
  strFileName: array [0 .. 255] of Char;
  hProcess   : Cardinal;
begin
  hProcess := OpenProcess(PROCESS_QUERY_INFORMATION or PROCESS_VM_READ, False, GetCurrentProcessId);
  GetModuleFileNameEx(hProcess, 0, strFileName, 256);
  CloseHandle(hProcess);

  Result := strFileName;
  Result := ExtractFilePath(Result);
end;

{ 获取本机网卡列表信息 }
function GetAdapterInfo(var lst: TList): Boolean;
var
  Adapters, Work: PIP_ADAPTER_INFO;
  BufLen        : ULONG;
  ret           : DWORD;
begin
  Result := False;

  BufLen := 1024 * 15;
  GetMem(Adapters, BufLen);
  try
    repeat
      ret := GetAdaptersInfo(Adapters, BufLen);
      case ret of
        ERROR_SUCCESS:
          begin
            if BufLen = 0 then
              Exit;
            Break;
          end;

        ERROR_NOT_SUPPORTED, ERROR_NO_DATA:
          Exit;

        ERROR_BUFFER_OVERFLOW:
          ReallocMem(Adapters, BufLen);
      else
        SetLastError(ret);
        RaiseLastOSError;
      end;
    until False;

    if ret = ERROR_SUCCESS then
    begin
      Work := Adapters;
      repeat
        lst.Add(Work);
        Work := Work^.Next;
      until (Work = nil);
      Result := True;
    end;
  finally
    FreeMem(Adapters);
  end;
end;

procedure LogErr(const strTemp: string);
var
  tf           : TextFile;
  strLogErrName: string;
  strDir       : string;
begin
  if strTemp = '......' then
    Exit;

  { 日志目录 }
  strDir := GetProcessPath + 'log';
  if not DirectoryExists(strDir) then
    ForceDirectories(strDir);

  { 写入日志字符串 }
  strLogErrName := Format('%s\%s.log', [strDir, FormatDateTime('yyyyMMdd', Now)]);
  AssignFile(tf, strLogErrName);
  if not FileExists(strLogErrName) then
    Rewrite(tf)
  else
    Append(tf);

  Writeln(tf, FormatDateTime('hh:mm:ss:zzz', Time) + chr(9) + strTemp);
  CloseFile(tf);
end;

{ 水平翻转 并行模式 }
procedure HorizMirror(bmp: TBitmap);
var
  StartScanLine: NativeInt;
  bmpWidthBytes: NativeInt;
begin
  StartScanLine := NativeInt(bmp.ScanLine[0]);
  bmpWidthBytes := NativeInt(bmp.ScanLine[1]) - NativeInt(bmp.ScanLine[0]);

  TParallel.For(0, bmp.height - 1,
    procedure(Y: Integer)
    var
      X: Integer;
      swapColor: DWORD;
      pColor01: PDWORD;
      pColor02: PDWORD;
    begin
      pColor01 := PDWORD(StartScanLine + Y * bmpWidthBytes);
      pColor02 := PDWORD(StartScanLine + Y * bmpWidthBytes + 4 * (bmp.Width - 1));
      for X := 0 to bmp.Width div 2 - 1 do
      begin
        swapColor := pColor02^;
        pColor02^ := pColor01^;
        pColor01^ := swapColor;
        Inc(pColor01);
        Dec(pColor02);
      end;
    end);
end;

{ 图片垂直镜像 }
procedure VertiMirror(bmp: TBitmap);
var
  count, Y: Integer;
  pColor01: PByte;
  pColor02: PByte;
  tmpColor: PByte;
begin
  count := Integer(bmp.ScanLine[0]) - Integer(bmp.ScanLine[1]);
  GetMem(tmpColor, count);
  try
    for Y := 0 to bmp.height div 2 - 1 do
    begin
      pColor01 := bmp.ScanLine[Y];
      pColor02 := bmp.ScanLine[bmp.height - Y - 1];
      Move(pColor01^, tmpColor^, count);
      Move(pColor02^, pColor01^, count);
      Move(tmpColor^, pColor02^, count);
    end;
  finally
    FreeMem(tmpColor);
  end;
end;

{ 转置翻转 并行模式 }
procedure HAndVMirror(bmp: TBitmap);
begin
  HorizMirror(bmp);
  VertiMirror(bmp);
end;

const
  c_PixBGRAMask: DWORD = $FF;
  c_GraySSERioR: DWORD = $4D;
  c_GraySSERioG: DWORD = $97;
  c_GraySSERioB: DWORD = $1C;
  c_ContSSEMask: DWORD = $80;
  c_ContSSEM257: DWORD = $0101;

procedure Gray_SSEParallel_Proc(pColor: PByte; const bmpWidth: Integer);
asm
  {$IFDEF WIN64}
  MOV     RAX,  RCX
  {$IFEND}

  MOV     ECX,  EDX
  MOVSS   XMM1, [c_PixBGRAMask]             // XMM1 = 000000000000000000000000000000FF
  MOVSS   XMM2, [c_GraySSERioB]             // XMM2 = 0000000000000000000000000000001C
  MOVSS   XMM3, [c_GraySSERioG]             // XMM3 = 00000000000000000000000000000097
  MOVSS   XMM4, [c_GraySSERioR]             // XMM4 = 0000000000000000000000000000004D
  SHUFPS  XMM1, XMM1, 0                     // XMM1 = 000000FF000000FF000000FF000000FF
  SHUFPS  XMM2, XMM2, 0                     // XMM2 = 0000001C0000001C0000001C0000001C
  SHUFPS  XMM3, XMM3, 0                     // XMM3 = 00000097000000970000009700000097
  SHUFPS  XMM4, XMM4, 0                     // XMM4 = 0000004D0000004D0000004D0000004D

@LOOP:
  MOVUPS  XMM0, [EAX]                       // XMM0 = |A3R3G3B3|A2R2G2B2|A1R1G1B1|A0R0G0B0|
  MOVAPS  XMM5, XMM0                        // XMM5 = |A3R3G3B3|A2R2G2B2|A1R1G1B1|A0R0G0B0|
  MOVAPS  XMM6, XMM0                        // XMM6 = |A3R3G3B3|A2R2G2B2|A1R1G1B1|A0R0G0B0|
  MOVAPS  XMM7, XMM0                        // XMM7 = |A3R3G3B3|A2R2G2B2|A1R1G1B1|A0R0G0B0|

  // 获取 4 个像素的 B3, B2, B1, B0
  ANDPS   XMM5, XMM1                        // XMM5 = |000000B3|000000B2|000000B1|000000B0|

  // 获取 4 个像素的 G3, G2, G1, G0
  PSRLD   XMM6, 8                           // XMM6 = |00A3R3G3|00A2R2G2|00A1R1G1|00A0R0G0|
  ANDPS   XMM6, XMM1                        // XMM6 = |000000G3|000000G2|000000G1|000000G0|

  // 获取 4 个像素的 R3, R2, R1, R0
  PSRLD   XMM7, 16                          // XMM7 = |0000A3R3|0000A2R2|0000A1R1|0000A0R0|
  ANDPS   XMM7, XMM1                        // XMM7 = |000000R3|000000R2|000000R1|000000R0|

  // 计算灰度值
  PMULLW  XMM5, XMM2                        // XMM5 = |B3 *  28|B2 *  28|B1 *  28|B0 *  28|
  PMULLW  XMM6, XMM3                        // XMM6 = |G3 * 151|G2 * 151|G1 * 151|G0 * 151|
  PMULLW  XMM7, XMM4                        // XMM7 = |R3 *  77|R2 *  77|R1 *  77|R0 *  77|
  PADDD   XMM5, XMM6                        // XMM5 = G+B
  PADDD   XMM5, XMM7                        // XMM5 = G+B+R
  PSRLD   XMM5, 8                           // XMM5 = |000000Y3|000000Y2|000000Y1|000000Y0|

  // 返回结果
  MOVAPS  XMM6, XMM5                        // XMM6  = |000000Y3|000000Y2|000000Y1|000000Y0|
  MOVAPS  XMM7, XMM5                        // XMM7  = |000000Y3|000000Y2|000000Y1|000000Y0|
  PSLLD   XMM6, 8                           // XMM6  = |0000Y300|0000Y200|0000Y100|0000Y000|
  PSLLD   XMM7, 16                          // XMM7  = |00Y30000|00Y20000|00Y10000|00Y00000|
  ORPS    XMM5, XMM6                        // XMM5  = |0000Y3Y3|0000Y2Y2|0000Y1Y1|0000Y0Y0|
  ORPS    XMM5, XMM7                        // XMM5  = |00Y3Y3Y3|00Y2Y2Y2|00Y1Y1Y1|00Y0Y0Y0|
  MOVUPS  [EAX], XMM5                       // [EAX] = XMM5

  ADD     EAX, 16                           // pColor 地址加 16，EAX 指向下4个像素的地址
  SUB     ECX, 4                            // Width 减 4, 每 4 个像素一循环
  JNZ     @LOOP                             // 循环
end;

{ 灰度 }
procedure dbImageGray(bmp: TBitmap);
var
  StartScanLine: NativeInt;
  bmpWidthBytes: NativeInt;
begin
  StartScanLine := NativeInt(bmp.ScanLine[0]);
  bmpWidthBytes := NativeInt(bmp.ScanLine[1]) - NativeInt(bmp.ScanLine[0]);

{$IFDEF WIN64}
  TParallel.For(0, bmp.height - 1,
    procedure(Y: Integer)
    var
      X: Integer;
      pColor: PRGBQuad;
      byeGray: Byte;
    begin
      pColor := PRGBQuad(StartScanLine + Y * bmpWidthBytes);
      for X := 0 to bmp.Width - 1 do
      begin
        byeGray := Round(0.299 * pColor^.rgbRed + 0.587 * pColor^.rgbGreen + 0.114 * pColor^.rgbBlue);
        pColor^ := TRGBQuad(RGB(byeGray, byeGray, byeGray));
        Inc(pColor);
      end;
    end);
{$ELSE}
  TParallel.For(0, bmp.height - 1,
    procedure(Y: Integer)
    var
      pColor: PByte;
    begin
      pColor := PByte(StartScanLine + Y * bmpWidthBytes);
      Gray_SSEParallel_Proc(pColor, bmp.Width);
    end);
{$IFEND}
end;

{ 截图保存 }
procedure SnapBmp(const hForm: THandle; bmp: TBitmap; bSnapHD: Boolean = False);
var
  strFileName: String;
  cvs        : TCanvas;
  snapDC     : HDC;
  rct        : TRect;
begin
  { 截图保存目录是否存在 }
  if bSnapHD then
    strFileName := Format('%ssnap\%s_HD.bmp', [GetProcessPath, FormatDateTime('yyyyMMddhhmmss', Now)])
  else
    strFileName := Format('%ssnap\%s.bmp', [GetProcessPath, FormatDateTime('yyyyMMddhhmmss', Now)]);
  if not DirectoryExists(ExtractFilePath(strFileName)) then
    ForceDirectories(ExtractFilePath(strFileName));

  { 保存到磁盘 }
  bmp.SaveToFile(strFileName);

  { 绘制到界面 }
  cvs    := TCanvas.Create;
  snapDC := GetDC(hForm);
  try
    GetWindowRect(hForm, rct);
    cvs.Handle := snapDC;
    cvs.StretchDraw(Rect(0, 0, rct.Width, rct.height), bmp);
  finally
    ReleaseDC(hForm, snapDC);
    cvs.Free
  end;
end;

{ 叠加降噪 }
procedure HDBmp32(const bmp: array of TBitmap; var bmpResult: TBitmap);
var
  I, J, count, intLen: Integer;
  P                  : array of PRGBQuad;
  Q                  : PRGBQuad;
  intValueR          : Integer;
  intValueG          : Integer;
  intValueB          : Integer;
begin
  Q     := bmpResult.ScanLine[bmpResult.height - 1];
  count := length(bmp);
  SetLength(P, count);
  for I := 0 to count - 1 do
  begin
    P[I] := bmp[I].ScanLine[bmp[I].height - 1];
  end;
  intLen := bmp[0].height * bmp[0].Width;

  for J := 0 to intLen - 1 do
  begin
    intValueR := 0;
    intValueG := 0;
    intValueB := 0;
    for I     := 0 to count - 1 do
    begin
      intValueR := intValueR + P[I]^.rgbRed;
      intValueG := intValueG + P[I]^.rgbGreen;
      intValueB := intValueB + P[I]^.rgbBlue;
    end;
    Q^.rgbRed   := intValueR div count;
    Q^.rgbGreen := intValueG div count;
    Q^.rgbBlue  := intValueB div count;
    Inc(Q);

    for I := 0 to count - 1 do
    begin
      Inc(P[I]);
    end;
  end;
end;

{ 清除视频涂鸦列表 }
procedure FreeVideoTYList(const bFree: Boolean = False);
var
  I: Integer;
begin
  if g_lstVideoTY = nil then Exit;

  try
    if g_lstVideoTY.count = 0 then Exit;

    for I := 0 to g_lstVideoTY.count - 1 do
    begin
      FreeMem(PVideoTYStyle(g_lstVideoTY.Items[I]).tyStyle);
      FreeMem(g_lstVideoTY.Items[I]);
    end;

    g_lstVideoTY.Clear;
  finally
    if bFree then
    begin
      g_lstVideoTY.Free;
    end;
  end;
end;

{ 0 绘制文字 }
procedure DrawTY_Text(bmp: TBitmap; tyvs: TVideo_Text);
begin
  bmp.Canvas.Font.color := tyvs.fontColor;
  bmp.Canvas.Font.size  := tyvs.fontsize;
  bmp.Canvas.TextOut(tyvs.pt.X, tyvs.pt.Y, string(tyvs.text));
end;

{ 1 绘制圆 }
procedure DrawTY_Circle(bmp: TBitmap; tyvs: TVideo_Circle);
var
  Graphics: TGPGraphics;
  Pen     : TGPPen;
  bsh     : TGPSolidBrush;
begin
  Graphics := TGPGraphics.Create(bmp.Canvas.Handle);
  Pen      := TGPPen.Create(MakeColor(GetBlue(tyvs.color), GetGreen(tyvs.color), GetRed(tyvs.color)), tyvs.size);

  try
    if tyvs.fill then
    begin
      bsh := TGPSolidBrush.Create(MakeColor(GetBlue(tyvs.color), GetGreen(tyvs.color), GetRed(tyvs.color)));
      Graphics.FillEllipse(bsh, tyvs.ptStart.X, tyvs.ptStart.Y, tyvs.ptEnd.X - tyvs.ptStart.X, tyvs.ptEnd.X - tyvs.ptStart.X);
      bsh.Free;
    end
    else
    begin
      Pen.SetDashStyle(TDashStyle(ifthen(tyvs.style = 1, Integer(DashStyleSolid), Integer(DashStyleDot))));
      Graphics.SetSmoothingMode(SmoothingModeAntiAlias);
      Graphics.DrawEllipse(Pen, tyvs.ptStart.X, tyvs.ptStart.Y, tyvs.ptEnd.X - tyvs.ptStart.X, tyvs.ptEnd.X - tyvs.ptStart.X);
    end;
  finally
    Pen.Free;
    Graphics.Free;
  end;
end;

{ 2 绘制椭圆 }
procedure DrawTY_Ellipse(bmp: TBitmap; tyvs: TVideo_Ellipse);
var
  Graphics: TGPGraphics;
  Pen     : TGPPen;
  bsh     : TGPSolidBrush;
begin
  Graphics := TGPGraphics.Create(bmp.Canvas.Handle);
  Pen      := TGPPen.Create(MakeColor(GetBlue(tyvs.color), GetGreen(tyvs.color), GetRed(tyvs.color)), tyvs.size);
  try
    if tyvs.fill then
    begin
      bsh := TGPSolidBrush.Create(MakeColor(GetBlue(tyvs.color), GetGreen(tyvs.color), GetRed(tyvs.color)));
      Graphics.FillEllipse(bsh, tyvs.ptStart.X, tyvs.ptStart.Y, tyvs.ptEnd.X - tyvs.ptStart.X, tyvs.ptEnd.Y - tyvs.ptStart.Y);
      bsh.Free;
    end
    else
    begin
      Pen.SetDashStyle(TDashStyle(ifthen(tyvs.style = 1, Integer(DashStyleSolid), Integer(DashStyleDot))));
      Graphics.SetSmoothingMode(SmoothingModeAntiAlias);
      Graphics.DrawEllipse(Pen, tyvs.ptStart.X, tyvs.ptStart.Y, tyvs.ptEnd.X - tyvs.ptStart.X, tyvs.ptEnd.Y - tyvs.ptStart.Y);
    end;
  finally
    Pen.Free;
    Graphics.Free;
  end;
end;

{ 3 绘制正方形 }
procedure DrawTY_Square(bmp: TBitmap; tyvs: TVideo_Square);
var
  Graphics: TGPGraphics;
  Pen     : TGPPen;
  bsh     : TGPSolidBrush;
begin
  Graphics := TGPGraphics.Create(bmp.Canvas.Handle);
  Pen      := TGPPen.Create(MakeColor(GetBlue(tyvs.color), GetGreen(tyvs.color), GetRed(tyvs.color)), tyvs.size);

  try
    if tyvs.fill then
    begin
      bsh := TGPSolidBrush.Create(MakeColor(GetBlue(tyvs.color), GetGreen(tyvs.color), GetRed(tyvs.color)));
      Graphics.FillRectangle(bsh, tyvs.ptStart.X, tyvs.ptStart.Y, tyvs.ptEnd.X - tyvs.ptStart.X, tyvs.ptEnd.X - tyvs.ptStart.X);
      bsh.Free;
    end
    else
    begin
      Pen.SetDashStyle(TDashStyle(ifthen(tyvs.style = 1, Integer(DashStyleSolid), Integer(DashStyleDot))));
      Graphics.SetSmoothingMode(SmoothingModeAntiAlias);
      Graphics.DrawRectangle(Pen, tyvs.ptStart.X, tyvs.ptStart.Y, tyvs.ptEnd.X - tyvs.ptStart.X, tyvs.ptEnd.X - tyvs.ptStart.X);
    end;
  finally
    Pen.Free;
    Graphics.Free;
  end;
end;

{ 4 绘制矩形 }
procedure DrawTY_Rectangle(bmp: TBitmap; tyvs: TVideo_Rectangle);
var
  Graphics: TGPGraphics;
  Pen     : TGPPen;
  bsh     : TGPSolidBrush;
begin
  Graphics := TGPGraphics.Create(bmp.Canvas.Handle);
  Pen      := TGPPen.Create(MakeColor(GetBlue(tyvs.color), GetGreen(tyvs.color), GetRed(tyvs.color)), tyvs.size);
  try
    if tyvs.fill then
    begin
      bsh := TGPSolidBrush.Create(MakeColor(GetBlue(tyvs.color), GetGreen(tyvs.color), GetRed(tyvs.color)));
      Graphics.FillRectangle(bsh, tyvs.ptStart.X, tyvs.ptStart.Y, tyvs.ptEnd.X - tyvs.ptStart.X, tyvs.ptEnd.Y - tyvs.ptStart.Y);
      bsh.Free;
    end
    else
    begin
      Pen.SetDashStyle(TDashStyle(ifthen(tyvs.style = 1, Integer(DashStyleSolid), Integer(DashStyleDot))));
      Graphics.SetSmoothingMode(SmoothingModeAntiAlias);
      Graphics.DrawRectangle(Pen, tyvs.ptStart.X, tyvs.ptStart.Y, tyvs.ptEnd.X - tyvs.ptStart.X, tyvs.ptEnd.Y - tyvs.ptStart.Y);
    end;
  finally
    Pen.Free;
    Graphics.Free;
  end;
end;

{ 5 绘制多边形 }
procedure DrawTY_Polygon(bmp: TBitmap; tyvs: TVideo_Polygon);
var
  Graphics: TGPGraphics;
  Pen     : TGPPen;
  bsh     : TGPSolidBrush;
  I       : Integer;
begin
  Graphics := TGPGraphics.Create(bmp.Canvas.Handle);
  Pen      := TGPPen.Create(MakeColor(GetBlue(tyvs.color), GetGreen(tyvs.color), GetRed(tyvs.color)), tyvs.size);
  try
    if tyvs.fill then
    begin
      bsh := TGPSolidBrush.Create(MakeColor(GetBlue(tyvs.color), GetGreen(tyvs.color), GetRed(tyvs.color)));
      if not tyvs.bEnd then
      begin
        for I := 0 to tyvs.count - 1 do
        begin
          Graphics.DrawRectangle(Pen, tyvs.pt[I].X, tyvs.pt[I].Y, 2, 2);
        end;
      end
      else
      begin
        Graphics.FillPolygon(bsh, PGPPoint(tyvs.pt), tyvs.count);
      end;
      bsh.Free;
    end
    else
    begin
      Pen.SetDashStyle(TDashStyle(ifthen(tyvs.style = 1, Integer(DashStyleSolid), Integer(DashStyleDot))));
      Graphics.SetSmoothingMode(SmoothingModeAntiAlias);
      if not tyvs.bEnd then
      begin
        for I := 0 to tyvs.count - 1 do
        begin
          Graphics.DrawRectangle(Pen, tyvs.pt[I].X, tyvs.pt[I].Y, 2, 2);
        end;
      end
      else
      begin
        Graphics.DrawPolygon(Pen, PGPPoint(tyvs.pt), tyvs.count);
      end;
    end;
  finally
    Pen.Free;
    Graphics.Free;
  end;
end;

{ 6 绘制直线 }
procedure DrawTY_Line(bmp: TBitmap; tyvs: TVideo_Line);
var
  Graphics: TGPGraphics;
  Pen     : TGPPen;
begin
  Graphics := TGPGraphics.Create(bmp.Canvas.Handle);
  Pen      := TGPPen.Create(MakeColor(GetBlue(tyvs.color), GetGreen(tyvs.color), GetRed(tyvs.color)), tyvs.size);
  try
    Pen.SetDashStyle(TDashStyle(ifthen(tyvs.style = 1, Integer(DashStyleSolid), Integer(DashStyleDot))));
    Graphics.SetSmoothingMode(SmoothingModeAntiAlias);
    Graphics.DrawLine(Pen, tyvs.ptStart.X, tyvs.ptStart.Y, tyvs.ptEnd.X, tyvs.ptEnd.Y);
  finally
    Pen.Free;
    Graphics.Free;
  end;
end;

{ 7 绘制曲线 }
procedure DrawTY_Curve(bmp: TBitmap; tyvs: TVideo_Curve);
var
  Graphics: TGPGraphics;
  Pen     : TGPPen;
  I       : Integer;
begin
  Graphics := TGPGraphics.Create(bmp.Canvas.Handle);
  Pen      := TGPPen.Create(MakeColor(GetBlue(tyvs.color), GetGreen(tyvs.color), GetRed(tyvs.color)), tyvs.size);
  try
    Pen.SetDashStyle(TDashStyle(ifthen(tyvs.style = 1, Integer(DashStyleSolid), Integer(DashStyleDot))));
    Graphics.SetSmoothingMode(SmoothingModeAntiAlias);
    if not tyvs.bEnd then
    begin
      for I := 0 to 1 do
      begin
        if tyvs.pt[I].X <> -1 then
        begin
          Graphics.DrawRectangle(Pen, tyvs.pt[I].X, tyvs.pt[I].Y, 2, 2);
        end;
      end;
    end
    else
    begin
      Graphics.DrawCurve(Pen, PGPPoint(@tyvs.pt), 3);
    end;
  finally
    Pen.Free;
    Graphics.Free;
  end;
end;

{ 8 绘制多点线段 }
procedure DrawTY_MulLine(bmp: TBitmap; tyvs: TVideo_MulLine);
var
  Graphics: TGPGraphics;
  Pen     : TGPPen;
  I       : Integer;
begin
  Graphics := TGPGraphics.Create(bmp.Canvas.Handle);
  Pen      := TGPPen.Create(MakeColor(GetBlue(tyvs.color), GetGreen(tyvs.color), GetRed(tyvs.color)), tyvs.size);
  try
    Pen.SetDashStyle(TDashStyle(ifthen(tyvs.style = 1, Integer(DashStyleSolid), Integer(DashStyleDot))));
    Graphics.SetSmoothingMode(SmoothingModeAntiAlias);
    if not tyvs.bEnd then
    begin
      for I := 0 to tyvs.count - 1 do
      begin
        Graphics.DrawRectangle(Pen, tyvs.pt[I].X, tyvs.pt[I].Y, 2, 2);
      end;
    end
    else
    begin
      for I := 0 to tyvs.count - 2 do
      begin
        Graphics.DrawLine(Pen, tyvs.pt[I].X, tyvs.pt[I].Y, tyvs.pt[I + 1].X, tyvs.pt[I + 1].Y);
      end;
    end;
  finally
    Pen.Free;
    Graphics.Free;
  end;
end;

{ 9 绘制多点曲线 }
procedure DrawTY_MulCurve(bmp: TBitmap; tyvs: TVideo_MulCurve);
var
  Graphics: TGPGraphics;
  Pen     : TGPPen;
  bsh     : TGPSolidBrush;
  I       : Integer;
begin
  Graphics := TGPGraphics.Create(bmp.Canvas.Handle);
  Pen      := TGPPen.Create(MakeColor(GetBlue(tyvs.color), GetGreen(tyvs.color), GetRed(tyvs.color)), tyvs.size);
  try
    if tyvs.fill then
    begin
      bsh := TGPSolidBrush.Create(MakeColor(GetBlue(tyvs.color), GetGreen(tyvs.color), GetRed(tyvs.color)));
      if not tyvs.bEnd then
      begin
        for I := 0 to tyvs.count - 1 do
        begin
          Graphics.DrawRectangle(Pen, tyvs.pt[I].X, tyvs.pt[I].Y, 2, 2);
        end;
      end
      else
      begin
        Graphics.DrawClosedCurve(Pen, PGPPoint(tyvs.pt), tyvs.count, 0.5);
      end;
      bsh.Free;
    end
    else
    begin
      Pen.SetDashStyle(TDashStyle(ifthen(tyvs.style = 1, Integer(DashStyleSolid), Integer(DashStyleDot))));
      Graphics.SetSmoothingMode(SmoothingModeAntiAlias);
      if not tyvs.bEnd then
      begin
        for I := 0 to tyvs.count - 1 do
        begin
          Graphics.DrawRectangle(Pen, tyvs.pt[I].X, tyvs.pt[I].Y, 2, 2);
        end;
      end
      else
      begin
        Graphics.DrawCurve(Pen, PGPPoint(tyvs.pt), tyvs.count);
      end;
    end;
  finally
    Pen.Free;
    Graphics.Free;
  end;
end;

{ 10 绘制红心 }
procedure DrawTY_RedHeart(bmp: TBitmap; tyvs: TVideo_SpecialPoint);
begin
  bmp.Canvas.Font.color := tyvs.fontColor;
  bmp.Canvas.Font.size  := tyvs.fontsize;
  bmp.Canvas.TextOut(tyvs.pt.X, tyvs.pt.Y, tyvs.text);
end;

{ 11 绘制任意 }
procedure DrawTY_Any(bmp: TBitmap; tyvs: TVideo_Any);
var
  Graphics: TGPGraphics;
  Pen     : TGPPen;
  I, count: Integer;
begin
  Graphics := TGPGraphics.Create(bmp.Canvas.Handle);
  Pen      := TGPPen.Create(MakeColor(GetBlue(tyvs.color), GetGreen(tyvs.color), GetRed(tyvs.color)), tyvs.size);
  try
    Pen.SetDashStyle(TDashStyle(ifthen(tyvs.style = 1, Integer(DashStyleSolid), Integer(DashStyleDot))));
    Graphics.SetSmoothingMode(SmoothingModeAntiAlias);
    count := tyvs.count;
    for I := 0 to count - 2 do
    begin
      Graphics.DrawLine(Pen, tyvs.pt[I].X, tyvs.pt[I].Y, tyvs.pt[I + 1].X, tyvs.pt[I + 1].Y);
    end;
  finally
    Pen.Free;
    Graphics.Free;
  end;
end;

procedure DeNoisesPlus(bmp: TarrBmp; var bmpResult: TBitmap);
var
  StartScanLine : array [0 .. c_intMaxFrame - 1] of Integer;
  bmpWidthBytes : Integer;
  I             : Integer;
  ResultScanLine: Integer;
begin
  bmpWidthBytes  := Integer(bmp[0].ScanLine[1]) - Integer(bmp[0].ScanLine[0]);
  ResultScanLine := Integer(bmpResult.ScanLine[0]);
  for I          := 0 to c_intMaxFrame - 1 do
  begin
    StartScanLine[I] := Integer(bmp[I].ScanLine[0]);
  end;

  TParallel.For(0, bmp[0].height - 1,
    procedure(Y: Integer)
    var
      intValueR: Integer;
      intValueG: Integer;
      intValueB: Integer;
      pColorX32: array [0 .. c_intMaxFrame - 1] of PRGBQuad;
      pResult32: PRGBQuad;
      X, J: Integer;
    begin
      for J := 0 to c_intMaxFrame - 1 do
      begin
        pColorX32[J] := PRGBQuad(StartScanLine[J] + Y * bmpWidthBytes);
      end;
      pResult32 := PRGBQuad(ResultScanLine + Y * bmpWidthBytes);

      for X := 0 to bmp[0].Width - 1 do
      begin
        intValueR := 0;
        intValueG := 0;
        intValueB := 0;
        for J := 0 to c_intMaxFrame - 1 do
        begin
          intValueR := intValueR + pColorX32[J]^.rgbRed;
          intValueG := intValueG + pColorX32[J]^.rgbGreen;
          intValueB := intValueB + pColorX32[J]^.rgbBlue;
        end;
        pResult32^.rgbRed := intValueR shr c_intRightSHT;
        pResult32^.rgbGreen := intValueG shr c_intRightSHT;
        pResult32^.rgbBlue := intValueB shr c_intRightSHT;
        Inc(pResult32);

        for J := 0 to c_intMaxFrame - 1 do
        begin
          Inc(pColorX32[J]);
        end;
      end;
    end);
end;

function CheckLAVSplitterInstall: Boolean;
var
  SysDevEnum: TSysDevEnum;
  PinList   : TPinList;
  I, J      : Integer;
begin
  Result     := False;
  SysDevEnum := TSysDevEnum.Create;
  PinList    := TPinList.Create;
  try
    for I := 0 to SysDevEnum.CountCategories - 1 do
    begin
      if SameText(string(SysDevEnum.Categories[I].FriendlyName), 'DirectShow Filters') then
      begin
        SysDevEnum.SelectIndexCategory(I);
        if SysDevEnum.CountFilters > 0 then
        begin
          for J := 0 to SysDevEnum.CountFilters - 1 do
          begin
            if SameText(string(SysDevEnum.Filters[J].FriendlyName), 'LAV Splitter') then
            begin
              Result := True;
              Break;
            end;
          end;
        end;

        Break;
      end;
    end;
  finally
    SysDevEnum.Free;
    PinList.Free;
  end;
end;

procedure InstallLAVSpillter;
var
  strCurrentPath: String;
  strFileName   : String;
begin
  if CheckLAVSplitterInstall then Exit;

  strCurrentPath := ExtractFilePath(ParamStr(0)) + 'dbVideo\LAVFilters';
  strFileName    := TPath.GetTempPath + 'dblav.cmd';
  with TStringList.Create do
  begin
    Add('@echo off');
    Add('%1 mshta vbscript:CreateObject("Shell.Application").ShellExecute("cmd.exe","/c %~s0 ::","","runas",1)(window.close)&&exit');
    Add('CD /D "' + strCurrentPath + '"');
    Add('');
    Add('regsvr32.exe /v /s LAVAudio.ax');
    Add('regsvr32.exe /v /s LAVSplitter.ax');
    Add('regsvr32.exe /v /s LAVVideo.ax');
    SaveToFile(strFileName);
    Free;
  end;

  WinExec(PAnsiChar(AnsiString(strFileName)), SW_HIDE);
end;


function AddDllDirectory(const NewDirectory: LPCWSTR): Pointer; stdcall; external kernel32; // 将目录添加到进程的 DLL 搜索路径
function RemoveDllDirectory(Cookie: Pointer): BOOL;             stdcall; external kernel32; // 移除之前添加的目录（使用 AddDllDirectory 返回的 Cookie）

var Cookie : Pointer = nil;

procedure InitSDK;
begin
  CoInitialize(nil);
  InitGDIPLUS;
  Cookie := AddDllDirectory(PChar(ExtractFilePath(ParamStr(0)) + 'plugins\ffmpeg'));
  g_lstVideoTY := TList.Create;
  {$IFDEF CPU64BITS}
  FSetExceptMask(Cardinal(-1));
  {$ENDIF}
end;

procedure FreeSDK;
begin
  FreeVideoTYList(True);
  RemoveDllDirectory(Cookie);
  FreeGDIPLUS;
end;

end.
