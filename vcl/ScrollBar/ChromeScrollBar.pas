unit ChromeScrollBar;

{ ==============================================================================
  Chrome 暗黑风格滚动条组件 (Delphi 13.2 / VCL)

  用法：
  1. 把 TChromeScrollBar 放到窗体上（非可视组件）。
  2. 把 Target 属性指向任意 TWinControl（TMemo / TRichEdit / TListBox /
  TTreeView / TListView / TScrollBox / TStringGrid / TPanel ...）。
  3. 组件会自动识别三种滚动来源：
  a) 窗口标准滚动条（GetScrollInfo）
  b) TScrollingWinControl / TCustomGrid 的内建滚动条
  c) 虚拟模式（设置 VirtualVerticalRange / VirtualHorizontalRange，
  滚动时触发 OnScroll，可自行 ScrollBy 移动目标内容）
  4. 水平、垂直方向可自动出现；可拖动滑块、点击箭头翻行、点击轨道翻页、
  鼠标悬停高亮、空闲后淡出（AutoHide）。

  说明：本组件不修改目标控件的滚动逻辑，只是在原有滚动基础上绘制覆盖层。
  所有颜色 / 尺寸均可自定义。
  ============================================================================== }

interface

uses Winapi.Windows, Winapi.Messages, Winapi.FlatSB, System.Classes, System.DateUtils, System.Math, System.SysUtils, System.Types, System.UITypes, Vcl.Controls, Vcl.ExtCtrls, Vcl.Forms, Vcl.Graphics, Vcl.StdCtrls;

type
  TChromeScrollBar = class;
  TCSBKind         = (csbVertical, csbHorizontal);
  TCSBMode         = (smNone, smNative, smControlScrollBar, smVirtual);
  TCSBScrollEvent  = procedure(Sender: TObject; AKind: TCSBKind; APosition: Integer) of object;
  TCSBWheelEvent   = procedure(Sender: TObject; AKind: TCSBKind; ADelta: Integer; var AHandled: Boolean) of object;

  PCSBFindRec = ^TCSBFindRec;

  TCSBFindRec = record
    Kind: TCSBKind;
    ParentHandle: HWND;
    Found: HWND;
  end;

  { 绘制在目标控件之上的滚动条覆盖层 }
  TCSBView = class(TCustomControl)
  private
    FController     : TChromeScrollBar;
    FKind           : TCSBKind;
    FHover          : Boolean;
    FDragging       : Boolean;
    FDragOffset     : Integer;
    FAlpha          : Integer;
    FAlphaTarget    : Integer;
    FLastActivity   : TDateTime;
    FPosition       : Integer;
    FMaxPos         : Integer;
    FPageSize       : Integer;
    FTrackColorValue: TColor;
    FHoverArrow     : Integer;
    { 三态视觉：0 = 正常，128 = 悬停，255 = 按下。定时器里插值，过渡才不突兀 }
    FHoverThumb     : Boolean;
    FArrowPressed   : Integer;
    FThumbGlow      : Integer;
    FArrowGlow      : array [0 .. 1] of Integer;
    FRepeatCode     : Word;
    FRepeatTimer    : TTimer;
    FPinRect        : TRect;
    FPinValid       : Boolean;
    FRestoring      : Boolean;
    { 控制器是否要求显示本覆盖层。DoTick / DoWake 以前无条件 ShowWindowNow，
      会把刚被隐藏的窗口又显示出来，30ms 一个来回，表现就是"滚动条不停闪烁"。 }
    FActive         : Boolean;
    function GetArrowSize: Integer;
    procedure GetArrowRects(out AFirst, ASecond: TRect);
    function ArrowIndexAt(X, Y: Integer): Integer;
    procedure DrawArrow(ACanvas: TCanvas; ARect: TRect; AFirst: Boolean; AActive: Boolean; AColor: TColor);
    procedure DrawArrowButton(const ARect: TRect; AIndex: Integer; AFirst: Boolean);
    procedure RepeatTick(Sender: TObject);
    function GetTrackLength: Integer;
    function GetThumbLength: Integer;
    function GetThumbRect: TRect;
    function TrackPosFromPoint(X, Y: Integer): Integer;
    procedure DoWake;
    procedure DoTick;
    { 本视图此刻是否需要按 30ms 持续跑：淡入淡出 / 三态插值 / 拖动 / 长按 / 自动隐藏倒计时。
      全静止时返回 False，控制器据此把定时器降到低频心跳。 }
    function IsBusy: Boolean;
    procedure CMMouseEnter(var Message: TMessage); message CM_MOUSEENTER;
    procedure CMMouseLeave(var Message: TMessage); message CM_MOUSELEAVE;
    procedure WMEraseBkgnd(var Message: TWMEraseBkgnd); message WM_ERASEBKGND;
    procedure WMMouseActivate(var Message: TMessage); message WM_MOUSEACTIVATE;
    procedure WMMouseWheel(var Message: TMessage); message WM_MOUSEWHEEL;
    procedure WMWindowPosChanging(var Message: TWMWindowPosChanging); message WM_WINDOWPOSCHANGING;
    procedure WMWindowPosChanged(var Message: TWMWindowPosChanged); message WM_WINDOWPOSCHANGED;
  protected
    procedure CreateParams(var Params: TCreateParams); override;
    procedure DoPaint;
    procedure Paint; override;
    procedure MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    procedure MouseMove(Shift: TShiftState; X, Y: Integer); override;
    procedure MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
  public
    constructor Create(AOwner: TChromeScrollBar; AKind: TCSBKind); reintroduce;
    { 覆盖层的 Parent 是宿主窗体，窗体析构时 TWinControl.Destroy 会把 Controls
      里的子控件直接 Destroy 掉（早于控制器自身的 Destroy）。必须在这里把
      控制器的 FViews[] 摘干净，否则 DestroyViews 会二次释放。 }
    destructor Destroy; override;
    procedure ShowWindowNow;
    { 把覆盖层钉在指定矩形上：目标控件滚动时 ScrollWindowEx 会把子窗口一起搬走，
      必须拒绝外部对位置/尺寸的修改，否则滚动条会上下抖。 }
    procedure PinTo(const R: TRect);
    { 目标控件滚动后立刻把窗口搬回原位（同步，赶在下一次绘制之前） }
    procedure EnsurePinned;
  end;

  { 挂在任意 TWinControl 上的滚动条控制器 }
  TChromeScrollBar = class(TComponent)
  private
    FTarget           : TWinControl;
    FViews            : array [TCSBKind] of TCSBView;
    FMode             : array [TCSBKind] of TCSBMode;
    FVirtualRange     : array [TCSBKind] of Integer;
    FVirtualPosition  : array [TCSBKind] of Integer;
    FBarOffset        : array [TCSBKind] of TRect;
    FLastBarW         : array [TCSBKind] of Integer;
    FLastBarH         : array [TCSBKind] of Integer;
    FTimer            : TTimer;
    FEnabled          : Boolean;
    FAutoHide         : Boolean;
    FAutoHideDelay    : Integer;
    FTransparentTrack : Boolean;
    FHideNative       : Boolean;
    FEditClass        : Boolean;
    FEditClassKnown   : Boolean;
  { EDIT / LISTBOX 切换焦点时会先擦背景再重画，中间那一帧就是肉眼看到的闪烁。
    这两类控件在 WM_PAINT 里本来就会铺满整个客户区，所以可以直接认领
    WM_ERASEBKGND 不画，闪一下就没了。其它控件保持原生行为。 }
  FNoEraseBkgnd     : Boolean;
    FHookedHandle     : HWND;
    FStyleHandle      : HWND;
    { 目标控件的父窗口（一般是 Form），也在它上面挂了子类化。
      在 DLL / 动态加载窗体的场合：FormCreate 里 HandleNeeded 会提前创建控件窗口，
      而 VCL 在 TForm.Create 结束时会把它销毁重建，新窗口上没有子类化。
      如果等第一次定时器 tick（30ms）再补装，那时窗口已经显示出来了，原生条就闪一帧。
      所以在父窗口上挂钩子：收到 WM_WINDOWPOSCHANGED / WM_SIZE / WM_SHOWWINDOW 时
      顺手重装一次，就能赶在窗口被显示之前把子类化重新按上去。 }
    FHookedParent     : HWND;
    { 挂过 OnResize 的父控件，以及它原来的事件值。
      窗口会被重建，但 OnResize 是 VCL 层属性，重建不影响它。 }
    FHookedParentCtl  : TWinControl;
    FPrevParentResize : TNotifyEvent;
    FInParentHook     : Boolean;
    FInRefresh        : Boolean;
    { 空闲闸门：只有确实需要重算时才跑 UpdateView（WM_SIZE / 属性变更 / 可见性变化等
      消息置位），避免 30ms 定时器在完全静止时还每帧全量重算。 }
    FNeedsRefresh     : Boolean;
    { 空闲心跳里的巡检缓存：内容变了（往 Memo 灌文本、ListBox 加项）不会产生
      任何我们收得到的消息，只能靠低频轮询「可滚范围」这一个数来发现。
      存上一次读到的值，不一样才跑完整 Refresh。 }
    FProbeOK          : array [TCSBKind] of Boolean;
    FProbeMax         : array [TCSBKind] of Integer;
    FBarSize          : Integer;
    FTrackColor       : TColor;
    FThumbColor       : TColor;
    FThumbHoverColor  : TColor;
    FThumbPressedColor: TColor;
    FWheelScroll      : Boolean;
    { OnScroll 去重：同一个位置只回调一次（滚到顶/底继续滚、拖动中重复提交
      都会走到同一处），FInScrollEvent 防重入（事件里再滚一次不会递归）。 }
    FLastEventPos     : array [TCSBKind] of Integer;
    FInScrollEvent    : Boolean;
    FOnScroll         : TCSBScrollEvent;
    FOnWheel          : TCSBWheelEvent;
    procedure SetTarget(AValue: TWinControl);
    procedure SetEnabled(AValue: Boolean);
    procedure SetAutoHide(AValue: Boolean);
    procedure SetBarSize(AValue: Integer);
    procedure SetTransparentTrack(AValue: Boolean);
    procedure SetHideNative(AValue: Boolean);
    procedure SetTrackColor(AValue: TColor);
    procedure SetThumbColor(AValue: TColor);
    procedure SetThumbHoverColor(AValue: TColor);
    procedure SetThumbPressedColor(AValue: TColor);
    function GetVirtualVRange: Integer;
    procedure SetVirtualVRange(AValue: Integer);
    function GetVirtualHRange: Integer;
    procedure SetVirtualHRange(AValue: Integer);
    procedure DestroyViews;
    procedure HideNativeBar(AKind: TCSBKind);
    { 覆盖层挂载点：从目标往上找第一个不滚动的祖先（通常就是窗体）。
      绝不能挂成被滚动窗口的子窗口——ScrollWindowEx 会连子窗口一起搬走。 }
    function OverlayParent: TWinControl;
    { 覆盖层父窗口坐标 -> 目标客户区坐标 }
    function ToTargetRect(const ARect: TRect): TRect;
    { 覆盖层不再被祖先裁剪，自己判断是否完整可见 }
    function BarFitsParent(AView: TCSBView; const R: TRect): Boolean;
    procedure EnsureSubclass;
    procedure RemoveSubclass;
    procedure EnsureParentHook;
    procedure RemoveParentHook;
    procedure ParentSawActivity;
    procedure ParentChildDestroyed(AChild: HWND);
    procedure ParentResized(Sender: TObject);
    function StripNativeStyle: Boolean;
    procedure PaintOverNativeStrips;
    procedure ApplySmoothPaint;
    procedure UpdateEditClass;
    procedure TimerTick(Sender: TObject);
    { 任何交互都立刻把定时器拉回 30ms，并置位待重算 }
    procedure WakeTimer;
    { 控件可见性 / 可用性变化后立刻重算，不等下一拍轮询 }
    procedure TargetStateChanged;
    { 控件颜色变化（切换亮 / 暗主题）后重取轨道色并立刻重画 }
    procedure TargetColorChanged;
    { 自己用控件底色擦一遍客户区（替代被我们挡掉的原生擦背景）。
      返回 False 表示这次不该接管，交回原生处理 }
    function EraseTargetBackground(ADC: HDC): Boolean;
    procedure InvalidateViews;
    procedure UpdateTrackColors;
    procedure UpdateView(AKind: TCSBKind);
    function ReadScrollState(AKind: TCSBKind; out APos, AMax, APage: Integer; out AMode: TCSBMode): Boolean;
    function GetBarRect(AKind: TCSBKind; out R: TRect): Boolean;
    function FindChildScrollBar(AKind: TCSBKind): HWND;
    function QueryScrollState(AKind: TCSBKind; out ACurPos, AMax, APage: Integer; out AMode: TCSBMode): Boolean;
    procedure CommitScroll(AKind: TCSBKind; ACurPos, ANewPos, APage: Integer);
    procedure ApplyScrollEx(AKind: TCSBKind; ACode: Word; APos, ADelta: Integer);
    procedure ApplyScroll(AKind: TCSBKind; ACode: Word; APos: Integer);
    procedure ApplyScrollSmooth(AKind: TCSBKind; ACode: Word; APos: Integer; ADelta: Integer);
    procedure DoScrollEvent(AKind: TCSBKind; APosition: Integer);
    procedure SetVirtualPositionValue(AKind: TCSBKind; APosition: Integer);
    procedure InvalidateTargetRect(const ARect: TRect);
    function InternalHandleWheel(AKind: TCSBKind; ADelta: Integer; AShift: Boolean): Boolean;
    function CurrentModeSupportsLineScroll(AKind: TCSBKind): Boolean;
  protected
    procedure Notification(AComponent: TComponent; Operation: TOperation); override;
    procedure Loaded; override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure Refresh;
    procedure DoRefresh;
    procedure TargetResized;
    function RangeProbeChanged: Boolean;
    procedure SetVirtualPosition(AKind: TCSBKind; APosition: Integer);
    function GetVirtualPosition(AKind: TCSBKind): Integer;
    { 让滚轮真正驱动滚动条：传入手工捕获的滚轮增量 }
    procedure HandleWheel(ADelta: Integer; AShift: Boolean = False);
    { 返回该方向滚动条当前的真实位置（由控件状态读出，已裁到合法范围） }
    function ViewPosition(AKind: TCSBKind): Integer;
    { 把覆盖层缓存的 位置/范围/页大小 与控件真实状态对齐（点击前调用，避免定时器还没刷新时把"按在滑块上"误判成"按在轨道上"） }
    procedure RefreshViewState(AKind: TCSBKind);
    { 应用层滚轮钩子回调（内部使用，请不要直接调用） }
    function HandleWheelMessage(AScreenPos: TPoint; AMsg: Cardinal; ADelta: Integer; AShift: Boolean): Boolean;
  published
    property Target          : TWinControl read FTarget write SetTarget;
    property Enabled         : Boolean read FEnabled write SetEnabled default True;
    property AutoHide        : Boolean read FAutoHide write SetAutoHide default True;
    property AutoHideDelay   : Integer read FAutoHideDelay write FAutoHideDelay default 1200;
    property BarSize         : Integer read FBarSize write SetBarSize default 8;
    property TransparentTrack: Boolean read FTransparentTrack write SetTransparentTrack default True;
    { 是否隐藏控件自带的原生滚动条（默认 True）。隐藏后原生条不再露出缝隙，但 EDIT 控件的位置需改用 EM_GETFIRSTVISIBLELINE 读取，组件内部已自动处理。 }
    property HideNativeScrollBar   : Boolean read FHideNative write SetHideNative default True;
    property WheelScroll           : Boolean read FWheelScroll write FWheelScroll default True;
    property TrackColor            : TColor read FTrackColor write SetTrackColor;
    property ThumbColor            : TColor read FThumbColor write SetThumbColor;
    property ThumbHoverColor       : TColor read FThumbHoverColor write SetThumbHoverColor;
    property ThumbPressedColor     : TColor read FThumbPressedColor write SetThumbPressedColor;
    property VirtualVerticalRange  : Integer read GetVirtualVRange write SetVirtualVRange default 0;
    property VirtualHorizontalRange: Integer read GetVirtualHRange write SetVirtualHRange default 0;
    property OnScroll              : TCSBScrollEvent read FOnScroll write FOnScroll;
    property OnWheel               : TCSBWheelEvent read FOnWheel write FOnWheel;
  end;

procedure Register;

implementation

type
  { TControl.Color 是 protected，用同构子类取到它 }
  TControlAccess = class(TControl);
  { OnResize 在 TControl 里也是 protected，同样需要一个同构子类 }
  TWinControlAccess = class(TWinControl);

var
  { 全局滚轮钩子：同一时刻只需要一个，所有控制器共享 }
  GlobalWheelHook  : HHOOK = 0;
  ActiveControllers: TList;

const
  CSBSubclassId = 1;
  { 父窗口的子类化用 id 2，和 1 分开，两套钩子互不干扰 }
  CSBParentSubclassId = 2;
  { 定时器双档：有交互 / 动画时 30ms，完全静止后退到 250ms 心跳。
    静止档只做兜底轮询（应对 TMemo.Lines.Add 这类「内容变了却不发 WM_VSCROLL」的控件），
    任何真实交互都会经 WakeTimer 立刻拉回 30ms。 }
  CSB_BUSY_INTERVAL = 30;
  CSB_IDLE_INTERVAL = 250;

function CSBSetWindowSubclass(AHandle: HWND; AProc: Pointer; AId: UINT_PTR; AData: DWORD_PTR): BOOL; stdcall; external 'comctl32.dll' name 'SetWindowSubclass';
function CSBRemoveWindowSubclass(AHandle: HWND; AProc: Pointer; AId: UINT_PTR): BOOL; stdcall; external 'comctl32.dll' name 'RemoveWindowSubclass';
function CSBDefSubclassProc(AHandle: HWND; AMsg: UINT; AW: WPARAM; AL: LPARAM): LRESULT; stdcall; external 'comctl32.dll' name 'DefSubclassProc';

{$IFDEF CSB_TRACE}
procedure CSBTrace(const S: string);
var
  F: TextFile;
begin
  AssignFile(F, 'E://AI//SB//Debug//csb_trace.log');
  if FileExists('E://AI//SB//Debug//csb_trace.log') then
    Append(F)
  else
    Rewrite(F);
  try
    Writeln(F, S);
  finally
    CloseFile(F);
  end;
end;
{$ENDIF}

{ WM_STYLECHANGING 的 lParam 指向的结构（对应 Winapi.Windows 的 TSTYLESTRUCT） }
type
  PCSBStyleStruct = ^TCSBStyleStruct;
  TCSBStyleStruct = record
    styleOld: DWORD;
    styleNew: DWORD;
  end;

function CSBSubclassProc(AHandle: HWND; AMsg: UINT; AW: WPARAM; AL: LPARAM; AId: UINT_PTR; AData: DWORD_PTR): LRESULT; stdcall;
var
  Stripped: Boolean;
  SS      : PCSBStyleStruct;
begin
  var Ctrl := TChromeScrollBar(Pointer(NativeUInt(AData)));
  { EDIT / LISTBOX 换焦点时会整块重画，中间那半帧空白就是肉眼看到的闪。
    LISTBOX 走 WM_ERASEBKGND 擦背景，这里直接认领返回 1（它自己在 WM_PAINT 里
    会铺满整个客户区）；EDIT 则在 WM_PAINT 里自己铺底，改用 WS_EX_COMPOSITED
    离屏合成，见 ApplySmoothPaint。 }
  if (AMsg = WM_ERASEBKGND) and (Ctrl <> nil) and Ctrl.FNoEraseBkgnd
    and Ctrl.EraseTargetBackground(HDC(AW)) then
  begin
    { 不能只返回 1 了事。LISTBOX 的 WM_PAINT 只画「有内容的矩形」——最后一项
      下面那块空白根本没人填，就留成未初始化的黑色；慢速改变大小时还会残留
      出一条条旧像素。这里自己用控件底色擦一遍，再返回 1 告诉系统「已经擦过」，
      既避免原生擦背景那一帧的闪，也不留脏区。 }
    Exit(1);
  end;

  { EDIT / LISTBOX 在内容变化、滚动范围更新之后会自己用 ShowScrollBar 把
    WS_VSCROLL / WS_HSCROLL 加回去（内部走 SetWindowLong(GWL_STYLE)，会先发
    WM_STYLECHANGING）。只在 WM_NCCALCSIZE / WM_NCPAINT 里事后剥，中间总有一段
    「样式位已经加回去、还没轮到剥」的空档；这段时间只要来一次绘制，原生条就被
    画到屏幕上 —— 启动时看到的那一闪就是这么来的。
    这里直接把新样式里的 WS_VSCROLL 抹掉，让它从一开始就加不回去。
    只抹 WS_VSCROLL：WS_HSCROLL 一旦抹掉，EDIT 就再也不会建立横向滚动范围
    （GetScrollInfo 的 nMax 恒为 0），横向条从此不出现 —— 这个坑踩过一次。 }
  if (AMsg = WM_STYLECHANGING) and (Ctrl <> nil) and Ctrl.FHideNative then
  begin
    SS := PCSBStyleStruct(AL);
    if SS <> nil then
      SS.styleNew := SS.styleNew and not DWORD(WS_VSCROLL);
  end;

  Stripped := False;
  if (AMsg = WM_NCCALCSIZE) and (Ctrl <> nil) then Ctrl.StripNativeStyle;
  { 原生滚动条属于非客户区。EDIT / LISTBOX 在内容变化、滚动范围更新之后会自己
    用 ShowScrollBar 把 WS_VSCROLL 加回去，于是 NCCALCSIZE 那次剥离被它悄悄撤销。
    这里在画之前再剥一次，让默认处理看到的样式位里根本没有滚动条。 }
  if (AMsg = WM_NCPAINT) and (Ctrl <> nil) then Stripped := Ctrl.StripNativeStyle;

  Result := CSBDefSubclassProc(AHandle, AMsg, AW, AL);

  { 光剥样式位还不够，必须补这一下 —— 启动时那一闪的真正来源就在这里。
    ShowScrollBar 内部是「先用类背景刷擦非客户区、再发 WM_NCPAINT」：擦的时候
    它还以为有滚动条，于是把右边那一条 17px 刷成了 COLOR_WINDOW（白）；等到
    WM_NCPAINT 进来样式位已经被我们剥掉，默认处理只画一圈边框、画不出箭头和
    滑块，那条白底就留在屏幕上了。它也不会自己消失，要等下一次真正重算非客户区
    （HideNativeBar 的 SWP_FRAMECHANGED）才被清掉 —— 实测要 200ms 以上。
    自绘覆盖层只有 8px，盖不住 17px，所以这里自己用控件底色把那一溜刷回去。 }
  if Stripped then Ctrl.PaintOverNativeStrips;

  { 目标尺寸一变就立刻重算覆盖层，不再等 30ms 定时器：拖动改变控件大小时滚动条能跟手，不会慢半拍。 }
  if (AMsg = WM_SIZE) and (Ctrl <> nil) then Ctrl.TargetResized;
  { 滚动消息一进来就立刻拉回 30ms 并置位重算：位置变化不再等定时器下一拍，
    静止时的心跳也因此可以放心退到 250ms（纯兜底）。 }
  if (Ctrl <> nil) and ((AMsg = WM_VSCROLL) or (AMsg = WM_HSCROLL)) then Ctrl.WakeTimer;
  { 键盘滚动（PageUp/PageDown/Home/End/方向键）由控件自己处理，不经过我们任何代码，
    只能在按键消息进来时提前唤醒，让下一拍立刻重读位置。 }
  if (Ctrl <> nil) and ((AMsg = WM_KEYDOWN) or (AMsg = WM_SYSKEYDOWN)) then Ctrl.WakeTimer;
  { 程序里批量灌内容（Lines.BeginUpdate / EndUpdate、Items.BeginUpdate / EndUpdate）
    只会发 WM_SETREDRAW，不发任何滚动消息。在这里唤醒，滚动条不用等空闲巡检
    就能立刻出现（巡检是兜底，250ms 才轮到一次）。 }
  if (Ctrl <> nil) and (AMsg = WM_SETREDRAW) then Ctrl.WakeTimer;
  { 控件被显示 / 隐藏（窗体 Show、Tab 切换）时立刻重算。
    显示的时候顺手走一遍完整的隐藏流程（剥样式位 + SWP_FRAMECHANGED 强制重算
    非客户区）：只剥样式位不够，客户区尺寸不会自己变，那一溜仍然占着位置。 }
  if (Ctrl <> nil) and (AMsg = WM_SHOWWINDOW) then
  begin
    if AW <> 0 then Ctrl.HideNativeBar(csbVertical);
    Ctrl.WakeTimer;
  end;
  { 控件被隐藏 / 禁用 / 重新启用时，覆盖层必须立刻跟着消失或回来。
    CM_ 是 VCL 内部消息，SetWindowSubclass 挂在 HWND 上能收到，照常放行给 VCL。 }
  if (Ctrl <> nil) and ((AMsg = CM_VISIBLECHANGED) or (AMsg = CM_ENABLEDCHANGED)) then
    Ctrl.TargetStateChanged;
  { 控件颜色变了（切换亮 / 暗主题）：TransparentTrack 模式下轨道色取自控件 Color，
    不重取的话切完主题轨道还是旧底色。 }
  if (Ctrl <> nil) and (AMsg = CM_COLORCHANGED) then Ctrl.TargetColorChanged;
end;

{ 父窗口的子类化回调，只干两件事：父窗口有动静时，把可能被重建的目标控件重装子类化。
  Form 的 WM_WINDOWPOSCHANGED / WM_SIZE / WM_SHOWWINDOW 一定发生在窗口显示之前，
  重装之后目标控件自己的非客户区消息才来，就不会漏。 }
function CSBParentSubclassProc(AHandle: HWND; AMsg: UINT; AW: WPARAM; AL: LPARAM;
  AId: UINT_PTR; AData: DWORD_PTR): LRESULT; stdcall;
var
  Ctrl: TChromeScrollBar;
begin
  Ctrl := TChromeScrollBar(Pointer(NativeUInt(AData)));
  if Ctrl <> nil then
  begin
    if (AMsg = WM_WINDOWPOSCHANGED) or (AMsg = WM_SIZE) or (AMsg = WM_SHOWWINDOW) then
      Ctrl.ParentSawActivity
    else if (AMsg = WM_PARENTNOTIFY) and (LOWORD(AW) = WM_DESTROY) then
      Ctrl.ParentChildDestroyed(HWND(AL));
  end;
  Result := CSBDefSubclassProc(AHandle, AMsg, AW, AL);
end;

function EnumChildScrollBars(AHandle: HWND; AParam: LPARAM): BOOL; stdcall;
var
  Buf                  : array [0 .. 31] of Char;
  ChildRect, ParentRect: TRect;
begin
  Result := True;
  var Rec:= PCSBFindRec(AParam);
  if (Rec = nil) or (GetParent(AHandle) <> Rec.ParentHandle) then Exit;
  if GetClassName(AHandle, Buf, Length(Buf)) <= 0 then Exit;
  if not SameText(Buf, 'ScrollBar') then Exit;
  if not GetWindowRect(AHandle, ChildRect) then Exit;
  if not GetWindowRect(Rec.ParentHandle, ParentRect) then Exit;

  case Rec.Kind of
    csbVertical:
      if Abs(ChildRect.Left - ParentRect.Right) < 40 then
      begin
        Rec.Found := AHandle;
        Result    := False;
      end;
    csbHorizontal:
      if Abs(ChildRect.Top - ParentRect.Bottom) < 40 then
      begin
        Rec.Found := AHandle;
        Result    := False;
      end;
  end;
end;

function BlendColor(ABack, AFore: TColor; AAlpha: Integer): TColor;
begin
  if AAlpha >= 255 then Exit(AFore);
  if AAlpha <= 0 then Exit(ABack);

  var BackColor := ColorToRGB(ABack);
  var ForeColor := ColorToRGB(AFore);
  var R1        := GetRValue(BackColor);
  var G1        := GetGValue(BackColor);
  var B1        := GetBValue(BackColor);
  var R2        := GetRValue(ForeColor);
  var G2        := GetGValue(ForeColor);
  var B2        := GetBValue(ForeColor);
  Result        := RGB((R1 * (255 - AAlpha) + R2 * AAlpha) div 255, (G1 * (255 - AAlpha) + G2 * AAlpha) div 255, (B1 * (255 - AAlpha) + B2 * AAlpha) div 255);
end;

{
  把绝对目标位置翻译成原生控件的相对滚动代码。
  EDIT / LISTBOX / SCROLLBOX 都只对 WM_VSCROLL / WM_HSCROLL 的相对代码（SB_LINEDOWN、SB_PAGEDOWN ...）有真正搬动内容的反应。
}
procedure SendNativeScroll(AHandle: HWND; AMsg: Cardinal; ACurPos, ANewPos, APage: Integer);
begin
  var Delta := ANewPos - ACurPos;
  if Delta = 0 then Exit;

  if APage < 1 then APage := 1;
  if Delta > 0 then
  begin
    while Delta > 0 do
    begin
      if Delta >= APage then
      begin
        SendMessage(AHandle, AMsg, SB_PAGEDOWN, 0);
        Dec(Delta, APage);
      end
      else
      begin
        SendMessage(AHandle, AMsg, SB_LINEDOWN, 0);
        Dec(Delta);
      end;
    end;
  end
  else
  begin
    Delta := -Delta;
    while Delta > 0 do
    begin
      if Delta >= APage then
      begin
        SendMessage(AHandle, AMsg, SB_PAGEUP, 0);
        Dec(Delta, APage);
      end
      else
      begin
        SendMessage(AHandle, AMsg, SB_LINEUP, 0);
        Dec(Delta);
      end;
    end;
  end;
end;

function ScrollCodeDirection(ACode: Word): Integer;
begin
  case ACode of
    SB_LINEUP, SB_PAGEUP, SB_TOP:
      Result := -1;
    SB_LINEDOWN, SB_PAGEDOWN, SB_BOTTOM:
      Result := 1;
  else
    Result := 0;
  end;
end;

function CSBGlobalWheelHook(Code: Integer; WPARAM: WPARAM; LPARAM: LPARAM): LRESULT; stdcall;
var
  Pt : TPoint;
begin
  if (Code = HC_ACTION) and (WPARAM = PM_REMOVE) and (LPARAM <> 0) and (ActiveControllers <> nil) then
  begin
    var Msg := PMSG(LPARAM);
    if (Msg.Message = WM_MOUSEWHEEL) or (Msg.Message = WM_MOUSEHWHEEL) then
    begin
      var Delta := SmallInt((Msg.WPARAM shr 16) and $FFFF);
      if Delta = 0 then Delta := 0;
      Pt.X      := SmallInt(Msg.LPARAM and $FFFF);
      Pt.Y      := SmallInt((Msg.LPARAM shr 16) and $FFFF);
      for var I := 0 to ActiveControllers.Count - 1 do
      begin
        var Ctrl := TChromeScrollBar(ActiveControllers[I]);
        try
          if Ctrl.HandleWheelMessage(Pt, Msg.Message, Delta, (Msg.WPARAM and MK_SHIFT) <> 0) then
          begin
            Msg.Message := WM_NULL;
            Break;
          end;
        except
        end;
      end;
    end;
  end;
  Result := CallNextHookEx(GlobalWheelHook, Code, WPARAM, LPARAM);
end;

{ EDIT 控件剥掉 WS_VSCROLL 之后，GetScrollInfo 返回的 nPage 会退化成 nMax+1
  （相当于"全部可见"），于是永远判定"需要滚动条" —— 窗体变大后滚动条也不隐藏；
  滑块比例同样会错。这里用几何方式自算：
  行高取第 0 / 1 行首字符的 Y 差，可见行数 = 文本区高度 div 行高。
  实测（40 行 TMemo，行高 15）：client 212→14 行、296→19 行、396→26 行，
  与未剥样式位时 EDIT 自己报的 nPage 完全一致。 }
function EditLineHeight(AH: HWND): Integer;
var
  C0, C1, Y0, Y1: Integer;
  Lines: array [0..1, 0..1] of Integer;
  TM    : TTextMetric;
begin
  Result := 0;
  { 必须用“当前可见”的行对来量行高：EM_POSFROMCHAR 对客户区外的字符返回 -1，
    滚动之后再拿第 0/1 行会量出垃圾值，退化成 tmHeight（比真实行高大 1px），
    可见行数随之变化，滑块长度在滚动时就会一跳一跳。 }
  Lines[0, 0] := SendMessage(AH, EM_GETFIRSTVISIBLELINE, 0, 0);
  Lines[0, 1] := Lines[0, 0] + 1;
  Lines[1, 0] := 0;
  Lines[1, 1] := 1;
  for var I := 0 to 1 do
  begin
    C0 := SendMessage(AH, EM_LINEINDEX, Lines[I, 0], 0);
    C1 := SendMessage(AH, EM_LINEINDEX, Lines[I, 1], 0);
    if (C0 < 0) or (C1 <= C0) then Continue;

    var V0 := SendMessage(AH, EM_POSFROMCHAR, C0, 0);
    var V1 := SendMessage(AH, EM_POSFROMCHAR, C1, 0);
    Y0 := Integer(HiWord(V0));
    if Y0 >= $8000 then Dec(Y0, $10000);
    Y1 := Integer(HiWord(V1));
    if Y1 >= $8000 then Dec(Y1, $10000);
    if (Y0 >= 0) and (Y1 > Y0) then
    begin
      Result := Y1 - Y0;
      Break;
    end;
  end;

  if Result <= 0 then
  begin
    var DC := GetDC(AH);
    if DC <> 0 then
    begin
      try
        GetTextMetrics(DC, TM);
        Result := TM.tmHeight;
      finally
        ReleaseDC(AH, DC);
      end;
    end;
  end;
  if Result <= 0 then Result := 1;
end;

{ EDIT 当前能完整显示的行数（几何法，不依赖被冻结的 nPage） }
function EditVisibleLines(AH: HWND): Integer;
var
  ER, CR: TRect;
begin
  FillChar(ER, SizeOf(ER), 0);
  SendMessage(AH, EM_GETRECT, 0, LPARAM(@ER));
  Result := ER.Bottom - ER.Top;
  if Result <= 0 then
  begin
    GetClientRect(AH, CR);
    Result := CR.Bottom - CR.Top;
  end;
  Result := Result div EditLineHeight(AH);
  if Result < 1 then Result := 1;
end;

{ EDIT 剥掉 WS_HSCROLL 之后 GetScrollInfo.nPos 冻结在 0，横向位置只能靠
  “第 0 个字符的客户区 x”反推：未滚动时 x 正好等于 EM_GETRECT.Left，
  向右滚了多少像素，x 就负多少。 }
function EditScrollPosX(AH: HWND): Integer;
var
  ER: TRect;
begin
  Result := 0;
  var CI := SendMessage(AH, EM_LINEINDEX, 0, 0);
  if CI < 0 then Exit;

  var V := SendMessage(AH, EM_POSFROMCHAR, CI, 0);
  var X := Integer(Word(V and $FFFF));
  if X >= $8000 then Dec(X, $10000);
  { 字符完全不可见时 EM_POSFROMCHAR 返回 -1，用 -30000 当哨兵挡掉 }
  if X < -30000 then Exit;
  FillChar(ER, SizeOf(ER), 0);
  SendMessage(AH, EM_GETRECT, 0, LPARAM(@ER));
  Result := ER.Left - X;
  if Result < 0 then Result := 0;
end;

{ TCSBView }

constructor TCSBView.Create(AOwner: TChromeScrollBar; AKind: TCSBKind);
begin
  inherited Create(AOwner);
  FController   := AOwner;
  FKind         := AKind;
  FAlpha        := 255;
  FAlphaTarget  := 255;
  FLastActivity := Now;
  TabStop       := False;
  ControlStyle  := ControlStyle + [csOpaque];
  Visible       := False;
  FHoverArrow   := -1;
  FHoverThumb   := False;
  FArrowPressed := -1;
  FThumbGlow    := 0;
  FArrowGlow[0] := 0;
  FArrowGlow[1] := 0;
  FPinValid     := False;
  FRestoring    := False;
  FActive := False;
  FillChar(FPinRect, SizeOf(FPinRect), 0);
  FRepeatTimer          := TTimer.Create(Self);
  FRepeatTimer.Enabled  := False;
  FRepeatTimer.Interval := 250;
  FRepeatTimer.OnTimer  := RepeatTick;
end;

procedure TCSBView.CreateParams(var Params: TCreateParams);
begin
  inherited CreateParams(Params);
  Params.Style   := Params.Style or WS_CHILD;
  Params.Style   := Params.Style and not(WS_BORDER or WS_THICKFRAME);
  Params.ExStyle := Params.ExStyle or WS_EX_NOACTIVATE;
end;

procedure TCSBView.WMEraseBkgnd(var Message: TWMEraseBkgnd);
begin
  Message.Result := 1;
end;

procedure TCSBView.WMMouseActivate(var Message: TMessage);
begin
  Message.Result := MA_NOACTIVATE;
end;

procedure TCSBView.WMMouseWheel(var Message: TMessage);
var
  Delta: Integer;
begin
  Delta := SmallInt(Message.WPARAM shr 16);
  if Delta = 0 then Exit;

  if FController.InternalHandleWheel(FKind, Delta, (Message.WPARAM and MK_SHIFT) <> 0) then Message.Result := 1;
end;

procedure TCSBView.CMMouseEnter(var Message: TMessage);
begin
  inherited;
  FHover := True;
  DoWake;
end;

procedure TCSBView.CMMouseLeave(var Message: TMessage);
var
  Pt: TPoint;
  R : TRect;
begin
  inherited;
  { 系统会误报 CM_MOUSELEAVE（窗口被重新命中测试、捕获切换等）。光标明明还在视图里
    就不能清高亮，否则贴着箭头 / 滑块时高亮会不断闪一下。这里直接拿屏幕坐标比对
    窗口矩形，不做任何坐标转换，避开 DPI 与父窗口偏移的坑 }
  GetCursorPos(Pt);
  GetWindowRect(Handle, R);
  if PtInRect(R, Pt) then Exit;
  FHover               := False;
  FHoverArrow          := -1;
  FRepeatTimer.Enabled := False;
  FHoverThumb          := False;
  FArrowPressed        := -1;
  Invalidate;
  DoWake;
end;

destructor TCSBView.Destroy;
begin
  { 为什么必须在这里摘指针：
    覆盖层挂在宿主窗体上（Parent = Form），而 Vcl.Controls 的
    TWinControl.Destroy 里有一段
        I := ControlCount;
        while I <> 0 do begin Instance := Controls[I-1]; Remove(Instance);
          Instance.Destroy; I := ControlCount; end;
    也就是窗体析构时会把子控件直接 Destroy 掉。这一步发生在窗体
    DestroyComponents（释放 TChromeScrollBar 等非可视组件）之前，
    所以视图可能先于控制器被销毁。此时控制器里的 FViews[] 还指着这块
    已经释放的内存，之后 Notification(opRemove) 或 Destroy 再走
    DestroyViews 就是二次释放 —— 现象正是调试器里看到的
    TCanvas.Destroy -> TFont.Destroy -> "Invalid pointer operation"。
    哪个先被销毁取决于 Controls 的 Z 序，所以是偶发崩溃。 }
  if FController <> nil then
  begin
    if FController.FViews[FKind] = Self then FController.FViews[FKind] := nil;
    FController := nil;
  end;
  if FRepeatTimer <> nil then FRepeatTimer.Enabled := False;
  inherited Destroy;
end;

procedure TCSBView.ShowWindowNow;
begin
  { 只有控制器要求显示时才真正显示，否则定时器会把隐藏动作撤销 }
  if not FActive then Exit;
  Visible := True;
  ShowWindow(Handle, SW_SHOWNA);
end;

{ 位置只由控制器决定。目标控件（ListBox / EDIT / TScrollBox）滚动内容时会调用
  ScrollWindowEx，它连子窗口一起平移，覆盖层就会跟着上下跳，30ms 后再被搬回来，
  看上去就是滚动条在抖。这里在 WM_WINDOWPOSCHANGING 阶段把坐标钉回 FPinRect。 }
procedure TCSBView.PinTo(const R: TRect);
begin
  FPinRect  := R;
  FPinValid := True;
  if BoundsRect <> R then BoundsRect := R;
end;

procedure TCSBView.WMWindowPosChanging(var Message: TWMWindowPosChanging);
begin
  if FPinValid and (Message.WindowPos <> nil) then
  begin
    Message.WindowPos.X     := FPinRect.Left;
    Message.WindowPos.Y     := FPinRect.Top;
    Message.WindowPos.cx    := FPinRect.Right - FPinRect.Left;
    Message.WindowPos.cy    := FPinRect.Bottom - FPinRect.Top;
    Message.WindowPos.flags := Message.WindowPos.flags and not(SWP_NOMOVE or SWP_NOSIZE);
  end;
  inherited;
end;

{ ScrollWindowEx 移动子窗口时会带 SWP_NOSENDCHANGING，WM_WINDOWPOSCHANGING 根本收不到，
  所以必须在 WM_WINDOWPOSCHANGED 里同步搬回去（同一次调用内完成，不会出现中间帧）。 }
procedure TCSBView.WMWindowPosChanged(var Message: TWMWindowPosChanged);
begin
  inherited;
  if not FPinValid or FRestoring or (Message.WindowPos = nil) then Exit;
  var WP := Message.WindowPos;
  if (WP.X = FPinRect.Left) and (WP.Y = FPinRect.Top) and (WP.cx = FPinRect.Right - FPinRect.Left) and (WP.cy = FPinRect.Bottom - FPinRect.Top) then Exit;
  FRestoring := True;
  try
    SetWindowPos(Handle, 0, FPinRect.Left, FPinRect.Top, FPinRect.Right - FPinRect.Left, FPinRect.Bottom - FPinRect.Top, SWP_NOZORDER or SWP_NOACTIVATE or SWP_NOREDRAW);
  finally
    FRestoring := False;
  end;
end;

procedure TCSBView.EnsurePinned;
var
  WR : TRect;
begin
  if not FPinValid or not HandleAllocated then Exit;
  var ParentHandle := GetParent(Handle);
  if ParentHandle = 0 then Exit;

  if not GetWindowRect(Handle, WR) then Exit;

  MapWindowPoints(0, ParentHandle, WR, 2);
{$IFDEF CSB_TRACE}
  CSBTrace(Format('PIN k=%d valid=%d wr=%d,%d pin=%d,%d', [Ord(FKind), Ord(FPinValid), WR.Left, WR.Top, FPinRect.Left, FPinRect.Top]));
{$ENDIF}
  if (WR.Left = FPinRect.Left) and (WR.Top = FPinRect.Top) then Exit;
  SetWindowPos(Handle, 0, FPinRect.Left, FPinRect.Top, FPinRect.Right - FPinRect.Left, FPinRect.Bottom - FPinRect.Top, SWP_NOZORDER or SWP_NOACTIVATE or SWP_NOREDRAW);
end;

procedure TCSBView.DoWake;
begin
  FAlphaTarget  := 255;
  FLastActivity := Now;
  if FActive and not Visible then ShowWindowNow;
  { 静止时定时器在 250ms 心跳上，这里必须立刻拉回 30ms，否则淡入会一格一格跳 }
  if FController <> nil then FController.WakeTimer;
end;

procedure TCSBView.DoTick;
var
  OldAlpha : Integer;
  Target   : Integer;
  Pt       : TPoint;
  R        : TRect;
begin
  { 控制器判定当前不需要滚动条：彻底安静，不要再把自己显示出来 }
  if not FActive then
  begin
    if Visible then Visible := False;
    Exit;
  end;

  if not FController.FAutoHide or FHover or FDragging then
    FAlphaTarget := 255
  else if (FAlphaTarget = 255) and (MilliSecondsBetween(Now, FLastActivity) > FController.FAutoHideDelay) then
    FAlphaTarget := 0;

  OldAlpha := FAlpha;
  if FAlpha < FAlphaTarget then
    FAlpha := Min(FAlpha + 51, FAlphaTarget)
  else if FAlpha > FAlphaTarget then
    FAlpha := Max(FAlpha - 51, FAlphaTarget);

  { 每帧用真实光标位置校验一次：控制取得捕获时光标可以在窗口外，
    其余情况下光标不在视图里就应该立刻清高亮，不依赖消息是否可靠。
    只有确实存在高亮态时才值得做这次校验——否则每帧白跑 GetCursorPos + GetWindowRect。 }
  if ((FHoverArrow >= 0) or FHoverThumb or (FArrowPressed >= 0) or FDragging)
    and (GetCapture <> Handle) then
  begin
    GetCursorPos(Pt);
    GetWindowRect(Handle, R);
    if not PtInRect(R, Pt) then
    begin
      FHoverArrow   := -1;
      FHoverThumb   := False;
      FArrowPressed := -1;
    end;
  end;

  { 三态高亮平滑过渡：一步最多走 64，约 4 帧（120ms）到位 }
  var NeedPaint := False;
  { 鼠标在箭头之外松开、或系统收走了捕获时，别让“按下”态卡住 }
  if (FArrowPressed >= 0) and (GetCapture <> Handle) then FArrowPressed := -1;

  if FDragging then
    Target := 255
  else if FHoverThumb then
    Target := 128
  else
    Target := 0;

  if FThumbGlow <> Target then
  begin
    if FThumbGlow < Target then
      FThumbGlow := Min(FThumbGlow + 64, Target)
    else
      FThumbGlow := Max(FThumbGlow - 64, Target);
    NeedPaint := True;
  end;

  for var I := 0 to 1 do
  begin
    if FArrowPressed = I then
      Target := 255
    else if FHoverArrow = I then
      Target := 128
    else
      Target := 0;
    if FArrowGlow[I] <> Target then
    begin
      if FArrowGlow[I] < Target then
        FArrowGlow[I] := Min(FArrowGlow[I] + 64, Target)
      else
        FArrowGlow[I] := Max(FArrowGlow[I] - 64, Target);
      NeedPaint := True;
    end;
  end;

  if (FAlpha = 0) and (FAlphaTarget = 0) then Exit;

  if not Visible then ShowWindowNow;
  if (FAlpha <> OldAlpha) or NeedPaint then Invalidate;
end;

{ 本视图此刻是否「需要按 30ms 持续跑」。
  判据是"目标值与当前值不一致"，而不是"鼠标在上面"——鼠标停在滑块上、高亮
  已经插值到位时根本没有任何动画可做，这时必须放行停机；否则光标一停到滚动条
  上，CPU 立刻又回到满载（实测 0.08% -> 7.9%）。 }
function TCSBView.IsBusy: Boolean;
var
  I, T: Integer;
begin
  Result := False;
  if not FActive or (FController = nil) then Exit;
  { 正在淡入 / 淡出 }
  if FAlpha <> FAlphaTarget then Exit(True);
  { 长按重复滚动进行中 }
  if (FRepeatTimer <> nil) and FRepeatTimer.Enabled then Exit(True);
  { 滑块三态插值未到位 }
  if FDragging then
    T := 255
  else if FHoverThumb then
    T := 128
  else
    T := 0;
  if FThumbGlow <> T then Exit(True);
  { 两个箭头三态插值未到位 }
  for I := 0 to 1 do
  begin
    if FArrowPressed = I then
      T := 255
    else if FHoverArrow = I then
      T := 128
    else
      T := 0;
    if FArrowGlow[I] <> T then Exit(True);
  end;
  { 条还亮着、开着自动隐藏、且指针不在上面：要按 30ms 数着 AutoHideDelay 才能准点淡出 }
  if FController.FAutoHide and (FAlpha > 0) and not FHover and not FDragging then Exit(True);
end;

function TCSBView.GetArrowSize: Integer;
begin
  var Full := IfThen(FKind = csbVertical, Height, Width);
  Result   := Max(12, FController.FBarSize + 6);
  Result   := Min(Result, Full div 3);
  Result   := Max(1, Result);
end;

procedure TCSBView.GetArrowRects(out AFirst, ASecond: TRect);
begin
  var ArrowSize := GetArrowSize;
  if FKind = csbVertical then
  begin
    AFirst  := Rect(0, 0, Width, ArrowSize);
    ASecond := Rect(0, Max(0, Height - ArrowSize), Width, Height);
  end
  else
  begin
    AFirst  := Rect(0, 0, ArrowSize, Height);
    ASecond := Rect(Max(0, Width - ArrowSize), 0, Width, Height);
  end;
end;

function TCSBView.ArrowIndexAt(X, Y: Integer): Integer;
var
  FirstRect, SecondRect: TRect;
begin
  Result := -1;
  if (X < 0) or (Y < 0) or (X >= Width) or (Y >= Height) then Exit;

  GetArrowRects(FirstRect, SecondRect);
  if PtInRect(FirstRect, Point(X, Y)) then
    Result := 0
  else if PtInRect(SecondRect, Point(X, Y)) then
    Result := 1;
end;

procedure TCSBView.DrawArrow(ACanvas: TCanvas; ARect: TRect; AFirst: Boolean; AActive: Boolean; AColor: TColor);
var
  S : Integer;
  P : array [0 .. 2] of TPoint;
begin
  if IsRectEmpty(ARect) then Exit;

  var MX              := (ARect.Left + ARect.Right) div 2;
  var MY              := (ARect.Top + ARect.Bottom) div 2;
  S                   := Min((ARect.Right - ARect.Left) div 2 - 1, (ARect.Bottom - ARect.Top) div 2 - 1);
  S                   := Max(1, S);
  ACanvas.Brush.Style := bsSolid;
  ACanvas.Brush.Color := AColor;
  ACanvas.Pen.Style   := psClear;
  if FKind = csbVertical then
  begin
    if AFirst then
    begin
      P[0] := Point(MX, MY - S);
      P[1] := Point(MX - S, MY + S);
      P[2] := Point(MX + S, MY + S);
    end
    else
    begin
      P[0] := Point(MX, MY + S);
      P[1] := Point(MX - S, MY - S);
      P[2] := Point(MX + S, MY - S);
    end;
  end
  else
  begin
    if AFirst then
    begin
      P[0] := Point(MX - S, MY);
      P[1] := Point(MX + S, MY - S);
      P[2] := Point(MX + S, MY + S);
    end
    else
    begin
      P[0] := Point(MX + S, MY);
      P[1] := Point(MX - S, MY - S);
      P[2] := Point(MX - S, MY + S);
    end;
  end;
  ACanvas.Polygon(P);
  ACanvas.Pen.Style := psSolid;
end;

procedure TCSBView.RepeatTick(Sender: TObject);
begin
  FRepeatTimer.Interval := 60;
  FController.ApplyScroll(FKind, FRepeatCode, FPosition);
end;

function TCSBView.GetTrackLength: Integer;
begin
  var Arrow := GetArrowSize;
  Result    := IfThen(FKind = csbVertical, Max(1, Height - 2 * Arrow), Max(1, Width - 2 * Arrow));
end;

function TCSBView.GetThumbLength: Integer;
begin
  var Track := GetTrackLength;
  Result    := Track * Max(1, FPageSize) div Max(1, FMaxPos + FPageSize);
  Result    := Max(16, Result);
  Result    := Min(Result, Track - 4);
  if Result < 8 then Result := Track;
end;

function TCSBView.GetThumbRect: TRect;
var
  ThumbLen, Avail, Offset, Side, Margin: Integer;
begin
  Result   := ClientRect;
  Margin   := 2;
  ThumbLen := GetThumbLength;
  Avail    := GetTrackLength - ThumbLen - Margin * 2;
  if Avail < 0 then Avail := 0;
  if FMaxPos <= 0 then
    Offset := 0
  else
    { 防御性钳制：FPosition 理论上已由 UpdateView 钳过，这里再保一次，避免任何调用路径把滑块推到轨道外面 }
    Offset := Round(Min(FPosition, FMaxPos) / FMaxPos * Avail);

  if FKind = csbVertical then
  begin
    Side          := Max(0, (Width - FController.FBarSize) div 2);
    Result.Left   := Min(Side, Width - 1);
    Result.Right  := Min(Result.Left + FController.FBarSize, Width);
    Result.Top    := GetArrowSize + Margin + Offset;
    Result.Bottom := Min(Result.Top + ThumbLen, Height);
    Result.Top    := Max(0, Result.Top);
  end
  else
  begin
    Side          := Max(0, (Height - FController.FBarSize) div 2);
    Result.Top    := Min(Side, Height - 1);
    Result.Bottom := Min(Result.Top + FController.FBarSize, Height);
    Result.Left   := GetArrowSize + Margin + Offset;
    Result.Right  := Min(Result.Left + ThumbLen, Width);
    Result.Left   := Max(0, Result.Left);
  end;
end;

function TCSBView.TrackPosFromPoint(X, Y: Integer): Integer;
var
  ThumbLen, Avail, Coord, Margin: Integer;
begin
  Margin   := 2;
  ThumbLen := GetThumbLength;
  Avail    := GetTrackLength - ThumbLen - Margin * 2;
  if Avail <= 0 then Exit(0);
  
  if FKind = csbVertical then
    Coord := Y - GetArrowSize - Margin - FDragOffset
  else
    Coord := X - GetArrowSize - Margin - FDragOffset;
  Result  := Round(Coord / Avail * FMaxPos);
  Result  := Max(0, Min(Result, FMaxPos));
end;

procedure TCSBView.Paint;
begin
  try
    DoPaint;
  except
  end;
end;

procedure TCSBView.DoPaint;
var
  Thumb, FirstRect, SecondRect, DrawThumb: TRect;
  ThumbColorValue, TrackColorValue       : TColor;
  Radius, Grow, Side, ThumbW             : Integer;
  Region                                 : HRGN;
begin
  TrackColorValue    := FTrackColorValue;
  Canvas.Brush.Style := bsSolid;
  Canvas.Brush.Color := TrackColorValue;
  Canvas.FillRect(ClientRect);

  if FAlpha <= 0 then Exit;
  Thumb := GetThumbRect;
  if IsRectEmpty(Thumb) then Exit;

  { 悬停 / 拖动时滑块加宽：细条在指针靠近时变粗，是 Chrome 的招牌手感 }
  DrawThumb := Thumb;
  Grow      := FThumbGlow * 4 div 255;
  if FKind = csbVertical then
  begin
    ThumbW := Min(Width, FController.FBarSize + Grow);
    Side   := (Width - ThumbW) div 2;
    DrawThumb.Left  := Side;
    DrawThumb.Right := Side + ThumbW;
  end
  else
  begin
    ThumbW := Min(Height, FController.FBarSize + Grow);
    Side   := (Height - ThumbW) div 2;
    DrawThumb.Top    := Side;
    DrawThumb.Bottom := Side + ThumbW;
  end;

  { 滑块颜色：正常 -> 悬停 -> 按下 两段插值 }
  if FThumbGlow <= 128 then
    ThumbColorValue := BlendColor(FController.FThumbColor, FController.FThumbHoverColor, FThumbGlow * 2)
  else
    ThumbColorValue := BlendColor(FController.FThumbHoverColor, FController.FThumbPressedColor, (FThumbGlow - 128) * 2);
  ThumbColorValue := BlendColor(TrackColorValue, ThumbColorValue, FAlpha);

  Radius := Min(6, Min(FController.FBarSize, GetTrackLength) div 2);
  Radius := Max(2, Radius);
  Region := CreateRoundRectRgn(DrawThumb.Left, DrawThumb.Top, DrawThumb.Right + 1, DrawThumb.Bottom + 1, Radius * 2, Radius * 2);
  try
    Canvas.Brush.Color := ThumbColorValue;
    FillRgn(Canvas.Handle, Region, Canvas.Brush.Handle);
  finally
    DeleteObject(Region);
  end;

  GetArrowRects(FirstRect, SecondRect);
  DrawArrowButton(FirstRect, 0, True);
  DrawArrowButton(SecondRect, 1, False);
end;

{ 箭头三态：底下一层圆角高亮背景 + 上面的三角，两者都随 FArrowGlow 平滑变化 }
procedure TCSBView.DrawArrowButton(const ARect: TRect; AIndex: Integer; AFirst: Boolean);
var
  Glow, BgAlpha          : Integer;
  BgColor, ArrowColor, Base: TColor;
  R                      : TRect;
  Region                 : HRGN;
begin
  if IsRectEmpty(ARect) then Exit;
  Glow := FArrowGlow[AIndex];

  if (Glow > 0) and (FAlpha > 0) then
  begin
    R := ARect;
    InflateRect(R, -1, -1);
    if (R.Right - R.Left > 4) and (R.Bottom - R.Top > 4) then
    begin
      BgAlpha := Glow * 70 div 255;
      BgColor := BlendColor(FTrackColorValue, FController.FThumbHoverColor, BgAlpha);
      BgColor := BlendColor(FTrackColorValue, BgColor, FAlpha);
      Region  := CreateRoundRectRgn(R.Left, R.Top, R.Right + 1, R.Bottom + 1, 6, 6);
      try
        Canvas.Brush.Style := bsSolid;
        Canvas.Brush.Color := BgColor;
        FillRgn(Canvas.Handle, Region, Canvas.Brush.Handle);
      finally
        DeleteObject(Region);
      end;
    end;
  end;

  { 正常时偏暗，悬停提亮，按下最亮 }
  Base := BlendColor(FTrackColorValue, FController.FThumbHoverColor, 170);
  if Glow <= 128 then
    ArrowColor := BlendColor(Base, FController.FThumbHoverColor, Glow * 2)
  else
    ArrowColor := BlendColor(FController.FThumbHoverColor, FController.FThumbPressedColor, (Glow - 128) * 2);
  ArrowColor := BlendColor(FTrackColorValue, ArrowColor, FAlpha);

  DrawArrow(Canvas, ARect, AFirst, Glow > 0, ArrowColor);
end;

procedure TCSBView.MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
var
  Thumb   : TRect;
  Code    : Word;
  ArrowIdx: Integer;
begin
  inherited MouseDown(Button, Shift, X, Y);
  if Button <> mbLeft then Exit;
  DoWake;
  FController.RefreshViewState(FKind);
  Thumb    := GetThumbRect;
  ArrowIdx := ArrowIndexAt(X, Y);
  if ArrowIdx >= 0 then
  begin
    if ArrowIdx = 0 then
      FRepeatCode := SB_LINEUP
    else
      FRepeatCode := SB_LINEDOWN;
    FController.ApplyScroll(FKind, FRepeatCode, FPosition);
    FRepeatTimer.Interval := 250;
    FRepeatTimer.Enabled  := True;
    FHoverArrow           := ArrowIdx;
    FArrowPressed        := ArrowIdx;
    SetCapture(Handle);
    Invalidate;
    Exit;
  end;
  if PtInRect(Thumb, Point(X, Y)) then
  begin
    FDragging := True;
    if FKind = csbVertical then
      FDragOffset := Y - Thumb.Top
    else
      FDragOffset := X - Thumb.Left;
    SetCapture(Handle);
  end
  else
  begin
    if FKind = csbVertical then
    begin
      if Y < Thumb.Top then
        Code := SB_PAGEUP
      else
        Code := SB_PAGEDOWN;
    end
    else
    begin
      if X < Thumb.Left then
        Code := SB_PAGEUP
      else
        Code := SB_PAGEDOWN;
    end;
    FController.ApplyScroll(FKind, Code, FPosition);
  end;
  Invalidate;
end;

procedure TCSBView.MouseMove(Shift: TShiftState; X, Y: Integer);
var
  NewPos  : Integer;
  NewArrow: Integer;
  NewThumb: Boolean;
begin
  inherited MouseMove(Shift, X, Y);
  if FDragging then
  begin
    NewPos := TrackPosFromPoint(X, Y);
    FController.ApplyScroll(FKind, SB_THUMBTRACK, NewPos);
    FPosition := NewPos;
    Exit;
  end;
  { 箭头和滑块分开判定：只有指针真在滑块上才让滑块高亮，
    在轨道空白处不该跟着变色 }
  NewArrow := ArrowIndexAt(X, Y);
  NewThumb := (NewArrow < 0) and PtInRect(GetThumbRect, Point(X, Y));
  if (NewArrow <> FHoverArrow) or (NewThumb <> FHoverThumb) then
  begin
    FHoverArrow := NewArrow;
    FHoverThumb := NewThumb;
    Invalidate;
  end;
  DoWake;
end;

procedure TCSBView.MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  FRepeatTimer.Enabled := False;
  FArrowPressed := -1;
  if GetCapture = Handle then
    ReleaseCapture;
  if FDragging then
  begin
    FDragging := False;
    FController.ApplyScroll(FKind, SB_THUMBPOSITION, FPosition);
    FPosition := FController.ViewPosition(FKind);
  end;
  inherited MouseUp(Button, Shift, X, Y);
  DoWake;
  Invalidate;
end;

{ TChromeScrollBar }

constructor TChromeScrollBar.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FEnabled           := True;
  FAutoHide          := True;
  FAutoHideDelay     := 1200;
  FBarSize           := 8;
  FTransparentTrack  := True;
  FHideNative        := True;
  FWheelScroll       := True;
  FHookedHandle      := 0;
  FStyleHandle       := 0;
  FHookedParent      := 0;
  FHookedParentCtl   := nil;
  FPrevParentResize  := nil;
  FInParentHook      := False;
  FTrackColor        := RGB(32, 33, 36);
  FThumbColor        := RGB(95, 99, 104);
  FThumbHoverColor   := RGB(154, 160, 166);
  FThumbPressedColor := RGB(205, 208, 211);
  if ActiveControllers = nil then ActiveControllers := TList.Create;
  if ActiveControllers.IndexOf(Self) < 0 then ActiveControllers.Add(Self);
  if GlobalWheelHook = 0 then GlobalWheelHook := SetWindowsHookEx(WH_GETMESSAGE, @CSBGlobalWheelHook, 0, GetCurrentThreadId);
  FTimer            := TTimer.Create(Self);
  FTimer.Interval   := CSB_BUSY_INTERVAL;
  FTimer.Enabled    := True;
  FTimer.OnTimer    := TimerTick;
  FLastEventPos[csbVertical]   := -1;
  FLastEventPos[csbHorizontal] := -1;
end;

destructor TChromeScrollBar.Destroy;
begin
  { 先断事件再拆东西：Destroy 过程中 WM_SIZE / WM_DESTROY 还会进来，
    只要事件指针还挂着，就可能回调到正在析构的宿主窗体上。 }
  FOnScroll := nil;
  FOnWheel  := nil;
  FEnabled  := False;
  try
    FTimer.Enabled := False;
    if ActiveControllers <> nil then ActiveControllers.Remove(Self);
    if (ActiveControllers <> nil) and (ActiveControllers.Count = 0) then
    begin
      if GlobalWheelHook <> 0 then
      begin
        UnhookWindowsHookEx(GlobalWheelHook);
        GlobalWheelHook := 0;
      end;
      FreeAndNil(ActiveControllers);
    end;
    RemoveSubclass;
    DestroyViews;
  except
  end;
  inherited Destroy;
end;

procedure Register;
begin
  RegisterComponents('Chrome UI', [TChromeScrollBar]);
end;

procedure TChromeScrollBar.Notification(AComponent: TComponent; Operation: TOperation);
begin
  try
    if (AComponent = FTarget) and (Operation = opRemove) then
    begin
      RemoveSubclass;
      FStyleHandle := 0;
      FTarget      := nil;
      DestroyViews;
    end
    else if (AComponent = FHookedParentCtl) and (Operation = opRemove) then
    begin
      { 父控件先被释放了，这时不能再去碰它的 OnResize，直接把钩子忘掉。
        否则留着的是个悬空指针，本组件销毁时会踩到已释放的内存。 }
      if FHookedParent <> 0 then
      begin
        if IsWindow(FHookedParent) then
          CSBRemoveWindowSubclass(FHookedParent, @CSBParentSubclassProc, CSBParentSubclassId);
        FHookedParent := 0;
      end;
      FHookedParentCtl  := nil;
      FPrevParentResize := nil;
    end;
  except
  end;
  inherited Notification(AComponent, Operation);
end;

procedure TChromeScrollBar.Loaded;
begin
  inherited Loaded;
  { 抢在窗体第一次显示之前把目标控件的句柄建出来、挂上子类化。
    这一步只建句柄，**不剥样式位**：此刻控件还没拿到内容（Demo 里 AddContent
    在 FormCreate 里，比 Loaded 晚），提前剥掉会让 EDIT 干脆不建立自己的滚动
    范围 —— GetScrollInfo 的 nMax 一直是 0，横向滚动条从此再也不出现。
    真正的剥离交给 WM_NCCALCSIZE / WM_NCPAINT：它们同样发生在第一帧绘制之前
    （不闪），但已经在内容就绪之后（nMax 是对的）。 }
  if (FTarget <> nil) and FHideNative and (FTarget.Parent <> nil) then
  begin
    if not FTarget.HandleAllocated then FTarget.HandleNeeded;
    if FTarget.HandleAllocated then EnsureSubclass;
  end;
  FNeedsRefresh := True;
  Refresh;
end;

procedure TChromeScrollBar.SetTarget(AValue: TWinControl);
begin
  if AValue = FTarget then Exit;
  RemoveSubclass;
  FStyleHandle := 0;
  DestroyViews;
  if FTarget <> nil then FTarget.RemoveFreeNotification(Self);
  FTarget         := AValue;
  FEditClassKnown := False;
  FEditClass      := False;
  if FTarget <> nil then
  begin
    FTarget.FreeNotification(Self);
    UpdateEditClass;
    { 代码里创建的组件不会走 Loaded（那个是 DFM 流化专用的），早期准备必须在这里
      补一遍，否则子类化要等到第一次定时器 tick（目标已经画过一帧）才装上，
      原生滚动条在那一帧就被画出来了 —— 肉眼就是启动时闪一下。
      这里**只建句柄 + 挂子类化，不剥样式位**：剥样式位会让还没内容的 EDIT
      干脆不建立横向滚动范围（nMax 恒为 0），横向条从此不出现。
      剥离交给子类化里的 WM_NCPAINT：装上之后第一帧就会剥 + 顺手擦掉已经画上去的
      那一条，屏幕上不会留下任何痕迹。 }
    if FHideNative and (FTarget.Parent <> nil) then
    begin
      if not FTarget.HandleAllocated then FTarget.HandleNeeded;
      if FTarget.HandleAllocated then EnsureSubclass;
    end;
    Refresh;
  end;
end;

{ 缓存目标是否为 EDIT / RICHEDIT 系列（这类控件隐藏原生条后
  GetScrollInfo 的 nPos 会冻结，必须改用 EM_GETFIRSTVISIBLELINE）。 }
procedure TChromeScrollBar.UpdateEditClass;
begin
  FEditClass      := False;
  FNoEraseBkgnd   := False;
  if (FTarget = nil) or not FTarget.HandleAllocated then Exit;
  FEditClassKnown := True;
  { 首选 VCL 类型判断：TEdit / TMemo / TRichEdit 全是 TCustomEdit 的后代。
    不要用 RealGetWindowClass 识别窗口类名 —— 实测同一个 TMemo 在不同宿主里
    返回的类名并不一致（独立探针返回 'Edit'，VCL 窗体里返回 'TMemo'），
    一旦判不出来，位置就只能读到被冻结的 GetScrollInfo.nPos（恒为 0），
    表现就是滑块永远贴在顶端不跟随滚动。 }
  if FTarget is TCustomEdit then
  begin
    FEditClass    := True;
    FNoEraseBkgnd := True;
  end
  else if FTarget is TCustomListBox then
    FNoEraseBkgnd := True;
  ApplySmoothPaint;
end;

{ EDIT / LISTBOX 换焦点时会整块重画：LISTBOX 先擦背景再重画，EDIT 直接在
  WM_PAINT 里自己铺底，中间那半帧空白就是肉眼看到的"闪"。两招一起上：
  - WM_ERASEBKGND 由子类化回调认领返回 1，LISTBOX 不再整块擦白；
  - EDIT 加 WS_EX_COMPOSITED，Windows 离屏合成后一次贴上，看不到中间态。
  只对这两类控件生效，其它控件保持原生行为（TScrollBox 等不能动，否则
  子控件移动时会留残影）。 }
procedure TChromeScrollBar.ApplySmoothPaint;
var
  Ex: NativeInt;
begin
  if not FNoEraseBkgnd then Exit;
  if (FTarget = nil) or not FTarget.HandleAllocated then Exit;
  Ex := GetWindowLongPtr(FTarget.Handle, GWL_EXSTYLE);
  if (Ex and WS_EX_COMPOSITED) = 0 then
    SetWindowLongPtr(FTarget.Handle, GWL_EXSTYLE, Ex or WS_EX_COMPOSITED);
end;

{ 隐藏原生滚动条：直接剥掉 WS_VSCROLL / WS_HSCROLL 样式位，并子类化目标窗口，
  让它在每次重算非客户区（WM_NCCALCSIZE）时再剥一次。
  为什么不能只调用 ShowScrollBar(False)：
  TListBox 每收到一次 WM_VSCROLL 就把 WS_VSCROLL 加回来，客户区随之在
  239 / 256 之间来回跳，于是原生条与自绘条交替闪现。
  剥样式位不影响滚动引擎：GetScrollInfo 的 pos / max / page 与 WM_VSCROLL
  都照常工作（EDIT 的 nPos 依旧冻结，仍用 EM_GETFIRSTVISIBLELINE 读取）。 }
procedure TChromeScrollBar.HideNativeBar(AKind: TCSBKind);
var
  H              : HWND;
  Style, NewStyle: NativeInt;
begin
  if not FHideNative then Exit;
  if (FTarget = nil) or not FTarget.HandleAllocated then Exit;
  EnsureSubclass;
  H := FTarget.Handle;
  if FStyleHandle = H then Exit; { 该句柄已处理过，后续由子类化回调持续维持 }
  
  Style    := GetWindowLongPtr(H, GWL_STYLE);
  NewStyle := Style and not NativeInt(WS_VSCROLL or WS_HSCROLL);
  if NewStyle <> Style then SetWindowLongPtr(H, GWL_STYLE, NewStyle);
  FStyleHandle := H;
  { 强制重算一次非客户区，让客户区立刻铺满整个窗口 }
  SetWindowPos(H, 0, 0, 0, 0, 0, SWP_NOMOVE or SWP_NOSIZE or SWP_NOZORDER or SWP_NOACTIVATE or SWP_FRAMECHANGED);
end;

{ 子类化目标窗口，句柄变化（RecreateWnd）时自动重挂 }
procedure TChromeScrollBar.EnsureSubclass;
var
  H: HWND;
begin
  if FTarget = nil then Exit;
  { 先挂好父窗口的子类化：目标控件的窗口可能在接下来被重建 }
  EnsureParentHook;
  if not FTarget.HandleAllocated then Exit;
  H := FTarget.Handle;
  if FHookedHandle = H then Exit;
  if FHookedHandle <> 0 then
  begin
    if IsWindow(FHookedHandle) then CSBRemoveWindowSubclass(FHookedHandle, @CSBSubclassProc, CSBSubclassId);
    FHookedHandle := 0;
  end;
  FStyleHandle := 0;
  if CSBSetWindowSubclass(H, @CSBSubclassProc, CSBSubclassId, DWORD_PTR(Self)) then FHookedHandle := H;
  ApplySmoothPaint;
end;

procedure TChromeScrollBar.RemoveSubclass;
begin
  RemoveParentHook;
  if FHookedHandle = 0 then Exit;
  if IsWindow(FHookedHandle) then CSBRemoveWindowSubclass(FHookedHandle, @CSBSubclassProc, CSBSubclassId);
  FHookedHandle := 0;
end;

{ 在目标控件的父窗口（通常是 Form）上挂子类化。
  目标控件的父窗口换了、或者 Form 的窗口被重建了，就跟着重新挂上。 }
procedure TChromeScrollBar.EnsureParentHook;
var
  P : HWND;
  PC: TWinControl;
begin
  if FTarget = nil then Exit;
  PC := FTarget.Parent;
  { 先挂 OnResize：父控件换了就把钩子挪过去。
    OnResize 是 VCL 层属性，父窗口被重建也不会丢。 }
  if PC <> FHookedParentCtl then
  begin
    RemoveParentHook;
    if PC <> nil then
    begin
      FHookedParentCtl  := PC;
      FPrevParentResize := TWinControlAccess(PC).OnResize;
      TWinControlAccess(PC).OnResize := ParentResized;
      PC.FreeNotification(Self);
    end;
  end;
  if (PC = nil) or not PC.HandleAllocated then Exit;
  P := PC.Handle;
  if P = FHookedParent then Exit;
  if FHookedParent <> 0 then
  begin
    if IsWindow(FHookedParent) then
      CSBRemoveWindowSubclass(FHookedParent, @CSBParentSubclassProc, CSBParentSubclassId);
    FHookedParent := 0;
  end;
  if CSBSetWindowSubclass(P, @CSBParentSubclassProc, CSBParentSubclassId, DWORD_PTR(Self)) then
    FHookedParent := P;
end;

procedure TChromeScrollBar.RemoveParentHook;
var
  M : TMethod;
  Me: TNotifyEvent;
begin
  if FHookedParent <> 0 then
  begin
    if IsWindow(FHookedParent) then
      CSBRemoveWindowSubclass(FHookedParent, @CSBParentSubclassProc, CSBParentSubclassId);
    FHookedParent := 0;
  end;
  if FHookedParentCtl <> nil then
  begin
    M  := TMethod(TWinControlAccess(FHookedParentCtl).OnResize);
    Me := ParentResized;
    if (not (csDestroying in FHookedParentCtl.ComponentState)) and
       (M.Code = TMethod(Me).Code) and (M.Data = TMethod(Me).Data) then
      TWinControlAccess(FHookedParentCtl).OnResize := FPrevParentResize;
    FHookedParentCtl.RemoveFreeNotification(Self);
    FHookedParentCtl  := nil;
    FPrevParentResize := nil;
  end;
end;

{ 父窗口有动静了：目标控件的窗口被重建了就重装子类化。
  EnsureSubclass 内部会判断 handle 是否变化，重复调用是廉价的、可重入安全的。 }
procedure TChromeScrollBar.ParentSawActivity;
begin
  if FInParentHook then Exit;
  if (FTarget = nil) or (csDestroying in ComponentState) then Exit;
  FInParentHook := True;
  try
    if FTarget.HandleAllocated and (FTarget.Handle <> FHookedHandle) then
      EnsureSubclass;
    { 重装之后顺手把样式位也剥一次：此刻可能还是不可见状态，Refresh 会被
      DoRefresh 的可见性闸门挡回去，但样式位必须赶在显示之前就干净。 }
    if FHideNative and FTarget.HandleAllocated then
    begin
      HideNativeBar(csbVertical);
      HideNativeBar(csbHorizontal);
    end;
  finally
    FInParentHook := False;
  end;
end;

{ 子窗口被销毁了（Windows 可能把刚释放的 HWND 值再分配出去）。
  此时 FHookedHandle 还存着旧值，但 SetWindowSubclass 已经随窗口没了。
  这里把它清掉，保证重建之后能重新装上。 }
procedure TChromeScrollBar.ParentChildDestroyed(AChild: HWND);
begin
  if (AChild <> 0) and (AChild = FHookedHandle) then
  begin
    FHookedHandle := 0;
    FStyleHandle  := 0;
  end;
end;

{ 父窗口尺寸变了：在窗口显示之前把可能被重建的目标控件重装子类化。
  DLL / 动态加载窗体尤其需要这一条：Form 的窗口在 TForm.Create 期间被创建、
  Create 结束时 VCL 会重建它，重建后的新窗口没有子类化。这时回到 OnResize
  重新装上——宿主一定是先 SetWindowPos 再 Show 的。 }
procedure TChromeScrollBar.ParentResized(Sender: TObject);
begin
  if Assigned(FPrevParentResize) then FPrevParentResize(Sender);
  if FTarget = nil then Exit;
  ParentSawActivity;
  { 此时一般已经能读到新的范围了，顺手把视图算一遍，不必等下一次 tick }
  Refresh;
end;

{ 只剥样式位，不触发重算（在 WM_NCCALCSIZE / WM_NCPAINT 内部调用，
  此处不能再 SetWindowPos）。返回 True 表示这次确实剥掉了东西。 }
function TChromeScrollBar.StripNativeStyle: Boolean;
var
  H              : HWND;
  Style, NewStyle: NativeInt;
begin
  Result := False;
  if not FHideNative then Exit;
  if (FTarget = nil) or not FTarget.HandleAllocated then Exit;

  H        := FTarget.Handle;
  Style    := GetWindowLongPtr(H, GWL_STYLE);
  NewStyle := Style and not NativeInt(WS_VSCROLL or WS_HSCROLL);
  if NewStyle <> Style then
  begin
    SetWindowLongPtr(H, GWL_STYLE, NewStyle);
    Result := True;
  end;
end;

{ 把「原生滚动条本来占的那一溜」用控件自己的底色盖回去。
  为什么非要补这一下：ShowScrollBar 内部是「先用类背景刷擦非客户区、再发
  WM_NCPAINT」。擦的时候它还以为有滚动条，于是把右边 17px 刷成了 COLOR_WINDOW
  （白色）；等 WM_NCPAINT 进来，样式位已经被我们剥掉，默认处理只画一圈边框、
  画不出箭头和滑块，那条白底就留在屏幕上了 —— 这就是启动时看到的那一闪。
  它也不会自己消失，得等下一次真正重算非客户区（SWP_FRAMECHANGED）才被清掉，
  实测要 200ms 以上。自绘覆盖层只有 8px，盖不住 17px，所以自己刷。
  最外圈 1px 让给边框：滚动条矩形本来就在边框以内，刷到边框上会把焦点框擦掉。 }
procedure TChromeScrollBar.PaintOverNativeStrips;
var
  DC         : HDC;
  WR, R      : TRect;
  Brush      : HBRUSH;
  CX, CY     : Integer;
begin
  if (FTarget = nil) or not FTarget.HandleAllocated then Exit;
  if not GetWindowRect(FTarget.Handle, WR) then Exit;
  OffsetRect(WR, -WR.Left, -WR.Top);
  if (WR.Right <= 2) or (WR.Bottom <= 2) then Exit;

  DC := GetWindowDC(FTarget.Handle);
  if DC = 0 then Exit;
  Brush := CreateSolidBrush(ColorToRGB(TControlAccess(FTarget).Color));
  if Brush = 0 then
  begin
    ReleaseDC(FTarget.Handle, DC);
    Exit;
  end;
  try
    CX := GetSystemMetrics(SM_CXVSCROLL);
    CY := GetSystemMetrics(SM_CYHSCROLL);
    { 右侧那一条（垂直滚动条）。左边多留 3px：实测系统擦的那一条比
      SM_CXVSCROLL 宽 1~2px，正好卡在边上会剩一道 2px 的亮边。多刷出去的
      几个像素本来就是控件自己的底色，看不出来，随后 WM_PAINT 会重画正文。 }
    R := Rect(WR.Right - CX - 3, WR.Top + 1, WR.Right - 1, WR.Bottom - 1);
    if (R.Right > R.Left) and (R.Bottom > R.Top) then FillRect(DC, R, Brush);
    { 底部那一条（水平滚动条） }
    R := Rect(WR.Left + 1, WR.Bottom - CY - 3, WR.Right - 1, WR.Bottom - 1);
    if (R.Right > R.Left) and (R.Bottom > R.Top) then FillRect(DC, R, Brush);
  finally
    DeleteObject(Brush);
    ReleaseDC(FTarget.Handle, DC);
  end;
end;

procedure TChromeScrollBar.SetHideNative(AValue: Boolean);
var
  K: TCSBKind;
begin
  if FHideNative = AValue then Exit;
  
  FHideNative := AValue;
  if (FTarget <> nil) and FTarget.HandleAllocated then
  begin
    if FHideNative then
      HideNativeBar(csbVertical)
    else
    begin
      { 交还原生条：摘钩子、恢复样式位、重算非客户区 }
      RemoveSubclass;
      FStyleHandle := 0;
      for K        := csbVertical to csbHorizontal do
        if K = csbVertical then
          ShowScrollBar(FTarget.Handle, SB_VERT, True)
        else
          ShowScrollBar(FTarget.Handle, SB_HORZ, True);
      SetWindowPos(FTarget.Handle, 0, 0, 0, 0, 0, SWP_NOMOVE or SWP_NOSIZE or SWP_NOZORDER or SWP_NOACTIVATE or SWP_FRAMECHANGED);
    end;
  end;
  FBarOffset[csbVertical]   := Rect(0, 0, 0, 0);
  FBarOffset[csbHorizontal] := Rect(0, 0, 0, 0);
  Refresh;
end;

procedure TChromeScrollBar.DestroyViews;
var
  K: TCSBKind;
  V: TCSBView;
begin
  for K := csbVertical to csbHorizontal do
  begin
    V := FViews[K];
    { 先摘指针再释放：视图析构时（TCSBView.Destroy）会回写 FViews[K]，
      这里提前置 nil 就不会被它改回来，重入也安全。 }
    FViews[K] := nil;
    FMode[K]  := smNone;
    if V <> nil then
    begin
      try
        V.Parent := nil;
      except
      end;
      V.Free;
    end;
  end;
end;

procedure TChromeScrollBar.TimerTick(Sender: TObject);
var
  Busy: Boolean;
  K   : TCSBKind;
begin
  try
    if (Application.MainForm <> nil) and (csDestroying in Application.MainForm.ComponentState) then
    begin
      FTimer.Enabled := False;
      DestroyViews;
      Exit;
    end;
	
    if (FTarget = nil) or (csDestroying in ComponentState) or (csDestroying in FTarget.ComponentState) then Exit;
    if Application.Terminated then
    begin
      FTimer.Enabled := False;
      Exit;
    end;
	
    { 空闲闸门：静止时不再无条件全量重算。
      以前这里每 30ms 无条件跑一次 Refresh（UpdateView ×2：GetScrollInfo +
      GetClientRect + SetWindowPos + Invalidate），一个什么都没干的窗口要吃掉
      约 5.5% 单核。现在只有两种情况才重算：
        ① 收到过需要重算的消息（FNeedsRefresh）；
        ② 有视图正在动（IsBusy：淡入淡出 / 高亮插值 / 拖动 / 长按 / 自动隐藏倒计时）。 }
    Busy := False;
    for K := csbVertical to csbHorizontal do
      if (FViews[K] <> nil) and FViews[K].IsBusy then Busy := True;
    { 还有没消化掉的待重算请求（刚建句柄 / 刚显示 / 还没轮到算）就别退到低频
      心跳，否则原生条要多露 250ms 才被剥掉 }
    if FNeedsRefresh then Busy := True;

    { 都不忙的时候做一次廉价巡检：内容变化是唯一没有唤醒消息的状态变更，
      不查这一下滚动条就永远不出现（必须滚一下滚轮才触发重算）。 }
    if not Busy and RangeProbeChanged then Busy := True;

    if (FNeedsRefresh or Busy) and FTarget.HandleAllocated then
    begin
      FNeedsRefresh := False;
      Refresh;
    end;

    for K := csbVertical to csbHorizontal do
      if FViews[K] <> nil then
      begin
        { 窗口没显示时钉位置是纯浪费（两次窗口 API） }
        if FViews[K].Visible then FViews[K].EnsurePinned;
        FViews[K].DoTick;
      end;

    { 静止后退到低频心跳：CPU 压到接近 0，同时保留兜底轮询 }
    if Busy then
    begin
      if FTimer.Interval <> CSB_BUSY_INTERVAL then FTimer.Interval := CSB_BUSY_INTERVAL;
    end
    else if FTimer.Interval <> CSB_IDLE_INTERVAL then
      FTimer.Interval := CSB_IDLE_INTERVAL;
  except
  end;
end;

procedure TChromeScrollBar.WakeTimer;
begin
  FNeedsRefresh := True;
  if not FTimer.Enabled then FTimer.Enabled := True;
  if FTimer.Interval <> CSB_BUSY_INTERVAL then FTimer.Interval := CSB_BUSY_INTERVAL;
end;

procedure TChromeScrollBar.TargetStateChanged;
begin
  if (FTarget = nil) or (csDestroying in ComponentState) then Exit;
  if csDestroying in FTarget.ComponentState then Exit;
  FNeedsRefresh := True;
  if FTarget.HandleAllocated then Refresh;
end;

{ 目标控件颜色变了（切换主题最常见）。TransparentTrack 模式下轨道色直接取自
  控件的 Color，必须立刻重取并同步重画 —— 控件本身是当场刷新的，覆盖层慢一帧
  就会看到轨道还是旧底色，切主题时特别明显。 }
{ 用控件自身的 Color 把客户区填一遍。WM_ERASEBKGND 的 DC 已经带好裁剪区，
  FillRect 只会落在真正需要重画的部分，不会整屏重绘。 }
function TChromeScrollBar.EraseTargetBackground(ADC: HDC): Boolean;
var
  R    : TRect;
  Brush: HBRUSH;
begin
  Result := False;
  if (ADC = 0) or (FTarget = nil) or not FTarget.HandleAllocated then Exit;
  { 禁用态的 EDIT / LISTBOX 系统是用 COLOR_3DFACE 擦的，不是控件自己的 Color，
    拿 Color 硬填会填错色。这种情况交回原生处理 —— 禁用控件拿不到焦点，
    也就没有当初要解决的那种切焦点闪烁 }
  if not FTarget.Enabled then Exit;
  if not GetClientRect(FTarget.Handle, R) then Exit;
  Brush := CreateSolidBrush(ColorToRGB(TControlAccess(FTarget).Color));
  if Brush = 0 then Exit;
  try
    FillRect(ADC, R, Brush);
    Result := True;
  finally
    DeleteObject(Brush);
  end;
end;

procedure TChromeScrollBar.TargetColorChanged;
var
  K: TCSBKind;
begin
  if csDestroying in ComponentState then Exit;
  UpdateTrackColors;
  for K := csbVertical to csbHorizontal do
    if FViews[K] <> nil then
    begin
      FViews[K].Invalidate;
      if FViews[K].Visible then FViews[K].Update;
    end;
end;

procedure TChromeScrollBar.UpdateTrackColors;
var
  K: TCSBKind;
  C: TColor;
begin
  C := FTrackColor;
  if FTransparentTrack and (FTarget <> nil) and FTarget.HandleAllocated then C := TControlAccess(FTarget).Color;
  for K := csbVertical to csbHorizontal do
    if FViews[K] <> nil then
      FViews[K].FTrackColorValue := C;
end;

procedure TChromeScrollBar.InvalidateViews;
var
  K: TCSBKind;
begin
  for K := csbVertical to csbHorizontal do
    if FViews[K] <> nil then
      FViews[K].Invalidate;
end;

procedure TChromeScrollBar.Refresh;
begin
  { 防重入：WM_SIZE 回调里会同步调用 Refresh，而 Refresh 内部的 SetWindowPos
    可能再次触发消息，递归下去会重复计算甚至打穿栈。 }
  if FInRefresh then Exit;
  FInRefresh := True;
  try
    DoRefresh;
  finally
    FInRefresh := False;
  end;
end;

{ 目标控件尺寸变化（WM_SIZE）后立刻重算覆盖层，不必等 30ms 定时器 }
procedure TChromeScrollBar.TargetResized;
var
  R: TRect;
begin
  { WM_SIZE 已经同步重算过了，清掉标志避免下一拍再跑一次 }
  FNeedsRefresh := False;
  Refresh;
  { 控件放大时，右侧原来被「原生滚动条」占住的那一条会变成客户区。可它上面还
    留着旧底色（原生条那一溜），而目标控件的子控件（TScrollBox 里的 TPanel、
    之类）不会因此收到 WM_PAINT —— 结果是放大之后在原位置留一条竖直残影，
    实测 8px 宽、贯穿整个客户区高度，颜色就是目标控件的 Color。
    这里连子控件一起作废：RDW_ALLCHILDREN 是关键，只作废目标自己的话，它的
    客户区被子控件盖住，WM_PAINT 里什么也画不出来。刻意不带 RDW_ERASE ——
    让目标用自己的底色去擦，正好就是残影的成因（会盖到子控件上）。
    不加 RDW_UPDATENOW：WM_SIZE 里同步重画会在拖动改变大小时拖慢响应，
    正常消息循环里马上就会重画。 }
  if (FTarget <> nil) and FTarget.HandleAllocated and GetClientRect(FTarget.Handle, R) then
    RedrawWindow(FTarget.Handle, @R, 0, RDW_INVALIDATE or RDW_ALLCHILDREN);
end;

{ 空闲心跳里的廉价巡检：只比「内容量」这一个数（EDIT 是总行数，其它控件是
  垂直滚动范围的 nMax），变了才值得跑完整 Refresh。
  为什么需要它：程序里往 EDIT / LISTBOX 灌内容（Lines.Add、Items.Add、直接改
  Text）既不产生 WM_VSCROLL，也不改窗口尺寸，我们一条唤醒消息都收不到。
  以前定时器退到 250ms 空闲心跳后就完全不动了，表现就是「自绘滚动条不出现，
  必须滚一下滚轮才出来」。
  成本：一次 SendMessage(EM_GETLINECOUNT) 或一次 GetScrollInfo，4 次/秒，
  比每 30ms 全量 Refresh（SetWindowPos + Invalidate）便宜两个数量级。 }
function TChromeScrollBar.RangeProbeChanged: Boolean;
var
  K     : TCSBKind;
  Bar   : Integer;
  SI    : TScrollInfo;
  NewVal: Integer;
  NewOK : Boolean;
begin
  Result := False;
  if (FTarget = nil) or not FTarget.HandleAllocated then Exit;
  for K := csbVertical to csbHorizontal do
  begin
    { EDIT 的垂直范围：剥掉 WS_VSCROLL 之后 GetScrollInfo 的 nMax 恒为 0
      （实测 459 行也读回 0），只能问总行数。横向照旧读 GetScrollInfo ——
      横向范围一旦建立过就一直有效。 }
    if (K = csbVertical) and FEditClass then
    begin
      NewOK  := True;
      NewVal := SendMessage(FTarget.Handle, EM_GETLINECOUNT, 0, 0);
    end
    else
    begin
      if K = csbVertical then Bar := SB_VERT else Bar := SB_HORZ;
      FillChar(SI, SizeOf(SI), 0);
      SI.cbSize := SizeOf(SI);
      SI.fMask  := SIF_RANGE;
      NewOK     := FlatSB_GetScrollInfo(FTarget.Handle, Bar, SI);
      NewVal    := SI.nMax;
    end;
    if (NewOK <> FProbeOK[K]) or (NewVal <> FProbeMax[K]) then
    begin
      FProbeOK[K]  := NewOK;
      FProbeMax[K] := NewVal;
      Result       := True;
    end;
  end;
end;

procedure TChromeScrollBar.DoRefresh;
begin
  try
    if (FTarget = nil) or (csDestroying in ComponentState) or (csDestroying in FTarget.ComponentState) then Exit;
    if not FTarget.HandleAllocated then
    begin
      { SetTarget 通常发生在 DFM 流化阶段，那时目标控件的句柄还没建出来。
        这里不能静默返回：子类化也装不上，之后连一条唤醒消息都收不到，
        整个控件就"死"在那里，直到用户恰好滚一下滚轮。留标记下一拍重试。 }
      FNeedsRefresh := True;
      Exit;
    end;
	
    if not FTarget.Visible or not IsWindowVisible(FTarget.Handle) then
    begin
      { 窗体还没显示时这里是必然命中的（CreateForm 阶段 Visible 还是 False）。
        不能就这么静默返回：那样 FMode 会永远停在 smNone，滚轮判定全部失效，
        而定时器又已经退到低频心跳 —— 表现就是「滚动条在、但完全没反应」。
        留个标记，下一拍继续试，直到真的能算。 }
      FNeedsRefresh := True;
      if FViews[csbVertical] <> nil then
      begin
        FViews[csbVertical].FActive := False;
        FViews[csbVertical].Visible := False;
      end;
      if FViews[csbHorizontal] <> nil then
      begin
        FViews[csbHorizontal].FActive := False;
        FViews[csbHorizontal].Visible := False;
      end;
      Exit;
    end;
	
    if not FEditClassKnown then  UpdateEditClass;
    UpdateTrackColors;
    if not FEnabled then
    begin
      FNeedsRefresh := True;
      if FViews[csbVertical] <> nil then
      begin
        FViews[csbVertical].FActive := False;
        FViews[csbVertical].Visible := False;
      end;
      if FViews[csbHorizontal] <> nil then
      begin
        FViews[csbHorizontal].FActive := False;
        FViews[csbHorizontal].Visible := False;
      end;
      Exit;
    end;
    UpdateView(csbVertical);
    UpdateView(csbHorizontal);
  except
  end;
end;

function TChromeScrollBar.OverlayParent: TWinControl;
var
  P: TWinControl;
begin
  Result := nil;
  if FTarget = nil then Exit;
  
  P := FTarget.Parent;
  while P <> nil do
  begin
    if not(P is TScrollingWinControl) then
      Exit(P);
    P := P.Parent;
  end;
  Result := FTarget.Parent;
end;

function TChromeScrollBar.ToTargetRect(const ARect: TRect): TRect;
var
  P: TWinControl;
begin
  Result := ARect;
  if (FTarget = nil) or not FTarget.HandleAllocated then Exit;
  P := nil;
  if FViews[csbVertical] <> nil then
    P := FViews[csbVertical].Parent
  else if FViews[csbHorizontal] <> nil then
    P := FViews[csbHorizontal].Parent;
  if (P = nil) or (P = FTarget) then Exit;
  
  MapWindowPoints(P.Handle, FTarget.Handle, Result, 2);
end;

function TChromeScrollBar.BarFitsParent(AView: TCSBView; const R: TRect): Boolean;
var
  P      : TWinControl;
  AR, Tmp: TRect;
begin
  Result := False;
  if (AView.Parent = nil) or (FTarget = nil) then Exit;
  Tmp := R;
  P   := FTarget.Parent;
  while (P <> nil) and (P <> AView.Parent) do
  begin
    if GetClientRect(P.Handle, AR) then
    begin
      MapWindowPoints(P.Handle, AView.Parent.Handle, AR, 2);
      if IsRectEmpty(AR) then Exit;
      if IsRectEmpty(Tmp) then Exit;
      IntersectRect(Tmp, Tmp, AR);
      if IsRectEmpty(Tmp) then Exit;
    end;
    P := P.Parent;
  end;
  Result := (Tmp.Left = R.Left) and (Tmp.Top = R.Top) and (Tmp.Right = R.Right) and (Tmp.Bottom = R.Bottom);
end;

procedure TChromeScrollBar.UpdateView(AKind: TCSBKind);
var
  View                  : TCSBView;
  R, TargetRect, OldRect: TRect;
  NewW, NewH            : Integer;
  Pos, MaxValue, Page   : Integer;
  Mode                  : TCSBMode;
  NewMaxPos             : Integer;
  Changed               : Boolean;
  WasVisible            : Boolean;
begin
  View := FViews[AKind];
  if View = nil then
  begin
    if OverlayParent = nil then Exit;
    View        := TCSBView.Create(Self, AKind);
    View.Parent := OverlayParent;
    View.BringToFront;
    FViews[AKind] := View;
  end;

  if not ReadScrollState(AKind, Pos, MaxValue, Page, Mode) then
  begin
    FMode[AKind] := smNone;
    { 这个方向没有滚动条：顺手把可能残留的原生条也藏掉，
      否则 EDIT 类控件会露出一条没用的原生滚动条 }
    HideNativeBar(AKind);
    View.FActive := False;
    if View.Visible then
    begin
      View.Visible := False;
      InvalidateTargetRect(ToTargetRect(View.BoundsRect));
    end;
    Exit;
  end;

  NewMaxPos := MaxValue - Page;
  if NewMaxPos < 0 then NewMaxPos := 0;
  if NewMaxPos <= 0 then
  begin
    FMode[AKind] := Mode;
    HideNativeBar(AKind);
    View.FActive := False;
    if View.Visible then
    begin
      View.Visible := False;
      InvalidateTargetRect(ToTargetRect(View.BoundsRect));
    end;
    Exit;
  end;

  { 滚到底之后继续滚，EDIT 的 EM_GETFIRSTVISIBLELINE 会短暂返回越界值
    （可见行数 29、总行 41 时合法上限是 12，却会冒出 13）。不钳制就会拿
    13/12 去算偏移，把滑块顶出轨道再弹回来，看上去就是滚动条在闪。 }
  if Pos > NewMaxPos then Pos := NewMaxPos;
  if Pos < 0 then Pos := 0;

  { 不经过 ApplyScrollEx 的路径（方向键、原生条拖动、控件自己处理的滚轮）
    在这里补一次，保证 OnScroll 和真实位置始终同步。DoScrollEvent 自带去重。 }
  DoScrollEvent(AKind, Pos);
  Changed      := (View.FPosition <> Pos) or (View.FMaxPos <> NewMaxPos) or (View.FPageSize <> Page) or (FMode[AKind] <> Mode) or not View.Visible;
  FMode[AKind] := Mode;
  if View.FPosition <> Pos then View.DoWake;
  View.FPosition := Pos;
  View.FMaxPos   := NewMaxPos;
  View.FPageSize := Page;

  { 隐藏原生滚动条，避免它从覆盖层旁边露出缝隙。
    实测：ShowScrollBar(False) 会移除 WS_VSCROLL，但控件的滚动引擎仍然活着
    （WM_VSCROLL 依旧能搬动内容）；只是 EDIT 类控件的 GetScrollInfo.nPos
    会冻结在 0，所以这类控件的位置改由 EM_GETFIRSTVISIBLELINE 读取。 }
  HideNativeBar(AKind);

  if not GetClientRect(FTarget.Handle, TargetRect) then
    Exit;
  NewW := TargetRect.Right - TargetRect.Left;
  NewH := TargetRect.Bottom - TargetRect.Top;
  if FHideNative then
  begin
    { 原生条已经被剥掉，GetScrollBarInfo 仍会返回残留的旧位置，
      用它算偏移会把自绘条放到错误的地方（横向条尤其明显）。
      HideNative 模式下直接贴客户区右/下边缘，每次重算，不做缓存。 }
    if AKind = csbVertical then
      FBarOffset[AKind] := Rect(NewW - FBarSize - 2, 0, NewW, NewH)
    else
      FBarOffset[AKind] := Rect(0, NewH - FBarSize - 2, NewW, NewH);
    FLastBarW[AKind] := NewW;
    FLastBarH[AKind] := NewH;
  end
  else if IsRectEmpty(FBarOffset[AKind]) or (NewW <> FLastBarW[AKind]) or (NewH <> FLastBarH[AKind]) then
  begin
    if GetBarRect(AKind, R) then
      FBarOffset[AKind] := Rect(R.Left - TargetRect.Left, R.Top - TargetRect.Top, R.Right - TargetRect.Left, R.Bottom - TargetRect.Top)
    else if AKind = csbVertical then
      FBarOffset[AKind] := Rect(NewW - FBarSize - 2, 0, NewW, NewH)
    else
      FBarOffset[AKind] := Rect(0, NewH - FBarSize - 2, NewW, NewH);
    FLastBarW[AKind]    := NewW;
    FLastBarH[AKind]    := NewH;
  end;
  R := Rect(TargetRect.Left + FBarOffset[AKind].Left, TargetRect.Top + FBarOffset[AKind].Top, TargetRect.Left + FBarOffset[AKind].Right, TargetRect.Top + FBarOffset[AKind].Bottom);
  if AKind = csbVertical then
  begin
    if (R.Right - R.Left) < FBarSize then  R.Right := R.Left + FBarSize;
  end
  else
  begin
    if (R.Bottom - R.Top) < FBarSize then R.Bottom := R.Top + FBarSize;
    { 水平条不能覆盖垂直条，否则右下角的下箭头会被水平条抢走点击 }
    if (FViews[csbVertical] <> nil) and FViews[csbVertical].Visible then
    begin
      if FHideNative or IsRectEmpty(FBarOffset[csbVertical]) then
        R.Right := Min(R.Right, TargetRect.Right - FBarSize - 2)
      else
        R.Right := Min(R.Right, TargetRect.Left + FBarOffset[csbVertical].Left);
      if R.Right < R.Left + FBarSize then R.Right := R.Left + FBarSize;
    end;
  end;

  { R 目前是目标客户区坐标，覆盖层挂在祖先上，换算过去 }
  if (View.Parent <> nil) and (View.Parent <> FTarget) then MapWindowPoints(FTarget.Handle, View.Parent.Handle, R, 2);

  if not View.FDragging and not BarFitsParent(View, R) then
  begin
    View.FActive := False;
    if View.Visible then
    begin
      View.Visible := False;
      InvalidateTargetRect(ToTargetRect(View.BoundsRect));
    end;
    Exit;
  end;

  View.FActive := True;
  WasVisible := View.Visible;
  if View.BoundsRect <> R then
  begin
    if WasVisible then
      OldRect := View.BoundsRect
    else
      OldRect := R;
    View.PinTo(R);
    Changed := True;
    if WasVisible then InvalidateTargetRect(ToTargetRect(OldRect));
  end;
  if not View.Visible then
  begin
    View.ShowWindowNow;
    Changed := True;
  end;
  if Changed then View.Invalidate;
end;

procedure TChromeScrollBar.InvalidateTargetRect(const ARect: TRect);
var
  ClientRect: TRect;
  Tmp       : TRect;
begin
  if (FTarget = nil) or not FTarget.HandleAllocated or IsRectEmpty(ARect) then Exit;
  if not GetClientRect(FTarget.Handle, ClientRect) then Exit;
  Tmp := ARect;
  if not IntersectRect(Tmp, Tmp, ClientRect) then Exit;
  
  InvalidateRect(FTarget.Handle, @Tmp, False);
end;

function TChromeScrollBar.ReadScrollState(AKind: TCSBKind; out APos, AMax, APage: Integer; out AMode: TCSBMode): Boolean;
var
  SI : TScrollInfo;
  CR : TRect;
  Bar: Integer;
  SB : TControlScrollBar;
begin
  Result := False;
  APos   := 0;
  AMax   := 0;
  APage  := 0;
  AMode  := smNone;
  if (FTarget = nil) or not FTarget.HandleAllocated then Exit;

  if AKind = csbVertical then
    Bar := SB_VERT
  else
    Bar := SB_HORZ;

  { TScrollingWinControl 必须优先：VCL 的 TControlScrollBar.Position 是精确像素，
    而它的 WM_VSCROLL 每次走 Increment（默认 8 像素），用 smNative 逐行推进会对不上。 }
  if FTarget is TScrollingWinControl then
  begin
    if AKind = csbVertical then
      SB := TScrollingWinControl(FTarget).VertScrollBar
    else
      SB := TScrollingWinControl(FTarget).HorzScrollBar;
    APos := SB.Position;
    AMax := SB.Range;
    GetClientRect(FTarget.Handle, CR);
    if AKind = csbVertical then
      APage := CR.Bottom - CR.Top
    else
      APage := CR.Right - CR.Left;
    if APage <= 0 then APage := 1;
    { 注意：不能用 IsScrollBarVisible 判断，原生条已被我们隐藏 }
    if (AMax > 0) and (AMax - APage > 0) then
    begin
      AMode  := smControlScrollBar;
      Result := True;
      Exit;
    end;
  end;

  FillChar(SI, SizeOf(SI), 0);
  SI.cbSize := SizeOf(SI);
  SI.fMask  := SIF_ALL;
  if FlatSB_GetScrollInfo(FTarget.Handle, Bar, SI) then
  begin
    APos  := SI.nPos;
    { nMax 是“最后一个可滚单位”的索引（行/项/像素坐标），nPage 是可见量，
      可滚范围 = (nMax + 1) - nPage。少加这个 1，滚到底就会差最后一行/最后一项。 }
    AMax  := SI.nMax + 1;
    APage := SI.nPage;
    if APage <= 0 then
      APage := 1;
    if FEditClass then
    begin
      { EDIT 剥掉样式位后 nPage 会退化成 nMax+1（相当于"全部可见"），必须自算：
        垂直 = 可见行数（几何法）；横向 = 客户区宽度（像素）。 }
      if AKind = csbVertical then
      begin
        APos  := SendMessage(FTarget.Handle, EM_GETFIRSTVISIBLELINE, 0, 0);
        APage := EditVisibleLines(FTarget.Handle);
        { nMax 是“最后一行”的索引，而 nPos / nPage 是行号 / 可见行数，
          可滚范围 = (nMax + 1) - nPage。直接用 nMax 会少一行，滚到底时
          滑块被推出轨道、下沿被窗口裁掉，长度看起来就变短了。 }
        AMax  := SendMessage(FTarget.Handle, EM_GETLINECOUNT, 0, 0);
      end
      else
      begin
        GetClientRect(FTarget.Handle, CR);
        APage := CR.Right - CR.Left;
        APos  := EditScrollPosX(FTarget.Handle);
      end;
    end;
    if (AMax > 0) and (AMax - APage > 0) then
    begin
      AMode  := smNative;
      Result := True;
      Exit;
    end;
  end;

  if FVirtualRange[AKind] > 0 then
  begin
    APos := FVirtualPosition[AKind];
    AMax := FVirtualRange[AKind];
    if AKind = csbVertical then
      APage := FTarget.ClientHeight
    else
      APage := FTarget.ClientWidth;
    if APage <= 0 then APage := 1;
    if (AMax > 0) and (AMax - APage > 0) then
    begin
      AMode  := smVirtual;
      Result := True;
    end;
  end;
end;

function TChromeScrollBar.GetBarRect(AKind: TCSBKind; out R: TRect): Boolean;
var
  SBI       : TScrollBarInfo;
  ObjId     : DWORD;
  Child     : HWND;
  WindowRect: TRect;
  P         : TPoint;
begin
  Result := False;
  FillChar(R, SizeOf(R), 0);
  if (FTarget = nil) or not FTarget.HandleAllocated then Exit;

  FillChar(SBI, SizeOf(SBI), 0);
  SBI.cbSize := SizeOf(SBI);
  if AKind = csbVertical then
    ObjId := OBJID_VSCROLL
  else
    ObjId := OBJID_HSCROLL;
  if GetScrollBarInfo(FTarget.Handle, LongInt(ObjId), SBI) then
  begin
    if (SBI.rgstate[0] and STATE_SYSTEM_INVISIBLE) = 0 then
    begin
      R := SBI.rcScrollBar;
      if not IsRectEmpty(R) then
      begin
        MapWindowPoints(0, FTarget.Handle, R, 2);
        Result := True;
        Exit;
      end;
    end;
  end;

  Child := FindChildScrollBar(AKind);
  if (Child <> 0) and GetWindowRect(Child, WindowRect) then
  begin
    P := Point(WindowRect.Left, WindowRect.Top);
    ScreenToClient(FTarget.Handle, P);
    R      := Bounds(P.X, P.Y, WindowRect.Right - WindowRect.Left, WindowRect.Bottom - WindowRect.Top);
    Result := not IsRectEmpty(R);
  end;
end;

function TChromeScrollBar.FindChildScrollBar(AKind: TCSBKind): HWND;
var
  Rec: TCSBFindRec;
begin
  Result := 0;
  if (FTarget = nil) or not FTarget.HandleAllocated then Exit;
  Rec.Kind         := AKind;
  Rec.ParentHandle := FTarget.Handle;
  Rec.Found        := 0;
  EnumChildWindows(FTarget.Handle, @EnumChildScrollBars, LPARAM(@Rec));
  Result := Rec.Found;
end;

{ 关键：位置以控件真实状态为唯一来源，避免 FPosition 与真实位置打架 }
{ 读取滚动状态的统一入口：位置 / 最大范围 / 可视页大小。
  返回 False 表示目标当前没有这方向的滚动条。 }
function TChromeScrollBar.QueryScrollState(AKind: TCSBKind; out ACurPos, AMax, APage: Integer; out AMode: TCSBMode): Boolean;
var
  Bar: Integer;
  SB : TControlScrollBar;
  SI : TScrollInfo;
  CR : TRect;
begin
  Result  := False;
  ACurPos := 0;
  AMax    := 0;
  APage   := 1;
  AMode   := FMode[AKind];
  if AMode = smNone then Exit;
  if (FTarget = nil) or not FTarget.HandleAllocated then Exit;

  case AMode of
    smNative:
      begin
        if AKind = csbVertical then
          Bar := SB_VERT
        else
          Bar := SB_HORZ;
        FillChar(SI, SizeOf(SI), 0);
        SI.cbSize := SizeOf(SI);
        SI.fMask  := SIF_ALL;
        if not FlatSB_GetScrollInfo(FTarget.Handle, Bar, SI) then Exit;
        ACurPos := SI.nPos;
        { 和 ReadScrollState 保持一致：nMax 是“最后一个可滚单位”的索引 }
        AMax    := SI.nMax + 1;
        APage   := Max(1, SI.nPage);
        { 隐藏原生条后 EDIT 的 nPos 不再更新，用"首个可见行"作为真实位置 }
        if FEditClass then
        begin
          if AKind = csbVertical then
          begin
            ACurPos := SendMessage(FTarget.Handle, EM_GETFIRSTVISIBLELINE, 0, 0);
            APage   := EditVisibleLines(FTarget.Handle);
            AMax    := SendMessage(FTarget.Handle, EM_GETLINECOUNT, 0, 0);
          end
          else
          begin
            GetClientRect(FTarget.Handle, CR);
            APage   := CR.Right - CR.Left;
            ACurPos := EditScrollPosX(FTarget.Handle);
          end;
        end;
      end;
    smControlScrollBar:
      begin
        if AKind = csbVertical then
          SB := TScrollingWinControl(FTarget).VertScrollBar
        else
          SB    := TScrollingWinControl(FTarget).HorzScrollBar;
        ACurPos := SB.Position;
        AMax    := SB.Range;
        GetClientRect(FTarget.Handle, CR);
        if AKind = csbVertical then
          APage := CR.Bottom - CR.Top
        else
          APage := CR.Right - CR.Left;
        APage   := Max(1, APage);
      end;
    smVirtual:
      begin
        ACurPos := FVirtualPosition[AKind];
        AMax    := FVirtualRange[AKind];
        GetClientRect(FTarget.Handle, CR);
        if AKind = csbVertical then
          APage := CR.Bottom - CR.Top
        else
          APage := CR.Right - CR.Left;
        APage   := Max(1, APage);
      end;
  else
    Exit;
  end;
  Result := True;
end;

{ 把内容真正滚到 ANewPos。
  注意：原生控件（EDIT / LISTBOX）只认 WM_VSCROLL 的相对滚动代码，
  SetScrollInfo / FlatSB_SetScrollPos 只会改索引不会搬动内容。 }
procedure TChromeScrollBar.CommitScroll(AKind: TCSBKind; ACurPos, ANewPos, APage: Integer);
var
  Msg                        : Cardinal;
  SB                         : TControlScrollBar;
  TmpPos, TmpMax, TmpPage    : Integer;
  TmpMode                    : TCSBMode;
begin
  if ANewPos = ACurPos then Exit;
  
  case FMode[AKind] of
    smNative:
      begin
        if AKind = csbVertical then
          Msg := WM_VSCROLL
        else
          Msg := WM_HSCROLL;
        { 绝对定位一次到位：SB_THUMBPOSITION 会让控件自己把越界值钳进合法范围。
          以前是发 SB_LINEDOWN/SB_LINEUP 逐步累加，滚到最右时每一步都会
          越过 EDIT 的真实上限，控件随即回弹，看上去就是滑块在末端来回弹跳。
          绝对定位既不会越界，也快得多（一次消息 vs 最多 Page 次）。 }
        SendMessage(FTarget.Handle, Msg,
          MakeWParam(SB_THUMBPOSITION, ANewPos and $FFFF), 0);
        { 极少数控件不认 SB_THUMBPOSITION，位置没动时退回逐步滚动 }
        if (ANewPos <> ACurPos) and
           QueryScrollState(AKind, TmpPos, TmpMax, TmpPage, TmpMode) and
           (TmpPos = ACurPos) then
          SendNativeScroll(FTarget.Handle, Msg, ACurPos, ANewPos, APage);
      end;
    smControlScrollBar:
      begin
        if AKind = csbVertical then
          SB := TScrollingWinControl(FTarget).VertScrollBar
        else
          SB        := TScrollingWinControl(FTarget).HorzScrollBar;
        SB.Position := ANewPos;
      end;
    smVirtual:
      SetVirtualPositionValue(AKind, ANewPos);
  end;
end;

{ 唯一的滚动入口：所有箭头 / 翻页 / 拖动 / 滚轮都走这里。
  位置一律以控件真实状态为准，因此不会出现"读到的位置和实际不一致"的抖动。 }
procedure TChromeScrollBar.ApplyScrollEx(AKind: TCSBKind; ACode: Word; APos, ADelta: Integer);
var
  CurPos, MaxValue, Page, MaxScroll, NewPos: Integer;
  LineStep                                 : Integer;
  Mode                                     : TCSBMode;
  View                                     : TCSBView;
  RealPos                                  : Integer;
begin
  if (FTarget = nil) or not FTarget.HandleAllocated then Exit;
  if csDestroying in FTarget.ComponentState then Exit;

  if not QueryScrollState(AKind, CurPos, MaxValue, Page, Mode) then Exit;
  View := FViews[AKind];

  { QueryScrollState 返回的 MaxValue 在 smNative 下已经是 nMax + 1，
    所以这里统一减 Page，不能再补 1（补了会多出一格，滚到底滑块越界）。 }
  MaxScroll := Max(0, MaxValue - Page);
  if ADelta <> 0 then
  begin
    { 滚轮：一次加上整段增量 }
    if ScrollCodeDirection(ACode) < 0 then
      NewPos := CurPos - ADelta
    else
      NewPos := CurPos + ADelta;
  end
  else
  begin
    { 横向按像素步进（原生 SB_LINERIGHT 一次就是一个字符宽，约 6~8px）；
      垂直按行 / 项步进，一次一行。 }
    if AKind = csbHorizontal then
      LineStep := 8
    else
      LineStep := 1;
    case ACode of
      SB_LINEUP:
        NewPos := CurPos - LineStep;
      SB_LINEDOWN:
        NewPos := CurPos + LineStep;
      SB_PAGEUP:
        NewPos := CurPos - Page;
      SB_PAGEDOWN:
        NewPos := CurPos + Page;
      SB_TOP:
        NewPos := 0;
      SB_BOTTOM:
        NewPos := MaxScroll;
      SB_THUMBTRACK, SB_THUMBPOSITION:
        NewPos := APos;
    else
      NewPos := APos;
    end;
  end;
  NewPos := Max(0, Min(NewPos, MaxScroll));

  CommitScroll(AKind, CurPos, NewPos, Page);

  if View <> nil then
  begin
    View.FPosition := NewPos;
    if ADelta <> 0 then View.DoWake;
    View.Invalidate;
    View.EnsurePinned;
  end;

  { 提交后以控件真实状态为准（EDIT / LISTBOX 会把越界值自己钳回去），
    统一在这里回调 OnScroll：箭头 / 长按重复 / 拖滑块 / 点轨道翻页 / 滚轮
    / 程序化 ScrollTo 全部覆盖。 }
  if QueryScrollState(AKind, RealPos, MaxValue, Page, Mode) then
    DoScrollEvent(AKind, RealPos)
  else
    DoScrollEvent(AKind, NewPos);

  { 交互期间保持高频档，松手后由 IsBusy 自然退回心跳 }
  WakeTimer;
end;

procedure TChromeScrollBar.ApplyScroll(AKind: TCSBKind; ACode: Word; APos: Integer);
begin
  ApplyScrollEx(AKind, ACode, APos, 0);
end;

procedure TChromeScrollBar.ApplyScrollSmooth(AKind: TCSBKind; ACode: Word; APos, ADelta: Integer);
begin
  ApplyScrollEx(AKind, ACode, APos, ADelta);
end;

function TChromeScrollBar.InternalHandleWheel(AKind: TCSBKind; ADelta: Integer; AShift: Boolean): Boolean;
var
  Handled: Boolean;
  Lines  : Integer;
  Steps  : Integer;
  Dir    : Integer;
begin
  Result := False;
  if not FWheelScroll or not FEnabled then Exit;
  if (FTarget = nil) or not FTarget.HandleAllocated then Exit;
  if csDestroying in FTarget.ComponentState then Exit;

  Handled := False;
  if Assigned(FOnWheel) then FOnWheel(Self, AKind, ADelta, Handled);
  if Handled then Exit(True);
  if FMode[AKind] = smNone then Exit;

  { Shift + 滚轮 = 水平滚动；否则垂直滚动 }
  if AShift then
  begin
    if AKind <> csbHorizontal then Exit;
  end
  else if AKind <> csbVertical then
    Exit;

  Lines := Mouse.WheelScrollLines;
  if Lines <= 0 then Lines := 3;
  if Lines > 30 then Lines := 30;
  Steps   := Lines;

  if CurrentModeSupportsLineScroll(AKind) then
  begin
    if ADelta > 0 then
      Dir := -1
    else if ADelta < 0 then
      Dir := 1
    else
      Exit;
    ApplyScrollSmooth(AKind, SB_LINEDOWN, 0, Steps * Dir);
  end
  else
  begin
    if ADelta > 0 then
      ApplyScrollSmooth(AKind, SB_PAGEUP, 0, 1)
    else if ADelta < 0 then
      ApplyScrollSmooth(AKind, SB_PAGEDOWN, 0, 1);
  end;
  if FViews[AKind] <> nil then FViews[AKind].DoWake;
  Result := True;
end;

function TChromeScrollBar.CurrentModeSupportsLineScroll(AKind: TCSBKind): Boolean;
begin
  Result := FMode[AKind] in [smNative, smControlScrollBar, smVirtual];
end;

{ OnScroll 的唯一出口。所有滚动路径最后都汇到这里，因此只要位置真的变了
  就一定会回调，位置没变（滚到顶继续滚、拖动中同一像素重复提交）就不回调。
  事件里若再次触发滚动，FInScrollEvent 会把内层这次挡掉，避免无限递归。 }
procedure TChromeScrollBar.DoScrollEvent(AKind: TCSBKind; APosition: Integer);
begin
  { 窗体开始析构后绝不能再回调：此时它的字段 / 控件已经陆续释放，事件里哪怕
    只改一次 Caption 都会踩到已释放的对象（退出时的访问违例就是这么来的）。
    Owner 就是宿主窗体，TCustomForm.Destroy 一进来就把 csDestroying 置上，
    比 FTarget 的 WM_DESTROY 更早，拿它当闸门最稳。 }
  if (csDestroying in ComponentState) or Application.Terminated then Exit;
  if (Owner <> nil) and (csDestroying in Owner.ComponentState) then Exit;
  if FLastEventPos[AKind] = APosition then Exit;
  FLastEventPos[AKind] := APosition;
  if not Assigned(FOnScroll) then Exit;
  if FInScrollEvent then Exit;
  FInScrollEvent := True;
  try
    FOnScroll(Self, AKind, APosition);
  finally
    FInScrollEvent := False;
  end;
end;

procedure TChromeScrollBar.SetVirtualPositionValue(AKind: TCSBKind; APosition: Integer);
var
  CR            : TRect;
  OldPos, MaxPos: Integer;
begin
  OldPos := FVirtualPosition[AKind];
  MaxPos := FVirtualRange[AKind];
  if (MaxPos > 0) and (FTarget <> nil) and FTarget.HandleAllocated then
  begin
    GetClientRect(FTarget.Handle, CR);
    if AKind = csbVertical then
      Dec(MaxPos, CR.Bottom - CR.Top)
    else
      Dec(MaxPos, CR.Right - CR.Left);
  end;
  APosition := Max(0, Min(APosition, Max(0, MaxPos)));
  if APosition = OldPos then Exit;
  FVirtualPosition[AKind] := APosition;
  if FTarget <> nil then
  begin
    if AKind = csbVertical then
      FTarget.ScrollBy(0, OldPos - APosition)
    else
      FTarget.ScrollBy(OldPos - APosition, 0);
  end;
  DoScrollEvent(AKind, APosition);
  Refresh;
end;

procedure TChromeScrollBar.SetVirtualPosition(AKind: TCSBKind; APosition: Integer);
begin
  SetVirtualPositionValue(AKind, APosition);
end;

function TChromeScrollBar.GetVirtualPosition(AKind: TCSBKind): Integer;
begin
  Result := FVirtualPosition[AKind];
end;

procedure TChromeScrollBar.RefreshViewState(AKind: TCSBKind);
var
  CurPos, MaxValue, Page: Integer;
  Mode                  : TCSBMode;
  View                  : TCSBView;
begin
  View := FViews[AKind];
  if View = nil then Exit;
  if not QueryScrollState(AKind, CurPos, MaxValue, Page, Mode) then Exit;
  View.FMaxPos   := Max(0, MaxValue - Page);
  View.FPageSize := Max(1, Page);
  if View.FMaxPos > 0 then
    View.FPosition := Max(0, Min(CurPos, View.FMaxPos))
  else
    View.FPosition := 0;
end;

function TChromeScrollBar.ViewPosition(AKind: TCSBKind): Integer;
var
  CurPos, MaxValue, Page: Integer;
  Mode                  : TCSBMode;
begin
  if QueryScrollState(AKind, CurPos, MaxValue, Page, Mode) then
  begin
    { MaxValue 在 smNative 里已经取的是 nMax + 1，这里不能再补 1，
      否则会返回比真实上限大 1 的位置（滚到底时滑块被推出轨道）。 }
    Result := Max(0, Min(CurPos, Max(0, MaxValue - Page)));
  end
  else if FViews[AKind] <> nil then
    Result := FViews[AKind].FPosition
  else
    Result := 0;
end;

procedure TChromeScrollBar.HandleWheel(ADelta: Integer; AShift: Boolean);
begin
  if AShift then
    InternalHandleWheel(csbHorizontal, ADelta, True)
  else
    InternalHandleWheel(csbVertical, ADelta, False);
end;

{ 应用层滚轮钩子回调：把光标下的滚轮消息转成自绘滚动条的滚动 }
function TChromeScrollBar.HandleWheelMessage(AScreenPos: TPoint; AMsg: Cardinal; ADelta: Integer; AShift: Boolean): Boolean;
var
  W    : HWND;
  P    : TPoint;
  R    : TRect;
  Kind : TCSBKind;
  Owned: Boolean;
begin
  Result := False;
  if not FWheelScroll or not FEnabled then Exit;
  if (FTarget = nil) or not FTarget.HandleAllocated then Exit;
  if csDestroying in ComponentState then Exit;
  if csDestroying in FTarget.ComponentState then Exit;

  { 光标必须落在目标控件上（含其子窗口）才算它的滚轮 }
  W := WindowFromPoint(AScreenPos);
  if W = 0 then Exit;
  
  if (W <> FTarget.Handle) and (not IsChild(FTarget.Handle, W)) then
  begin
    Owned    := False;
    for Kind := csbVertical to csbHorizontal do
      if (FViews[Kind] <> nil) and FViews[Kind].HandleAllocated and (FViews[Kind].Handle = W) then Owned := True;
    if not Owned then Exit;
  end;

  { 滚轮可能被控件自己吃掉（原生 EDIT / LISTBOX 就是这样），我们拦不到也无需拦，
    但必须提前唤醒：否则内容滚了、滚动条要等最多一个心跳周期才跟上。 }
  WakeTimer;

  if AMsg = WM_MOUSEHWHEEL then
  begin
    { 横向滚轮设备：直接驱动水平条 }
    if ADelta = 0 then Exit;
    Result := InternalHandleWheel(csbHorizontal, ADelta, False);
    Exit;
  end;

  if AShift then
    Kind := csbHorizontal
  else
    Kind := csbVertical;

  if FMode[Kind] = smNone then Exit;

  { 命中覆盖层本身时，由 TCSBView.WMMouseWheel 处理，避免重复滚动 }
  if FViews[Kind] <> nil then
  begin
    R := FViews[Kind].BoundsRect;
    P := AScreenPos;
    if FViews[Kind].Parent <> nil then ScreenToClient(FViews[Kind].Parent.Handle, P);
    if PtInRect(R, P) and FViews[Kind].Visible then Exit;
  end;

  Result := InternalHandleWheel(Kind, ADelta, AShift);
end;

procedure TChromeScrollBar.SetEnabled(AValue: Boolean);
begin
  if FEnabled = AValue then Exit;
  FEnabled := AValue;
  Refresh;
end;

procedure TChromeScrollBar.SetAutoHide(AValue: Boolean);
var
  K: TCSBKind;
begin
  if FAutoHide = AValue then Exit;
  FAutoHide := AValue;
  for K     := csbVertical to csbHorizontal do
    if FViews[K] <> nil then
      FViews[K].DoWake;
end;

procedure TChromeScrollBar.SetBarSize(AValue: Integer);
begin
  AValue := Max(4, Min(24, AValue));
  if FBarSize = AValue then Exit;
  FBarSize := AValue;
  Refresh;
end;

procedure TChromeScrollBar.SetTrackColor(AValue: TColor);
begin
  if FTrackColor = AValue then Exit;
  FTrackColor := AValue;
  UpdateTrackColors;
  InvalidateViews;
end;

procedure TChromeScrollBar.SetThumbColor(AValue: TColor);
begin
  if FThumbColor = AValue then Exit;
  
  FThumbColor := AValue;
  InvalidateViews;
end;

procedure TChromeScrollBar.SetThumbHoverColor(AValue: TColor);
begin
  if FThumbHoverColor = AValue then Exit;
  
  FThumbHoverColor := AValue;
  InvalidateViews;
end;

procedure TChromeScrollBar.SetThumbPressedColor(AValue: TColor);
begin
  if FThumbPressedColor = AValue then Exit;
  
  FThumbPressedColor := AValue;
  InvalidateViews;
end;

procedure TChromeScrollBar.SetTransparentTrack(AValue: Boolean);
begin
  if FTransparentTrack = AValue then Exit;
  
  FTransparentTrack := AValue;
  UpdateTrackColors;
  InvalidateViews;
end;

function TChromeScrollBar.GetVirtualVRange: Integer;
begin
  Result := FVirtualRange[csbVertical];
end;

procedure TChromeScrollBar.SetVirtualVRange(AValue: Integer);
begin
  AValue := Max(0, AValue);
  if FVirtualRange[csbVertical] = AValue then Exit;
  
  FVirtualRange[csbVertical] := AValue;
  Refresh;
end;

function TChromeScrollBar.GetVirtualHRange: Integer;
begin
  Result := FVirtualRange[csbHorizontal];
end;

procedure TChromeScrollBar.SetVirtualHRange(AValue: Integer);
begin
  AValue := Max(0, AValue);
  if FVirtualRange[csbHorizontal] = AValue then Exit;
  
  FVirtualRange[csbHorizontal] := AValue;
  Refresh;
end;

end.
