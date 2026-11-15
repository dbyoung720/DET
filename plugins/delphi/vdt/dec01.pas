unit dec01;
{
  功能(Func)：FFMPEG 视频软解码到位图 (FFMPEG Video Decode to Bitmap)
  时间(Time)：2026-10-01
  作者(Auth)：dbyoung@sina.com
  版本(Vers)：v4.0
  语言(Lang): Delphi 13.2
}

interface

uses Winapi.Windows, System.Classes, System.SysUtils, System.Threading, DLLSyncHelper, {$I ffhead.inc}, Vcl.Graphics;

type
  TImageProcessCallback = procedure (bmp: TBitmap) of object;

{ TVideoDecode01 }
type
  TVideoDecode01 = class(TThread)
  private
    Fpfct          : PAVFormatContext;
    Fpcct          : PAVCodecContext;
    FiVideoIndex   : Integer;
    FpCPUFrame     : PAVFrame;
    FBmp32         : TBitmap;
    FilineSize     : Integer;
    FpBits         : Pointer;
    Fpkt           : TAVPacket;
    FDrawUICanvas  : TCanvas;
    FbShowFrameRate: Boolean;
    Fswsct         : PSwsContext;
    FintST         : Cardinal;
    FintFrameCount : Integer;
    FUserCallback  : TImageProcessCallback;
    procedure CalcFrameRate(const bShowFrameRate: Boolean);
    procedure FrameToBitmap(const frame: PAVFrame);
    procedure VideoDecode(DecCT: PAVCodecContext; pkt: TAVPacket; pCPUVideoframe: PAVFrame);
    procedure UpdateUI;
  protected
    procedure Execute; override;
  public
    constructor Create(const strVideoFileName: string; const hDrawUI: THandle; const UserCallback : TImageProcessCallback = nil; const bShowFrameRate: Boolean = True); overload;
    destructor Destroy; override;
  end;

implementation

type
  TBMPAccess         = class(TBitmap);
  TBitmapImageAccess = class(TBitmapImage);

constructor TVideoDecode01.Create(const strVideoFileName: string; const hDrawUI: THandle; const UserCallback : TImageProcessCallback = nil; const bShowFrameRate: Boolean = True);
var
  decoder: PAVCodec;
begin
  inherited Create(False);
  FreeOnTerminate := True;
  FbShowFrameRate := bShowFrameRate;
  FUserCallback   := UserCallback;

  { 文件是否存在 }
  if not FileExists(strVideoFileName) then Exit;

  { 1. 打开文件 }
  Fpfct := nil;
  if avformat_open_input(@Fpfct, PAnsiChar(AnsiString(strVideoFileName)), nil, nil) <> 0 then Exit;

  { 2. 文件中是否包含流 }
  if avformat_find_stream_info(Fpfct, nil) < 0 then Exit;

  { 3. 查找是否包含视频流 }
  FiVideoIndex := av_find_best_stream(Fpfct, AVMEDIA_TYPE_VIDEO, -1, -1, nil, 0);
  if FiVideoIndex < 0 then Exit;

  { 4. 寻找解码器 }
  decoder := avcodec_find_decoder(Fpfct^.streams[FiVideoIndex]^.codecpar^.codec_id);
  if decoder = nil then Exit;

  { 5.0 初始化解码器 }
  Fpcct := avcodec_alloc_context3(decoder);
  if Fpcct = nil then Exit;

  { 5.1 将视频流里面的参数复制到 AVCodecContext 的上下文当中 }
  if avcodec_parameters_to_context(Fpcct, Fpfct^.streams[FiVideoIndex]^.codecpar) < 0 then Exit;

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
  FpCPUFrame := av_frame_alloc();

  { 7.3 解码准备 --- 用于计算帧率 }
  FintST         := GetTickCount;
  FintFrameCount := 0;
end;

destructor TVideoDecode01.Destroy;
begin
  { 8.0 销毁解码资源 }
  if Assigned(Fpcct)      then avcodec_free_context(@Fpcct);
  if Assigned(FpCPUFrame) then av_frame_free(@FpCPUFrame);
  if Assigned(Fpfct)      then avformat_close_input(@Fpfct);
  if Assigned(Fswsct)     then sws_freeContext(Fswsct);

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
procedure TVideoDecode01.FrameToBitmap(const frame: PAVFrame);
begin
  { 初始化图像格式转换 }
  if not Assigned(Fswsct) then
    Fswsct := sws_getContext(Fpcct^.Width, Fpcct^.Height, TAVPixelFormat(frame^.format), Fpcct^.Width, Fpcct^.Height, AV_PIX_FMT_RGB32, Ord(SWS_BICUBIC), nil, nil, nil);

  { 获取到位图；有可能是倒置的图像；如果想解决倒置问题，1：创建时就倒置，负负得正；2：使用 WINAPI 函数 SetBitmapBits，也是负负得正 }
  sws_scale(Fswsct, @frame^.data, @frame^.linesize, 0, frame^.Height, @FpBits, @FilineSize);
end;

{ 解码视频帧 }
procedure TVideoDecode01.VideoDecode(DecCT: PAVCodecContext; pkt: TAVPacket; pCPUVideoframe: PAVFrame);
var
  ret: Integer;
begin
  if avcodec_send_packet(DecCT, @pkt) = 0 then
  begin
    while True do
    begin
      if Terminated then Break;

      ret := avcodec_receive_frame(DecCT, pCPUVideoframe);
      if (ret = AVERROR_EAGAIN) or (ret = AVERROR_EOF) then Break;

      if ret < 0 then Break;

      { 计算帧率 }
      Inc(FintFrameCount);

      { 7.5 得到一帧视频。一帧视频解码到位图 }
      FrameToBitmap(pCPUVideoframe);

      { 回调用户的处理过程 }
      if Assigned(FUserCallback) then FUserCallback(FBmp32);

      { 7.6 绘制到界面 }
      Synchronize(UpdateUI);
    end;
  end;
end;

procedure TVideoDecode01.Execute;
begin
  { 7.4 开始解码 }
  while av_read_frame(Fpfct, @Fpkt) >= 0 do
  begin
    if Terminated then Exit;

    { 解码视频帧 }
    if Fpkt.stream_index = FiVideoIndex then
      VideoDecode(Fpcct, Fpkt, FpCPUFrame);

    av_packet_unref(@Fpkt);
  end;
end;

{ 计算解码帧率 }
procedure TVideoDecode01.CalcFrameRate(const bShowFrameRate: Boolean);
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

procedure TVideoDecode01.UpdateUI;
begin
  { 计算解码帧率 }
  CalcFrameRate(FbShowFrameRate);

  { 绘制到界面 }
  FDrawUICanvas.StretchDraw(FDrawUICanvas.ClipRect, FBmp32);
end;

end.
