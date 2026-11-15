unit dec06;
{
  功能(Func)：FFMPEG 视频硬解码，DX 渲染
  时间(Time)：2026-10-01
  作者(Auth)：dbyoung@sina.com
  版本(Vers)：v4.0
  语言(Lang): Delphi 13.2
}

interface

uses Winapi.Windows, Winapi.Direct3D9, Winapi.D3DX9, Winapi.DXTypes, System.Classes, System.SysUtils, System.Threading, DLLSyncHelper, {$I ffhead.inc}, Vcl.Graphics;

type
  PDXVA2DevicePriv = ^TDXVA2DevicePriv;
  TDXVA2DevicePriv = record
    d3dlib       : HMODULE;
    dxva2lib     : HMODULE;
    device_handle: THandle;
    d3d9         : IDIRECT3D9;
    d3d9device   : IDIRECT3DDEVICE9;
  end;

{ TVideoDecode06 }
type
  TVideoDecode06 = class(TThread)
  private
    Fpfct          : PAVFormatContext;
    Fpcct          : PAVCodecContext;
    FiVideoIndex   : Integer;
    FpGPUFrame     : PAVFrame;
    Fpkt           : TAVPacket;
    FbShowFrameRate: Boolean;
    Fswsct         : PSwsContext;
    FintST         : Cardinal;
    FintFrameCount : Integer;
    FintRate       : Integer;
    Fhw_device_ctx : PAVBufferRef;
    FhDrawUI       : Thandle;
    Fpriv          : PDXVA2DevicePriv;
    FDXFont        : ID3DXFont;
    Fsurface       : IDIRECT3DSURFACE9;
    FbD3DReset     : Boolean;
    { + 寻找硬件解码器 }
    function FindHWDecoder(const strName: string; var hwType: TAVHWDeviceType): Boolean;
    { + 查询硬件是否支持此格式视频硬解 }
    function GetSupportHWConfig(decoder: PAVCodec; hwType: TAVHWDeviceType): Boolean;
    { + 初始化硬解解码器 }
    function InitHWDecoder(var pcct: PAVCodecContext; hwType: TAVHWDeviceType): Boolean;
    function hw_decoder_init(ctx: PAVCodecContext; const hwType: TAVHWDeviceType): Integer;
    procedure VideoDecode(DecCT: PAVCodecContext; pkt: TAVPacket; pGPUFrame: PAVFrame);
    procedure dxPlay(pGPUVideoframe: PAVFrame; DecCT: PAVCodecContext; const hDrawUI: THandle);
    procedure CreateFont(d3d: IDirect3DDevice9);
    procedure RenderText;
  protected
    procedure Execute; override;
  public
    constructor Create(const strVideoFileName: string; const hDrawUI: THandle; const bShowFrameRate: Boolean = True); overload;
    destructor Destroy; override;
  end;

implementation

const
  { 与 TAVHWDeviceType 类型对应；字符串区分大小写 }
  c_strHWTypeNames: array [TAVHWDeviceType] of PAnsiChar = ('none', 'vdpau', 'cuda', 'vaapi', 'dxva2', 'qsv', 'videotoolbox', 'd3d11va', 'drm', 'opencl', 'mediacodec', 'vulkan', 'd3d12va', 'amf', 'ohcodec');
  c_strHWType     : PAnsiChar = 'dxva2';

var
  Fhw_pix_fmt : TAVPixelFormat;

constructor TVideoDecode06.Create(const strVideoFileName: string; const hDrawUI: THandle;  const bShowFrameRate: Boolean = True);
var
  hwType  : TAVHWDeviceType;
begin
  inherited Create(False);
  FreeOnTerminate := True;
  FbShowFrameRate := bShowFrameRate;
  FhDrawUI        := hDrawUI;
  FbD3DReset      := False;
  Fpfct           := nil;

  { 文件是否存在 }
  if not FileExists(strVideoFileName) then Exit;

  { + 寻找硬件解码器；字符串必须用小写 }
  if not FindHWDecoder(string(c_strHWType), hwType) then Exit;

  { 1. 打开文件 }
  if avformat_open_input(@Fpfct, PAnsiChar(AnsiString(strVideoFileName)), nil, nil) <> 0 then Exit;

  { 2. 文件中是否包含流 }
  if avformat_find_stream_info(Fpfct, nil) < 0 then Exit;

  { 3. 查找是否包含视频流 }
  FiVideoIndex := av_find_best_stream(Fpfct, AVMEDIA_TYPE_VIDEO, -1, -1, nil, 0);
  if FiVideoIndex < 0 then Exit;

  { 4.0 寻找解码器 }
  var decoder := avcodec_find_decoder(Fpfct^.streams[FiVideoIndex]^.codecpar^.codec_id);
  if  decoder = nil then Exit;

  { + 查询硬件是否支持此格式视频硬解 }
  if not GetSupportHWConfig(decoder, hwType) then Exit;

  { 5.0 初始化解码器 }
  Fpcct := avcodec_alloc_context3(decoder);
  if Fpcct = nil then Exit;

  { 5.1 将视频流里面的参数复制到 AVCodecContext 的上下文当中 }
  if avcodec_parameters_to_context(Fpcct, Fpfct^.streams[FiVideoIndex]^.codecpar) < 0 then Exit;

  { + 初始化硬解解码器 }
  if not InitHWDecoder(Fpcct, hwType) then Exit;

  { 6.0 打开解码器 }
  if avcodec_open2(Fpcct, decoder, nil) < 0 then Exit;

  { 7.2 解码准备 --- 初始化临时帧临时变量 }
  FpGPUFrame := av_frame_alloc();

  { 7.3 解码准备 --- 用于计算帧率 }
  FintST         := GetTickCount;
  FintFrameCount := 0;
end;

{ 寻找硬件解码器 }
function TVideoDecode06.FindHWDecoder(const strName: string; var hwType: TAVHWDeviceType): Boolean;
begin
  var chrName := PAnsiChar(AnsiString(strName));
  hwType      := av_hwdevice_find_type_by_name(chrName);
  Result      := hwType <> AV_HWDEVICE_TYPE_NONE;
end;

{ 查询硬件是否支持此格式视频硬解 }
function TVideoDecode06.GetSupportHWConfig(decoder: PAVCodec; hwType: TAVHWDeviceType): Boolean;
begin
  Result := False;
  var I  :  Integer := 0;
  while True do
  begin
    var config := avcodec_get_hw_config(decoder, I);
    if not Assigned(config) then Exit;

    if ((config.methods and AV_CODEC_HW_CONFIG_METHOD_HW_DEVICE_CTX) <> 0) and (config.device_type = hwType) then
    begin
      Fhw_pix_fmt:= config.pix_fmt;
      Result     := True;
      Break;
    end;
    Inc(I);
  end;
end;

function TVideoDecode06.hw_decoder_init(ctx: PAVCodecContext; const hwType: TAVHWDeviceType): Integer;
begin
  { 初始化硬件加速上下文 }
  var err := av_hwdevice_ctx_create(@Fhw_device_ctx, hwType, c_strHWType, nil, 0);
  if err < 0 then
  begin
    Result := err;
    Exit;
  end;

  { 设定硬件 GPU 加速 }
  ctx.hw_device_ctx := Fhw_device_ctx;
  Result            := err;
end;

function get_hw_format(s: PAVCodecContext; const pix_fmts: PAVPixelFormat): TAVPixelFormat; cdecl;
begin
  var p := pix_fmts;
  while p^ <> AV_PIX_FMT_NONE do
  begin
    if p^ = Fhw_pix_fmt then
    begin
      Result := p^;
      Exit;
    end;
    Inc(p);
  end;

  Result := AV_PIX_FMT_NONE;
end;

{ + 初始化硬解解码器 }
function TVideoDecode06.InitHWDecoder(var pcct: PAVCodecContext; hwType: TAVHWDeviceType): Boolean;
begin
  pcct^.thread_count := GetActiveProcessorCount($FFFF);
  pcct^.thread_type  := 0;
  pcct^.get_format   := @get_hw_format;
  Result             := hw_decoder_init(pcct, hwType) >= 0;
end;

destructor TVideoDecode06.Destroy;
begin
  { 8.0 销毁解码资源 }
  if Assigned(Fpcct)      then avcodec_free_context(@Fpcct);
  if Assigned(FpGPUFrame) then av_frame_free(@FpGPUFrame);
  if Assigned(Fpfct)      then avformat_close_input(@Fpfct);
  if Assigned(Fswsct)     then sws_freeContext(Fswsct);

  inherited;
end;

procedure TVideoDecode06.CreateFont(d3d: IDirect3DDevice9);
begin
  var FontDesc: TD3DXFontDesc;
  ZeroMemory(@FontDesc, SizeOf(FontDesc));
  FontDesc.Height := 20;
  FontDesc.Width  := 0;
  FontDesc.Weight := FW_NORMAL;
  FontDesc.Italic := False;
  StrCopy(FontDesc.FaceName, '宋体');
  D3DXCreateFontIndirect(d3d, FontDesc, FDXFont);
end;

procedure TVideoDecode06.RenderText;
const
  c_iSpace : Integer = 30;
begin
  var rct01 := Rect(20, 0 * c_iSpace + 20, 1800, 1 * c_iSpace + 20);
  var rct02 := Rect(20, 1 * c_iSpace + 20, 1800, 2 * c_iSpace + 20);
  var rct03 := Rect(20, 2 * c_iSpace + 20, 1800, 3 * c_iSpace + 20);
  var rct04 := Rect(20, 3 * c_iSpace + 20, 1800, 4 * c_iSpace + 20);
  var rct05 := Rect(20, 4 * c_iSpace + 20, 1800, 5 * c_iSpace + 20);
  FDXFont.DrawTextW(nil, PChar('作者(Auth)：dbyoung@sina.com'),                                          -1, @rct01, DT_LEFT or DT_TOP, D3DCOLOR_XRGB(255, 255, 0));
  FDXFont.DrawTextW(nil, PChar('大小(Size)：' + InttoStr(Fpcct^.Width) + 'X' + InttoStr(Fpcct^.Height)), -1, @rct02, DT_LEFT or DT_TOP, D3DCOLOR_XRGB(255, 255, 0));
  FDXFont.DrawTextW(nil, PChar('时长(Leng)：' + InttoStr(Fpfct^.duration div AV_TIME_BASE) + '秒'),      -1, @rct03, DT_LEFT or DT_TOP, D3DCOLOR_XRGB(255, 255, 0));
  FDXFont.DrawTextW(nil, PChar('用时(Time)：' + InttoStr((GetTickCount - FintST) div 1000) + '秒'),      -1, @rct04, DT_LEFT or DT_TOP, D3DCOLOR_XRGB(255, 255, 0));
  FDXFont.DrawTextW(nil, PChar('速率(Rate)：' + InttoStr(FintRate) + '帧/秒'),                           -1, @rct05, DT_LEFT or DT_TOP, D3DCOLOR_XRGB(255, 255, 0));
end;

procedure TVideoDecode06.dxPlay(pGPUVideoframe: PAVFrame; DecCT: PAVCodecContext; const hDrawUI: THandle);
var
  device_ctx: PAVHWDeviceContext;
  clientRct : TRect;
begin
  { 获取待绘制的数据、DX 设备信息 }
  if not FbD3DReset then
  begin
    FbD3DReset  := True;
    Fsurface    := IDIRECT3DSURFACE9(pGPUVideoframe^.data[3]);     // 待绘制的数据
    device_ctx  := PAVHWDeviceContext(DecCT^.hw_device_ctx^.data); // 设备上下文信息
    Fpriv       := PDXVA2DevicePriv(device_ctx^.user_opaque);      // DX 设备信息
    CreateFont(Fpriv.d3d9device);                                  // 用于 DX 界面上绘制文本
  end;

  { 开始渲染 }
  Fpriv^.d3d9device.BeginScene;
  GetClientRect(hDrawUI, clientRct);
  var srcRect    := Rect (0, 0, pGPUVideoframe^.width, pGPUVideoframe^.height);
  var BackBuffer :IDIRECT3DSURFACE9 := nil;
  Fpriv^.d3d9device.Clear(0, nil, D3DCLEAR_TARGET, D3DCOLOR_XRGB(0, 0, 0), 1.0, 0);
  Fpriv^.d3d9device.GetBackBuffer(0, 0, D3DBACKBUFFER_TYPE_MONO, BackBuffer);
  Fpriv^.d3d9device.StretchRect(Fsurface, @srcRect, BackBuffer, nil, D3DTEXF_LINEAR);
  RenderText;
  Fpriv^.d3d9device.EndScene;
  Fpriv^.d3d9device.Present(nil, @clientRct, hDrawUI, nil);
  BackBuffer._Release;
  BackBuffer := nil;
end;

{ 解码视频帧 }
procedure TVideoDecode06.VideoDecode(DecCT: PAVCodecContext; pkt: TAVPacket; pGPUFrame: PAVFrame);
begin
  if avcodec_send_packet(DecCT, @pkt) <> 0 then Exit;

  while True do
  begin
    if Terminated then Break;

    var ret := avcodec_receive_frame(DecCT, pGPUFrame);
    if (ret = AVERROR_EAGAIN) or (ret = AVERROR_EOF) then Break;
    if ret < 0 then Break;

    if TAVPixelFormat(pGPUFrame^.format) <> Fhw_pix_fmt then Break;

    { 计算帧率 }
    Inc(FintFrameCount);
    FintRate := Round(1000 * FintFrameCount / (0.000001 + GetTickCount - FintST));

    { DX 渲染 }
    dxPlay(pGPUFrame, DecCT, FhDrawUI);
  end;
end;

procedure TVideoDecode06.Execute;
begin
  { 7.4 开始解码 }
  while av_read_frame(Fpfct, @Fpkt) >= 0 do
  begin
    if Terminated then Exit;
    if Fpkt.stream_index <> FiVideoIndex then Continue;

    { 解码视频帧 }
    VideoDecode(Fpcct, Fpkt, FpGPUFrame);

    av_packet_unref(@Fpkt);
  end;
end;

end.
