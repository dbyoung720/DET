unit DSPlayer;

{ 播放引擎：基于 LAV Filters 构建 DirectShow 滤镜图
  LAV Splitter Source ─→ LAV Video Decoder ─→ VMR9(窗口无模式)
                       ├→ LAV Audio Decoder ─→ 默认音频渲染
                       └→ (内嵌字幕 pin) ─→ SubGrabber(采样回调)
  支持：轨道枚举/切换(IAMStreamSelect)、倍速(IMediaSeeking.SetRate)、音量(IBasicAudio)、seek、内嵌字幕采样转发 
}

interface

uses Winapi.Windows, Winapi.ActiveX, Winapi.DirectShow9, System.SysUtils, System.Classes, System.Generics.Collections, DSCommon, Subtitles, SubGrabber;

type
  TStreamKind = (skVideo, skAudio, skSubtitle);

  TStreamInfo = record
    Index: Integer;
    Kind: TStreamKind;
    Name: string;
    Enabled: Boolean;
  end;

  TDSPlayerState = (psClosed, psStopped, psPaused, psPlaying);

  TRendererKind = (rkVMR9, rkEVR);

  TDSPlayer = class
  private
    FGraph: IGraphBuilder;
    FMediaControl: IMediaControl;
    FMediaSeeking: IMediaSeeking;
    FBasicAudio: IBasicAudio;
    FMediaEvent: IMediaEvent;
    FSplitter: IBaseFilter;
    FVideoDecoder: IBaseFilter;
    FAudioDecoder: IBaseFilter;
    FVideoRenderer: IBaseFilter;
    FWindowless: IVMRWindowlessControl9;
    FEvrDisplay: IMFVideoDisplayControl;
    FRendererKind: TRendererKind;
    FStreamSelect: IAMStreamSelect;
    FFileLoaded: Boolean;
    FDurationDs: Int64;
    FState: TDSPlayerState;
    FRate: Double;
    FInternalSubEnabled: Boolean;
    FCtlWnd: HWND;
    FGrabberFilters: TList<IBaseFilter>;
    FOnSubSample: TSubSampleEvent;
    FOnSeek: TNotifyEvent;
    function GetDurationUs: Int64;
    function GetPositionUs: Int64;
    procedure SetPositionUs(const Value: Int64);
    procedure SetupVMR9;
    procedure SetupEVR;
    procedure SetupRenderer;
    function GetRendererIsEVR: Boolean;
    function ConnectSubtitlePins: Integer;
  public
    constructor Create;
    destructor Destroy; override;
    // 建图与销毁
    procedure LoadFile(const FileName: string);
    procedure CloseFile;
    // 状态控制
    procedure Play;
    procedure Pause;
    procedure Stop;
    function GetMediaState: Integer; // OA 状态: 0 stopped, 1 paused, 2 running
    // 属性
    function IsLoaded: Boolean;
    property DurationUs: Int64 read GetDurationUs;
    property PositionUs: Int64 read GetPositionUs write SetPositionUs;
    procedure SetRate(ARate: Double);
    function GetRate: Double;
    procedure SetVolume(APercent: Integer); // 0..100
    function GetVolume: Integer;
    procedure SetMute(AMuted: Boolean);
    function GetMute: Boolean;
    // 轨道
    procedure EnumStreams(List: TList<TStreamInfo>);
    procedure EnableStream(AIndex: Integer);
    property InternalSubEnabled: Boolean read FInternalSubEnabled write FInternalSubEnabled;
    // 视频窗口
    procedure SetVideoWindow(AWnd: HWND);
    procedure UpdateVideoPosition;
    procedure RepaintVideo;
    procedure DisplayModeChanged;
    // 供配置对话框使用：LAV 解码器滤镜实例（未加载/未用到时为 nil）
    property VideoDecoder: IBaseFilter read FVideoDecoder;
    property AudioDecoder: IBaseFilter read FAudioDecoder;
    property SplitterFilter: IBaseFilter read FSplitter;
    // 字幕采样回调（内嵌字幕）
    property OnSubSample: TSubSampleEvent read FOnSubSample write FOnSubSample;
    // seek 后通知（清空内嵌字幕缓存）
    property OnSeek: TNotifyEvent read FOnSeek write FOnSeek;
    // 渲染器选择：切换后需重新 LoadFile 建图
    property RendererKind: TRendererKind read FRendererKind write FRendererKind;
    property RendererIsEVR: Boolean read GetRendererIsEVR;
  end;

implementation

{ TDSPlayer }

constructor TDSPlayer.Create;
begin
  inherited Create;
  FState              := psClosed;
  FRate               := 1.0;
  FRendererKind       := rkVMR9;
  FInternalSubEnabled := True;
  FDurationDs         := 0;
  FGrabberFilters     := TList<IBaseFilter>.Create;
end;

destructor TDSPlayer.Destroy;
begin
  CloseFile;
  FGrabberFilters.Free;
  inherited Destroy;
end;

procedure TDSPlayer.LoadFile(const FileName: string);
var
  FS: IFileSourceFilter;
  VPIn, APin, VIn, VOut: IPin;
  LavVideo, LavAudio: IBaseFilter;
begin
  CloseFile;
  if not FileExists(FileName) then raise Exception.Create('文件不存在：' + FileName);

  // 查找 LAV Splitter Source：优先免注册加载（exe 附近搜 .ax），回退到注册表
  FSplitter := CreateLavFilter('LAVSplitter.ax', CLSID_LAVSplitterSource);
  if not Assigned(FSplitter) then FSplitter := FindFilterByFriendlyName('LAV Splitter Source');
  if not Assigned(FSplitter) then raise Exception.Create('未找到 LAV Filters（LAVSplitter.ax）');

  FGraph := nil;
  CoCreateInstance(CLSID_FilterGraph, nil, CLSCTX_INPROC_SERVER, IGraphBuilder, FGraph);
  if FGraph = nil then raise Exception.Create('创建 Filter Graph 失败。');

  FGraph.AddFilter(FSplitter, 'LAV Splitter Source');
  if not Succeeded(FSplitter.QueryInterface(IFileSourceFilter, FS)) then raise Exception.Create('LAV Splitter Source 不支持 IFileSourceFilter。');
  if not Succeeded(FS.Load(PChar(FileName), nil)) then raise Exception.Create('LAV Splitter 打开文件失败：' + FileName);

  // ---------- 视频 ----------
  VPIn := FirstPin(FSplitter, PINDIR_OUTPUT, @MEDIATYPE_Video);
  if Assigned(VPIn) then
  begin
    SetupRenderer;
    // 经 LAV Video Decoder 解码
    LavVideo := CreateLavFilter('LAVVideo.ax', CLSID_LAVVideoDecoder);
    if not Assigned(LavVideo) then LavVideo := FindFilterByFriendlyName('LAV Video Decoder');
    if Assigned(LavVideo) then
    begin
      FVideoDecoder := LavVideo;
      FGraph.AddFilter(LavVideo, 'LAV Video Decoder');
      VIn := FirstPin(LavVideo, PINDIR_INPUT);
      VOut := FirstPin(LavVideo, PINDIR_OUTPUT);
      if Assigned(VIn) and Succeeded(FGraph.Connect(VPIn, VIn)) then
      begin
        if Assigned(VOut) then
        begin
          // 显式连到 VMR9 的输入 pin：用 Render() 有可能插进系统默认渲染器
          // （会另开一个 ActiveMovie 窗口），这里必须指定 VMR9。
          VIn := FirstPin(FVideoRenderer, PINDIR_INPUT);
          if not Assigned(VIn) or Failed(FGraph.Connect(VOut, VIn)) then FGraph.Render(VOut);
        end;
      end
      else
        FGraph.Render(VPIn); // 回退：直接渲染视频 pin
    end
    else
      FGraph.Render(VPIn);
  end;

  // ---------- 音频 ----------
  APin := FirstPin(FSplitter, PINDIR_OUTPUT, @MEDIATYPE_Audio);
  if Assigned(APin) then
  begin
    LavAudio := CreateLavFilter('LAVAudio.ax', CLSID_LAVAudioDecoder);
    if not Assigned(LavAudio) then LavAudio := FindFilterByFriendlyName('LAV Audio Decoder');
    if Assigned(LavAudio) then
    begin
      FAudioDecoder := LavAudio;
      FGraph.AddFilter(LavAudio, 'LAV Audio Decoder');
      VIn := FirstPin(LavAudio, PINDIR_INPUT);
      VOut := FirstPin(LavAudio, PINDIR_OUTPUT);
      if Assigned(VIn) and Succeeded(FGraph.Connect(APin, VIn)) then
      begin
        if Assigned(VOut) then FGraph.Render(VOut);
      end
      else
        FGraph.Render(APin);
    end
    else
      FGraph.Render(APin);
  end;

  // ---------- 内嵌字幕 ----------
  ConnectSubtitlePins;

  // ---------- 接口 ----------
  FGraph.QueryInterface(IMediaControl, FMediaControl);
  FGraph.QueryInterface(IMediaSeeking, FMediaSeeking);
  FGraph.QueryInterface(IBasicAudio, FBasicAudio);
  FGraph.QueryInterface(IMediaEvent, FMediaEvent);
  if Assigned(FSplitter)     then FSplitter.QueryInterface(IAMStreamSelect, FStreamSelect);
  if Assigned(FMediaSeeking) then FMediaSeeking.GetDuration(FDurationDs);
  if Assigned(FMediaSeeking) and (FRate <> 1.0) then FMediaSeeking.SetRate(FRate);

  FFileLoaded := True;
  FState := psStopped;
end;

procedure TDSPlayer.CloseFile;
begin
  if Assigned(FMediaControl) then FMediaControl.Stop;
  FWindowless := nil;
  FEvrDisplay := nil;
  FStreamSelect := nil;
  FMediaControl := nil;
  FMediaSeeking := nil;
  FBasicAudio := nil;
  FMediaEvent := nil;
  for var i := 0 to FGrabberFilters.Count - 1 do FGrabberFilters[i] := nil;
  FGrabberFilters.Clear;
  FVideoRenderer := nil;
  FVideoDecoder := nil;
  FAudioDecoder := nil;
  FSplitter := nil;
  if Assigned(FGraph) then FGraph := nil; // 引用释放即销毁图
  FFileLoaded := False;
  FState := psClosed;
  FDurationDs := 0;
end;

procedure TDSPlayer.SetupVMR9;
var
  Config: IVMRFilterConfig9;
begin
  FVideoRenderer := CreateInstanceFilter(CLSID_VideoMixingRenderer9);
  if not Assigned(FVideoRenderer) then raise Exception.Create('创建 VMR9 渲染器失败。');
  FGraph.AddFilter(FVideoRenderer, 'Video Mixing Renderer 9');
  if Succeeded(FVideoRenderer.QueryInterface(IVMRFilterConfig9, Config)) then
  begin
    Config.SetNumberOfStreams(1);
    Config.SetRenderingMode(VMR9Mode_Windowless);
  end;
  if Succeeded(FVideoRenderer.QueryInterface(IVMRWindowlessControl9, FWindowless)) then
  begin
    FWindowless.SetAspectRatioMode(VMR9ARMode_LetterBox);
    if FCtlWnd <> 0 then FWindowless.SetVideoClippingWindow(FCtlWnd);
  end;
end;

procedure TDSPlayer.SetupEVR;
var
  GS: IMFGetService;
begin
  // EVR 是系统组件（正常注册），CLSID 取自注册表 CLSID\{FA10746C-9B63-4B6C-BC49-FC300EA5F256}
  FVideoRenderer := CreateInstanceFilter(CLSID_EnhancedVideoRenderer);
  if not Assigned(FVideoRenderer) then raise Exception.Create('创建 EVR 渲染器失败（系统未注册 Enhanced Video Renderer）。');
  FGraph.AddFilter(FVideoRenderer, 'Enhanced Video Renderer');
  // 取窗口控制服务
  if Succeeded(FVideoRenderer.QueryInterface(IID_IMFGetService, GS)) then GS.GetService(MR_VIDEO_RENDER_SERVICE, IID_IMFVideoDisplayControl, FEvrDisplay);
  if not Assigned(FEvrDisplay) then raise Exception.Create('EVR 未提供 IMFVideoDisplayControl 服务。');
  if FCtlWnd <> 0 then FEvrDisplay.SetVideoWindow(FCtlWnd);
end;

procedure TDSPlayer.SetupRenderer;
begin
  FWindowless := nil;
  FEvrDisplay := nil;
  case FRendererKind of
    rkEVR:  SetupEVR;
    rkVMR9: SetupVMR9;
  end;
end;

function TDSPlayer.GetRendererIsEVR: Boolean;
begin
  Result := (FRendererKind = rkEVR);
end;

function TDSPlayer.ConnectSubtitlePins: Integer;
var
  En     : IEnumPins;
  Pin    : IPin;
  Fetched: ULONG;
  Pmt    : PMediaTypeRec;
  Grabber: IBaseFilter;
  GrabPin: IPin;
  G      : TSubGrabberFilter;
  Name   : string;
begin
  Result := 0;
  if not Assigned(FSplitter) or not Assigned(FGraph) then Exit;
  if Failed(FSplitter.EnumPins(En)) then Exit;
  try
    while En.Next(1, Pin, @Fetched) = S_OK do
    begin
      Pmt := nil;
      try
        var Dir: TPinDirection;
        if Failed(Pin.QueryDirection(Dir)) or (Dir <> PINDIR_OUTPUT) then Continue;
        Pmt := GetPinMediaType(Pin, PINDIR_OUTPUT);
        if not Assigned(Pmt) then Continue;
        if not (IsEqualGuid(Pmt^.majortype, MEDIATYPE_Subtitle) or IsEqualGuid(Pmt^.majortype, MEDIATYPE_Text)) then Continue;

        G := TSubGrabberFilter.Create;
        Grabber := G;
        G.Pin.OnSample := FOnSubSample;
        Name := 'Sub Grabber ' + IntToStr(Result);
        if Failed(FGraph.AddFilter(Grabber, PChar(Name))) then Continue;
        GrabPin := FirstPin(Grabber, PINDIR_INPUT);
        if Assigned(GrabPin) and Succeeded(FGraph.Connect(Pin, GrabPin)) then
        begin
          FGrabberFilters.Add(Grabber);
          Inc(Result);
        end
        else
          FGraph.RemoveFilter(Grabber);
      finally
        DeleteMediaType(Pmt);
        Pin := nil;
      end;
    end;
  finally
    En := nil;
  end;
end;

procedure TDSPlayer.Play;
begin
  if Assigned(FMediaControl) then
  begin
    FMediaControl.Run;
    FState := psPlaying;
  end;
end;

procedure TDSPlayer.Pause;
begin
  if Assigned(FMediaControl) then
  begin
    FMediaControl.Pause;
    FState := psPaused;
  end;
end;

procedure TDSPlayer.Stop;
begin
  if Assigned(FMediaControl) then
  begin
    FMediaControl.Stop;
    if Assigned(FMediaSeeking) then
    begin
      var Zero: Int64 := 0;
      var Stop: Int64 := 0;
      FMediaSeeking.SetPositions(Zero, AM_SEEKING_AbsolutePositioning, Stop, AM_SEEKING_NoPositioning);
    end;
    FState := psStopped;
    if Assigned(FOnSeek) then FOnSeek(nil);
  end;
end;

function TDSPlayer.GetMediaState: Integer;
var
  S: TFilterState;
begin
  Result := 0;
  if Assigned(FMediaControl) then
    if Succeeded(FMediaControl.GetState(0, S)) then
    begin
      case S of
        State_Stopped: Result := 0;
        State_Paused: Result := 1;
        State_Running: Result := 2;
      end;
    end;
end;

function TDSPlayer.IsLoaded: Boolean;
begin
  Result := FFileLoaded;
end;

function TDSPlayer.GetDurationUs: Int64;
begin
  if Assigned(FMediaSeeking) then FMediaSeeking.GetDuration(FDurationDs);
  Result := DsToUs(FDurationDs);
end;

function TDSPlayer.GetPositionUs: Int64;
var
  P: Int64;
begin
  Result := 0;
  if Assigned(FMediaSeeking) then
    if Succeeded(FMediaSeeking.GetCurrentPosition(P)) then Result := DsToUs(P);
end;

procedure TDSPlayer.SetPositionUs(const Value: Int64);
begin
  if not Assigned(FMediaSeeking) then Exit;
  if Value < 0 then Exit;
  
  var Ds := UsToDs(Value);
  if Ds > FDurationDs then Ds := FDurationDs;
  var Stop: Int64 := 0;
  FMediaSeeking.SetPositions(Ds, AM_SEEKING_AbsolutePositioning, Stop, AM_SEEKING_NoPositioning);
  if Assigned(FOnSeek) then FOnSeek(nil);
end;

procedure TDSPlayer.SetRate(ARate: Double);
begin
  if ARate < 0.25 then ARate := 0.25;
  if ARate > 4.0 then ARate := 4.0;
  FRate := ARate;
  if Assigned(FMediaSeeking) then FMediaSeeking.SetRate(FRate);
end;

function TDSPlayer.GetRate: Double;
begin
  Result := FRate;
  if Assigned(FMediaSeeking) then FMediaSeeking.GetRate(FRate);
end;

procedure TDSPlayer.SetVolume(APercent: Integer);
begin
  if not Assigned(FBasicAudio) then Exit;
  if APercent < 0 then APercent := 0;
  if APercent > 100 then APercent := 100;
  if APercent = 0 then
    FBasicAudio.put_Volume(-10000)
  else
    FBasicAudio.put_Volume(-Round(100 * (100 - APercent)) - 0);
end;

function TDSPlayer.GetVolume: Integer;
var
  V: Integer;
begin
  Result := 100;
  if Assigned(FBasicAudio) and Succeeded(FBasicAudio.get_Volume(V)) then Result := Round(100 + V / 100);
end;

procedure TDSPlayer.SetMute(AMuted: Boolean);
begin
  if AMuted then
  begin
    if Assigned(FBasicAudio) then FBasicAudio.put_Volume(-10000);
  end
  else
    SetVolume(GetVolume);
end;

function TDSPlayer.GetMute: Boolean;
var
  V: Integer;
begin
  Result := False;
  if Assigned(FBasicAudio) and Succeeded(FBasicAudio.get_Volume(V)) then Result := V <= -10000;
end;

procedure TDSPlayer.EnumStreams(List: TList<TStreamInfo>);
var
  Count       : DWORD;
  Flags, Group: DWORD;
  Lcid        : DWORD;
  Pmt         : PAMMediaType;
  Name        : PWCHAR;
  Obj, Unk    : IUnknown;
  Info        : TStreamInfo;
begin
  List.Clear;
  if not Assigned(FStreamSelect) then Exit;
  if Failed(FStreamSelect.Count(Count)) then Exit;

  for var i := 0 to Count - 1 do
  begin
    Pmt := nil;
    Name := nil;
    Obj := nil;
    Unk := nil;
    try
      Flags := 0;
      Lcid  := 0;
      Group := 0;
      if Succeeded(FStreamSelect.Info(i, Pmt, Flags, Lcid, Group, Name, Obj, Unk)) then
      begin
        if not Assigned(Pmt) then Continue;
        Info.Index := i;
        Info.Name := '';
        if Name <> nil then Info.Name := string(Name);
        Info.Enabled := (Flags and AMSTREAMSELECTINFO_ENABLED) <> 0;
        if IsEqualGuid(Pmt^.majortype, MEDIATYPE_Video) then
          Info.Kind := skVideo
        else if IsEqualGuid(Pmt^.majortype, MEDIATYPE_Audio) then
          Info.Kind := skAudio
        else if IsEqualGuid(Pmt^.majortype, MEDIATYPE_Subtitle) or IsEqualGuid(Pmt^.majortype, MEDIATYPE_Text) then
          Info.Kind := skSubtitle
        else
          Continue;
        List.Add(Info);
      end;
    finally
      if Assigned(Pmt) then DeleteMediaType(Pmt);
      if Name <> nil then   CoTaskMemFree(Name);
    end;
  end;
end;

procedure TDSPlayer.EnableStream(AIndex: Integer);
begin
  if not Assigned(FStreamSelect) then Exit;

  // LAV Splitter 对 AMSTREAMSELECTENABLE_ENABLEALL 返回 E_NOTIMPL，必须用 ENABLE 只启用目标流。
  FStreamSelect.Enable(AIndex, AMSTREAMSELECTENABLE_ENABLE);
end;

procedure TDSPlayer.SetVideoWindow(AWnd: HWND);
begin
  FCtlWnd := AWnd;
  if Assigned(FWindowless) and (AWnd <> 0) then FWindowless.SetVideoClippingWindow(AWnd);
  if Assigned(FEvrDisplay) and (AWnd <> 0) then FEvrDisplay.SetVideoWindow(AWnd);
end;

// 计算信箱式目标矩形（VMR9/EVR 共用）
function GetLetterboxRect(ClientWnd: HWND; NativeW, NativeH, ArW, ArH: Integer; out Dst: TRect): Boolean;
var
  R     : TRect;
  Sx, Sy: Double;
  DW, DH: Integer;
begin
  Result := False;
  if (ClientWnd = 0) or (not GetClientRect(ClientWnd, R)) then Exit;
  if (R.Right <= R.Left) or (R.Bottom <= R.Top) then Exit;
  if (NativeW <= 0) or (NativeH <= 0) then Exit;

  if ArW <= 0 then ArW := NativeW;
  if ArH <= 0 then ArH := NativeH;
  DW := R.Right - R.Left;
  DH := R.Bottom - R.Top;
  Sx := DW / NativeW;
  Sy := DH / NativeH;
  if Sx < Sy then
  begin
    Dst.Left := 0;
    Dst.Right := DW;
    DH := Round(NativeH * Sx * ArW / ArH);
    Dst.Top := (R.Bottom - R.Top - DH) div 2;
    Dst.Bottom := Dst.Top + DH;
  end
  else
  begin
    Dst.Top := 0;
    Dst.Bottom := R.Bottom - R.Top;
    DW := Round(NativeW * Sy * ArW / ArH);
    Dst.Left := (R.Right - R.Left - DW) div 2;
    Dst.Right := Dst.Left + DW;
  end;
  Result := True;
end;

procedure TDSPlayer.UpdateVideoPosition;
var
  R: TRect;
  W, H, ArW, ArH: LongInt;
  Dst: TRect;
  Full: TMFVideoNormalizedRect;
  EvrW, EvrH: TSize;
begin
  if FCtlWnd = 0 then Exit;

  if Assigned(FWindowless) then
  begin
    if not GetClientRect(FCtlWnd, R) then Exit;
    if (R.Right <= R.Left) or (R.Bottom <= R.Top) then Exit;
    if Succeeded(FWindowless.GetNativeVideoSize(W, H, ArW, ArH)) and (W > 0) and (H > 0) then
      if GetLetterboxRect(FCtlWnd, W, H, ArW, ArH, Dst) then FWindowless.SetVideoPosition(nil, @Dst);
    Exit;
  end;

  if Assigned(FEvrDisplay) then
  begin
    if Failed(FEvrDisplay.GetNativeVideoSize(EvrW, EvrH)) then Exit;
    if GetLetterboxRect(FCtlWnd, EvrW.cx, EvrH.cy, EvrW.cx, EvrH.cy, Dst) then
    begin
      Full.left := 0; Full.top := 0;
      Full.right := 1; Full.bottom := 1;
      FEvrDisplay.SetVideoPosition(@Full, @Dst);
    end;
  end;
end;

procedure TDSPlayer.RepaintVideo;
begin
  if Assigned(FWindowless) and (FCtlWnd <> 0) then
  begin
    var DC := GetDC(FCtlWnd);
    try
      FWindowless.RepaintVideo(FCtlWnd, DC);
    finally
      ReleaseDC(FCtlWnd, DC);
    end;
    Exit;
  end;

  if Assigned(FEvrDisplay) then FEvrDisplay.RepaintVideo;
end;

procedure TDSPlayer.DisplayModeChanged;
begin
  if Assigned(FWindowless) then FWindowless.DisplayModeChanged;
end;

end.
