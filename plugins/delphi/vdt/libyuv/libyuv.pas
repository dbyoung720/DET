unit LibYuv;

interface

uses Winapi.Windows, System.SysUtils, System.Math;

type
  PYuvConstants = ^TYuvConstants;
  TYuvConstants = record
    kUVToB: array[0..31] of Byte;
    kUVToG: array[0..31] of Byte;
    kUVToR: array[0..31] of Byte;
    kYToRgb: array[0..15] of SmallInt;
    kYBiasToRgb: array[0..15] of SmallInt;
  end;

function YuvI601Constants: PYuvConstants; cdecl;
function YuvJPEGConstants: PYuvConstants; cdecl;
function YuvH709Constants: PYuvConstants; cdecl;
function YuvF709Constants: PYuvConstants; cdecl;
function Yuv2020Constants: PYuvConstants; cdecl;
function YuvV2020Constants: PYuvConstants; cdecl;
function YvuI601Constants: PYuvConstants; cdecl;
function YvuJPEGConstants: PYuvConstants; cdecl;
function YvuH709Constants: PYuvConstants; cdecl;
function YvuF709Constants: PYuvConstants; cdecl;
function Yvu2020Constants: PYuvConstants; cdecl;
function YvuV2020Constants: PYuvConstants; cdecl;

//----- Matrix-aware conversions ------------------------------------------------
function I420ToARGBMatrix(SrcY: PByte; SrcStrideY: Integer;
                          SrcU: PByte; SrcStrideU: Integer;
                          SrcV: PByte; SrcStrideV: Integer;
                          DstARGB: PByte; DstStrideARGB: Integer;
                          Matrix: PYuvConstants;
                          Width, Height: Integer): Integer; cdecl;
function I422ToARGBMatrix(SrcY: PByte; SrcStrideY: Integer;
                          SrcU: PByte; SrcStrideU: Integer;
                          SrcV: PByte; SrcStrideV: Integer;
                          DstARGB: PByte; DstStrideARGB: Integer;
                          Matrix: PYuvConstants;
                          Width, Height: Integer): Integer; cdecl;
function I444ToARGBMatrix(SrcY: PByte; SrcStrideY: Integer;
                          SrcU: PByte; SrcStrideU: Integer;
                          SrcV: PByte; SrcStrideV: Integer;
                          DstARGB: PByte; DstStrideARGB: Integer;
                          Matrix: PYuvConstants;
                          Width, Height: Integer): Integer; cdecl;
function I010ToARGBMatrix(SrcY: PWord; SrcStrideY: Integer;
                          SrcU: PWord; SrcStrideU: Integer;
                          SrcV: PWord; SrcStrideV: Integer;
                          DstARGB: PByte; DstStrideARGB: Integer;
                          Matrix: PYuvConstants;
                          Width, Height: Integer): Integer; cdecl;
function I210ToARGBMatrix(SrcY: PWord; SrcStrideY: Integer;
                          SrcU: PWord; SrcStrideU: Integer;
                          SrcV: PWord; SrcStrideV: Integer;
                          DstARGB: PByte; DstStrideARGB: Integer;
                          Matrix: PYuvConstants;
                          Width, Height: Integer): Integer; cdecl;
function P010ToARGBMatrix(SrcY: PWord; SrcStrideY: Integer;
                          SrcUV: PWord; SrcStrideUV: Integer;
                          DstARGB: PByte; DstStrideARGB: Integer;
                          Matrix: PYuvConstants;
                          Width, Height: Integer): Integer; cdecl;
function P210ToARGBMatrix(SrcY: PWord; SrcStrideY: Integer;
                          SrcUV: PWord; SrcStrideUV: Integer;
                          DstARGB: PByte; DstStrideARGB: Integer;
                          Matrix: PYuvConstants;
                          Width, Height: Integer): Integer; cdecl;
function NV12ToARGBMatrix(SrcY: PByte; SrcStrideY: Integer;
                          SrcUV: PByte; SrcStrideUV: Integer;
                          DstARGB: PByte; DstStrideARGB: Integer;
                          Matrix: PYuvConstants;
                          Width, Height: Integer): Integer; cdecl;
function NV21ToARGBMatrix(SrcY: PByte; SrcStrideY: Integer;
                          SrcVU: PByte; SrcStrideVU: Integer;
                          DstARGB: PByte; DstStrideARGB: Integer;
                          Matrix: PYuvConstants;
                          Width, Height: Integer): Integer; cdecl;
function YUY2ToARGBMatrix(SrcYUY2: PByte; SrcStrideYUY2: Integer;
                          DstARGB: PByte; DstStrideARGB: Integer;
                          Matrix: PYuvConstants;
                          Width, Height: Integer): Integer; cdecl;
function UYVYToARGBMatrix(SrcUYVY: PByte; SrcStrideUYVY: Integer;
                          DstARGB: PByte; DstStrideARGB: Integer;
                          Matrix: PYuvConstants;
                          Width, Height: Integer): Integer; cdecl;
function I400ToARGBMatrix(SrcY: PByte; SrcStrideY: Integer;
                          DstARGB: PByte; DstStrideARGB: Integer;
                          Matrix: PYuvConstants;
                          Width, Height: Integer): Integer; cdecl;

//----- FourCC helpers ----------------------------------------------------------
function FourCC(const Code: string): Cardinal; inline;

//----- CPU ---------------------------------------------------------------------
function InitCpuFlags: Integer; cdecl;
function MaskCpuFlags(EnableFlags: Integer): Integer; cdecl;
procedure CpuId(InfoEax, InfoEcx: Integer; CpuInfo: PInteger); cdecl;

//----- Conversion: YUV -> ARGB -------------------------------------------------
function I420ToARGB(SrcY: PByte; SrcStrideY: Integer;
                    SrcU: PByte; SrcStrideU: Integer;
                    SrcV: PByte; SrcStrideV: Integer;
                    DstARGB: PByte; DstStrideARGB: Integer;
                    Width, Height: Integer): Integer; cdecl;
function I420ToABGR(SrcY: PByte; SrcStrideY: Integer;
                    SrcU: PByte; SrcStrideU: Integer;
                    SrcV: PByte; SrcStrideV: Integer;
                    DstABGR: PByte; DstStrideABGR: Integer;
                    Width, Height: Integer): Integer; cdecl;
function NV12ToARGB(SrcY: PByte; SrcStrideY: Integer;
                    SrcUV: PByte; SrcStrideUV: Integer;
                    DstARGB: PByte; DstStrideARGB: Integer;
                    Width, Height: Integer): Integer; cdecl;
function NV21ToARGB(SrcY: PByte; SrcStrideY: Integer;
                    SrcVU: PByte; SrcStrideVU: Integer;
                    DstARGB: PByte; DstStrideARGB: Integer;
                    Width, Height: Integer): Integer; cdecl;
function I422ToARGB(SrcY: PByte; SrcStrideY: Integer;
                    SrcU: PByte; SrcStrideU: Integer;
                    SrcV: PByte; SrcStrideV: Integer;
                    DstARGB: PByte; DstStrideARGB: Integer;
                    Width, Height: Integer): Integer; cdecl;
function I444ToARGB(SrcY: PByte; SrcStrideY: Integer;
                    SrcU: PByte; SrcStrideU: Integer;
                    SrcV: PByte; SrcStrideV: Integer;
                    DstARGB: PByte; DstStrideARGB: Integer;
                    Width, Height: Integer): Integer; cdecl;
function UYVYToARGB(SrcUYVY: PByte; SrcStrideUYVY: Integer;
                    DstARGB: PByte; DstStrideARGB: Integer;
                    Width, Height: Integer): Integer; cdecl;
function YUY2ToARGB(SrcYUY2: PByte; SrcStrideYUY2: Integer;
                    DstARGB: PByte; DstStrideARGB: Integer;
                    Width, Height: Integer): Integer; cdecl;
function RGB24ToARGB(SrcRGB24: PByte; SrcStrideRGB24: Integer;
                     DstARGB: PByte; DstStrideARGB: Integer;
                     Width, Height: Integer): Integer; cdecl;
function RGB565ToARGB(SrcRGB565: PByte; SrcStrideRGB565: Integer;
                      DstARGB: PByte; DstStrideARGB: Integer;
                      Width, Height: Integer): Integer; cdecl;

//----- Conversion: ARGB -> YUV -------------------------------------------------
function ARGBToI420(SrcARGB: PByte; SrcStrideARGB: Integer;
                    DstY: PByte; DstStrideY: Integer;
                    DstU: PByte; DstStrideU: Integer;
                    DstV: PByte; DstStrideV: Integer;
                    Width, Height: Integer): Integer; cdecl;
function ARGBToNV12(SrcARGB: PByte; SrcStrideARGB: Integer;
                    DstY: PByte; DstStrideY: Integer;
                    DstUV: PByte; DstStrideUV: Integer;
                    Width, Height: Integer): Integer; cdecl;
function ARGBToNV21(SrcARGB: PByte; SrcStrideARGB: Integer;
                    DstY: PByte; DstStrideY: Integer;
                    DstVU: PByte; DstStrideVU: Integer;
                    Width, Height: Integer): Integer; cdecl;
function ARGBToRGB565(SrcARGB: PByte; SrcStrideARGB: Integer;
                      DstRGB565: PByte; DstStrideRGB565: Integer;
                      Width, Height: Integer): Integer; cdecl;

//----- Planar conversions ------------------------------------------------------
function I420Copy(SrcY: PByte; SrcStrideY: Integer;
                  SrcU: PByte; SrcStrideU: Integer;
                  SrcV: PByte; SrcStrideV: Integer;
                  DstY: PByte; DstStrideY: Integer;
                  DstU: PByte; DstStrideU: Integer;
                  DstV: PByte; DstStrideV: Integer;
                  Width, Height: Integer): Integer; cdecl;
function I420ToI422(SrcY: PByte; SrcStrideY: Integer;
                    SrcU: PByte; SrcStrideU: Integer;
                    SrcV: PByte; SrcStrideV: Integer;
                    DstY: PByte; DstStrideY: Integer;
                    DstU: PByte; DstStrideU: Integer;
                    DstV: PByte; DstStrideV: Integer;
                    Width, Height: Integer): Integer; cdecl;
function I422ToI420(SrcY: PByte; SrcStrideY: Integer;
                    SrcU: PByte; SrcStrideU: Integer;
                    SrcV: PByte; SrcStrideV: Integer;
                    DstY: PByte; DstStrideY: Integer;
                    DstU: PByte; DstStrideU: Integer;
                    DstV: PByte; DstStrideV: Integer;
                    Width, Height: Integer): Integer; cdecl;
function NV12ToI420(SrcY: PByte; SrcStrideY: Integer;
                    SrcUV: PByte; SrcStrideUV: Integer;
                    DstY: PByte; DstStrideY: Integer;
                    DstU: PByte; DstStrideU: Integer;
                    DstV: PByte; DstStrideV: Integer;
                    Width, Height: Integer): Integer; cdecl;
function NV21ToI420(SrcY: PByte; SrcStrideY: Integer;
                    SrcVU: PByte; SrcStrideVU: Integer;
                    DstY: PByte; DstStrideY: Integer;
                    DstU: PByte; DstStrideU: Integer;
                    DstV: PByte; DstStrideV: Integer;
                    Width, Height: Integer): Integer; cdecl;
function UYVYToI420(SrcUYVY: PByte; SrcStrideUYVY: Integer;
                    DstY: PByte; DstStrideY: Integer;
                    DstU: PByte; DstStrideU: Integer;
                    DstV: PByte; DstStrideV: Integer;
                    Width, Height: Integer): Integer; cdecl;
function YUY2ToI420(SrcYUY2: PByte; SrcStrideYUY2: Integer;
                    DstY: PByte; DstStrideY: Integer;
                    DstU: PByte; DstStrideU: Integer;
                    DstV: PByte; DstStrideV: Integer;
                    Width, Height: Integer): Integer; cdecl;

//----- Rotation ----------------------------------------------------------------
function I420Rotate(SrcY: PByte; SrcStrideY: Integer;
                    SrcU: PByte; SrcStrideU: Integer;
                    SrcV: PByte; SrcStrideV: Integer;
                    DstY: PByte; DstStrideY: Integer;
                    DstU: PByte; DstStrideU: Integer;
                    DstV: PByte; DstStrideV: Integer;
                    Width, Height, Rotation: Integer): Integer; cdecl;
function ARGBRotate(SrcARGB: PByte; SrcStrideARGB: Integer;
                    DstARGB: PByte; DstStrideARGB: Integer;
                    Width, Height, Rotation: Integer): Integer; cdecl;
function ARGBMirror(SrcARGB: PByte; SrcStrideARGB: Integer;
                    DstARGB: PByte; DstStrideARGB: Integer;
                    Width, Height: Integer): Integer; cdecl;

//----- Scaling -----------------------------------------------------------------
function ARGBScale(SrcARGB: PByte; SrcStrideARGB: Integer;
                   SrcWidth, SrcHeight: Integer;
                   DstARGB: PByte; DstStrideARGB: Integer;
                   DstWidth, DstHeight: Integer;
                   Filtering: Integer): Integer; cdecl;
function ScalePlane(Src: PByte; SrcStride, SrcWidth, SrcHeight: Integer;
                    Dst: PByte; DstStride, DstWidth, DstHeight: Integer;
                    Filtering: Integer): Integer; cdecl;

//----- Comparison / quality ----------------------------------------------------
function I420Psnr(SrcYa: PByte; StrideYa: Integer;
                  SrcUa: PByte; StrideUa: Integer;
                  SrcVa: PByte; StrideVa: Integer;
                  SrcYb: PByte; StrideYb: Integer;
                  SrcUb: PByte; StrideUb: Integer;
                  SrcVb: PByte; StrideVb: Integer;
                  Width, Height: Integer): Double; cdecl;
function CalcFramePsnr(SrcA: PByte; StrideA: Integer;
                       SrcB: PByte; StrideB: Integer;
                       Width, Height: Integer): Double; cdecl;
function HashDjb2(Src: PByte; Count: UInt64; Seed: Cardinal): Cardinal; cdecl;

procedure LibYuvInitialize;

implementation

{$IFDEF WIN32}
  {$I .\obj\link_x86.inc}
  {$I .\obj\syms_x86.inc}
  function LibYuvCrtInit(a, f, l: Pointer): Integer; cdecl; external name '_LibYuvCrtInit';
  function YuvI601Constants: PYuvConstants; cdecl; external name '_Ly_kYuvI601Constants';
  function YuvJPEGConstants: PYuvConstants; cdecl; external name '_Ly_kYuvJPEGConstants';
  function YuvH709Constants: PYuvConstants; cdecl; external name '_Ly_kYuvH709Constants';
  function YuvF709Constants: PYuvConstants; cdecl; external name '_Ly_kYuvF709Constants';
  function Yuv2020Constants: PYuvConstants; cdecl; external name '_Ly_kYuv2020Constants';
  function YuvV2020Constants: PYuvConstants; cdecl; external name '_Ly_kYuvV2020Constants';
  function YvuI601Constants: PYuvConstants; cdecl; external name '_Ly_kYvuI601Constants';
  function YvuJPEGConstants: PYuvConstants; cdecl; external name '_Ly_kYvuJPEGConstants';
  function YvuH709Constants: PYuvConstants; cdecl; external name '_Ly_kYvuH709Constants';
  function YvuF709Constants: PYuvConstants; cdecl; external name '_Ly_kYvuF709Constants';
  function Yvu2020Constants: PYuvConstants; cdecl; external name '_Ly_kYvu2020Constants';
  function YvuV2020Constants: PYuvConstants; cdecl; external name '_Ly_kYvuV2020Constants';
{$ELSE}
  {$I .\obj\link_x64.inc}
  {$I .\obj\syms_x64.inc}
  function LibYuvCrtInit(a, f, l: Pointer): Integer; cdecl; external name 'LibYuvCrtInit';
  function YuvI601Constants: PYuvConstants; cdecl; external name 'Ly_kYuvI601Constants';
  function YuvJPEGConstants: PYuvConstants; cdecl; external name 'Ly_kYuvJPEGConstants';
  function YuvH709Constants: PYuvConstants; cdecl; external name 'Ly_kYuvH709Constants';
  function YuvF709Constants: PYuvConstants; cdecl; external name 'Ly_kYuvF709Constants';
  function Yuv2020Constants: PYuvConstants; cdecl; external name 'Ly_kYuv2020Constants';
  function YuvV2020Constants: PYuvConstants; cdecl; external name 'Ly_kYuvV2020Constants';
  function YvuI601Constants: PYuvConstants; cdecl; external name 'Ly_kYvuI601Constants';
  function YvuJPEGConstants: PYuvConstants; cdecl; external name 'Ly_kYvuJPEGConstants';
  function YvuH709Constants: PYuvConstants; cdecl; external name 'Ly_kYvuH709Constants';
  function YvuF709Constants: PYuvConstants; cdecl; external name 'Ly_kYvuF709Constants';
  function Yvu2020Constants: PYuvConstants; cdecl; external name 'Ly_kYvu2020Constants';
  function YvuV2020Constants: PYuvConstants; cdecl; external name 'Ly_kYvuV2020Constants';
{$ENDIF}

function LyAlloc(N: NativeUInt): Pointer; cdecl;
begin
  GetMem(Result, N);
end;

procedure LyFree(P: Pointer); cdecl;
begin
  if P <> nil then FreeMem(P);
end;

function LyLog10(X: Double): Double; cdecl;
begin
  Result := System.Math.Log10(X);
end;

procedure LibYuvInitialize;
begin
  LibYuvCrtInit(@LyAlloc, @LyFree, @LyLog10);
  InitCpuFlags;
end;

function FourCC(const Code: string): Cardinal;
begin
  Result := 0;
  if Length(Code) >= 4 then
    Result := Cardinal(Ord(Code[1])) or (Cardinal(Ord(Code[2])) shl 8) or
              (Cardinal(Ord(Code[3])) shl 16) or (Cardinal(Ord(Code[4])) shl 24)
  else if Length(Code) > 0 then
  begin
    Result := Cardinal(Ord(Code[1]));
    if Length(Code) > 1 then Result := Result or (Cardinal(Ord(Code[2])) shl 8);
    if Length(Code) > 2 then Result := Result or (Cardinal(Ord(Code[3])) shl 16);
    if Length(Code) > 3 then Result := Result or (Cardinal(Ord(Code[4])) shl 24);
  end;
end;

{$IFDEF WIN32}
function InitCpuFlags: Integer; cdecl; external name '_InitCpuFlags';
function MaskCpuFlags(EnableFlags: Integer): Integer; cdecl; external name '_MaskCpuFlags';
procedure CpuId(InfoEax, InfoEcx: Integer; CpuInfo: PInteger); cdecl; external name '_CpuId';
function I420ToARGB(SrcY: PByte; SrcStrideY: Integer; SrcU: PByte; SrcStrideU: Integer; SrcV: PByte; SrcStrideV: Integer; DstARGB: PByte; DstStrideARGB: Integer; Width, Height: Integer): Integer; cdecl; external name '_I420ToARGB';
function I420ToABGR(SrcY: PByte; SrcStrideY: Integer; SrcU: PByte; SrcStrideU: Integer; SrcV: PByte; SrcStrideV: Integer; DstABGR: PByte; DstStrideABGR: Integer; Width, Height: Integer): Integer; cdecl; external name '_I420ToABGR';
function NV12ToARGB(SrcY: PByte; SrcStrideY: Integer; SrcUV: PByte; SrcStrideUV: Integer; DstARGB: PByte; DstStrideARGB: Integer; Width, Height: Integer): Integer; cdecl; external name '_NV12ToARGB';
function NV21ToARGB(SrcY: PByte; SrcStrideY: Integer; SrcVU: PByte; SrcStrideVU: Integer; DstARGB: PByte; DstStrideARGB: Integer; Width, Height: Integer): Integer; cdecl; external name '_NV21ToARGB';
function I422ToARGB(SrcY: PByte; SrcStrideY: Integer; SrcU: PByte; SrcStrideU: Integer; SrcV: PByte; SrcStrideV: Integer; DstARGB: PByte; DstStrideARGB: Integer; Width, Height: Integer): Integer; cdecl; external name '_I422ToARGB';
function I444ToARGB(SrcY: PByte; SrcStrideY: Integer; SrcU: PByte; SrcStrideU: Integer; SrcV: PByte; SrcStrideV: Integer; DstARGB: PByte; DstStrideARGB: Integer; Width, Height: Integer): Integer; cdecl; external name '_I444ToARGB';
function UYVYToARGB(SrcUYVY: PByte; SrcStrideUYVY: Integer; DstARGB: PByte; DstStrideARGB: Integer; Width, Height: Integer): Integer; cdecl; external name '_UYVYToARGB';
function YUY2ToARGB(SrcYUY2: PByte; SrcStrideYUY2: Integer; DstARGB: PByte; DstStrideARGB: Integer; Width, Height: Integer): Integer; cdecl; external name '_YUY2ToARGB';
function RGB24ToARGB(SrcRGB24: PByte; SrcStrideRGB24: Integer; DstARGB: PByte; DstStrideARGB: Integer; Width, Height: Integer): Integer; cdecl; external name '_RGB24ToARGB';
function RGB565ToARGB(SrcRGB565: PByte; SrcStrideRGB565: Integer; DstARGB: PByte; DstStrideARGB: Integer; Width, Height: Integer): Integer; cdecl; external name '_RGB565ToARGB';
function ARGBToI420(SrcARGB: PByte; SrcStrideARGB: Integer; DstY: PByte; DstStrideY: Integer; DstU: PByte; DstStrideU: Integer; DstV: PByte; DstStrideV: Integer; Width, Height: Integer): Integer; cdecl; external name '_ARGBToI420';
function ARGBToNV12(SrcARGB: PByte; SrcStrideARGB: Integer; DstY: PByte; DstStrideY: Integer; DstUV: PByte; DstStrideUV: Integer; Width, Height: Integer): Integer; cdecl; external name '_ARGBToNV12';
function ARGBToNV21(SrcARGB: PByte; SrcStrideARGB: Integer; DstY: PByte; DstStrideY: Integer; DstVU: PByte; DstStrideVU: Integer; Width, Height: Integer): Integer; cdecl; external name '_ARGBToNV21';
function ARGBToRGB565(SrcARGB: PByte; SrcStrideARGB: Integer; DstRGB565: PByte; DstStrideRGB565: Integer; Width, Height: Integer): Integer; cdecl; external name '_ARGBToRGB565';
function I420Copy(SrcY: PByte; SrcStrideY: Integer; SrcU: PByte; SrcStrideU: Integer; SrcV: PByte; SrcStrideV: Integer; DstY: PByte; DstStrideY: Integer; DstU: PByte; DstStrideU: Integer; DstV: PByte; DstStrideV: Integer; Width, Height: Integer): Integer; cdecl; external name '_I420Copy';
function I420ToI422(SrcY: PByte; SrcStrideY: Integer; SrcU: PByte; SrcStrideU: Integer; SrcV: PByte; SrcStrideV: Integer; DstY: PByte; DstStrideY: Integer; DstU: PByte; DstStrideU: Integer; DstV: PByte; DstStrideV: Integer; Width, Height: Integer): Integer; cdecl; external name '_I420ToI422';
function I422ToI420(SrcY: PByte; SrcStrideY: Integer; SrcU: PByte; SrcStrideU: Integer; SrcV: PByte; SrcStrideV: Integer; DstY: PByte; DstStrideY: Integer; DstU: PByte; DstStrideU: Integer; DstV: PByte; DstStrideV: Integer; Width, Height: Integer): Integer; cdecl; external name '_I422ToI420';
function NV12ToI420(SrcY: PByte; SrcStrideY: Integer; SrcUV: PByte; SrcStrideUV: Integer; DstY: PByte; DstStrideY: Integer; DstU: PByte; DstStrideU: Integer; DstV: PByte; DstStrideV: Integer; Width, Height: Integer): Integer; cdecl; external name '_NV12ToI420';
function NV21ToI420(SrcY: PByte; SrcStrideY: Integer; SrcVU: PByte; SrcStrideVU: Integer; DstY: PByte; DstStrideY: Integer; DstU: PByte; DstStrideU: Integer; DstV: PByte; DstStrideV: Integer; Width, Height: Integer): Integer; cdecl; external name '_NV21ToI420';
function UYVYToI420(SrcUYVY: PByte; SrcStrideUYVY: Integer; DstY: PByte; DstStrideY: Integer; DstU: PByte; DstStrideU: Integer; DstV: PByte; DstStrideV: Integer; Width, Height: Integer): Integer; cdecl; external name '_UYVYToI420';
function YUY2ToI420(SrcYUY2: PByte; SrcStrideYUY2: Integer; DstY: PByte; DstStrideY: Integer; DstU: PByte; DstStrideU: Integer; DstV: PByte; DstStrideV: Integer; Width, Height: Integer): Integer; cdecl; external name '_YUY2ToI420';
function I420Rotate(SrcY: PByte; SrcStrideY: Integer; SrcU: PByte; SrcStrideU: Integer; SrcV: PByte; SrcStrideV: Integer; DstY: PByte; DstStrideY: Integer; DstU: PByte; DstStrideU: Integer; DstV: PByte; DstStrideV: Integer; Width, Height, Rotation: Integer): Integer; cdecl; external name '_I420Rotate';
function ARGBRotate(SrcARGB: PByte; SrcStrideARGB: Integer; DstARGB: PByte; DstStrideARGB: Integer; Width, Height, Rotation: Integer): Integer; cdecl; external name '_ARGBRotate';
function ARGBMirror(SrcARGB: PByte; SrcStrideARGB: Integer; DstARGB: PByte; DstStrideARGB: Integer; Width, Height: Integer): Integer; cdecl; external name '_ARGBMirror';
function ARGBScale(SrcARGB: PByte; SrcStrideARGB: Integer; SrcWidth, SrcHeight: Integer; DstARGB: PByte; DstStrideARGB: Integer; DstWidth, DstHeight: Integer; Filtering: Integer): Integer; cdecl; external name '_ARGBScale';
function ScalePlane(Src: PByte; SrcStride, SrcWidth, SrcHeight: Integer; Dst: PByte; DstStride, DstWidth, DstHeight, Filtering: Integer): Integer; cdecl; external name '_ScalePlane';
function I420Psnr(SrcYa: PByte; StrideYa: Integer; SrcUa: PByte; StrideUa: Integer; SrcVa: PByte; StrideVa: Integer; SrcYb: PByte; StrideYb: Integer; SrcUb: PByte; StrideUb: Integer; SrcVb: PByte; StrideVb: Integer; Width, Height: Integer): Double; cdecl; external name '_I420Psnr';
function CalcFramePsnr(SrcA: PByte; StrideA: Integer; SrcB: PByte; StrideB: Integer; Width, Height: Integer): Double; cdecl; external name '_CalcFramePsnr';
function HashDjb2(Src: PByte; Count: UInt64; Seed: Cardinal): Cardinal; cdecl; external name '_HashDjb2';
function I420ToARGBMatrix(SrcY: PByte; SrcStrideY: Integer; SrcU: PByte; SrcStrideU: Integer; SrcV: PByte; SrcStrideV: Integer; DstARGB: PByte; DstStrideARGB: Integer; Matrix: PYuvConstants; Width, Height: Integer): Integer; cdecl; external name '_I420ToARGBMatrix';
function I422ToARGBMatrix(SrcY: PByte; SrcStrideY: Integer; SrcU: PByte; SrcStrideU: Integer; SrcV: PByte; SrcStrideV: Integer; DstARGB: PByte; DstStrideARGB: Integer; Matrix: PYuvConstants; Width, Height: Integer): Integer; cdecl; external name '_I422ToARGBMatrix';
function I444ToARGBMatrix(SrcY: PByte; SrcStrideY: Integer; SrcU: PByte; SrcStrideU: Integer; SrcV: PByte; SrcStrideV: Integer; DstARGB: PByte; DstStrideARGB: Integer; Matrix: PYuvConstants; Width, Height: Integer): Integer; cdecl; external name '_I444ToARGBMatrix';
function I010ToARGBMatrix(SrcY: PWord; SrcStrideY: Integer; SrcU: PWord; SrcStrideU: Integer; SrcV: PWord; SrcStrideV: Integer; DstARGB: PByte; DstStrideARGB: Integer; Matrix: PYuvConstants; Width, Height: Integer): Integer; cdecl; external name '_I010ToARGBMatrix';
function I210ToARGBMatrix(SrcY: PWord; SrcStrideY: Integer; SrcU: PWord; SrcStrideU: Integer; SrcV: PWord; SrcStrideV: Integer; DstARGB: PByte; DstStrideARGB: Integer; Matrix: PYuvConstants; Width, Height: Integer): Integer; cdecl; external name '_I210ToARGBMatrix';
function P010ToARGBMatrix(SrcY: PWord; SrcStrideY: Integer; SrcUV: PWord; SrcStrideUV: Integer; DstARGB: PByte; DstStrideARGB: Integer; Matrix: PYuvConstants; Width, Height: Integer): Integer; cdecl; external name '_P010ToARGBMatrix';
function P210ToARGBMatrix(SrcY: PWord; SrcStrideY: Integer; SrcUV: PWord; SrcStrideUV: Integer; DstARGB: PByte; DstStrideARGB: Integer; Matrix: PYuvConstants; Width, Height: Integer): Integer; cdecl; external name '_P210ToARGBMatrix';
function NV12ToARGBMatrix(SrcY: PByte; SrcStrideY: Integer; SrcUV: PByte; SrcStrideUV: Integer; DstARGB: PByte; DstStrideARGB: Integer; Matrix: PYuvConstants; Width, Height: Integer): Integer; cdecl; external name '_NV12ToARGBMatrix';
function NV21ToARGBMatrix(SrcY: PByte; SrcStrideY: Integer; SrcVU: PByte; SrcStrideVU: Integer; DstARGB: PByte; DstStrideARGB: Integer; Matrix: PYuvConstants; Width, Height: Integer): Integer; cdecl; external name '_NV21ToARGBMatrix';
function YUY2ToARGBMatrix(SrcYUY2: PByte; SrcStrideYUY2: Integer; DstARGB: PByte; DstStrideARGB: Integer; Matrix: PYuvConstants; Width, Height: Integer): Integer; cdecl; external name '_YUY2ToARGBMatrix';
function UYVYToARGBMatrix(SrcUYVY: PByte; SrcStrideUYVY: Integer; DstARGB: PByte; DstStrideARGB: Integer; Matrix: PYuvConstants; Width, Height: Integer): Integer; cdecl; external name '_UYVYToARGBMatrix';
function I400ToARGBMatrix(SrcY: PByte; SrcStrideY: Integer; DstARGB: PByte; DstStrideARGB: Integer; Matrix: PYuvConstants; Width, Height: Integer): Integer; cdecl; external name '_I400ToARGBMatrix';
{$ELSE}
function InitCpuFlags: Integer; cdecl; external name 'InitCpuFlags';
function MaskCpuFlags(EnableFlags: Integer): Integer; cdecl; external name 'MaskCpuFlags';
procedure CpuId(InfoEax, InfoEcx: Integer; CpuInfo: PInteger); cdecl; external name 'CpuId';
function I420ToARGB(SrcY: PByte; SrcStrideY: Integer; SrcU: PByte; SrcStrideU: Integer; SrcV: PByte; SrcStrideV: Integer; DstARGB: PByte; DstStrideARGB: Integer; Width, Height: Integer): Integer; cdecl; external name 'I420ToARGB';
function I420ToABGR(SrcY: PByte; SrcStrideY: Integer; SrcU: PByte; SrcStrideU: Integer; SrcV: PByte; SrcStrideV: Integer; DstABGR: PByte; DstStrideABGR: Integer; Width, Height: Integer): Integer; cdecl; external name 'I420ToABGR';
function NV12ToARGB(SrcY: PByte; SrcStrideY: Integer; SrcUV: PByte; SrcStrideUV: Integer; DstARGB: PByte; DstStrideARGB: Integer; Width, Height: Integer): Integer; cdecl; external name 'NV12ToARGB';
function NV21ToARGB(SrcY: PByte; SrcStrideY: Integer; SrcVU: PByte; SrcStrideVU: Integer; DstARGB: PByte; DstStrideARGB: Integer; Width, Height: Integer): Integer; cdecl; external name 'NV21ToARGB';
function I422ToARGB(SrcY: PByte; SrcStrideY: Integer; SrcU: PByte; SrcStrideU: Integer; SrcV: PByte; SrcStrideV: Integer; DstARGB: PByte; DstStrideARGB: Integer; Width, Height: Integer): Integer; cdecl; external name 'I422ToARGB';
function I444ToARGB(SrcY: PByte; SrcStrideY: Integer; SrcU: PByte; SrcStrideU: Integer; SrcV: PByte; SrcStrideV: Integer; DstARGB: PByte; DstStrideARGB: Integer; Width, Height: Integer): Integer; cdecl; external name 'I444ToARGB';
function UYVYToARGB(SrcUYVY: PByte; SrcStrideUYVY: Integer; DstARGB: PByte; DstStrideARGB: Integer; Width, Height: Integer): Integer; cdecl; external name 'UYVYToARGB';
function YUY2ToARGB(SrcYUY2: PByte; SrcStrideYUY2: Integer; DstARGB: PByte; DstStrideARGB: Integer; Width, Height: Integer): Integer; cdecl; external name 'YUY2ToARGB';
function RGB24ToARGB(SrcRGB24: PByte; SrcStrideRGB24: Integer; DstARGB: PByte; DstStrideARGB: Integer; Width, Height: Integer): Integer; cdecl; external name 'RGB24ToARGB';
function RGB565ToARGB(SrcRGB565: PByte; SrcStrideRGB565: Integer; DstARGB: PByte; DstStrideARGB: Integer; Width, Height: Integer): Integer; cdecl; external name 'RGB565ToARGB';
function ARGBToI420(SrcARGB: PByte; SrcStrideARGB: Integer; DstY: PByte; DstStrideY: Integer; DstU: PByte; DstStrideU: Integer; DstV: PByte; DstStrideV: Integer; Width, Height: Integer): Integer; cdecl; external name 'ARGBToI420';
function ARGBToNV12(SrcARGB: PByte; SrcStrideARGB: Integer; DstY: PByte; DstStrideY: Integer; DstUV: PByte; DstStrideUV: Integer; Width, Height: Integer): Integer; cdecl; external name 'ARGBToNV12';
function ARGBToNV21(SrcARGB: PByte; SrcStrideARGB: Integer; DstY: PByte; DstStrideY: Integer; DstVU: PByte; DstStrideVU: Integer; Width, Height: Integer): Integer; cdecl; external name 'ARGBToNV21';
function ARGBToRGB565(SrcARGB: PByte; SrcStrideARGB: Integer; DstRGB565: PByte; DstStrideRGB565: Integer; Width, Height: Integer): Integer; cdecl; external name 'ARGBToRGB565';
function I420Copy(SrcY: PByte; SrcStrideY: Integer; SrcU: PByte; SrcStrideU: Integer; SrcV: PByte; SrcStrideV: Integer; DstY: PByte; DstStrideY: Integer; DstU: PByte; DstStrideU: Integer; DstV: PByte; DstStrideV: Integer; Width, Height: Integer): Integer; cdecl; external name 'I420Copy';
function I420ToI422(SrcY: PByte; SrcStrideY: Integer; SrcU: PByte; SrcStrideU: Integer; SrcV: PByte; SrcStrideV: Integer; DstY: PByte; DstStrideY: Integer; DstU: PByte; DstStrideU: Integer; DstV: PByte; DstStrideV: Integer; Width, Height: Integer): Integer; cdecl; external name 'I420ToI422';
function I422ToI420(SrcY: PByte; SrcStrideY: Integer; SrcU: PByte; SrcStrideU: Integer; SrcV: PByte; SrcStrideV: Integer; DstY: PByte; DstStrideY: Integer; DstU: PByte; DstStrideU: Integer; DstV: PByte; DstStrideV: Integer; Width, Height: Integer): Integer; cdecl; external name 'I422ToI420';
function NV12ToI420(SrcY: PByte; SrcStrideY: Integer; SrcUV: PByte; SrcStrideUV: Integer; DstY: PByte; DstStrideY: Integer; DstU: PByte; DstStrideU: Integer; DstV: PByte; DstStrideV: Integer; Width, Height: Integer): Integer; cdecl; external name 'NV12ToI420';
function NV21ToI420(SrcY: PByte; SrcStrideY: Integer; SrcVU: PByte; SrcStrideVU: Integer; DstY: PByte; DstStrideY: Integer; DstU: PByte; DstStrideU: Integer; DstV: PByte; DstStrideV: Integer; Width, Height: Integer): Integer; cdecl; external name 'NV21ToI420';
function UYVYToI420(SrcUYVY: PByte; SrcStrideUYVY: Integer; DstY: PByte; DstStrideY: Integer; DstU: PByte; DstStrideU: Integer; DstV: PByte; DstStrideV: Integer; Width, Height: Integer): Integer; cdecl; external name 'UYVYToI420';
function YUY2ToI420(SrcYUY2: PByte; SrcStrideYUY2: Integer; DstY: PByte; DstStrideY: Integer; DstU: PByte; DstStrideU: Integer; DstV: PByte; DstStrideV: Integer; Width, Height: Integer): Integer; cdecl; external name 'YUY2ToI420';
function I420Rotate(SrcY: PByte; SrcStrideY: Integer; SrcU: PByte; SrcStrideU: Integer; SrcV: PByte; SrcStrideV: Integer; DstY: PByte; DstStrideY: Integer; DstU: PByte; DstStrideU: Integer; DstV: PByte; DstStrideV: Integer; Width, Height, Rotation: Integer): Integer; cdecl; external name 'I420Rotate';
function ARGBRotate(SrcARGB: PByte; SrcStrideARGB: Integer; DstARGB: PByte; DstStrideARGB: Integer; Width, Height, Rotation: Integer): Integer; cdecl; external name 'ARGBRotate';
function ARGBMirror(SrcARGB: PByte; SrcStrideARGB: Integer; DstARGB: PByte; DstStrideARGB: Integer; Width, Height: Integer): Integer; cdecl; external name 'ARGBMirror';
function ARGBScale(SrcARGB: PByte; SrcStrideARGB: Integer; SrcWidth, SrcHeight: Integer; DstARGB: PByte; DstStrideARGB: Integer; DstWidth, DstHeight: Integer; Filtering: Integer): Integer; cdecl; external name 'ARGBScale';
function ScalePlane(Src: PByte; SrcStride, SrcWidth, SrcHeight: Integer; Dst: PByte; DstStride, DstWidth, DstHeight, Filtering: Integer): Integer; cdecl; external name 'ScalePlane';
function I420Psnr(SrcYa: PByte; StrideYa: Integer; SrcUa: PByte; StrideUa: Integer; SrcVa: PByte; StrideVa: Integer; SrcYb: PByte; StrideYb: Integer; SrcUb: PByte; StrideUb: Integer; SrcVb: PByte; StrideVb: Integer; Width, Height: Integer): Double; cdecl; external name 'I420Psnr';
function CalcFramePsnr(SrcA: PByte; StrideA: Integer; SrcB: PByte; StrideB: Integer; Width, Height: Integer): Double; cdecl; external name 'CalcFramePsnr';
function HashDjb2(Src: PByte; Count: UInt64; Seed: Cardinal): Cardinal; cdecl; external name 'HashDjb2';
function I420ToARGBMatrix(SrcY: PByte; SrcStrideY: Integer; SrcU: PByte; SrcStrideU: Integer; SrcV: PByte; SrcStrideV: Integer; DstARGB: PByte; DstStrideARGB: Integer; Matrix: PYuvConstants; Width, Height: Integer): Integer; cdecl; external name 'I420ToARGBMatrix';
function I422ToARGBMatrix(SrcY: PByte; SrcStrideY: Integer; SrcU: PByte; SrcStrideU: Integer; SrcV: PByte; SrcStrideV: Integer; DstARGB: PByte; DstStrideARGB: Integer; Matrix: PYuvConstants; Width, Height: Integer): Integer; cdecl; external name 'I422ToARGBMatrix';
function I444ToARGBMatrix(SrcY: PByte; SrcStrideY: Integer; SrcU: PByte; SrcStrideU: Integer; SrcV: PByte; SrcStrideV: Integer; DstARGB: PByte; DstStrideARGB: Integer; Matrix: PYuvConstants; Width, Height: Integer): Integer; cdecl; external name 'I444ToARGBMatrix';
function I010ToARGBMatrix(SrcY: PWord; SrcStrideY: Integer; SrcU: PWord; SrcStrideU: Integer; SrcV: PWord; SrcStrideV: Integer; DstARGB: PByte; DstStrideARGB: Integer; Matrix: PYuvConstants; Width, Height: Integer): Integer; cdecl; external name 'I010ToARGBMatrix';
function I210ToARGBMatrix(SrcY: PWord; SrcStrideY: Integer; SrcU: PWord; SrcStrideU: Integer; SrcV: PWord; SrcStrideV: Integer; DstARGB: PByte; DstStrideARGB: Integer; Matrix: PYuvConstants; Width, Height: Integer): Integer; cdecl; external name 'I210ToARGBMatrix';
function P010ToARGBMatrix(SrcY: PWord; SrcStrideY: Integer; SrcUV: PWord; SrcStrideUV: Integer; DstARGB: PByte; DstStrideARGB: Integer; Matrix: PYuvConstants; Width, Height: Integer): Integer; cdecl; external name 'P010ToARGBMatrix';
function P210ToARGBMatrix(SrcY: PWord; SrcStrideY: Integer; SrcUV: PWord; SrcStrideUV: Integer; DstARGB: PByte; DstStrideARGB: Integer; Matrix: PYuvConstants; Width, Height: Integer): Integer; cdecl; external name 'P210ToARGBMatrix';
function NV12ToARGBMatrix(SrcY: PByte; SrcStrideY: Integer; SrcUV: PByte; SrcStrideUV: Integer; DstARGB: PByte; DstStrideARGB: Integer; Matrix: PYuvConstants; Width, Height: Integer): Integer; cdecl; external name 'NV12ToARGBMatrix';
function NV21ToARGBMatrix(SrcY: PByte; SrcStrideY: Integer; SrcVU: PByte; SrcStrideVU: Integer; DstARGB: PByte; DstStrideARGB: Integer; Matrix: PYuvConstants; Width, Height: Integer): Integer; cdecl; external name 'NV21ToARGBMatrix';
function YUY2ToARGBMatrix(SrcYUY2: PByte; SrcStrideYUY2: Integer; DstARGB: PByte; DstStrideARGB: Integer; Matrix: PYuvConstants; Width, Height: Integer): Integer; cdecl; external name 'YUY2ToARGBMatrix';
function UYVYToARGBMatrix(SrcUYVY: PByte; SrcStrideUYVY: Integer; DstARGB: PByte; DstStrideARGB: Integer; Matrix: PYuvConstants; Width, Height: Integer): Integer; cdecl; external name 'UYVYToARGBMatrix';
function I400ToARGBMatrix(SrcY: PByte; SrcStrideY: Integer; DstARGB: PByte; DstStrideARGB: Integer; Matrix: PYuvConstants; Width, Height: Integer): Integer; cdecl; external name 'I400ToARGBMatrix';
{$ENDIF}

initialization
  LibYuvInitialize;

end.
