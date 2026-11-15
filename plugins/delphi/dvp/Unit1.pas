unit Unit1;

interface

uses Winapi.Windows, Winapi.MultiMon, Winapi.Messages, Winapi.ActiveX, Winapi.DirectShow9, Winapi.ShellAPI,
     System.SysUtils, System.Variants, System.Classes, System.ImageList, System.Win.ComObj, System.UITypes,
     System.Generics.Collections, System.Generics.Defaults, System.Math, System.Win.Registry, System.Actions, System.StrUtils,
     Vcl.Controls, Vcl.Forms, Vcl.StdCtrls, Vcl.Graphics, Vcl.Menus, Vcl.ImgList, Vcl.Dialogs, Vcl.ExtCtrls, Vcl.ComCtrls, Vcl.ActnList, Vcl.ActnMan,
     Vcl.ActnCtrls, Vcl.ActnMenus, Vcl.PlatformDefaultStyleActnCtrls, Vcl.ToolWin, Vcl.ImageCollection, Vcl.VirtualImageList, Vcl.BaseImageCollection,
     DSPlayer, DSCommon, Subtitles, SubOverlay, SubGrabber, OsdWin;

type
  TfrmVideoPlayer = class(TForm)
    ActionManager1: TActionManager;
    barMain: TActionMainMenuBar;
    pmMain: TPopupMenu;
    ImageCollection1: TImageCollection;
    VirtualImageList1: TVirtualImageList;
    actPlayPause: TAction;
    actStop: TAction;
    actSeekBack5: TAction;
    actSeekFwd5: TAction;
    actSeekBack30: TAction;
    actSeekFwd30: TAction;
    actRate025: TAction;
    actRate050: TAction;
    actRate075: TAction;
    actRate100: TAction;
    actRate125: TAction;
    actRate150: TAction;
    actRate200: TAction;
    actRate300: TAction;
    actRate400: TAction;
    actSpeedUp: TAction;
    actSpeedDown: TAction;
    actSpeedReset: TAction;
    actFullScreen: TAction;
    actVideoTrack: TAction;
    actRenderVMR9: TAction;
    actRenderEVR: TAction;
    actLavVideoCfg: TAction;
    actAudioTrack: TAction;
    actVolumeUp: TAction;
    actVolumeDown: TAction;
    actMute: TAction;
    actLavAudioCfg: TAction;
    actOpenVideo: TAction;
    actOpenSubtitle: TAction;
    actExit: TAction;
    actSubtitleTrack: TAction;
    actSubCloseExt: TAction;
    actSubDelayPlus: TAction;
    actSubDelayMinus: TAction;
    actSubGrow: TAction;
    actSubShrink: TAction;
    PnlVideo: TPanel;
    PnlBottom: TPanel;
    SeekBar: TTrackBar;
    BtnPlay: TButton;
    BtnStop: TButton;
    LblTime: TLabel;
    LblState: TLabel;
    VolumeBar: TTrackBar;
    FTimer: TTimer;
    procedure FormMenuCommand(Sender: TObject);
  private
    SubOverlayWin: TSubOverlay;    // 字幕覆盖层（分层顶层窗口）
    OsdWin: TOsdWindow;            // 音量等短暂提示
    // ---- 引擎与字幕 ----
    FPlayer: TDSPlayer;
    FExtSubs: TList<TSubtitleItem>;
    FIntSubs: TList<TSubtitleItem>;
    FExtSubEnabled: Boolean;
    FSubDelayUs: Int64;
    FCurrentRate: Double;          // 当前倍速
    FSeeking: Boolean;
    FPrevFileName: string;
    FHintText: string;
    FHintUntil: TDateTime;
    // ---- 全屏 ----
    FFullScreen: Boolean;
    FSavedHostWnd: HWND;           // 逃逸前的宿主父窗口
    FSavedRect: TRect;             // 逃逸前相对宿主客户区的位置
    FSavedStyle: NativeInt;
    FSavedExStyle: NativeInt;
    // ---- 光标空闲隐藏 ----
    FLastCursorPos: TPoint;
    FLastCursorMoveTick: Int64;
    FCursorHidden: Boolean;
    // ---- 消息钩子 ----
    FOldAppMessage: TMessageEvent;
    FWheelHook: HHOOK;             // 线程级 WH_GETMESSAGE（宿主消息泵不调用本 DLL 的 Application.OnMessage）
    FLastWheelTick: Int64;         // 滚轮去重：同一格会被投递两次
    FLastWheelDelta: Integer;
    // ---- 系统音量（滚轮/滑块/快捷键调 Windows 主音量）----
    FEndpointVolume: IAudioEndpointVolume;  // Core Audio 端点音量（懒加载）
    FSyncingVolume: Boolean;                // 程序同步滑块时不回写系统音量
    // ---- 动态菜单 ----
    FMenusBuilt: Boolean;
    FStreamActions: TObjectList<TAction>;   // 轨道/字幕动态项（自己管理生命周期）
    // UI
    procedure BuildUI;
    procedure BuildContextMenu;
    procedure ContextMenuPopup(Sender: TObject);
    function AddMenuItem(Parent: TMenuItem; const Caption: string; OnClick: TNotifyEvent; ShortCut: TShortCut = 0; Checked: Boolean = False; RadioItem: Boolean = False; Tag: Integer = 0): TMenuItem;
    // 动态菜单（ActionBand）
    function FindClientAction(AnItem: TActionClientItem; AAction: TCustomAction): TActionClientItem;
    function ClientItemOf(AAction: TCustomAction): TActionClientItem;
    function AddDynamicItem(AParent: TActionClientItem; const ACaption: string; ATag: Integer; AOnExec: TNotifyEvent; AImageIndex: Integer = -1; AEnabled: Boolean = True): TActionClientItem;
    procedure AddSeparator(AParent: TActionClientItem);
    procedure RebuildStreamMenus;
    procedure RebuildRateMenu;
    procedure RebuildRendererMenu;
    procedure SetRateValue(ARate: Double);
    procedure SetRateTag(ATag: Integer);
    // 播放控制
    procedure DoOpenFile(Sender: TObject);
    procedure DoCloseApp(Sender: TObject);
    procedure DoPlayPause(Sender: TObject);
    procedure DoStop(Sender: TObject);
    procedure DoSeekRelative(DeltaUs: Int64);
    procedure DoSeekByMenu(Sender: TObject);   // Tag = 偏移微秒（右键菜单用）
    procedure DoRate(Sender: TObject);
    procedure DoRateUp(Sender: TObject);
    procedure DoRateDown(Sender: TObject);
    procedure DoRateReset(Sender: TObject);
    procedure DoStreamSelect(Sender: TObject);
    procedure DoToggleExtSub(Sender: TObject);
    procedure DoLoadExtSub(Sender: TObject);
    procedure DoCloseExtSub(Sender: TObject);
    procedure DoVolUp(Sender: TObject);
    procedure DoVolDown(Sender: TObject);
    procedure DoMute(Sender: TObject);
    procedure ApplyVolume(Delta: Integer);
    procedure ShowVolumeOsd;
    // 系统音量（Core Audio 端点）
    function MediaPlaying: Boolean;
    procedure InitEndpointVolume;
    function SysGetVolume: Integer;            // 0..100，失败返回 -1
    procedure SysSetVolume(AVal: Integer);
    procedure SeekBarChange(Sender: TObject);
    procedure VolumeChange(Sender: TObject);
    procedure TimerTick(Sender: TObject);
    procedure FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    // LAV 配置 / 渲染器
    procedure DoLavVideoConfig(Sender: TObject);
    procedure DoLavAudioConfig(Sender: TObject);
    procedure ShowLavPropertyPage(const AFilter: IBaseFilter; const AxName, ACaption: string);
    procedure DoSwitchRenderer(Sender: TObject);
    procedure LoadRendererPref;
    procedure SaveRendererPref;
    procedure EnsureLavCompatibleWithRenderer;
    function ReadLavHwAccel: Integer;
    procedure WriteLavHwAccel(Mode: Integer);
    procedure SetHint(const Text: string);
    // 字幕
    procedure DoSubDelayPlus(Sender: TObject);
    procedure DoSubDelayMinus(Sender: TObject);
    procedure DoSubDelayDelta(DeltaUs: Int64);
    procedure DoSubBigger(Sender: TObject);
    procedure DoSubSmaller(Sender: TObject);
    procedure UpdateSubDisplay;
    procedure SubSampleHandler(StartDs, EndDs: Int64; const Text: string; const Subtype: TGUID);
    procedure SeekHandler(Sender: TObject);
    procedure OpenSubFile(const FileName: string);
    procedure AutoLoadExternalSubtitles(const VideoFile: string);
    function IsSubtitleFile(const FileName: string): Boolean;
    // 全屏 / 光标
    procedure DoFullscreen(Sender: TObject);
    procedure SetFullScreen(AOn: Boolean);
    function CurrentMonitorRect: TRect;
    procedure UpdateCursorVisibility;
    procedure RestoreCursor;
    procedure SyncOverlays;
    // 事件
    procedure FormShown(Sender: TObject);
    procedure FormResize(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormMouseWheel(Sender: TObject; Shift: TShiftState; WheelDelta: Integer; MousePos: TPoint; var Handled: Boolean);
    procedure AppMessage(var Msg: TMsg; var Handled: Boolean);
    // 滚轮调音量
    procedure InstallWheelHook;
    procedure UninstallWheelHook;
    function IsOwnWindow(AWnd: HWND): Boolean;
    function HandleWheel(AWheelDelta: Integer): Boolean;
    procedure WMDropFiles(var Msg: TMessage); message WM_DROPFILES;
    procedure WMMove(var Msg: TWMMove); message WM_MOVE;
  protected
    procedure WndProc(var Message: TMessage); override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure OpenPath(const FileName: string);
    procedure OpenMediaFile(const FileName: string);
  end;

implementation

{$R *.dfm}

{ 创建  }
constructor TfrmVideoPlayer.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  KeyPreview          := True;
  OnShow              := FormShown;
  OnResize            := FormResize;
  OnDestroy           := FormDestroy;
  OnKeyDown           := FormKeyDown;
  OnMouseWheel        := FormMouseWheel;
  barMain.AllowHiding := True;

  FPlayer := TDSPlayer.Create;
  LoadRendererPref;
  FExtSubs       := TList<TSubtitleItem>.Create;
  FIntSubs       := TList<TSubtitleItem>.Create;
  FExtSubEnabled := True;
  FSubDelayUs    := 0;
  FStreamActions := TObjectList<TAction>.Create(True);
  GetCursorPos(FLastCursorPos);
  FLastCursorMoveTick := Int64(GetTickCount64);
  FCursorHidden       := False;

  BuildUI;
end;

{ 销毁 }
destructor TfrmVideoPlayer.Destroy;
begin
  if Assigned(FTimer) then FTimer.Enabled := False;
  UninstallWheelHook;
  RestoreCursor;
  if FFullScreen then
    try
      SetFullScreen(False);
    except
    end;
  if Assigned(FPlayer) then
  begin
    try
      FPlayer.CloseFile;
    except
    end;
    FreeAndNil(FPlayer);
  end;
  FreeAndNil(OsdWin);
  FreeAndNil(SubOverlayWin);
  FreeAndNil(FExtSubs);
  FreeAndNil(FIntSubs);
  FreeAndNil(FStreamActions);
  inherited;
end;

{ 建界面：覆盖层 + 消息钩子 }
procedure TfrmVideoPlayer.BuildUI;
begin
  PnlVideo.OnDblClick := DoFullscreen;   // 双击视频区切换全屏
  SeekBar.OnChange    := SeekBarChange;
  BtnPlay.OnClick     := DoPlayPause;
  BtnStop.OnClick     := DoStop;
  VolumeBar.OnChange  := VolumeChange;
  pmMain.OnPopup      := ContextMenuPopup;
  FTimer.OnTimer      := TimerTick;

  // 字幕覆盖层 / OSD：宿主为视频面板，句柄就绪后再建窗口
  SubOverlayWin := TSubOverlay.Create(PnlVideo);
  OsdWin        := TOsdWindow.Create(PnlVideo);

  // 滚轮调音量：渲染器子窗口可能持有焦点，靠 Application 级消息钩子接管。
  // 保存宿主原有 handler，销毁时原样还回去，避免影响宿主。
  FOldAppMessage        := Application.OnMessage;
  Application.OnMessage := AppMessage;

  FormResize(nil);
end;

function TfrmVideoPlayer.FindClientAction(AnItem: TActionClientItem; AAction: TCustomAction): TActionClientItem;
begin
  Result := nil;
  if AnItem.Action = AAction then Exit(AnItem);
  for var i := 0 to AnItem.Items.Count - 1 do
  begin
    Result := FindClientAction(AnItem.Items[i], AAction);
    if Result <> nil then Exit;
  end;
end;

function TfrmVideoPlayer.ClientItemOf(AAction: TCustomAction): TActionClientItem;
begin
  Result := nil;
  for var i := 0 to ActionManager1.ActionBars.Count - 1 do
    for var j := 0 to ActionManager1.ActionBars[i].Items.Count - 1 do
    begin
      Result := FindClientAction(ActionManager1.ActionBars[i].Items[j], AAction);
      if Result <> nil then Exit;
    end;
end;

function TfrmVideoPlayer.AddDynamicItem(AParent: TActionClientItem; const ACaption: string; ATag: Integer; AOnExec: TNotifyEvent; AImageIndex: Integer; AEnabled: Boolean): TActionClientItem;
begin
  Result := nil;
  if AParent = nil then Exit;
  var A := TAction.Create(Self);
  A.Caption    := ACaption;
  A.Tag        := ATag;
  A.OnExecute  := AOnExec;
  A.ImageIndex := AImageIndex;
  A.Enabled    := AEnabled;
  A.ShortCut   := 0;
  FStreamActions.Add(A);
  Result        := AParent.Items.Add;
  Result.Action := A;
end;

procedure TfrmVideoPlayer.AddSeparator(AParent: TActionClientItem);
begin
  if AParent = nil then Exit;

  var It := AParent.Items.Add;
  It.Caption := '-';
end;

procedure TfrmVideoPlayer.RebuildStreamMenus;
var
  Streams                  : TList<TStreamInfo>;
  It                       : TStreamInfo;
  ClientV, ClientA, ClientS: TActionClientItem;
  HasV, HasA, HasS         : Boolean;
begin
  if not FMenusBuilt then Exit;

  ClientV := ClientItemOf(actVideoTrack);
  ClientA := ClientItemOf(actAudioTrack);
  ClientS := ClientItemOf(actSubtitleTrack);
  if (ClientV = nil) or (ClientA = nil) or (ClientS = nil) then Exit;

  // 释放上一轮动态项
  FStreamActions.Clear;
  ClientV.Items.Clear;
  ClientA.Items.Clear;
  ClientS.Items.Clear;

  Streams := TList<TStreamInfo>.Create;
  try
    if FPlayer.IsLoaded then
      try
        FPlayer.EnumStreams(Streams);
      except
        // 枚举失败只显示占位项
      end;

    // 字幕轨：先放外挂字幕开关
    AddDynamicItem(ClientS, '外挂字幕', -1, DoToggleExtSub, Ord(FExtSubEnabled));
    AddSeparator(ClientS);

    HasV := False; HasA := False; HasS := False;
    for It in Streams do
    begin
      case It.Kind of
        skVideo:
          begin
            AddDynamicItem(ClientV, It.Name, It.Index, DoStreamSelect, Ord(It.Enabled));
            HasV := True;
          end;
        skAudio:
          begin
            AddDynamicItem(ClientA, It.Name, It.Index, DoStreamSelect, Ord(It.Enabled));
            HasA := True;
          end;
      else
        AddDynamicItem(ClientS, It.Name, It.Index, DoStreamSelect, Ord(It.Enabled));
        HasS := True;
      end;
    end;

    if not HasV then AddDynamicItem(ClientV, '(无视频轨)',   -1, nil, 0, False);
    if not HasA then AddDynamicItem(ClientA, '(无音频轨)',   -1, nil, 0, False);
    if not HasS then AddDynamicItem(ClientS, '(无内嵌字幕)', -1, nil, 0, False);
  finally
    Streams.Free;
  end;
end;

procedure TfrmVideoPlayer.RebuildRateMenu;
var
  Acts: array[0..8] of TAction;
begin
  Acts[0] := actRate025; Acts[1] := actRate050; Acts[2] := actRate075;
  Acts[3] := actRate100; Acts[4] := actRate125; Acts[5] := actRate150;
  Acts[6] := actRate200; Acts[7] := actRate300; Acts[8] := actRate400;
  var Cur := FCurrentRate;
  if (FPlayer <> nil) and FPlayer.IsLoaded then Cur := FPlayer.GetRate;
  for var i := 0 to 8 do Acts[i].ImageIndex := Ord(Abs(RateValues[i] - Cur) < 0.005);
end;

procedure TfrmVideoPlayer.RebuildRendererMenu;
begin
  if FPlayer = nil then Exit;

  actRenderVMR9.ImageIndex := Ord(FPlayer.RendererKind = rkVMR9);
  actRenderEVR.ImageIndex := Ord(FPlayer.RendererKind = rkEVR);
end;

procedure TfrmVideoPlayer.SetRateValue(ARate: Double);
var
  Acts: array[0..8] of TAction;
begin
  Acts[0] := actRate025; Acts[1] := actRate050; Acts[2] := actRate075;
  Acts[3] := actRate100; Acts[4] := actRate125; Acts[5] := actRate150;
  Acts[6] := actRate200; Acts[7] := actRate300; Acts[8] := actRate400;
  FCurrentRate := ARate;
  for var i := 0 to 8 do Acts[i].ImageIndex := Ord(Abs(RateValues[i] - ARate) < 0.005);
  if FPlayer.IsLoaded then
    try
      FPlayer.SetRate(ARate);
    except
    end;
end;

procedure TfrmVideoPlayer.SetRateTag(ATag: Integer);
begin
  SetRateValue(RateValues[RateTagIndex(ATag)]);
end;

{ ---- 右键上下文菜单 ---- }

function TfrmVideoPlayer.AddMenuItem(Parent: TMenuItem; const Caption: string; OnClick: TNotifyEvent; ShortCut: TShortCut; Checked: Boolean; RadioItem: Boolean; Tag: Integer): TMenuItem;
begin
  Result           := TMenuItem.Create(Parent);
  Result.Caption   := Caption;
  Result.OnClick   := OnClick;
  Result.ShortCut  := ShortCut;
  Result.Checked   := Checked;
  Result.RadioItem := RadioItem;
  Result.Tag       := Tag;
  Parent.Add(Result);
end;

procedure TfrmVideoPlayer.ContextMenuPopup(Sender: TObject);
begin
  BuildContextMenu;
end;

procedure TfrmVideoPlayer.BuildContextMenu;
const
  Rates: array [0..8] of Integer = (25, 50, 75, 100, 125, 150, 200, 300, 400);
var
  M, RateM, SubM, VidM, AudM, RendM: TMenuItem;
  It                               : TStreamInfo;
  HasV, HasA, HasS                 : Boolean;
begin
  while pmMain.Items.Count > 0 do pmMain.Items.Delete(0);

  var Loaded := FPlayer.IsLoaded;

  AddMenuItem(pmMain.Items, '打开文件…'#9'Ctrl+O', DoOpenFile, 0);
  AddMenuItem(pmMain.Items, '-', nil, 0);

  if FPlayer.GetMediaState = 2 then
    M := AddMenuItem(pmMain.Items, '暂停'#9'空格', DoPlayPause, 0)
  else
    M := AddMenuItem(pmMain.Items, '播放'#9'空格', DoPlayPause, 0);
  M.Enabled := Loaded;
  M := AddMenuItem(pmMain.Items, '停止', DoStop, 0);
  M.Enabled := Loaded;
  AddMenuItem(pmMain.Items, '-', nil, 0);
  M := AddMenuItem(pmMain.Items, '后退 5 秒'#9'Ctrl+←', DoSeekByMenu, 0);
  M.Tag := -5000000;
  M.Enabled := Loaded;
  M := AddMenuItem(pmMain.Items, '快进 5 秒'#9'Ctrl+→', DoSeekByMenu, 0);
  M.Tag := 5000000;
  M.Enabled := Loaded;
  AddMenuItem(pmMain.Items, '-', nil, 0);

  // 倍速
  RateM         := TMenuItem.Create(pmMain);
  RateM.Caption := '倍速';
  pmMain.Items.Add(RateM);
  var Cur := Round(FPlayer.GetRate * 100);
  for var i := Low(Rates) to High(Rates) do AddMenuItem(RateM, Format('%.2fx', [Rates[i] / 100]), DoRate, 0, Rates[i] = Cur, True, Rates[i]);
  RateM.Enabled := Loaded;

  // 轨道与字幕
  var Streams := TList<TStreamInfo>.Create;
  try
    if Loaded then
      try
        FPlayer.EnumStreams(Streams);
      except
        // 枚举失败就只显示占位项
      end;

    SubM := TMenuItem.Create(pmMain);
    SubM.Caption := '字幕';
    pmMain.Items.Add(SubM);
    AddMenuItem(SubM, '外挂字幕', DoToggleExtSub, 0, FExtSubEnabled and (FExtSubs.Count > 0), True);
    AddMenuItem(SubM, '加载外挂字幕…', DoLoadExtSub, 0);
    AddMenuItem(SubM, '-', nil, 0);
    HasS := False;
    for It in Streams do
      if It.Kind = skSubtitle then
      begin
        AddMenuItem(SubM, It.Name, DoStreamSelect, 0, It.Enabled, True, It.Index);
        HasS := True;
      end;
    if not HasS then
    begin
      M := AddMenuItem(SubM, '(无内嵌字幕)', nil, 0);
      M.Tag := -1;
      M.Enabled := False;
    end;
    AddMenuItem(SubM, '-', nil, 0);
    AddMenuItem(SubM, '字幕延迟 +100ms'#9'T', DoSubDelayPlus, 0);
    AddMenuItem(SubM, '字幕延迟 -100ms'#9'Y', DoSubDelayMinus, 0);
    AddMenuItem(SubM, '-', nil, 0);
    AddMenuItem(SubM, '字幕增大'#9'F3', DoSubBigger, 0);
    AddMenuItem(SubM, '字幕减小'#9'F2', DoSubSmaller, 0);

    VidM         := TMenuItem.Create(pmMain);
    VidM.Caption := '视频轨';
    pmMain.Items.Add(VidM);
    HasV := False;
    for It in Streams do
      if It.Kind = skVideo then
      begin
        AddMenuItem(VidM, It.Name, DoStreamSelect, 0, It.Enabled, True, It.Index);
        HasV := True;
      end;
    if not HasV then
    begin
      M := AddMenuItem(VidM, '(无视频轨)', nil, 0);
      M.Tag := -1;
      M.Enabled := False;
    end;

    AudM         := TMenuItem.Create(pmMain);
    AudM.Caption := '音频轨';
    pmMain.Items.Add(AudM);
    HasA := False;
    for It in Streams do
      if It.Kind = skAudio then
      begin
        AddMenuItem(AudM, It.Name, DoStreamSelect, 0, It.Enabled, True, It.Index);
        HasA := True;
      end;
    if not HasA then
    begin
      M := AddMenuItem(AudM, '(无音频轨)', nil, 0);
      M.Tag := -1;
      M.Enabled := False;
    end;
  finally
    Streams.Free;
  end;

  AddMenuItem(pmMain.Items, '-', nil, 0);

  // 渲染器
  RendM         := TMenuItem.Create(pmMain);
  RendM.Caption := '渲染器';
  pmMain.Items.Add(RendM);
  M := AddMenuItem(RendM, 'VMR9 窗口模式', DoSwitchRenderer, 0, FPlayer.RendererKind = rkVMR9, True, 0);
  M.Enabled := Loaded;
  M := AddMenuItem(RendM, 'EVR', DoSwitchRenderer, 0, FPlayer.RendererKind = rkEVR, True, 1);
  M.Enabled := Loaded;

  M := AddMenuItem(pmMain.Items, 'LAV 视频解码器配置…', DoLavVideoConfig, 0);
  M.Enabled := Loaded;
  M := AddMenuItem(pmMain.Items, 'LAV 音频解码器配置…', DoLavAudioConfig, 0);
  M.Enabled := Loaded;

  AddMenuItem(pmMain.Items, '-', nil, 0);
  if FFullScreen then
    AddMenuItem(pmMain.Items, '退出全屏'#9'F11', DoFullscreen, 0, True)
  else
    AddMenuItem(pmMain.Items, '全屏'#9'F11', DoFullscreen, 0);
end;

{ 打开 / 关闭 }

procedure TfrmVideoPlayer.DoOpenFile(Sender: TObject);
begin
  var OD := TOpenDialog.Create(Self);
  try
    OD.Title  := '打开媒体文件';
    OD.Filter :=
      '视频文件|*.mp4;*.mkv;*.avi;*.mov;*.flv;*.wmv;*.ts;*.m2ts;*.webm;*.ogv;*.mpg;*.mpeg;*.rmvb;*.vob|' +
      '音频文件|*.mp3;*.flac;*.m4a;*.aac;*.ogg;*.wav;*.wma;*.ape;*.opus;*.dsf;*.dff|' +
      '所有文件|*.*';
    if OD.Execute then OpenMediaFile(OD.FileName);
  finally
    OD.Free;
  end;
end;

procedure TfrmVideoPlayer.OpenPath(const FileName: string);
begin
  OpenMediaFile(FileName);
end;

procedure TfrmVideoPlayer.OpenMediaFile(const FileName: string);
begin
  var Fn := FileName.Replace('/', '\');
  try
    FPlayer.OnSubSample := SubSampleHandler;
    FPlayer.OnSeek := SeekHandler;
    // 渲染器与 LAV 硬解模式必须匹配（VMR9 不能吃 DXVA2 native）
    EnsureLavCompatibleWithRenderer;
    // 必须先给渲染器提供显示窗口，再建图；否则会退化成独立渲染窗口
    FPlayer.SetVideoWindow(PnlVideo.Handle);
    FPlayer.LoadFile(Fn);
  except
    on E: Exception do
    begin
      MessageDlg(E.Message, mtError, [mbOK], 0);
      Exit;
    end;
  end;

  FIntSubs.Clear;
  FExtSubs.Clear;
  FSubDelayUs := 0;
  FPrevFileName := Fn;

  // 自动搜索视频同目录下的外挂字幕（同名/前缀匹配）
  AutoLoadExternalSubtitles(Fn);

  FPlayer.UpdateVideoPosition;
  FPlayer.Play;

  var Streams := TList<TStreamInfo>.Create;
  try
    FPlayer.EnumStreams(Streams);
    // 默认启用第一条真实字幕轨（跳过 “No subtitles” 占位项）
    for var It in Streams do
      if (It.Kind = skSubtitle) and (not SameText(It.Name, 'No subtitles')) and (Pos('V:', It.Name) = 0) then
      begin
        FPlayer.EnableStream(It.Index);
        Break;
      end;
  finally
    Streams.Free;
  end;

  FMenusBuilt := True;
  RebuildStreamMenus;
  SetRateValue(1.0); 
  RebuildRendererMenu;
  FTimer.Enabled := True;
  LblState.Caption := ExtractFileName(Fn);
end;

procedure TfrmVideoPlayer.SeekHandler(Sender: TObject);
begin
  FIntSubs.Clear;
end;

procedure TfrmVideoPlayer.SubSampleHandler(StartDs, EndDs: Int64; const Text: string; const Subtype: TGUID);
var
  It: TSubtitleItem;
begin
  It.StartUs := DsToUs(StartDs);
  It.EndUs   := DsToUs(EndDs);
  It.Text    := StringReplace(Text, '\N', #13#10, [rfReplaceAll, rfIgnoreCase]);
  It.Text    := StringReplace(It.Text, '\n', ' ', [rfReplaceAll]);
  It.Text    := StripSubTags(It.Text); 
  if Trim(It.Text) = '' then Exit;
  FIntSubs.Add(It);
end;

function TfrmVideoPlayer.IsSubtitleFile(const FileName: string): Boolean;
const
  SubExts: array [0..6] of string = ('.srt', '.ass', '.ssa', '.vtt', '.smi', '.sami', '.sub');
begin
  Result := False;
  for var i := Low(SubExts) to High(SubExts) do
    if SameText(ExtractFileExt(FileName), SubExts[i]) then Exit(True);
end;

procedure TfrmVideoPlayer.AutoLoadExternalSubtitles(const VideoFile: string);
var
  Pattern, FullName: string;
  SR               : TSearchRec;
  Candidates       : TArray<string>;
  LoadedFiles      : Integer;
begin
  var MediaFile := VideoFile.Replace('/', '\');
  var Dir := ExtractFileDir(MediaFile);
  if (Dir = '') or (not DirectoryExists(Dir)) then Exit;
  var Base := ChangeFileExt(ExtractFileName(MediaFile), '').ToLower;

  Candidates := nil;
  for Pattern in ['.srt', '.ass', '.ssa', '.vtt', '.smi', '.sami', '.sub'] do
  begin
    if FindFirst(IncludeTrailingPathDelimiter(Dir) + '*' + Pattern, faAnyFile, SR) = 0 then
    try
      repeat
        var Name := SR.Name;
        if (Name <> '.') and (Name <> '..') and ChangeFileExt(Name, '').ToLower.StartsWith(Base) then
        begin
          SetLength(Candidates, Length(Candidates) + 1);
          Candidates[High(Candidates)] := IncludeTrailingPathDelimiter(Dir) + Name;
        end;
      until FindNext(SR) <> 0;
    finally
      FindClose(SR);
    end;
  end;

  // 完全同名的排最前，其余按名称排序
  TArray.Sort<string>(Candidates,
    TComparer<string>.Construct(
      function(const L, R: string): Integer
      var
        LB, RB: string;
      begin
        LB := ChangeFileExt(ExtractFileName(L), '').ToLower;
        RB := ChangeFileExt(ExtractFileName(R), '').ToLower;
        if LB = Base then
          Result := -1
        else if RB = Base then
          Result := 1
        else
          Result := CompareText(LB, RB);
      end));

  LoadedFiles := 0;
  for FullName in Candidates do
  try
    ParseSubtitleFile(FullName, FExtSubs);
    Inc(LoadedFiles);
  except
  end;

  if (FExtSubs.Count > 0) and (LoadedFiles > 0) then FExtSubEnabled := True;
end;

procedure TfrmVideoPlayer.OpenSubFile(const FileName: string);
begin
  try
    ParseSubtitleFile(FileName.Replace('/', '\'), FExtSubs);
    FExtSubEnabled := True;
    LblState.Caption := Format('已加载字幕 %s（共 %d 条）', [ExtractFileName(FileName), FExtSubs.Count]);
    RebuildStreamMenus;
  except
    on E: Exception do MessageDlg('解析字幕失败：' + E.Message, mtError, [mbOK], 0);
  end;
end;

procedure TfrmVideoPlayer.DoLoadExtSub(Sender: TObject);
begin
  var OD := TOpenDialog.Create(Self);
  try
    OD.Title  := '加载外挂字幕';
    OD.Filter := '字幕文件|*.srt;*.ass;*.ssa;*.vtt;*.smi;*.sami;*.sub;*.txt|所有文件|*.*';
    if OD.Execute then OpenSubFile(OD.FileName);
  finally
    OD.Free;
  end;
end;

procedure TfrmVideoPlayer.DoCloseExtSub(Sender: TObject);
begin
  FExtSubEnabled := not FExtSubEnabled;
  if not FExtSubEnabled then FExtSubs.Clear;
  RebuildStreamMenus;
end;

procedure TfrmVideoPlayer.DoToggleExtSub(Sender: TObject);
begin
  FExtSubEnabled := not FExtSubEnabled;
  RebuildStreamMenus;
end;

procedure TfrmVideoPlayer.DoStreamSelect(Sender: TObject);
begin
  if not (Sender is TAction) then Exit;
  if TAction(Sender).Tag < 0 then Exit;   // 无效流占位
  try
    FPlayer.EnableStream(TAction(Sender).Tag);
  except
  end;
  RebuildStreamMenus;
end;

{ 播放控制 }

procedure TfrmVideoPlayer.DoPlayPause(Sender: TObject);
begin
  if not FPlayer.IsLoaded then Exit;
  if FPlayer.GetMediaState = 2 then
    FPlayer.Pause
  else
    FPlayer.Play;
end;

procedure TfrmVideoPlayer.DoStop(Sender: TObject);
begin
  if FPlayer.IsLoaded then FPlayer.Stop;
end;

procedure TfrmVideoPlayer.DoSeekRelative(DeltaUs: Int64);
begin
  if not FPlayer.IsLoaded then Exit;
  FPlayer.PositionUs := FPlayer.PositionUs + DeltaUs;
end;

procedure TfrmVideoPlayer.DoSeekByMenu(Sender: TObject);
begin
  if Sender is TMenuItem then DoSeekRelative(TMenuItem(Sender).Tag);
end;

procedure TfrmVideoPlayer.DoRate(Sender: TObject);
begin
  if Sender is TMenuItem then SetRateValue(TMenuItem(Sender).Tag / 100);
end;

procedure TfrmVideoPlayer.DoRateUp(Sender: TObject);
begin
  SetRateValue(FPlayer.GetRate + 0.25);
end;

procedure TfrmVideoPlayer.DoRateDown(Sender: TObject);
begin
  SetRateValue(Max(0.25, FPlayer.GetRate - 0.25));
end;

procedure TfrmVideoPlayer.DoRateReset(Sender: TObject);
begin
  SetRateValue(1.0);
end;

procedure TfrmVideoPlayer.SeekBarChange(Sender: TObject);
begin
  if not FPlayer.IsLoaded then Exit;
  if FSeeking then Exit;   // 程序刷新进度条时不触发
  FPlayer.PositionUs := Round(SeekBar.Position / 1000 * FPlayer.DurationUs);
end;

{ 系统音量（滚轮/滑块/快捷键/静音都走 Windows 主音量） }

function TfrmVideoPlayer.MediaPlaying: Boolean;
begin
  Result := Assigned(FPlayer) and FPlayer.IsLoaded and (FPlayer.GetMediaState = 2);
end;

procedure TfrmVideoPlayer.InitEndpointVolume;
var
  DevEnum: IMMDeviceEnumerator;
  Dev: IMMDevice;
begin
  if FEndpointVolume <> nil then Exit;
  if Failed(CoCreateInstance(CLSID_MMDeviceEnumerator, nil, CLSCTX_ALL, IID_IMMDeviceEnumerator, DevEnum)) then Exit;
  if Failed(DevEnum.GetDefaultAudioEndpoint(0, 0, Dev)) then Exit;  // eRender / eConsole
  Dev.Activate(IID_IAudioEndpointVolume, CLSCTX_ALL, nil, FEndpointVolume);
end;

function TfrmVideoPlayer.SysGetVolume: Integer;
var
  V: Single;
begin
  Result := -1;
  if FEndpointVolume = nil then Exit;
  if Succeeded(FEndpointVolume.GetMasterVolumeLevelScalar(V)) then Result := Round(V * 100);
end;

procedure TfrmVideoPlayer.SysSetVolume(AVal: Integer);
begin
  if FEndpointVolume = nil then Exit;
  FEndpointVolume.SetMasterVolumeLevelScalar(AVal / 100, nil);
end;

procedure TfrmVideoPlayer.VolumeChange(Sender: TObject);
begin
  if FSyncingVolume or (not MediaPlaying) then Exit;   // 程序同步/非播放状态不回写
  SysSetVolume(VolumeBar.Position);
end;

procedure TfrmVideoPlayer.ApplyVolume(Delta: Integer);
begin
  if (VolumeBar = nil) or (Delta = 0) then Exit;
  if not MediaPlaying then Exit;   // 非播放状态不可调节
  
  InitEndpointVolume;
  var V := SysGetVolume;
  if V < 0 then Exit;
  
  var NewV := Min(100, Max(0, V + Delta));
  if NewV <> V then SysSetVolume(NewV);
  FSyncingVolume := True;
  try
    VolumeBar.Position := NewV;
  finally
    FSyncingVolume := False;
  end;
  ShowVolumeOsd;
end;

procedure TfrmVideoPlayer.ShowVolumeOsd;
var
  M: LongBool;
begin
  if OsdWin = nil then Exit;
  if (FEndpointVolume <> nil) and Succeeded(FEndpointVolume.GetMute(M)) and M then
    OsdWin.ShowText('静音')
  else
    OsdWin.ShowText(Format('音量 %d', [VolumeBar.Position]));
end;

procedure TfrmVideoPlayer.DoVolUp(Sender: TObject);
begin
  ApplyVolume(5);
end;

procedure TfrmVideoPlayer.DoVolDown(Sender: TObject);
begin
  ApplyVolume(-5);
end;

procedure TfrmVideoPlayer.DoMute(Sender: TObject);
var
  M: LongBool;
begin
  if not MediaPlaying then Exit;
  InitEndpointVolume;
  if FEndpointVolume = nil then Exit;
  if Succeeded(FEndpointVolume.GetMute(M)) then FEndpointVolume.SetMute(not M, nil);
  ShowVolumeOsd;
end;

{ LAV Filters 配置页 }
procedure TfrmVideoPlayer.ShowLavPropertyPage(const AFilter: IBaseFilter; const AxName, ACaption: string);
var
  Spec: ISpecifyPropertyPages;
  Pages: TCAGUID;
  Unk: IUnknown;
  Cookies: TArray<Longint>;
  i: Integer;
  H1, H2, H3: HResult;
begin
  if AFilter = nil then Exit;
  
  H1           := AFilter.QueryInterface(ISpecifyPropertyPages, Spec);
  H2           := E_FAIL;
  Pages.cElems := 0;
  Pages.pElems := nil;
  if Succeeded(H1) then H2 := Spec.GetPages(Pages);
  if Failed(H1) or Failed(H2) or (Pages.cElems = 0) then
  begin
    MessageDlg('该滤镜没有提供配置页面。', mtInformation, [mbOK], 0);
    Exit;
  end;

  Unk := AFilter;
  try
    // 先把每个页面类在进程内注册成类工厂（转发到 .ax 的 DllGetClassObject）
    SetLength(Cookies, Pages.cElems);
    for i := 0 to Pages.cElems - 1 do Cookies[i] := 0;
    for i := 0 to Pages.cElems - 1 do
      if not RegisterLavClass(AxName, Pages.pElems^[i], Cookies[i]) then Cookies[i] := 0;
    H3 := OleCreatePropertyFrame(Handle, 0, 0, PChar(ACaption), 1, @Unk, Pages.cElems, Pages.pElems, GetUserDefaultLCID, 0, nil);
    for i := 0 to High(Cookies) do RevokeLavClass(Cookies[i]);
    if Failed(H3) then MessageDlg('打开 LAV 配置页面失败。' + sLineBreak + '（未注册的 LAV Filters 需要属性页 CLSID 能被进程内解析）', mtWarning, [mbOK], 0);
  finally
    CoTaskMemFree(Pages.pElems);
    Spec := nil;
  end;
end;

procedure TfrmVideoPlayer.DoLavVideoConfig(Sender: TObject);
begin
  if not FPlayer.IsLoaded then
  begin
    MessageDlg('请先打开媒体文件。', mtInformation, [mbOK], 0);
    Exit;
  end;
  
  if FPlayer.VideoDecoder = nil then
  begin
    MessageDlg('当前滤镜图中没有 LAV 视频解码器。', mtInformation, [mbOK], 0);
    Exit;
  end;

  ShowLavPropertyPage(FPlayer.VideoDecoder, 'LAVVideo.ax', 'LAV 视频解码器配置');
end;

procedure TfrmVideoPlayer.DoLavAudioConfig(Sender: TObject);
begin
  if not FPlayer.IsLoaded then
  begin
    MessageDlg('请先打开媒体文件。', mtInformation, [mbOK], 0);
    Exit;
  end;

  if FPlayer.AudioDecoder = nil then
  begin
    MessageDlg('当前滤镜图中没有 LAV 音频解码器。', mtInformation, [mbOK], 0);
    Exit;
  end;
  ShowLavPropertyPage(FPlayer.AudioDecoder, 'LAVAudio.ax', 'LAV 音频解码器配置');
end;

{ 渲染器切换 }

procedure TfrmVideoPlayer.LoadRendererPref;
begin
  var Reg := TRegistry.Create(KEY_READ);
  try
    if Reg.OpenKeyReadOnly('Software\LAVPlayer') and Reg.ValueExists('Renderer') and (Reg.ReadInteger('Renderer') = 1) then FPlayer.RendererKind := rkEVR;
  finally
    Reg.Free;
  end;
end;

procedure TfrmVideoPlayer.SaveRendererPref;
begin
  var Reg := TRegistry.Create(KEY_WRITE);
  try
    if Reg.OpenKey('Software\LAVPlayer', True) then Reg.WriteInteger('Renderer', Ord(FPlayer.RendererKind));
  finally
    Reg.Free;
  end;
end;

procedure TfrmVideoPlayer.DoSwitchRenderer(Sender: TObject);
var
  Kind: TRendererKind;
begin
  if Sender is TMenuItem then
    Kind := TRendererKind(TMenuItem(Sender).Tag)
  else if Sender is TAction then
    Kind := TRendererKind(TAction(Sender).Tag - 121)  // 121=VMR9, 122=EVR
  else
    Exit;
  if Kind = FPlayer.RendererKind then Exit;

  var WasPlaying := (FPlayer.GetMediaState = 2);
  var WasPaused  := (FPlayer.GetMediaState = 1);
  var PosUs      := FPlayer.PositionUs;
  FPlayer.RendererKind := Kind;
  SaveRendererPref;
  RebuildRendererMenu;

  if FPlayer.IsLoaded and (FPrevFileName <> '') then
  begin
    FPlayer.CloseFile;
    OpenMediaFile(FPrevFileName);
    if FPlayer.IsLoaded then
    begin
      FPlayer.PositionUs := PosUs;
      if WasPlaying then
        FPlayer.Play
      else if WasPaused then
        FPlayer.Pause;
    end;
  end;
end;

{ LAV 解码模式与渲染器的兼容性
  HKCU\Software\LAV\Video\HWAccel\HWAccel
  0=None 1=CUDA 2=QuickSync 3=DXVA2(copy-back) 4=DXVA2(native) 5=D3D11
}
function TfrmVideoPlayer.ReadLavHwAccel: Integer;
begin
  Result := 0;
  var Reg := TRegistry.Create(KEY_READ);
  try
    if Reg.OpenKeyReadOnly('Software\LAV\Video\HWAccel') and Reg.ValueExists('HWAccel') then Result := Reg.ReadInteger('HWAccel');
  finally
    Reg.Free;
  end;
end;

procedure TfrmVideoPlayer.WriteLavHwAccel(Mode: Integer);
begin
  var Reg := TRegistry.Create(KEY_WRITE);
  try
    if Reg.OpenKey('Software\LAV\Video\HWAccel', False) then Reg.WriteInteger('HWAccel', Mode);
  finally
    Reg.Free;
  end;
end;

procedure TfrmVideoPlayer.SetHint(const Text: string);
begin
  FHintText  := Text;
  FHintUntil := Now + (8 / 86400);   // 显示 8 秒
end;

procedure TfrmVideoPlayer.EnsureLavCompatibleWithRenderer;
var
  Mode: Integer;
begin
  Mode := ReadLavHwAccel;
  if FPlayer.RendererKind = rkVMR9 then
  begin
    // VMR9 吃不下 DXVA2 原生/回拷的 10bit 输出（实测黑屏），统一用 D3D11 回拷
    if (Mode = 3) or (Mode = 4) then
    begin
      WriteLavHwAccel(5);
      SetHint('LAV 解码已自动改为 D3D11（VMR9 不支持 DXVA2 输出）');
    end;
  end
  else if FPlayer.RendererKind = rkEVR then
  begin
    // EVR 支持 native 零拷贝；若是回拷模式则升级为 native
    if (Mode = 3) or (Mode = 5) then
    begin
      WriteLavHwAccel(4);
      SetHint('LAV 解码已自动改为 DXVA2 native（EVR 支持零拷贝）');
    end;
  end;
end;

{ 字幕 }

procedure TfrmVideoPlayer.DoSubDelayPlus(Sender: TObject);
begin
  DoSubDelayDelta(100000);
end;

procedure TfrmVideoPlayer.DoSubDelayMinus(Sender: TObject);
begin
  DoSubDelayDelta(-100000);
end;

procedure TfrmVideoPlayer.DoSubDelayDelta(DeltaUs: Int64);
begin
  FSubDelayUs := FSubDelayUs + DeltaUs;
  if FSubDelayUs < -300000000 then FSubDelayUs := -300000000;
  if FSubDelayUs > 300000000  then FSubDelayUs := 300000000;
  LblState.Caption := Format('速度: %.2fx  字幕延迟: %dms', [FPlayer.GetRate, FSubDelayUs div 1000]);
end;

procedure TfrmVideoPlayer.DoSubBigger(Sender: TObject);
begin
  SubOverlayWin.FontSize := SubOverlayWin.FontSize + 2;
  SubOverlayWin.Redraw;
end;

procedure TfrmVideoPlayer.DoSubSmaller(Sender: TObject);
begin
  SubOverlayWin.FontSize := SubOverlayWin.FontSize - 2;
  SubOverlayWin.Redraw;
end;

procedure TfrmVideoPlayer.UpdateSubDisplay;
var
  Txt : string;
begin
  if not FPlayer.IsLoaded then
  begin
    SubOverlayWin.Text := '';
    Exit;
  end;
  
  var PosUs := FPlayer.PositionUs;
  var TxtExt := '';
  var TxtInt := '';
  if FExtSubEnabled then
    FindSubtitleText(FExtSubs, PosUs, FSubDelayUs, TxtExt);
  if FPlayer.InternalSubEnabled then
    FindSubtitleText(FIntSubs, PosUs, FSubDelayUs, TxtInt);
  if FExtSubEnabled and (TxtExt <> '') then
    Txt := TxtExt
  else if FPlayer.InternalSubEnabled and (TxtInt <> '') then
    Txt := TxtInt
  else
    Txt := '';
  SubOverlayWin.Text := Txt;
end;

{ 定时刷新 }

procedure TfrmVideoPlayer.TimerTick(Sender: TObject);
const
  OAStates: array [0..2] of string = ('已停止', '已暂停', '播放中');
  function FmtT(Us: Int64): string;
  var
    T      : Int64;
    H, M, S: Integer;
  begin
    T := Us div 1000000;
    H := T div 3600;
    M := (T mod 3600) div 60;
    S := T mod 60;
    Result := IfThen(H > 0, Format('%d:%.2d:%.2d', [H, M, S]), Format('%.2d:%.2d', [M, S]));
  end;
begin
  // 音量滑块只在播放时可用；播放中跟随系统音量
  if VolumeBar <> nil then
  begin
    VolumeBar.Enabled := MediaPlaying;
    if MediaPlaying and (not FSyncingVolume) and (not VolumeBar.Focused) then
    begin  // 滑块持有焦点=用户正在拖/按，不回写覆盖用户操作
      var V := SysGetVolume;
      if (V >= 0) and (V <> VolumeBar.Position) then
      begin
        FSyncingVolume := True;
        try
          VolumeBar.Position := V;
        finally
          FSyncingVolume := False;
        end;
      end;
    end;
  end;
  // 光标空闲隐藏检查不依赖媒体是否加载（全屏空窗口时也要生效）
  UpdateCursorVisibility;
  if not FPlayer.IsLoaded then
  begin
    if OsdWin <> nil then OsdWin.Tick;
    Exit;
  end;

  var PosUs := FPlayer.PositionUs;
  var DurUs := FPlayer.DurationUs;
  FSeeking := True;
  try
    SeekBar.Position :=IfThen(DurUs > 0, Round(PosUs / DurUs * 1000), 0);
  finally
    FSeeking := False;
  end;
  LblTime.Caption := Format('%s / %s', [FmtT(PosUs), FmtT(DurUs)]);
  if FExtSubs.Count > 0 then
    LblState.Caption := Format('外挂字幕 %d 条  %s  速度: %.2fx  字幕延迟: %dms', [FExtSubs.Count, OAStates[FPlayer.GetMediaState], FPlayer.GetRate, FSubDelayUs div 1000])
  else
    LblState.Caption := Format('%s  速度: %.2fx  字幕延迟: %dms', [OAStates[FPlayer.GetMediaState], FPlayer.GetRate, FSubDelayUs div 1000]);
  // 渲染器切换时的临时提示（覆盖状态文字，几秒后自动消失）
  if (FHintText <> '') and (Now < FHintUntil) then LblState.Caption := FHintText;
  UpdateSubDisplay;
  if OsdWin <> nil then OsdWin.Tick;
end;

{ 全屏 / 光标 }

procedure TfrmVideoPlayer.DoFullscreen(Sender: TObject);
begin
  SetFullScreen(not FFullScreen);
end;

{ 当前显示器的工作区（rcMonitor，虚拟桌面坐标）}
function TfrmVideoPlayer.CurrentMonitorRect: TRect;
var
  hMon: HMONITOR;
  MI  : TMonitorInfo;
begin
  hMon := 0;
  if IsWindow(Handle) then hMon := MonitorFromWindow(Handle, MONITOR_DEFAULTTONEAREST);
  MI.cbSize := SizeOf(MI);
  if (hMon <> 0) and GetMonitorInfo(hMon, @MI) then
    Result := MI.rcMonitor
  else
    Result := Rect(0, 0, GetSystemMetrics(SM_CXSCREEN), GetSystemMetrics(SM_CYSCREEN));
end;

procedure TfrmVideoPlayer.SetFullScreen(AOn: Boolean);
var
  R: TRect;
begin
  if AOn = FFullScreen then Exit;

  if AOn then
  begin
    // 目标显示器
    var MonRect := CurrentMonitorRect;
    // 记录宿主父窗口
    FSavedHostWnd := GetAncestor(Handle, GA_PARENT);
    if FSavedHostWnd = 0 then FSavedHostWnd := GetWindow(Handle, GW_OWNER);
    // 记录相对宿主客户区的矩形，退出时据此还原
    GetWindowRect(Handle, R);
    if IsWindow(FSavedHostWnd) then MapWindowPoints(0, FSavedHostWnd, R, 2);
    FSavedRect    := R;
    FSavedStyle   := GetWindowLongPtr(Handle, GWL_STYLE);
    FSavedExStyle := GetWindowLongPtr(Handle, GWL_EXSTYLE);

    FFullScreen := True;
    barMain.Visible := False;
    PnlBottom.Visible := False;

    // 脱离宿主，变成顶层 popup
    Winapi.Windows.SetParent(Handle, 0);
    // 全屏样式：去掉 WS_CHILD 与标题栏/边框
    SetWindowLongPtr(Handle, GWL_STYLE, (FSavedStyle and not NativeInt(WS_CHILD or WS_CAPTION or WS_THICKFRAME or WS_SYSMENU or WS_MINIMIZEBOX or WS_MAXIMIZEBOX)) or NativeInt(WS_POPUP) or NativeInt(WS_VISIBLE));
    SetWindowLongPtr(Handle, GWL_EXSTYLE, (FSavedExStyle and not NativeInt(WS_EX_CLIENTEDGE or WS_EX_WINDOWEDGE)) or NativeInt(WS_EX_TOPMOST));

    // 此时窗口已无父窗口，HWND_TOPMOST 合法，位置/尺寸生效
    SetWindowPos(Handle, HWND_TOPMOST, MonRect.Left, MonRect.Top, MonRect.Right - MonRect.Left, MonRect.Bottom - MonRect.Top, SWP_FRAMECHANGED or SWP_SHOWWINDOW);

    if Assigned(SubOverlayWin) then SubOverlayWin.TopMost := True;   // 否则字幕层会被置顶窗体压住
    if Assigned(OsdWin) then OsdWin.TopMost := True;
    RestoreCursor;   // 进入全屏重新计时
  end
  else
  begin
    FFullScreen := False;

    SetWindowLongPtr(Handle, GWL_EXSTYLE, FSavedExStyle);
    SetWindowLongPtr(Handle, GWL_STYLE, FSavedStyle);

    // 取消置顶要在「窗口还是顶层窗口」时做，z 序参数只对顶层窗口有效
    SetWindowPos(Handle, HWND_NOTOPMOST, 0, 0, 0, 0, SWP_NOMOVE or SWP_NOSIZE or SWP_NOACTIVATE);
    if IsWindow(FSavedHostWnd) then Winapi.Windows.SetParent(Handle, FSavedHostWnd);

    // 还原位置与大小
    SetWindowPos(Handle, 0, FSavedRect.Left, FSavedRect.Top, FSavedRect.Right - FSavedRect.Left, FSavedRect.Bottom - FSavedRect.Top, SWP_NOZORDER or SWP_NOACTIVATE or SWP_FRAMECHANGED or SWP_SHOWWINDOW);

    // 尺寸还原之后再让菜单栏/控制栏出现，否则 VCL 会按全屏尺寸重新布局
    barMain.Visible := True;
    PnlBottom.Visible := True;
    if Assigned(SubOverlayWin) then SubOverlayWin.TopMost := False;
    if Assigned(OsdWin) then OsdWin.TopMost := False;
    RestoreCursor;
  end;
  // style 变化后拖放注册需要重新挂上
  DragAcceptFiles(Handle, True);
  FormResize(nil);
end;

procedure TfrmVideoPlayer.UpdateCursorVisibility;
var
  P: TPoint;
begin
  if GetCursorPos(P) then
  begin
    if (P.X <> FLastCursorPos.X) or (P.Y <> FLastCursorPos.Y) then
    begin
      FLastCursorPos := P;
      FLastCursorMoveTick := Int64(GetTickCount64);
      if FCursorHidden then
      begin
        ShowCursor(True);
        FCursorHidden := False;
      end;
    end;
  end;

  // 超时隐藏光标
  if FFullScreen and (not FCursorHidden) and (Int64(GetTickCount64) - FLastCursorMoveTick >= 10000) then
  begin
    ShowCursor(False);
    FCursorHidden := True;
  end;
end;

procedure TfrmVideoPlayer.RestoreCursor;
begin
  if FCursorHidden then
  begin
    ShowCursor(True);
    FCursorHidden := False;
  end;
  FLastCursorMoveTick := Int64(GetTickCount64);
end;

procedure TfrmVideoPlayer.SyncOverlays;
begin
  if Assigned(SubOverlayWin) then
  begin
    SubOverlayWin.SyncToParent;
    SubOverlayWin.Redraw;
  end;
  if Assigned(OsdWin) then OsdWin.Reposition;
end;

{ 事件 }

procedure TfrmVideoPlayer.FormShown(Sender: TObject);
begin
  DragAcceptFiles(Handle, True);
  InstallWheelHook;   // 句柄就绪后挂线程级滚轮钩子
  InitEndpointVolume; // 系统主音量端点（Core Audio）
  SyncOverlays;
  // 动态菜单必须在句柄就绪之后才填充（CreateWnd 期间插入会重入卡死）
  if not FMenusBuilt then
  begin
    FMenusBuilt := True;
    RebuildStreamMenus;
    RebuildRateMenu;
    RebuildRendererMenu;
  end;
  FTimer.Enabled := True;
end;

procedure TfrmVideoPlayer.FormResize(Sender: TObject);
begin
  if Assigned(FPlayer) and FPlayer.IsLoaded then
  begin
    FPlayer.UpdateVideoPosition;
    FPlayer.RepaintVideo;
  end;
  SyncOverlays;
end;

procedure TfrmVideoPlayer.FormDestroy(Sender: TObject);
begin
  if Assigned(FTimer) then FTimer.Enabled := False;
  UninstallWheelHook;
  // 只还原我们自己挂的消息钩子，避免清掉宿主的
  if Assigned(FOldAppMessage) then
    Application.OnMessage := FOldAppMessage
  else if Assigned(Application.OnMessage) then
    Application.OnMessage := nil;
end;

procedure TfrmVideoPlayer.WMMove(var Msg: TWMMove);
begin
  inherited;
  SyncOverlays;
end;

{ 快捷键 }
procedure TfrmVideoPlayer.WndProc(var Message: TMessage);
begin
  if Message.Msg = WM_KEYDOWN then
  begin
    case Message.WParam of
      VK_SPACE:    begin DoPlayPause(nil);           Message.Result := 1; Exit; end;
      VK_LEFT:     begin DoSeekRelative(-5000000);   Message.Result := 1; Exit; end;
      VK_RIGHT:    begin DoSeekRelative(5000000);    Message.Result := 1; Exit; end;
      VK_UP:       begin DoVolUp(nil);               Message.Result := 1; Exit; end;
      VK_DOWN:     begin DoVolDown(nil);             Message.Result := 1; Exit; end;
      VK_ADD:      begin DoRateUp(nil);              Message.Result := 1; Exit; end;
      VK_SUBTRACT: begin DoRateDown(nil);            Message.Result := 1; Exit; end;
      VK_ESCAPE:
        if FFullScreen then
        begin
          SetFullScreen(False);
          Message.Result := 1;
          Exit;
        end;
      Ord('M'):    begin DoMute(nil);                Message.Result := 1; Exit; end;
      Ord('T'):    begin DoSubDelayDelta(100000);    Message.Result := 1; Exit; end;
      Ord('Y'):    begin DoSubDelayDelta(-100000);   Message.Result := 1; Exit; end;
      Ord('R'):    begin DoRateReset(nil);           Message.Result := 1; Exit; end;
    end;
  end;
  inherited;
end;

procedure TfrmVideoPlayer.WMDropFiles(var Msg: TMessage);
var
  Name: string;
begin
  var hDrop := THandle(Msg.WParam);
  var Count := DragQueryFile(hDrop, $FFFFFFFF, nil, 0);
  if Count > 0 then
  begin
    SetLength(Name, MAX_PATH);
    var Len := DragQueryFile(hDrop, 0, PChar(Name), MAX_PATH);
    SetLength(Name, Len);
    if IsSubtitleFile(Name) then
      OpenSubFile(Name)
    else
      OpenMediaFile(Name);
  end;
  DragFinish(hDrop);
end;

{ 滚轮调音量 }

var
  GWheelForm: TfrmVideoPlayer = nil;   // 当前挂了钩子的窗体

function WheelMsgHook(Code: Integer; WParam: WPARAM; LParam: LPARAM): LRESULT; stdcall;
var
  Msg: PMsg;
begin
  Result := CallNextHookEx(0, Code, WParam, LParam);
  if (Code <> HC_ACTION) or (LParam = 0) or (GWheelForm = nil) then Exit;

  Msg := PMsg(LParam);
  if Msg.message <> WM_MOUSEWHEEL then Exit;

  // wParam 高字 = 带符号增量（上滚为正，一格 120）
  if GWheelForm.HandleWheel(SmallInt(LongRec(Longint(Msg.wParam)).Hi)) then
  begin
    Msg.message := WM_NULL;   // 已处理：宿主与其它控件都不再看到这条消息
    Msg.wParam := 0;
    Msg.lParam := 0;
  end;
end;

procedure TfrmVideoPlayer.InstallWheelHook;
begin
  GWheelForm := Self;
  if FWheelHook <> 0 then Exit;

  // 同进程同线程的钩子：hMod 必须为 0
  FWheelHook := SetWindowsHookEx(WH_GETMESSAGE, @WheelMsgHook, 0, GetCurrentThreadId);
  if FWheelHook = 0 then GWheelForm := nil;   // 挂不上就退回 OnMouseWheel / Application.OnMessage
end;

procedure TfrmVideoPlayer.UninstallWheelHook;
begin
  if FWheelHook <> 0 then
  begin
    UnhookWindowsHookEx(FWheelHook);
    FWheelHook := 0;
  end;
  if GWheelForm = Self then GWheelForm := nil;
end;

{ 窗口是否属于本窗体：父窗口链 + 属主链（字幕/OSD 覆盖层是 owner 关系）。 }
function TfrmVideoPlayer.IsOwnWindow(AWnd: HWND): Boolean;
begin
  Result := False;
  while AWnd <> 0 do
  begin
    if AWnd = Handle then Exit(True);
    var P := GetParent(AWnd);
    if P <> 0 then
      AWnd := P
    else
    begin
      var O := GetWindow(AWnd, GW_OWNER);
      AWnd := O;
    end;
  end;
end;

{ 返回 True 表示滚轮已被消费。只处理光标确实落在本窗体上的情况；
  被宿主其它 Tab 盖住时（WindowFromPoint 取到别人的窗口）一律放行。 }
function TfrmVideoPlayer.HandleWheel(AWheelDelta: Integer): Boolean;
var
  P    : TPoint;
  Steps: Integer;
begin
  Result := False;
  if (FPlayer = nil) or (VolumeBar = nil) then Exit;
  if (not IsWindow(Handle)) or (not IsWindowVisible(Handle)) then Exit;
  if Application.ModalLevel > 0 then Exit;   // 有模态窗体时不干扰
  if not GetCursorPos(P) then Exit;
  if not IsOwnWindow(WindowFromPoint(P)) then Exit;

  // 滚轮也算鼠标活动：唤醒自动隐藏的光标
  FLastCursorMoveTick := Int64(GetTickCount64);
  if FCursorHidden then
  begin
    ShowCursor(True);
    FCursorHidden := False;
  end;

  if AWheelDelta = 0 then Exit;
  if not MediaPlaying then Exit;   // 非播放状态不调音量，滚轮放行给宿主

  // Win10+ 的“悬停滚动”会把同一格滚动投递两条（焦点窗口一条、光标下窗口一条），
  // 都在本线程队列里，这里只认第一条；60ms 内同向的算重复投递，消费掉但不重复调音量
  var Tick := Int64(GetTickCount64);
  if (Tick - FLastWheelTick < 60) and
     (Sign(AWheelDelta) = Sign(FLastWheelDelta)) then
  begin
    Result := True;
    Exit;
  end;

  FLastWheelTick := Tick;
  FLastWheelDelta := AWheelDelta;
  Steps := AWheelDelta div WHEEL_DELTA;          // 一格 = 120
  if Steps = 0 then Steps := Ord(AWheelDelta > 0) - Ord(AWheelDelta < 0); // 高精度滚轮 / 触摸板
  if Steps = 0 then Exit;

  ApplyVolume(Steps * 5);
  SetHint(Format('音量: %d', [VolumeBar.Position]));
  Result := True;
end;

procedure TfrmVideoPlayer.FormMouseWheel(Sender: TObject; Shift: TShiftState; WheelDelta: Integer; MousePos: TPoint; var Handled: Boolean);
begin
  if HandleWheel(WheelDelta) then Handled := True;
end;

procedure TfrmVideoPlayer.AppMessage(var Msg: TMsg; var Handled: Boolean);
begin
  // 重置空闲计时并唤醒光标
  case Msg.message of
    WM_MOUSEMOVE, WM_LBUTTONDOWN, WM_MBUTTONDOWN, WM_RBUTTONDOWN, WM_LBUTTONDBLCLK, WM_RBUTTONDBLCLK, WM_MOUSEWHEEL:
      begin
        FLastCursorMoveTick := Int64(GetTickCount64);
        if FCursorHidden then
        begin
          ShowCursor(True);
          FCursorHidden := False;
        end;
      end;
  end;

  if Msg.message <> WM_MOUSEWHEEL then Exit;
  if HandleWheel(SmallInt(LongRec(Longint(Msg.wParam)).Hi)) then Handled := True;
end;

procedure TfrmVideoPlayer.FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
  if Key = VK_SPACE         then DoPlayPause(nil)
  else if Key = VK_LEFT     then DoSeekRelative(-5000000)
  else if Key = VK_RIGHT    then DoSeekRelative(5000000)
  else if Key = VK_UP       then DoVolUp(nil)
  else if Key = VK_DOWN     then DoVolDown(nil)
  else if Key = VK_F11      then DoFullscreen(nil)
  else if Key = VK_ESCAPE   then if FFullScreen then SetFullScreen(False)
  else if Key = VK_ADD      then DoRateUp(nil)
  else if Key = VK_SUBTRACT then DoRateDown(nil)
  else if Key = Ord('M')    then DoMute(nil)
  else if Key = Ord('T')    then DoSubDelayDelta(100000)
  else if Key = Ord('Y')    then DoSubDelayDelta(-100000)
  else if Key = Ord('R')    then DoRateReset(nil)
  else if Key = VK_F3       then DoSubBigger(nil)
  else if Key = VK_F2       then DoSubSmaller(nil);
end;

{ 菜单命令统一入口 }
procedure TfrmVideoPlayer.FormMenuCommand(Sender: TObject);
begin
  case TAction(Sender).Tag of
    101: DoPlayPause(Sender);                                                     // actPlayPause   - 播放/暂停
    102: DoStop(Sender);                                                          // actStop        - 停止
    103: DoSeekRelative(-5000000);                                                // actSeekBack5   - 后退 5 秒
    104: DoSeekRelative(5000000);                                                 // actSeekFwd5    - 快进 5 秒
    105: DoSeekRelative(-30000000);                                               // actSeekBack30  - 后退 30 秒
    106: DoSeekRelative(30000000);                                                // actSeekFwd30   - 快进 30 秒
    107, 108, 109, 110, 111, 112, 113, 114, 115: SetRateTag(TAction(Sender).Tag); // 倍速 0.25x ~ 4.00x
    116: DoRateUp(Sender);                                                        // actSpeedUp     - 加速
    117: DoRateDown(Sender);                                                      // actSpeedDown   - 减速
    118: DoRateReset(Sender);                                                     // actSpeedReset  - 重置速度
    119: DoFullscreen(Sender);                                                    // actFullScreen  - 全屏
    120: ;                                                                        // actVideoTrack  - 视频轨（有子项）
    121: DoSwitchRenderer(Sender);                                                // actRenderVMR9  - VMR9
    122: DoSwitchRenderer(Sender);                                                // actRenderEVR   - EVR
    123: DoLavVideoConfig(Sender);                                                // actLavVideoCfg - LAV 视频配置
    124: ;                                                                        // actAudioTrack  - 音频轨（有子项）
    125: DoVolUp(Sender);                                                         // actVolumeUp    - 音量 +
    126: DoVolDown(Sender);                                                       // actVolumeDown  - 音量 -
    127: DoMute(Sender);                                                          // actMute        - 静音
    128: DoLavAudioConfig(Sender);                                                // actLavAudioCfg - LAV 音频配置
    129: DoOpenFile(Sender);                                                      // actOpenVideo   - 打开视频文件
    130: DoLoadExtSub(Sender);                                                    // actOpenSubtitle- 打开字幕文件
    131: DoCloseApp(Sender);                                                      // actClose       - 关闭
    132: ;                                                                        // actSubtitleTrack- 字幕轨（有子项）
    133: DoCloseExtSub(Sender);                                                   // actSubCloseExt - 关闭外挂字幕
    134: DoSubDelayPlus(Sender);                                                  // actSubDelayPlus
    135: DoSubDelayMinus(Sender);                                                 // actSubDelayMinus
    136: DoSubBigger(Sender);                                                     // actSubGrow     - 字幕增大
    137: DoSubSmaller(Sender);                                                    // actSubShrink   - 字幕减小
  end;
end;

procedure TfrmVideoPlayer.DoCloseApp(Sender: TObject);
begin
  try
    FPlayer.CloseFile;
  except
  end;

  FTimer.Enabled     := False;
  SubOverlayWin.Text := '';
  LblState.Caption   := '已停止（关闭宿主标签页可退出插件）';
  LblTime.Caption    := '00:00 / 00:00';
  SeekBar.Position   := 0;
end;

end.

