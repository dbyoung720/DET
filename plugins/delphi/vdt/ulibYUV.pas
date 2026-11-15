unit ulibYUV;

interface

uses Winapi.Windows, {$I ffhead.inc}, System.SysUtils;

{ NV12 YUV420 转 RGB }
function libYUV_NV12ToARGB(const src_y: PByte; src_stride_y: NativeInt; const src_uv: PByte; src_stride_uv: NativeInt; dst_argb: PByte; dst_stride_argb, Width, Height: NativeInt): NativeInt;

{ P010LE YUV420 转 RGB }
function libYUV_P010LEToARGB(const frame: PAVFrame; dst_argb: PByte; iLineLength, iWidth, iHeight: NativeInt): NativeInt;

implementation

var
  FhlibYUV         : HMODULE;
  kYuvI601Constants: Pointer;
  NV12ToARGB       : function(const src_y: PByte; src_stride_y: NativeInt; const src_uv: PByte; src_stride_uv: NativeInt; dst_argb: PByte; dst_stride_argb, Width, Height: NativeInt): NativeInt; cdecl;
  P010ToARGBMatrix : function(const src_y: PWORD; src_stride_y: NativeInt; const src_uv: PWORD; src_stride_uv: NativeInt; dst_argb: PByte; dst_stride_argb: Integer; const YuvConstants: Pointer; Width, Height: NativeInt): NativeInt; cdecl;

{ NV12 YUV420 转 RGB }
function libYUV_NV12ToARGB(const src_y: PByte; src_stride_y: NativeInt; const src_uv: PByte; src_stride_uv: NativeInt; dst_argb: PByte; dst_stride_argb, Width, Height: NativeInt): NativeInt;
begin
   Result := NV12ToARGB(src_y, src_stride_y, src_uv, src_stride_uv, dst_argb, dst_stride_argb, Width, Height);
end;

{ P010LE YUV420 转 RGB }
function libYUV_P010LEToARGB(const frame: PAVFrame; dst_argb: PByte; iLineLength, iWidth, iHeight: NativeInt): NativeInt;
begin
  Result := P010ToARGBMatrix(PWORD(frame^.data[0]), frame^.linesize[0] div 2, PWORD(frame^.data[1]), frame^.linesize[1] div 2, dst_argb, iLineLength, kYuvI601Constants, frame^.Width, -frame^.Height);
end;

procedure LoadlibYUVDLL;
begin
  FhlibYUV           := LoadLibrary(PChar(ExtractFilePath(ParamStr(0)) + 'plugins\libYUV.dll'));
  @NV12ToARGB        := GetProcAddress(FhlibYUV, 'NV12ToARGB');
  @P010ToARGBMatrix  := GetProcAddress(FhlibYUV, 'P010ToARGBMatrix');
  kYuvI601Constants  := GetProcAddress(FhlibYUV, 'kYuvI601Constants');
end;

procedure FreelibYUVDll;
begin
  FreeLibrary(FhlibYUV);
end;

initialization
  LoadlibYUVDLL;

finalization
  FreelibYUVDll;

end.
