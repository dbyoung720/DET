unit TurboJpeg.Static;

// libjpeg-turbo TurboJPEG API 的 Delphi 静态链接绑定
// 支持 Win32(x86) 与 Win64(x64)，直接链接 COFF .obj，不依赖 DLL

interface

uses
  System.SysUtils, TurboJpeg.Force, TurboJpeg.CRT;

const
  TJSAMP_444  = 0;
  TJSAMP_422  = 1;
  TJSAMP_420  = 2;
  TJSAMP_GRAY = 3;
  TJSAMP_440  = 4;
  TJSAMP_411  = 5;

  TJPF_RGB     = 0;
  TJPF_BGR     = 1;
  TJPF_RGBX    = 2;
  TJPF_BGRX    = 3;
  TJPF_XBGR    = 4;
  TJPF_XRGB    = 5;
  TJPF_GRAY    = 6;
  TJPF_RGBA    = 7;
  TJPF_BGRA    = 8;
  TJPF_ABGR    = 9;
  TJPF_ARGB    = 10;
  TJPF_CMYK    = 11;
  TJPF_UNKNOWN = -1;

  TJCS_RGB   = 0;
  TJCS_YCbCr = 1;
  TJCS_GRAY  = 2;
  TJCS_CMYK  = 3;
  TJCS_YCCK  = 4;

  TJFLAG_BOTTOMUP      = 2;
  TJFLAG_FORCEMMX      = 8;
  TJFLAG_FORCESSE      = 16;
  TJFLAG_FORCESSE2     = 32;
  TJFLAG_FORCESSE3     = 128;
  TJFLAG_FASTUPSAMPLE  = 256;
  TJFLAG_NOREALLOC     = 1024;
  TJFLAG_FASTDCT       = 2048;
  TJFLAG_ACCURATEDCT   = 4096;
  TJFLAG_STOPONWARNING = 8192;
  TJFLAG_PROGRESSIVE   = 16384;
  TJFLAG_LIMITSCANS    = 32768;

type
  TTjHandle = Pointer;

  TTjScalingFactor = TurboJpeg.Force.TTjScalingFactor;
  PTjScalingFactor = TurboJpeg.Force.PTjScalingFactor;

function tjInitCompress: TTjHandle;
function tjInitDecompress: TTjHandle;
function tjDestroy(handle: TTjHandle): Integer;
function tjGetErrorStr: PAnsiChar;
function tjBufSize(width, height, jpegSubsamp: Integer): LongWord;
procedure tjFree(buffer: PByte);
function tjDecompressHeader2(handle: TTjHandle; jpegBuf: PByte; jpegSize: LongWord; var width, height, jpegSubsamp: Integer): Integer;
function tjDecompress2(handle: TTjHandle; jpegBuf: PByte; jpegSize: LongWord; dstBuf: PByte; width, pitch, height, pixelFormat, flags: Integer): Integer;
function tjCompress2(handle: TTjHandle; srcBuf: PByte; width, pitch, height, pixelFormat: Integer; var jpegBuf: PByte; var jpegSize: LongWord; jpegSubsamp, jpegQual, flags: Integer): Integer;
function tjGetScalingFactors(var NumFactors: Integer): PTjScalingFactor;
function TjLastError: string;

implementation

function tjInitCompress: TTjHandle;
begin
  Result := TurboJpeg.Force.tjInitCompress;
end;

function tjInitDecompress: TTjHandle;
begin
  Result := TurboJpeg.Force.tjInitDecompress;
end;

function tjDestroy(handle: TTjHandle): Integer;
begin
  Result := TurboJpeg.Force.tjDestroy(handle);
end;

function tjGetErrorStr: PAnsiChar;
begin
  Result := TurboJpeg.Force.tjGetErrorStr;
end;

function tjBufSize(width, height, jpegSubsamp: Integer): LongWord;
begin
  Result := TurboJpeg.Force.tjBufSize(width, height, jpegSubsamp);
end;

procedure tjFree(buffer: PByte);
begin
  TurboJpeg.Force.tjFree(buffer);
end;

function tjDecompressHeader2(handle: TTjHandle; jpegBuf: PByte; jpegSize: LongWord; var width, height, jpegSubsamp: Integer): Integer;
begin
  Result := TurboJpeg.Force.tjDecompressHeader2(handle, jpegBuf, jpegSize, width, height, jpegSubsamp);
end;

function tjDecompress2(handle: TTjHandle; jpegBuf: PByte; jpegSize: LongWord; dstBuf: PByte; width, pitch, height, pixelFormat, flags: Integer): Integer;
begin
  Result := TurboJpeg.Force.tjDecompress2(handle, jpegBuf, jpegSize, dstBuf, width, pitch, height, pixelFormat, flags);
end;

function tjCompress2(handle: TTjHandle; srcBuf: PByte; width, pitch, height, pixelFormat: Integer; var jpegBuf: PByte; var jpegSize: LongWord; jpegSubsamp, jpegQual, flags: Integer): Integer;
begin
  Result := TurboJpeg.Force.tjCompress2(handle, srcBuf, width, pitch, height, pixelFormat, jpegBuf, jpegSize, jpegSubsamp, jpegQual, flags);
end;

function tjGetScalingFactors(var NumFactors: Integer): PTjScalingFactor;
begin
  Result := TurboJpeg.Force.tjGetScalingFactors(NumFactors);
end;

function TjLastError: string;
begin
  Result := string(tjGetErrorStr);
end;

initialization
  ForceAllTurboJpegObjects;
  if GForceSink = nil then;

end.
