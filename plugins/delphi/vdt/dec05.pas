unit dec05;
{
  功能(Func)：FFMPEG 视频硬解码 libYUV 到位图 (FFMPEG Video Decode to Bitmap)
  时间(Time)：2026-10-01
  作者(Auth)：dbyoung@sina.com
  版本(Vers)：v4.0
  语言(Lang): Delphi 13.2
}

interface

uses Winapi.Windows, Winapi.Direct3D9, Winapi.D3DX9, System.Classes, System.SysUtils, System.Threading, DLLSyncHelper, {$I ffhead.inc}, Vcl.Graphics;

type
  TImageProcessCallback = procedure (bmp: TBitmap) of object;

{ TVideoDecode05 }
type
  TVideoDecode05 = class(TThread)
  private
    Fpfct          : PAVFormatContext;
    Fpcct          : PAVCodecContext;
    FiVideoIndex   : Integer;
    FpGPUFrame     : PAVFrame;
    FpCPUFrame     : PAVFrame;
    FBmp32         : TBitmap;
    FilineSize     : Integer;
    FpBits         : PByte;
    Fpkt           : TAVPacket;
    FDrawUICanvas  : TCanvas;
    FbShowFrameRate: Boolean;
    Fswsct         : PSwsContext;
    FintST         : Cardinal;
    FintFrameCount : Integer;
    FUserCallback  : TImageProcessCallback;
    Fhw_device_ctx : PAVBufferRef;
    { + 寻找硬件解码器 }
    function FindHWDecoder(const strName: string; var hwType: TAVHWDeviceType): Boolean;
    { + 查询硬件是否支持此格式视频硬解 }
    function GetSupportHWConfig(decoder: PAVCodec; hwType: TAVHWDeviceType): Boolean;
    { + 初始化硬解解码器 }
    function InitHWDecoder(var pcct: PAVCodecContext; hwType: TAVHWDeviceType): Boolean;
    function hw_decoder_init(ctx: PAVCodecContext; const hwType: TAVHWDeviceType): Integer;
    procedure CalcFrameRate(const bShowFrameRate: Boolean);
    procedure FrameToBitmap(const frame: PAVFrame);
    procedure VideoDecode(DecCT: PAVCodecContext; pkt: TAVPacket; pGPUFrame: PAVFrame);
    procedure UpdateUI;
  protected
    procedure Execute; override;
  public
    constructor Create(const strVideoFileName: string; const hDrawUI: THandle; const UserCallback : TImageProcessCallback = nil; const bShowFrameRate: Boolean = True); overload;
    destructor Destroy; override;
  end;

implementation

uses libyuv;

const
  { 与 TAVHWDeviceType 类型对应；字符串区分大小写 }
  hw_type_names  : array [0 .. 14] of PAnsiChar = ('none', 'vdpau', 'cuda', 'vaapi', 'dxva2', 'qsv', 'videotoolbox', 'd3d11va', 'drm', 'opencl', 'mediacodec', 'vulkan', 'd3d12va', 'amf', 'ohcodec');
  c_strNewHWType : PAnsiChar = 'd3d11va';

type
  TBMPAccess         = class(TBitmap);
  TBitmapImageAccess = class(TBitmapImage);

var
  Fhw_pix_fmt : TAVPixelFormat;

constructor TVideoDecode05.Create(const strVideoFileName: string; const hDrawUI: THandle; const UserCallback : TImageProcessCallback = nil; const bShowFrameRate: Boolean = True);
var
  decoder : PAVCodec;
  hwType  : TAVHWDeviceType;
begin
  inherited Create(False);
  FreeOnTerminate := True;
  FbShowFrameRate := bShowFrameRate;
  FUserCallback   := UserCallback;

  { 文件是否存在 }
  if not FileExists(strVideoFileName) then Exit;

  { + 寻找硬件解码器；字符串必须用小写；使用 D3D11VA 替代 QSV，原因很复杂 }
  if not FindHWDecoder(string(c_strNewHWType), hwType) then Exit;

  { 1. 打开文件 }
  Fpfct := nil;
  if avformat_open_input(@Fpfct, PAnsiChar(AnsiString(strVideoFileName)), nil, nil) <> 0 then Exit;

  { 2. 文件中是否包含流 }
  if avformat_find_stream_info(Fpfct, nil) < 0 then Exit;

  { 3. 查找是否包含视频流 }
  FiVideoIndex := av_find_best_stream(Fpfct, AVMEDIA_TYPE_VIDEO, -1, -1, nil, 0);
  if FiVideoIndex < 0 then Exit;

  { 4.0 寻找解码器 }
  decoder := avcodec_find_decoder(Fpfct^.streams[FiVideoIndex]^.codecpar^.codec_id);
  if decoder = nil then Exit;

  { + 查询硬件是否支持此格式视频硬解 }
  if not GetSupportHWConfig(decoder, hwType) then
    Exit;

  { 5.0 初始化解码器 }
  Fpcct := avcodec_alloc_context3(decoder);
  if Fpcct = nil then Exit;

  { 5.1 将视频流里面的参数复制到 AVCodecContext 的上下文当中 }
  if avcodec_parameters_to_context(Fpcct, Fpfct^.streams[FiVideoIndex]^.codecpar) < 0 then Exit;

  { + 初始化硬解解码器 }
  if not InitHWDecoder(Fpcct, hwType) then Exit;

  { 6.0 打开解码器 }
  if avcodec_open2(Fpcct, decoder, nil) < 0 then Exit;

  { 7.0 解码准备 --- 创建临时画布，用于解码后的图片绘制到界面 }
  FDrawUICanvas        := TCanvas.Create;
  FDrawUICanvas.Handle := GetDC(hDrawUI);

  { 7.1 解码准备 --- 创建临时位图，设置输出图片为 32bit 位图 }
  FBmp32             := TBitmap.Create;
  FBmp32.PixelFormat := pf32bit;
  FBmp32.Width       := Fpcct^.Width;
  FBmp32.Height      := Fpcct^.Height;
  FpBits             := TBitmapImageAccess(TBMPAccess(FBmp32).FImage).FDIB.dsBm.bmBits;       // 图像像素内存地址；ffmpeg 解码得到的图像直接指向这个地址；
  FilineSize         := TBitmapImageAccess(TBMPAccess(FBmp32).FImage).FDIB.dsBm.bmWidthBytes; // 图像每行字节数

  { 7.2 解码准备 --- 初始化临时帧临时变量 }
  FpGPUFrame := av_frame_alloc();
  FpCPUFrame := av_frame_alloc();

  { 7.3 解码准备 --- 用于计算帧率 }
  FintST         := GetTickCount;
  FintFrameCount := 0;
end;

{ 寻找硬件解码器 }
function TVideoDecode05.FindHWDecoder(const strName: string; var hwType: TAVHWDeviceType): Boolean;
var
  chrName: PAnsiChar;
begin
  chrName := PAnsiChar(AnsiString(strName));
  hwType  := av_hwdevice_find_type_by_name(chrName);
  Result  := hwType <> AV_HWDEVICE_TYPE_NONE;
end;

{ 查询硬件是否支持此格式视频硬解 }
function TVideoDecode05.GetSupportHWConfig(decoder: PAVCodec; hwType: TAVHWDeviceType): Boolean;
var
  I     : Integer;
  config: PAVCodecHWConfig;
begin
  Result := False;
  I      := 0;
  while True do
  begin
    config := avcodec_get_hw_config(decoder, I);
    if not Assigned(config) then
      Exit;

    if ((config.methods and AV_CODEC_HW_CONFIG_METHOD_HW_DEVICE_CTX) <> 0) and (config.device_type = hwType) then
    begin
      Fhw_pix_fmt:= config.pix_fmt;
      Result     := True;
      Break;
    end;
    Inc(I);
  end;
end;

function get_hw_format(s: PAVCodecContext; const pix_fmts: PAVPixelFormat): TAVPixelFormat; cdecl;
var
  p: PAVPixelFormat;
begin
  p := pix_fmts;
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

function TVideoDecode05.hw_decoder_init(ctx: PAVCodecContext; const hwType: TAVHWDeviceType): Integer;
var
  err: Integer;
begin
  { 初始化硬件加速上下文 }
  err := av_hwdevice_ctx_create(@Fhw_device_ctx, hwType, c_strNewHWType, nil, 0);
  if err < 0 then
  begin
    Result := err;
    Exit;
  end;

  { 设定硬件 GPU 加速 }
  ctx.hw_device_ctx := Fhw_device_ctx;
  Result            := err;
end;

{ + 初始化硬解解码器 }
function TVideoDecode05.InitHWDecoder(var pcct: PAVCodecContext; hwType: TAVHWDeviceType): Boolean;
begin
  pcct^.thread_count := 1;
  pcct^.thread_type  := 0;
  pcct^.get_format   := @get_hw_format;
  Result             := hw_decoder_init(pcct, hwType) >= 0;
end;

destructor TVideoDecode05.Destroy;
begin
  { 8.0 销毁解码资源 }
  if Assigned(Fpcct)          then avcodec_free_context(@Fpcct);
  if Assigned(FpGPUFrame)     then av_frame_free(@FpGPUFrame);
  if Assigned(FpCPUFrame)     then av_frame_free(@FpCPUFrame);
  if Assigned(Fpfct)          then avformat_close_input(@Fpfct);
  if Assigned(Fswsct)         then sws_freeContext(Fswsct);

  { 8.1 销毁位图资源 }
  if Assigned(FBmp32) then FBmp32.Free;

  { 8.2 销毁画布资源 }
  if Assigned(FDrawUICanvas) then
  begin
    DeleteDC(FDrawUICanvas.Handle);
    FDrawUICanvas.Free;
  end;

  inherited;
end;

{ 一帧视频解码到位图 }
procedure TVideoDecode05.FrameToBitmap(const frame: PAVFrame);
begin
  { 获取到位图。sws_scale 函数效率低下, libyuv 效率较高 }
  if frame^.format = Ord(AV_PIX_FMT_NV12) then
  begin
    NV12ToARGB(frame^.data[0], frame^.linesize[0], frame^.data[1], frame^.linesize[1], FpBits, FilineSize, frame^.Width, -frame^.Height);
  end
  else if frame^.format = Ord(AV_PIX_FMT_P010LE) then
  begin
    P010ToARGBMatrix(PWord(frame^.data[0]), frame^.linesize[0] div 2, PWORD(frame^.data[1]), frame^.linesize[1] div 2, FpBits, FilineSize, YuvI601Constants, frame^.Width, -frame^.Height);
  end
  else
  begin
    { 初始化图像格式转换 }
    if not Assigned(Fswsct) then
      Fswsct := sws_getContext(Fpcct^.Width, Fpcct^.Height, TAVPixelFormat(frame^.format), Fpcct^.Width, Fpcct^.Height, AV_PIX_FMT_RGB32, Ord(SWS_BICUBIC), nil, nil, nil);

    { 获取到位图；有可能是倒置的图像；如果想解决倒置问题，1：创建时就倒置，负负得正；2：使用 WINAPI 函数 SetBitmapBits，也是负负得正 }
    sws_scale(Fswsct, @frame^.data, @frame^.linesize, 0, frame^.Height, @FpBits, @FilineSize);
  end;
end;

{ 解码视频帧 }
procedure TVideoDecode05.VideoDecode(DecCT: PAVCodecContext; pkt: TAVPacket; pGPUFrame: PAVFrame);
var
  ret: Integer;
begin
  if avcodec_send_packet(DecCT, @pkt) = 0 then
  begin
    while True do
    begin
      if Terminated then Break;

      ret := avcodec_receive_frame(DecCT, pGPUFrame);
      if (ret = AVERROR_EAGAIN) or (ret = AVERROR_EOF) then Break;

      if ret < 0 then Break;

      if TAVPixelFormat(pGPUFrame^.format) <> Fhw_pix_fmt then Break;

      { 硬解码转换 GPU 显存 ---> CPU 内存 }
      ret := av_hwframe_transfer_data(FpCPUFrame, pGPUFrame, 0);
      if ret < 0 then Break;

      { 计算帧率 }
      Inc(FintFrameCount);

      { 7.5 得到一帧视频。一帧视频解码到位图 }
      FrameToBitmap(FpCPUFrame);

      { 回调用户的处理过程 }
      if Assigned(FUserCallback) then FUserCallback(FBmp32);

      { 7.6 绘制到界面 }
      Synchronize(UpdateUI);
    end;
  end;
end;

procedure TVideoDecode05.Execute;
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

{ 计算解码帧率 }
procedure TVideoDecode05.CalcFrameRate(const bShowFrameRate: Boolean);
var
  intRate: Integer;
begin
  if not bShowFrameRate then Exit;

  { 计算帧率。注意：图片绘制也会影响解码帧率 }
  intRate                   := Round(1000 * FintFrameCount / (0.000001 + GetTickCount - FintST));
  FBmp32.Canvas.Brush.Style := bsClear;
  FBmp32.Canvas.Font.Color  := clYellow;
  FBmp32.Canvas.Font.Size   := 50;
  FBmp32.Canvas.Font.Name   := '宋体';
  FBmp32.Canvas.TextOut(20, 020, '作者(Auth)：dbyoung@sina.com');
  FBmp32.Canvas.TextOut(20, 100, Format('大小(Size)：%d X %d',  [Fpcct^.Width, Fpcct^.Height]));
  FBmp32.Canvas.TextOut(20, 180, Format('时长(Leng)：%0.2d 秒', [Fpfct^.duration div AV_TIME_BASE]));
  FBmp32.Canvas.TextOut(20, 260, Format('用时(Time)：%0.2d 秒', [(GetTickCount - FintST) div 1000]));
  FBmp32.Canvas.TextOut(20, 340, Format('速率(Rate)：%d 帧/秒', [intRate]));
end;

procedure TVideoDecode05.UpdateUI;
begin
  { 计算解码帧率 }
  CalcFrameRate(FbShowFrameRate);

  { 绘制到界面 }
  FDrawUICanvas.StretchDraw(FDrawUICanvas.ClipRect, FBmp32);
end;

end.
