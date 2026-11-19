unit uMain;

interface

uses Winapi.Windows, Winapi.Messages, Winapi.ShellAPI, System.SysUtils, System.Classes, System.Types, System.UITypes, System.Math,
     System.ImageList, System.Actions, System.IOUtils, System.IniFiles, System.Generics.Collections, System.Generics.Defaults, System.Diagnostics,
	 Vcl.Forms, Vcl.Controls, Vcl.StdCtrls, Vcl.ExtCtrls, Vcl.ComCtrls, Vcl.Grids, Vcl.ToolWin, Vcl.Buttons, Vcl.ActnList, Vcl.Menus,
     Vcl.ImgList, Vcl.ValEdit, Vcl.ActnMan, Vcl.ActnMenus, Vcl.ImageCollection,
     Vcl.VirtualImageList, Vcl.PlatformDefaultStyleActnCtrls, Vcl.StdStyleActnCtrls, Vcl.ActnCtrls, Vcl.Dialogs, Vcl.Graphics, Vcl.Clipbrd, Vcl.Imaging.jpeg, Vcl.Imaging.pngimage,
     VirtualTrees.BaseTree, VirtualTrees.BaseAncestorVCL, VirtualTrees, VirtualTrees.Types, VirtualTrees.AncestorVCL,
     uImageKit, uThumbEngine, uAbout, uProps, Vcl.BaseImageCollection, Winapi.Dwmapi;

const
  APP_TITLE       = '看图软件 PicView';
  WM_OPENFOLDER   = WM_APP + 11;
  MAX_VIEW_PIXELS = 30000000;
  THUMB_STEPS: array[0..4] of Integer = (64, 96, 128, 160, 192);
  { ImageList 固定槽位数: 0=占位图, 1=文件夹图标, 2=磁盘图标, 3=上级目录图标, 4..=LRU 缩略图。 列表只加载可见项, ImageList 不再随文件数量无限增长。 }
  PV_DARK_BG        = TColor($181818); { RGB(24, 24, 24)   main background }
  PV_DARK_BAR       = TColor($202020); { RGB(32, 32, 32)   menu / tool bar }
  PV_DARK_PANEL     = TColor($1C1C1C); { RGB(28, 28, 28)   panel headers }
  PV_DARK_SURFACE   = TColor($242120); { RGB(32, 33, 36)   lists / editors }
  PV_DARK_ACCENT    = TColor($5F3A1E); { RGB(30, 58, 95)   selection }
  PV_DARK_BORDER    = TColor($3A3A3A); { RGB(58, 58, 58)   separators }
  PV_DARK_TEXT_DIM  = TColor($A0A0A0); { RGB(160,160,160) disabled text }
  THUMB_SLOTS         = 256;
  THUMB_RESERVED      = 4;
  THUMB_PREFETCH_ROWS = 2;
  { 一轮定时器最多应用的缩略图张数: 缓存命中时会一次到货几十张, 分批应用才不会让主线程在一帧里做几十次位图转换。 }
  THUMB_APPLY_BUDGET = 32;
  VT_MARGIN          = 2;
  { 页签右上角关闭按钮的边长 }
  TAB_CLOSE_SIZE = 16;
  { 页签的高度与宽度 }
  TAB_HEIGHT = 30;
  TAB_WIDTH  = 132;
  { 右键菜单项额外增加的垂直高度(像素) }
  PV_MENU_ITEM_VPAD = 10;
  { ActionBar 弹出子菜单项额外增加的垂直高度(像素) }
  PV_SUBMENU_ITEM_VPAD = 12;
  { ActionBar 弹出子菜单项文字统一左边界(像素), 保证有/无图标项文字对齐 }
  PV_SUBMENU_TEXT_X = 44;
  { 菜单条首个按钮距窗体左边缘的间距(像素); 下拉弹窗 X 会跟随此值 }
  PV_MENU_HORZ_MARGIN = 8;
  { 取页签矩形用的 comctl32 消息 }
  TCM_FIRST       = $1300;
  TCM_GETITEMRECT = TCM_FIRST + 10;
  { 根目录: 浏览器顶层的"本机磁盘"列表。所有本地磁盘作为浏览区的根, 双击盘符即可进入该盘。 }
  DRIVES_ROOT  = '::Drives';
  DRIVES_LABEL = '计算机';

type
  TFileRec = record
    Name: string;
    Path: string;
    Size: Int64;
    Modified: TDateTime;
  end;

  TFolderRec = record
    Name: string;
    Path: string;
    IsParent: Boolean;
    IsDrive: Boolean;
  end;

  TZoomMode = (zmFit, zmActual, zmCustom);
  TSortMode = (smName, smSize, smDate, smType);
  TTabMode  = (tmBrowse, tmView);

  { 每个页签独立保存自己的文件夹、文件列表、当前图像与显示状态 }
  TTabInfo = class
  public
    Mode: TTabMode;
    CanClose: Boolean;   { 是否显示关闭按钮并允许关闭 }
    Sheet: TTabSheet;
    Caption: string;
    Folder: string;
    Files: TArray<TFileRec>;
    Folders: TArray<TFolderRec>;
    Index: Integer;
    Base: TBitmap;
    Wic: TWICImage;
    Rotation: Integer;
    Zoom: Double;
    ZoomMode: TZoomMode;
    LoadError: string;
    DecodeMs: Double;      { 解码用时(毫秒) }
    Thumbs: TArray<TBitmap>;
    ThumbIdx: Integer;
    constructor Create;
    destructor Destroy; override;
    procedure ClearThumbs;
    function CurrentPath: string;
  end;

  TfrmPicView = class(TForm)
    MenuMain: TActionMainMenuBar;
    ImageCollection1: TImageCollection;
    VirtualImageList1: TVirtualImageList;
    ActionManager1: TActionManager;
    PopupMenuBrowse: TPopupMenu;
    PopupMenuThumbs: TPopupMenu;
    PopupMenuTabs: TPopupMenu;
    PopupMenuView: TPopupMenu;
    ImageListBrowse: TImageList;
    ImageListThumbs: TImageList;
    TimerThumbs: TTimer;
    TimerRepaint: TTimer;
    TimerSlide: TTimer;
    TimerHint: TTimer;
    OpenDialog1: TOpenDialog;
    FileOpenDialog1: TFileOpenDialog;
    SaveDialog1: TSaveDialog;
    miPbView: TMenuItem;
    miPbCopyPath: TMenuItem;
    miPbExplore: TMenuItem;
    miPbSep1: TMenuItem;
    miPbDelete: TMenuItem;
    miPbOpenFolder: TMenuItem;
    miPbSep0: TMenuItem;
    miPbProperties: TMenuItem;
    miPtCopyPath: TMenuItem;
    miPtExplore: TMenuItem;
    miPtSep1: TMenuItem;
    miPtDelete: TMenuItem;
    miPtSaveAs: TMenuItem;
    miPtProperties: TMenuItem;
    miTabNew: TMenuItem;
    miTabClose: TMenuItem;
    miTabCloseOthers: TMenuItem;
    miTabCloseAll: TMenuItem;
    miPvBack: TMenuItem;
    miPvSep1: TMenuItem;
    miPvPrev: TMenuItem;
    miPvNext: TMenuItem;
    miPvSep2: TMenuItem;
    miPvFit: TMenuItem;
    miPvActual: TMenuItem;
    miPvZoomIn: TMenuItem;
    miPvZoomOut: TMenuItem;
    miPvRotateCW: TMenuItem;
    miPvRotateCCW: TMenuItem;
    miPvSep3: TMenuItem;
    miPvSlide: TMenuItem;
    miPvFull: TMenuItem;
    miPvSep4: TMenuItem;
    miPvSaveAs: TMenuItem;
    miPvCopyImage: TMenuItem;
    miPvCopyPath: TMenuItem;
    miPvExplore: TMenuItem;
    miPvSep5: TMenuItem;
    miPvProperties: TMenuItem;
    miPvDelete: TMenuItem;
    miPvSep6: TMenuItem;
    miPvClose: TMenuItem;
    actOpenFolder: TAction;
    actOpenFile: TAction;
    actNewBrowseTab: TAction;
    actCloseTab: TAction;
    actCloseOthers: TAction;
    actCloseAll: TAction;
    actExit: TAction;
    actRefresh: TAction;
    actViewSelected: TAction;
    actBackToBrowse: TAction;
    actGo: TAction;
    actGoUp: TAction;
    actPrev: TAction;
    actNext: TAction;
    actFirst: TAction;
    actLast: TAction;
    actFit: TAction;
    actActual: TAction;
    actZoomIn: TAction;
    actZoomOut: TAction;
    actRotateCW: TAction;
    actRotateCCW: TAction;
    actSlideShow: TAction;
    actFullScreen: TAction;
    actDelete: TAction;
    actSaveAs: TAction;
    actCopyImage: TAction;
    actCopyPath: TAction;
    actExplore: TAction;
    actShowThumbs: TAction;
    actShowInfo: TAction;
    actShowStatus: TAction;
    actSortName: TAction;
    actSortSize: TAction;
    actSortDate: TAction;
    actSortType: TAction;
    actSize64: TAction;
    actSize96: TAction;
    actSize128: TAction;
    actSize160: TAction;
    actSize192: TAction;
    actThumbSmaller: TAction;
    actThumbBigger: TAction;
    actProperties: TAction;
    actComputer: TAction;
    actAbout: TAction;
    PanelToolBarHost: TPanel;
    PanelTabs: TPanel;
    PageControl1: TPageControl;
    ToolBarBrowse: TToolBar;
    tbBOpenFolder: TToolButton;
    tbBComputer: TToolButton;
    tbBOpenFile: TToolButton;
    tbBNewTab: TToolButton;
    tbBSep1: TToolButton;
    tbBUp: TToolButton;
    tbBRefresh: TToolButton;
    tbBSep2: TToolButton;
    tbBSmaller: TToolButton;
    tbBBigger: TToolButton;
    tbBSep3: TToolButton;
    tbBView: TToolButton;
    tbBSep4: TToolButton;
    tbBClose: TToolButton;
    tbBSep5: TToolButton;
    tbBAbout: TToolButton;
    ToolBarView: TToolBar;
    tbVBack: TToolButton;
    tbVPrev: TToolButton;
    tbVNext: TToolButton;
    tbVSep1: TToolButton;
    tbVFit: TToolButton;
    tbVActual: TToolButton;
    tbVZoomIn: TToolButton;
    tbVZoomOut: TToolButton;
    tbVSep2: TToolButton;
    tbVRotateCW: TToolButton;
    tbVRotateCCW: TToolButton;
    tbVSep3: TToolButton;
    tbVSlide: TToolButton;
    tbVFull: TToolButton;
    tbVSep4: TToolButton;
    tbVSaveAs: TToolButton;
    tbVDelete: TToolButton;
    tbVSep5: TToolButton;
    tbVClose: TToolButton;
    tbVSep6: TToolButton;
    tbVAbout: TToolButton;
    PanelAddress: TPanel;
    cbPath: TComboBox;
    btnGo: TButton;
    btnUp: TButton;
    PanelBody: TPanel;
    PanelRight: TPanel;
    PanelRightHead: TPanel;
    vleInfo: TValueListEditor;
    Splitter2: TSplitter;
    PanelCenter: TPanel;
    PanelBrowse: TPanel;
    PanelBrowseHead: TPanel;
    LabelThumbs: TLabel;
    cbThumbSize: TComboBox;
    LabelSort: TLabel;
    cbSort: TComboBox;
    LabelCount: TLabel;
    LabelBrowseHint: TLabel;
    lvBrowse: TVirtualStringTree;
    PanelView: TPanel;
    ScrollBoxViewer: TScrollBox;
    ImageMain: TImage;
    Splitter3: TSplitter;
    PanelThumbs: TPanel;
    PanelThumbsHead: TPanel;
    LabelFilm: TLabel;
    LabelFilmCount: TLabel;
    lvThumbs: TVirtualStringTree;
    PanelHint: TPanel;
    StatusBar1: TStatusBar;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure FormMouseWheel(Sender: TObject; Shift: TShiftState; WheelDelta: Integer; MousePos: TPoint; var Handled: Boolean);
    procedure PageControl1Change(Sender: TObject);
    procedure PageControl1MouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
    procedure PageControl1DrawTab(Control: TCustomTabControl; TabIndex: Integer; const Rect: TRect; Active: Boolean);
    procedure ApplyTabSize;
    function TabCloseRect(AIndex: Integer): TRect;
    procedure cbPathKeyPress(Sender: TObject; var Key: Char);
    procedure cbThumbSizeChange(Sender: TObject);
    procedure cbSortChange(Sender: TObject);
    procedure lvBrowseDblClick(Sender: TObject);
    procedure lvBrowseMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
    procedure PopupMenuBrowsePopup(Sender: TObject);
    procedure PvMenuItemMeasure(Sender: TObject; ACanvas: TCanvas; var Width, Height: Integer);
    procedure PvMenuItemDraw(Sender: TObject; ACanvas: TCanvas; ARect: TRect; State: TOwnerDrawState);
    procedure PvToolBarDraw(Sender: TToolBar; Button: TToolButton; State: TCustomDrawState; var DefaultDraw: Boolean);
    procedure SetupDarkPopup(AMenu: TPopupMenu);
    procedure ApplyDarkTheme;
    procedure EnableDarkTitleBar;
    procedure EnableNativeDarkMode;
    procedure PvMenuGetPopupClass(Sender: TObject; var PopupClass: TCustomPopupClass);
    procedure miPbOpenFolderClick(Sender: TObject);
    procedure ImageMainMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
    procedure ImageMainMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);
    procedure ImageMainMouseUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
    procedure ImageMainDblClick(Sender: TObject);
    procedure ScrollBoxViewerResize(Sender: TObject);
    procedure TimerThumbsTimer(Sender: TObject);
    procedure TimerRepaintTimer(Sender: TObject);
    procedure SetupVT(V: TVirtualStringTree);
    function VTCellW: Integer;
    function VTCellH: Integer;
    function VTCols(V: TVirtualStringTree): Integer;
    function VTRootCount(V: TVirtualStringTree; ATotal: Integer): Integer;
    function VTItemAt(V: TVirtualStringTree; X, Y: Integer): Integer;
    function VTSelected(V: TVirtualStringTree): Integer;
    procedure VTSetSelected(V: TVirtualStringTree; AIndex: Integer);
    function VTNodeOfRow(V: TVirtualStringTree; ARow: Integer): PVirtualNode;
    function VTVisibleRows(out AFirstRow, ALastRow: Integer): Boolean;
    function VTVisibleRange(out AFrom, ATo: Integer): Boolean;
    procedure VTListPaintCell(Sender: TBaseVirtualTree; TargetCanvas: TCanvas; Node: PVirtualNode; Column: TColumnIndex; CellPaintMode: TVTCellPaintMode; CellRect: TRect; var ContentRect: TRect);
    procedure VTGetHint(Sender: TBaseVirtualTree; Node: PVirtualNode; Column: TColumnIndex; var LineBreakStyle: TVTTooltipLineBreakStyle; var HintText: string);
    procedure VTListKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure VTListResize(Sender: TObject);
    procedure HandleBrowseSelect(I: Integer);
    procedure HandleThumbsSelect(I: Integer);
    procedure TimerSlideTimer(Sender: TObject);
    procedure TimerHintTimer(Sender: TObject);
    procedure actOpenFolderExecute(Sender: TObject);
    procedure actOpenFileExecute(Sender: TObject);
    procedure actNewBrowseTabExecute(Sender: TObject);
    procedure actCloseTabExecute(Sender: TObject);
    procedure actCloseOthersExecute(Sender: TObject);
    procedure actCloseAllExecute(Sender: TObject);
    procedure actExitExecute(Sender: TObject);
    procedure actRefreshExecute(Sender: TObject);
    procedure actViewSelectedExecute(Sender: TObject);
    procedure actBackToBrowseExecute(Sender: TObject);
    procedure actGoExecute(Sender: TObject);
    procedure actGoUpExecute(Sender: TObject);
    procedure actPrevExecute(Sender: TObject);
    procedure actNextExecute(Sender: TObject);
    procedure actFirstExecute(Sender: TObject);
    procedure actLastExecute(Sender: TObject);
    procedure actFitExecute(Sender: TObject);
    procedure actActualExecute(Sender: TObject);
    procedure actZoomInExecute(Sender: TObject);
    procedure actZoomOutExecute(Sender: TObject);
    procedure actRotateCWExecute(Sender: TObject);
    procedure actRotateCCWExecute(Sender: TObject);
    procedure actSlideShowExecute(Sender: TObject);
    procedure actFullScreenExecute(Sender: TObject);
    procedure actDeleteExecute(Sender: TObject);
    procedure actSaveAsExecute(Sender: TObject);
    procedure actCopyImageExecute(Sender: TObject);
    procedure actCopyPathExecute(Sender: TObject);
    procedure actExploreExecute(Sender: TObject);
    procedure actPanelsExecute(Sender: TObject);
    procedure actSortExecute(Sender: TObject);
    procedure actThumbSizeExecute(Sender: TObject);
    procedure actThumbStepExecute(Sender: TObject);
    procedure actPropertiesExecute(Sender: TObject);
    procedure actComputerExecute(Sender: TObject);
    procedure actAboutExecute(Sender: TObject);
  private
    FTabs: TList<TTabInfo>;
    FTab: TTabInfo;
    FIniFile: string;
    FFolder: string;
    FLoaded: Boolean;
    FUpdatingUI: Boolean;
    FSwitching: Boolean;
    FClosing: Boolean;
    FSelectingThumb: Boolean;
    FPendingFolder: string;
    FSelectedFolderPath: string;
    FFolderIconIdx: Integer;
    FDriveIconIdx: Integer;
    FUpIconIdx: Integer;
    FRebuilding: Boolean;
    FThumbEngine: TThumbEngine;
    FIndexSlot: TDictionary<Integer, Integer>;
    FThumbFailed: TDictionary<Integer, Boolean>;
    FThumbRequested: TDictionary<Integer, UInt64>;
    FCaptionCache: TDictionary<Integer, string>;
    FChangedIdx: TList<Integer>;
    FEvictedIdx: Integer;
    FMeasureBmp: TBitmap;
    FSlotOwner: TArray<Integer>;
    FSlotTick: TArray<Int64>;
    FSlotClock: Int64;
    FThumbGen: Int64;
    FLastTopIndex: Integer;
    FVisibleFrom: Integer;
    FVisibleTo: Integer;
    FSelBrowse: Integer;
    FSelThumbs: Integer;
    FNeedSubmit: Boolean;
    FFullScreen: Boolean;
    FSortMode: TSortMode;
    FZoomMode: TZoomMode;
    FThumbSize: Integer;
    FPlaceholderIdx: Integer;
    FDragging: Boolean;
    FDragLast: TPoint;
    FSaveBounds: TRect;
    FTabCloseRects: TArray<TRect>;
    procedure WMDropFiles(var Msg: TMessage); message WM_DROPFILES;
    procedure WMOpenFolder(var Msg: TMessage); message WM_OPENFOLDER;
    function CurrentPath: string;
    function NormalizePath(const APath: string): string;
    function IsDrivesRoot(const APath: string): Boolean;
    function IsDriveRootPath(const APath: string): Boolean;
    function FolderDisplayName(const APath: string): string;
    function ParentFolderOf(const APath: string): string;
    procedure EnumerateDrives(out AFolders: TArray<TFolderRec>);
    function TabOfPage(APage: TTabSheet): TTabInfo;
    function ThumbList: TImageList;
    function ThumbView: TVirtualStringTree;
    procedure LoadSettings;
    procedure SaveSettings;
    procedure AddPathHistory(const APath: string);
    procedure EnumerateDirectory(const ADir: string; out AFiles: TArray<TFileRec>; out AFolders: TArray<TFolderRec>);
    procedure SortFiles(var AFiles: TArray<TFileRec>);
    function IndexOfPath(const AFiles: TArray<TFileRec>; const APath: string): Integer;
    procedure RebuildTabFiles(ATab: TTabInfo; const APreferPath: string; AReloadImage: Boolean);
    procedure LoadFolderIntoTab(ATab: TTabInfo; const ADir: string; const ASelectFile: string);
    function AddTab(AMode: TTabMode; const AFolder, AFile: string): TTabInfo;
    procedure RemoveTab(ATab: TTabInfo);
    procedure CloseTab(ATab: TTabInfo);
    procedure ActivateTab(ATab: TTabInfo);
    procedure ApplyModeUI;
    procedure NormalizeTopBars;
    procedure ApplyMenuMode(AIsBrowse: Boolean);
    function ItemOffset: Integer;
    procedure EnterFolder(const APath: string);
    procedure PrepareThumbs;
    procedure ClearThumbsForAll;
    procedure SetThumbSize(ASize: Integer);
    procedure SyncSortActions;
    procedure SyncSizeActions;
    procedure SetSortMode(AMode: TSortMode);
    procedure ShowBrowseTab;
    procedure ShowViewTab;
    procedure SelectThumb(AIndex: Integer);
    procedure ResetThumbSlots;
    function AllocSlot(AIndex: Integer): Integer;
    procedure TouchSlot(ASlot: Integer);
    function ItemCaption(AIndex: Integer): string;
    function ItemImageIndex(AIndex: Integer): Integer;
    procedure SubmitVisibleThumbs;
    procedure ApplyThumbResult(const AResult: TThumbResult);
    procedure QueueThumbData(AIndex: Integer);
    procedure PruneRequested(AFrom, ATo: Integer);
    function FindBrowseTab(const AFolder: string): TTabInfo;
    function BrowseCaption(const ADir: string): string;
    function ShortCaption(const S: string): string;
    function ElideCaption(const S: string): string;
    procedure LoadCurrentImage;
    procedure ClearViewer;
    procedure ApplyZoom;
    procedure ZoomStep(AFactor: Double);
    procedure SetZoomMode(AMode: TZoomMode);
    procedure UpdateImagePosition;
    procedure UpdateInfo;
    procedure UpdateStatus;
    procedure UpdateCaption;
    procedure SetFullScreen(AOn: Boolean);
    procedure FlashHint(const AText: string);
    procedure DeleteToRecycleBin(const AFileName: string);
    procedure NextImage(ALoop: Boolean = False);
    procedure PrevImage(ALoop: Boolean = False);
  public
    procedure NavigateToFolder(AIndex: Integer);
    procedure OpenFolder(const APath: string; const ASelectFile: string = '');
    procedure OpenViewTab(const AFolder, AFile: string);
    procedure CloseActiveTab;
    function TabCount: Integer;
    function ActiveMode: TTabMode;
  end;

var
  frmPicView: TfrmPicView;

implementation

uses Vcl.StdActnMenus;

{$R *.dfm}

{ ActionBar 子菜单项垂直间距 }

type
  { 菜单项未设 ImageIndex，GetImageSize 返回 (0,0)，VirtualImageList 尺寸无效； 直接覆盖 CalcBounds 增加控件高度，文字/图标按实际 Height 居中 }
  TPvMenuItem = class(TStandardMenuItem)
  protected
    procedure CalcBounds; override;
    procedure DrawSeparator(const Offset: Integer); override;
  end;

  { 让本 popup 的菜单项与各级子 popup 都使用上面的自定义类 }
  TPvMenuPopup = class(TStandardMenuPopup)
  private
    procedure PvGetControlClass(Sender: TCustomActionBar; AnItem: TActionClient;
      var ControlClass: TCustomActionControlClass);
    procedure PvGetPopupClass(Sender: TObject; var PopupClass: TCustomPopupClass);
  public
    constructor Create(AOwner: TComponent); override;
  end;

procedure TPvMenuItem.CalcBounds;
var
  R: TRect;
  Delta: Integer;
begin
  inherited CalcBounds;
  { 分隔线保持系统原高，不跟随普通菜单项一起加高 }
  if (Height <= 0) or Separator then Exit;

  CalcLayout;  { 图标按新高度重新垂直居中 }

  { VCL 对有图标项把 TextBounds 放在图标右侧, 无图标项则顶到最左, 导致文字不对齐。
    这里强制所有项的文字左边界统一到 PV_SUBMENU_TEXT_X, 并同步调整宽度。
    图标仍由 VCL 自动绘制(GlyphPos 不动), 位置在文字左侧。 }
  R := TextBounds;
  Delta := PV_SUBMENU_TEXT_X - R.Left;
  if Delta <> 0 then
  begin
    OffsetRect(R, Delta, 0);
    TextBounds := R;
    Width := Width + Delta;
  end;
  SetBounds(Left, Top, Width, Height + PV_SUBMENU_ITEM_VPAD);
end;

procedure TPvMenuItem.DrawSeparator(const Offset: Integer);
var
  CY: Integer;
begin
  CY := ClientHeight div 2;
  Canvas.Pen.Color := PV_DARK_BORDER;
  Canvas.Pen.Width := 1;
  Canvas.MoveTo(13, CY);
  Canvas.LineTo(ClientWidth - 13, CY);
end;

constructor TPvMenuPopup.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  OnGetControlClass := PvGetControlClass;
  OnGetPopupClass := PvGetPopupClass;
end;

procedure TPvMenuPopup.PvGetControlClass(Sender: TCustomActionBar; AnItem: TActionClient; var ControlClass: TCustomActionControlClass);
begin
  if ControlClass = TStandardMenuItem then
    ControlClass := TPvMenuItem;
end;

procedure TPvMenuPopup.PvGetPopupClass(Sender: TObject;
  var PopupClass: TCustomPopupClass);
begin
  PopupClass := TPvMenuPopup;
end;

procedure TfrmPicView.PvMenuGetPopupClass(Sender: TObject;
  var PopupClass: TCustomPopupClass);
begin
  PopupClass := TPvMenuPopup;
end;

{ TTabInfo }

constructor TTabInfo.Create;
begin
  inherited Create;
  Mode     := tmBrowse;
  CanClose := True;
  Sheet    := nil;
  Index    := -1;
  Rotation := 0;
  Zoom     := 1;
  ZoomMode := zmFit;
  ThumbIdx := 0;
  Base     := nil;
  Wic      := nil;
  DecodeMs := 0;
end;

destructor TTabInfo.Destroy;
begin
  ClearThumbs;
  FreeAndNil(Wic);
  FreeAndNil(Base);
  SetLength(Files, 0);
  inherited Destroy;
end;

procedure TTabInfo.ClearThumbs;
var
  I: Integer;
begin
  for I := 0 to High(Thumbs) do FreeAndNil(Thumbs[I]);
  SetLength(Thumbs, 0);
  ThumbIdx := 0;
end;

function TTabInfo.CurrentPath: string;
begin
  if (Index >= 0) and (Index <= High(Files)) then
    Result := Files[Index].Path
  else
    Result := '';
end;

{ 通用工具 }

function TfrmPicView.CurrentPath: string;
begin
  if (FTab <> nil) and (FTab.Mode = tmBrowse) and (FSelectedFolderPath <> '') then
    Result := FSelectedFolderPath
  else if FTab <> nil then
    Result := FTab.CurrentPath
  else
    Result := '';
end;

function TfrmPicView.NormalizePath(const APath: string): string;
begin
  if APath = '' then Exit('');
  if IsDrivesRoot(APath) then Exit(DRIVES_ROOT);
  try
    Result := ExpandFileName(APath);
  except
    Result := APath;
  end;
end;

{ 根目录 ("::Drives") = 本机磁盘列表 }
function TfrmPicView.IsDrivesRoot(const APath: string): Boolean;
begin
  Result := SameText(APath, DRIVES_ROOT);
end;

{ 磁盘根目录 }
function TfrmPicView.IsDriveRootPath(const APath: string): Boolean;
begin
  Result := (Length(APath) = 3) and (APath[3] = '\') and (APath[1] >= 'A') and (APath[1] <= 'Z');
end;

{ 路径的界面显示名: 根目录显示为"计算机" }
function TfrmPicView.FolderDisplayName(const APath: string): string;
begin
  if IsDrivesRoot(APath) then
    Result := DRIVES_LABEL
  else
    Result := APath;
end;

{ 上一级目录 }
function TfrmPicView.ParentFolderOf(const APath: string): string;
begin
  Result := '';
  if APath = '' then Exit;
  if IsDrivesRoot(APath) then Exit;
  if IsDriveRootPath(APath) then
  begin
    Result := DRIVES_ROOT;
    Exit;
  end;
  
  var P := TPath.GetDirectoryName(ExcludeTrailingPathDelimiter(APath));
  if (P <> '') and TDirectory.Exists(P) then
  begin
    Result := P;
    Exit;
  end;
  
  { 上一级就是根目录 }
  if (Length(APath) >= 2) and (APath[2] = ':') then Result := DRIVES_ROOT;
end;

{ 枚举本机磁盘, 作为浏览器的根目录: 只收本地固定磁盘 }
procedure TfrmPicView.EnumerateDrives(out AFolders: TArray<TFolderRec>);
var
  Mask: DWORD;
  I: Integer;
  Letter, Root, VolLabel, Name: string;
  Rec: TFolderRec;
  VolFS, VolBuf: array[0..261] of Char;
  Serial, MaxComp, Flags: DWORD;
begin
  SetLength(AFolders, 0);
  Mask := GetLogicalDrives;
  for I := 0 to 25 do
    if (Mask and (DWORD(1) shl I)) <> 0 then
    begin
      Letter := Chr(Ord('A') + I);
      Root := Letter + ':\';
      if GetDriveTypeW(PWideChar(Root)) <> DRIVE_FIXED then Continue;
      VolLabel := '';
      if GetVolumeInformationW(PWideChar(Root), @VolBuf[0], 261, @Serial, MaxComp, Flags, @VolFS[0], 261) then VolLabel := string(PWideChar(@VolBuf[0]));
      if VolLabel = '' then
        Name := Letter + ':'
      else
        Name := Letter + ': ' + VolLabel;
      Rec.Name := Name;
      Rec.Path := Root;
      Rec.IsParent := False;
      Rec.IsDrive := True;
      SetLength(AFolders, Length(AFolders) + 1);
      AFolders[High(AFolders)] := Rec;
    end;
end;

function TfrmPicView.TabOfPage(APage: TTabSheet): TTabInfo;
begin
  if APage <> nil then
    Result := TTabInfo(Pointer(APage.Tag))
  else
    Result := nil;
end;

function TfrmPicView.ThumbList: TImageList;
begin
  if (FTab <> nil) and (FTab.Mode = tmBrowse) then
    Result := ImageListBrowse
  else
    Result := ImageListThumbs;
end;

function TfrmPicView.ThumbView: TVirtualStringTree;
begin
  if (FTab <> nil) and (FTab.Mode = tmBrowse) then
    Result := lvBrowse
  else
    Result := lvThumbs;
end;

function TfrmPicView.ShortCaption(const S: string): string;
begin
  if Length(S) > 18 then
    Result := Copy(S, 1, 16) + '..'
  else
    Result := S;
end;

{ 按格子实际像素宽度截断文件名: 保留开头与扩展名, 中间用 ... 省略 }
function TfrmPicView.ElideCaption(const S: string): string;
var
  C: TCanvas;
  Ext, Stem, Tail, Test: string;
  MaxW, Lo, Hi, Mid: Integer;
begin
  Result := S;
  if (S = '') or (FThumbSize < 16) then Exit;
  
  MaxW := FThumbSize + 20 - 12;      { 与 ListView_SetIconSpacing 横距一致 }
  if Screen.PixelsPerInch > 96 then MaxW := MulDiv(MaxW, 96, Screen.PixelsPerInch);
  if MaxW < 24 then MaxW := 24;
  if FMeasureBmp = nil then
  begin
    FMeasureBmp := TBitmap.Create;
    FMeasureBmp.Canvas.Font.Assign(lvBrowse.Font);
  end;
  try
    C := FMeasureBmp.Canvas;
    if C.TextWidth(S) <= MaxW then Exit;
    Ext := ExtractFileExt(S);
    Stem := Copy(S, 1, Length(S) - Length(Ext));
    Tail := '...' + Ext;
    if C.TextWidth(Tail) > MaxW then
    begin
      Result := '...';
      Exit;
    end;
	
    Lo := 0;
    Hi := Length(Stem);
    while Lo < Hi do
    begin
      Mid := (Lo + Hi + 1) div 2;
      Test := Copy(Stem, 1, Mid) + Tail;
      if C.TextWidth(Test) <= MaxW then
        Lo := Mid
      else
        Hi := Mid - 1;
    end;
    Result := Copy(Stem, 1, Lo) + Tail;
  finally
    { 测量位图常驻复用, 列表每次绘制都要量宽 }
  end;
end;

function TfrmPicView.BrowseCaption(const ADir: string): string;
var
  S: string;
begin
  if IsDrivesRoot(ADir) then  Exit(DRIVES_LABEL);
  S := StringReplace(ADir, '/', '\', [rfReplaceAll]);
  S := ExtractFileName(ExcludeTrailingPathDelimiter(S));
  if S = '' then S := ADir;
  Result := '浏览: ' + ShortCaption(S);
end;

procedure TfrmPicView.DeleteToRecycleBin(const AFileName: string);
var
  Op  : TSHFileOpStruct;
  From: string;
begin
  FillChar(Op, SizeOf(Op), 0);
  From      := AFileName + #0#0;
  Op.Wnd    := Handle;
  Op.wFunc  := FO_DELETE;
  Op.pFrom  := PChar(From);
  Op.fFlags := FOF_ALLOWUNDO or FOF_NOCONFIRMATION or FOF_SILENT or FOF_NOERRORUI;
  SHFileOperation(Op);
end;

procedure TfrmPicView.AddPathHistory(const APath: string);
begin
  var D := FolderDisplayName(APath);
  if cbPath.Items.IndexOf(D) < 0 then cbPath.Items.Insert(0, D);
  while cbPath.Items.Count > 15 do cbPath.Items.Delete(cbPath.Items.Count - 1);
  cbPath.Text := D;
end;

procedure TfrmPicView.EnumerateDirectory(const ADir: string; out AFiles: TArray<TFileRec>; out AFolders: TArray<TFolderRec>);
var
  H: THandle;
  FD: TWin32FindDataW;
  Files: TArray<TFileRec>;
  Folders: TArray<TFolderRec>;
  FRec: TFileRec;
  DRec: TFolderRec;
  NF, ND, CapF, CapD: Integer;
  Base, Nm, Parent: string;
  LFT: TFileTime;
  ST: TSystemTime;
begin
  { 文件与子目录在同一次 FindFirstFileW 遍历中取回 }
  if IsDrivesRoot(ADir) then
  begin
    { 根目录: 只列出本机磁盘, 没有上级, 也没有文件 }
    SetLength(AFiles, 0);
    EnumerateDrives(AFolders);
    Exit;
  end;
  
  NF := 0; CapF := 1024;
  ND := 0; CapD := 64;
  SetLength(Files, CapF);
  SetLength(Folders, CapD);
  Base := IncludeTrailingPathDelimiter(ADir);
  Parent := ParentFolderOf(ADir);
  if Parent <> '' then
  begin
    DRec.Name := '..';
    DRec.Path := Parent;
    DRec.IsParent := True;
    DRec.IsDrive := False;
    Folders[ND] := DRec;
    Inc(ND);
  end;
  H := FindFirstFileW(PWideChar(Base + '*'), FD);
  if H <> INVALID_HANDLE_VALUE then
  try
    repeat
      Nm := string(PWideChar(@FD.cFileName[0]));
      if (Nm = '') or (Nm = '.') or (Nm = '..') then Continue;
      if (FD.dwFileAttributes and FILE_ATTRIBUTE_DIRECTORY) <> 0 then
      begin
        if ND = CapD then
        begin
          CapD := CapD * 2;
          SetLength(Folders, CapD);
        end;
        DRec.Name := Nm;
        DRec.Path := Base + Nm;
        DRec.IsParent := False;
        DRec.IsDrive := False;
        Folders[ND] := DRec;
        Inc(ND);
      end
      else if IsImageFile(Nm) then
      begin
        if NF = CapF then
        begin
          CapF := CapF * 2;
          SetLength(Files, CapF);
        end;
        FRec.Name := Nm;
        FRec.Path := Base + Nm;
        FRec.Size := (Int64(FD.nFileSizeHigh) shl 32) or Int64(FD.nFileSizeLow);
        FRec.Modified := 0;
        if FileTimeToLocalFileTime(FD.ftLastWriteTime, LFT) then
          if FileTimeToSystemTime(LFT, ST) then
            try
              FRec.Modified := EncodeDate(ST.wYear, ST.wMonth, ST.wDay) + EncodeTime(ST.wHour, ST.wMinute, ST.wSecond, ST.wMilliseconds);
            except
              FRec.Modified := 0;
            end;
        Files[NF] := FRec;
        Inc(NF);
      end;
    until not FindNextFileW(H, FD);
  finally
    Winapi.Windows.FindClose(H);
  end;
  SetLength(Files, NF);
  SetLength(Folders, ND);
  SortFiles(Files);
  if ND > 1 then
    TArray.Sort<TFolderRec>(Folders, TComparer<TFolderRec>.Construct(
      function(const L, R: TFolderRec): Integer
      begin
        if L.IsParent then Result := -1
        else if R.IsParent then Result := 1
        else Result := CompareText(L.Name, R.Name);
      end));
  AFiles := Files;
  AFolders := Folders;
end;

procedure TfrmPicView.SortFiles(var AFiles: TArray<TFileRec>);
begin
  TArray.Sort<TFileRec>(AFiles, TComparer<TFileRec>.Construct(
    function(const L, R: TFileRec): Integer
    begin
      case FSortMode of
        smSize:
          begin
            if L.Size < R.Size then Result := -1
            else if L.Size > R.Size then Result := 1
            else Result := CompareText(L.Name, R.Name);
          end;
        smDate:
          begin
            if L.Modified < R.Modified then Result := -1
            else if L.Modified > R.Modified then Result := 1
            else Result := CompareText(L.Name, R.Name);
          end;
        smType:
          begin
            Result := CompareText(ExtractFileExt(L.Name), ExtractFileExt(R.Name));
            if Result = 0 then
              Result := CompareText(L.Name, R.Name);
          end;
      else
        Result := CompareText(L.Name, R.Name);
      end;
    end));
end;

function TfrmPicView.IndexOfPath(const AFiles: TArray<TFileRec>; const APath: string): Integer;
var
  I: Integer;
begin
  Result := -1;
  if APath = '' then Exit;
  
  for I := 0 to High(AFiles) do
    if SameText(AFiles[I].Path, APath) or SameText(AFiles[I].Name, APath) then Exit(I);
  for I := 0 to High(AFiles) do
    if SameText(AFiles[I].Name, ExtractFileName(StringReplace(APath, '/', '\', [rfReplaceAll]))) then Exit(I);
end;

procedure TfrmPicView.RebuildTabFiles(ATab: TTabInfo; const APreferPath: string; AReloadImage: Boolean);
var
  Keep: string;
begin
  if ATab = nil then Exit;
  
  Keep := APreferPath;
  if Keep = '' then Keep := ATab.CurrentPath;
  EnumerateDirectory(ATab.Folder, ATab.Files, ATab.Folders);
  ATab.ClearThumbs;
  ATab.Index := IndexOfPath(ATab.Files, Keep);
  if ATab.Index < 0 then
  begin
    if Length(ATab.Files) > 0 then
      ATab.Index := 0
    else
      ATab.Index := -1;
  end;
  if AReloadImage then
  begin
    FreeAndNil(ATab.Wic);
    FreeAndNil(ATab.Base);
    ATab.Rotation := 0;
    ATab.LoadError := '';
  end;
end;

procedure TfrmPicView.LoadFolderIntoTab(ATab: TTabInfo; const ADir: string; const ASelectFile: string);
var
  D: string;
  Idx: Integer;
begin
  if ATab = nil then Exit;
  
  D := Trim(ADir);
  if D = '' then Exit;
  
  if IsDrivesRoot(D) then
  begin
    { 根目录: 本机磁盘列表 }
    FFolder := D;
    ATab.Mode := tmBrowse;
    ATab.Folder := D;
    FreeAndNil(ATab.Wic);
    FreeAndNil(ATab.Base);
    ATab.Rotation := 0;
    EnumerateDirectory(D, ATab.Files, ATab.Folders);
    ATab.ClearThumbs;
    ATab.Index := -1;
    ATab.Caption := DRIVES_LABEL;
    if ATab.Sheet <> nil then ATab.Sheet.Caption := ATab.Caption;
    AddPathHistory(D);
    Exit;
  end;
  
  D := ExpandFileName(D);
  if not TDirectory.Exists(D) then
  begin
    ShowMessage('文件夹不存在: ' + D);
    Exit;
  end;
  
  FFolder := D;
  ATab.Mode := tmBrowse;
  ATab.Folder := D;
  FreeAndNil(ATab.Wic);
  FreeAndNil(ATab.Base);
  ATab.Rotation := 0;
  EnumerateDirectory(D, ATab.Files, ATab.Folders);
  ATab.ClearThumbs;
  Idx := IndexOfPath(ATab.Files, ASelectFile);
  if Idx < 0 then
  begin
    if Length(ATab.Files) > 0 then
      Idx := 0
    else
      Idx := -1;
  end;
  ATab.Index := Idx;
  ATab.Caption := BrowseCaption(D);
  if ATab.Sheet <> nil then ATab.Sheet.Caption := ATab.Caption;
  AddPathHistory(D);
end;

{ 设置 }

procedure TfrmPicView.LoadSettings;
begin
  FIniFile := ChangeFileExt(Application.ExeName, '.ini');
  var Ini := TIniFile.Create(FIniFile);
  try
    FFolder := Ini.ReadString('General', 'LastFolder', TPath.GetPicturesPath);
    FThumbSize := Ini.ReadInteger('General', 'ThumbSize', 128);
    if not (FThumbSize in [64, 96, 128, 160, 192]) then FThumbSize := 128;
    FSortMode := TSortMode(Ini.ReadInteger('General', 'Sort', 0));
    if Ord(FSortMode) > Ord(smType) then FSortMode := smName;
    FZoomMode := TZoomMode(Ini.ReadInteger('General', 'Zoom', 0));
    if Ord(FZoomMode) > Ord(zmCustom) then FZoomMode := zmFit;
    if FZoomMode = zmCustom then FZoomMode := zmFit;

    FUpdatingUI := True;
    try
      cbThumbSize.ItemIndex := cbThumbSize.Items.IndexOf(IntToStr(FThumbSize));
      if cbThumbSize.ItemIndex < 0 then cbThumbSize.ItemIndex := 2;
      cbSort.ItemIndex := Ord(FSortMode);
    finally
      FUpdatingUI := False;
    end;
    SyncSortActions;
    SyncSizeActions;

    actShowStatus.Checked := Ini.ReadBool('Panels', 'Status', True);
    actShowThumbs.Checked := False;
    actShowInfo.Checked   := False;

    var L := Ini.ReadInteger('Window', 'Left', -1);
    var T := Ini.ReadInteger('Window', 'Top', -1);
    var W := Ini.ReadInteger('Window', 'Width', 0);
    var H := Ini.ReadInteger('Window', 'Height', 0);
    if (W > 600) and (H > 400) and (L > -1000) and (T > -1000) then
    begin
      if L + W > Screen.WorkAreaRect.Right then L := Screen.WorkAreaRect.Right - W;
      if T + H > Screen.WorkAreaRect.Bottom then T := Screen.WorkAreaRect.Bottom - H;
      if L < Screen.WorkAreaRect.Left then L := Screen.WorkAreaRect.Left;
      if T < Screen.WorkAreaRect.Top then T := Screen.WorkAreaRect.Top;
      SetBounds(L, T, W, H);
    end;
  finally
    Ini.Free;
  end;
end;

procedure TfrmPicView.SaveSettings;
begin
  var Ini := TIniFile.Create(FIniFile);
  try
    Ini.WriteString('General', 'LastFolder', FFolder);
    Ini.WriteInteger('General', 'ThumbSize', FThumbSize);
    Ini.WriteInteger('General', 'Sort', Ord(FSortMode));
    Ini.WriteInteger('General', 'Zoom', Ord(FZoomMode));
    Ini.WriteBool('Panels', 'Status', actShowStatus.Checked);
    if not FFullScreen then
    begin
      Ini.WriteInteger('Window', 'Left', Left);
      Ini.WriteInteger('Window', 'Top', Top);
      Ini.WriteInteger('Window', 'Width', Width);
      Ini.WriteInteger('Window', 'Height', Height);
    end;
  finally
    Ini.Free;
  end;
end;

procedure TfrmPicView.SyncSortActions;
begin
  actSortName.Checked := FSortMode = smName;
  actSortSize.Checked := FSortMode = smSize;
  actSortDate.Checked := FSortMode = smDate;
  actSortType.Checked := FSortMode = smType;
end;

procedure TfrmPicView.SyncSizeActions;
begin
  actSize64.Checked := FThumbSize = 64;
  actSize96.Checked := FThumbSize = 96;
  actSize128.Checked := FThumbSize = 128;
  actSize160.Checked := FThumbSize = 160;
  actSize192.Checked := FThumbSize = 192;
end;

procedure TfrmPicView.SetSortMode(AMode: TSortMode);
var
  T: TTabInfo;
begin
  FSortMode := AMode;
  FUpdatingUI := True;
  try
    cbSort.ItemIndex := Ord(AMode);
  finally
    FUpdatingUI := False;
  end;
  SyncSortActions;
  for T in FTabs do RebuildTabFiles(T, T.CurrentPath, False);
  if FTab <> nil then ActivateTab(FTab);
end;

{ 页签 }

function TfrmPicView.AddTab(AMode: TTabMode; const AFolder, AFile: string): TTabInfo;
begin
  var Dir    := NormalizePath(AFolder);
  var F      := NormalizePath(AFile);
  FSwitching := True;
  try
    var Tab      := TTabInfo.Create;
    Tab.Mode     := AMode;
    Tab.Folder   := Dir;
    Tab.ZoomMode := FZoomMode;
    Tab.Zoom := 1;
    EnumerateDirectory(Dir, Tab.Files, Tab.Folders);
    Tab.Index := 0;
    if AMode = tmView then
    begin
      Tab.Index := IndexOfPath(Tab.Files, F);
      if Tab.Index < 0 then
        if Length(Tab.Files) > 0 then
          Tab.Index := 0
        else
          Tab.Index := -1;
      Tab.Caption := ShortCaption(ExtractFileName(F));
    end
    else
    begin
      Tab.Caption := BrowseCaption(Dir);
      if Length(Tab.Files) = 0 then
        Tab.Index := -1;
    end;
    if Dir <> '' then
      FFolder := Dir;

    var Sheet         := TTabSheet.Create(Self);
    Sheet.PageControl := PageControl1;
    Sheet.Caption     := Tab.Caption;
    Sheet.Tag         := NativeInt(Pointer(Tab));
    Tab.Sheet         := Sheet;
    FTabs.Add(Tab);
    ApplyTabSize;
    Result := Tab;
  finally
    FSwitching := False;
  end;
end;

procedure TfrmPicView.RemoveTab(ATab: TTabInfo);
begin
  if ATab = nil then Exit;
  
  FClosing := True;
  try
    FTabs.Remove(ATab);
    if ATab.Sheet <> nil then FreeAndNil(ATab.Sheet);
    if FTab = ATab then FTab := nil;
    ATab.Free;
  finally
    FClosing := False;
  end;
end;

procedure TfrmPicView.CloseTab(ATab: TTabInfo);
var
  T: TTabInfo;
begin
  if ATab = nil then Exit;
  
  if not ATab.CanClose then
  begin
    { 根浏览页签: 不给关闭按钮, 也不允许关闭 }
    StatusBar1.Panels[4].Text := '根浏览页签不能关闭';
    Exit;
  end;
  
  if FTabs.Count <= 1 then
  begin
    { 唯一的页签: 先补一个不可关闭的浏览页签 }
    T := AddTab(tmBrowse, ATab.Folder, '');
    T.CanClose := False;
  end;
  RemoveTab(ATab);
  ActivateTab(TabOfPage(PageControl1.ActivePage));
end;

procedure TfrmPicView.PageControl1MouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
var
  Idx: Integer;
  T: TTabInfo;
  R: TRect;
begin
  Idx := PageControl1.IndexOfTabAt(X, Y);
  if (Idx < 0) or (Idx >= PageControl1.PageCount) then Exit;
  
  T := TabOfPage(PageControl1.Pages[Idx]);
  if T = nil then Exit;
  
  if Button = mbLeft then
  begin
    { 点在页签右上角的关闭按钮上: 关闭该查看页签 }
    R := TabCloseRect(Idx);
    if (R.Right > R.Left) and PtInRect(R, Point(X, Y)) then
    begin
      CloseTab(T);
      Exit;
    end;
  end;
  
  if Button = mbMiddle then
    CloseTab(T)
  else if (Button = mbLeft) and (T <> FTab) then
    ActivateTab(T);
end;

{ 页签关闭按钮的位置 (自绘时缓存); 不可关闭的页签返回空矩形 }
function TfrmPicView.TabCloseRect(AIndex: Integer): TRect;
begin
  Result := TRect.Create(0, 0, 0, 0);
  if (AIndex < 0) or (AIndex >= Length(FTabCloseRects)) then Exit;
  Result := FTabCloseRects[AIndex];
end;

{ 自绘页签: 深色底板 + 标题 + (查看页签才有) 关闭按钮 }
procedure TfrmPicView.PageControl1DrawTab(Control: TCustomTabControl; TabIndex: Integer; const Rect: TRect; Active: Boolean);
var
  T: TTabInfo;
  S: string;
  R: TRect;
  CX, CY, W, Reserve: Integer;
begin
  if (TabIndex < 0) or (TabIndex >= PageControl1.PageCount) then Exit;
  if Length(FTabCloseRects) < PageControl1.PageCount then SetLength(FTabCloseRects, PageControl1.PageCount);
  FTabCloseRects[TabIndex] := TRect.Create(0, 0, 0, 0);
  T := TabOfPage(PageControl1.Pages[TabIndex]);
  if T = nil then Exit;
  S := T.Caption;
  R := Rect;

  { 底板 }
  Control.Canvas.Brush.Style := bsSolid;
  Control.Canvas.Pen.Width := 1;
  if Active then
  begin
    Control.Canvas.Brush.Color := RGB(32, 58, 92);
    Control.Canvas.Pen.Color := RGB(56, 104, 160);
  end
  else
  begin
    Control.Canvas.Brush.Color := RGB(42, 46, 53);
    Control.Canvas.Pen.Color := RGB(56, 61, 68);
  end;
  Control.Canvas.RoundRect(R.Left + 1, R.Top, R.Right - 1, R.Bottom - 1, 5, 5);

  { 关闭按钮: 除根浏览页签外, 其它页签都有 }
  Reserve := 0;
  if T.CanClose then
  begin
    Reserve := TAB_CLOSE_SIZE + 8;
    CX := R.Right - TAB_CLOSE_SIZE - 8;
    CY := (R.Top + R.Bottom) div 2;
    W := Max(4, TAB_CLOSE_SIZE div 3);
    Control.Canvas.Pen.Color := RGB(186, 192, 202);
    Control.Canvas.Pen.Width := 2;
    Control.Canvas.MoveTo(CX - W, CY - W);
    Control.Canvas.LineTo(CX + W, CY + W);
    Control.Canvas.MoveTo(CX + W, CY - W);
    Control.Canvas.LineTo(CX - W, CY + W);
    FTabCloseRects[TabIndex] := TRect.Create(CX - TAB_CLOSE_SIZE div 2 - 2,
      CY - TAB_CLOSE_SIZE div 2 - 2, CX + TAB_CLOSE_SIZE div 2 + 2,
      CY + TAB_CLOSE_SIZE div 2 + 2);
  end;

  { 标题 }
  Control.Canvas.Font.Color := clWhite;
  R.Left := R.Left + 8;
  R.Right := R.Right - 8 - Reserve;
  DrawTextW(Control.Canvas.Handle, PWideChar(S), Length(S), R, DT_CENTER or DT_VCENTER or DT_SINGLELINE or DT_END_ELLIPSIS or DT_NOPREFIX);
end;

{ 页签加大: TCM_SETITEMSIZE 只有在页签建好之后才有效, 所以放在 AddTab 里做 }
procedure TfrmPicView.ApplyTabSize;
begin
  if not PageControl1.HandleAllocated then Exit;

  PageControl1.TabWidth := 0;      { 先复位, 保证重新按固定宽度创建 }
  PageControl1.TabWidth := TAB_WIDTH;
  PageControl1.TabHeight := TAB_HEIGHT;
end;

procedure TfrmPicView.PageControl1Change(Sender: TObject);
begin
  if (not FLoaded) or FSwitching or FClosing then Exit;
  ActivateTab(TabOfPage(PageControl1.ActivePage));
end;

procedure TfrmPicView.ActivateTab(ATab: TTabInfo);
begin
  if ATab = nil then Exit;
  FSwitching := True;
  try
    if PageControl1.ActivePage <> ATab.Sheet then PageControl1.ActivePage := ATab.Sheet;
  finally
    FSwitching := False;
  end;
  FTab                := ATab;
  FFolder             := ATab.Folder;
  FSelectedFolderPath := '';
  ApplyModeUI;
  if ATab.Mode = tmBrowse then
    ShowBrowseTab
  else
    ShowViewTab;
  UpdateCaption;
end;

{ 单一菜单条按条目 Tag 决定显隐: Tag bit0=浏览模式显示, bit1=查看模式显示。
  只改条目自己的 Visible, 不动 Action.Visible -- 后者会连带禁用快捷键,
  例如浏览模式下若把"全屏"动作隐藏, F11 也会跟着失效。 
}
procedure TfrmPicView.ApplyMenuMode(AIsBrowse: Boolean);

  { 隐藏两端没有可见菜单项的分隔线, 避免模式切换后多条分隔线连成一片 }
  procedure CollapseSeparators(Clients: TActionClients);
  var
    I, J: Integer;
    Found: Boolean;
  begin
    for I := 0 to Clients.Count - 1 do
    begin
      if (not Clients[I].Visible) or (Clients[I].Caption <> '-') then Continue;

      Found := False;
      for J := I - 1 downto 0 do
        if Clients[J].Visible and (Clients[J].Caption <> '-') then
        begin
          Found := True;
          Break;
        end;
      if not Found then
      begin
        Clients[I].Visible := False;
        Continue;
      end;

      Found := False;
      for J := I + 1 to Clients.Count - 1 do
        if Clients[J].Visible then
        begin
          Found := Clients[J].Caption <> '-';
          Break;
        end;
      if not Found then Clients[I].Visible := False;
    end;
  end;

  procedure Apply(Clients: TActionClients);
  var
    I, Bit: Integer;
    It: TActionClientItem;
  begin
    for I := 0 to Clients.Count - 1 do
    begin
      It := Clients[I];
      if It.Items.Count > 0 then Apply(It.Items);
      if It.Tag = 0 then
      begin
        It.Visible := True;   { 分隔线先恢复, 最后统一折叠 }
        Continue;
      end;
      if AIsBrowse then Bit := 1 else Bit := 2;
      It.Visible := (It.Tag and Bit) <> 0;
    end;
    CollapseSeparators(Clients);
  end;

begin
  MenuMain.Visible := True;
  if ActionManager1.ActionBars.Count = 0 then Exit;
  Apply(TActionClientItem(ActionManager1.ActionBars[0]).Items);
end;

procedure TfrmPicView.ApplyModeUI;
var
  IsBrowse: Boolean;
begin
  if (FTab = nil) or FFullScreen then Exit;
  
  IsBrowse := FTab.Mode = tmBrowse;
  ApplyMenuMode(IsBrowse);
  PanelToolBarHost.Visible := True;
  ToolBarBrowse.Visible := IsBrowse;
  ToolBarView.Visible := not IsBrowse;
  PanelAddress.Visible := IsBrowse;
  PanelTabs.Visible := True;
  StatusBar1.Visible := actShowStatus.Checked;

  { 浏览模式不再显示右侧栏; 查看模式由"图像信息"开关控制 }
  PanelRight.Visible := (not IsBrowse) and actShowInfo.Checked;
  PanelRightHead.Caption := ' 图像信息';
  vleInfo.Visible        := True;
  Splitter2.Visible      := PanelRight.Visible;
  PanelBrowse.Visible    := IsBrowse;
  PanelView.Visible      := not IsBrowse;
  PanelThumbs.Visible    := (not IsBrowse) and actShowThumbs.Checked;
  Splitter3.Visible      := PanelThumbs.Visible;
  NormalizeTopBars;
end;

{ Delphi 的 BUG。
  强制顶部各条按 菜单栏-工具栏-页签栏-地址栏 的顺序排列。
  VCL 对 alTop 控件按 Top 排序, 全屏切换反复隐藏/显示后 MenuMain 的 Top
  会变得与工具栏相同甚至更大, 导致工具栏被排到菜单栏上方。 } 
procedure TfrmPicView.NormalizeTopBars;
begin
  DisableAlign;
  try
    MenuMain.Top         := 0;
    PanelToolBarHost.Top := MenuMain.Top + MenuMain.Height;
    PanelTabs.Top        := PanelToolBarHost.Top + PanelToolBarHost.Height;
    PanelAddress.Top     := PanelTabs.Top + PanelTabs.Height;
  finally
    EnableAlign;
  end;
end;

procedure TfrmPicView.ClearThumbsForAll;
var
  T: TTabInfo;
begin
  for T in FTabs do T.ClearThumbs;
end;

procedure TfrmPicView.SetThumbSize(ASize: Integer);
begin
  if not (ASize in [64, 96, 128, 160, 192]) then Exit;
  
  FThumbSize := ASize;
  FUpdatingUI := True;
  try
    cbThumbSize.ItemIndex := cbThumbSize.Items.IndexOf(IntToStr(ASize));
  finally
    FUpdatingUI := False;
  end;
  SyncSizeActions;
  ClearThumbsForAll;
  if FTab <> nil then PrepareThumbs;
  UpdateStatus;
end;

{ 列表与缩略图槽位 }

procedure TfrmPicView.ResetThumbSlots;
begin
  SetLength(FSlotOwner, THUMB_SLOTS);
  SetLength(FSlotTick, THUMB_SLOTS);
  for var I := 0 to THUMB_SLOTS - 1 do
  begin
    FSlotOwner[I] := -1;
    FSlotTick[I] := 0;
  end;
  FIndexSlot.Clear;
  FThumbFailed.Clear;
  FThumbRequested.Clear;
  FCaptionCache.Clear;
  FSlotClock := 0;
end;

function TfrmPicView.VTCellW: Integer;
begin
  Result := FThumbSize + 20;
end;

function TfrmPicView.VTCellH: Integer;
begin
  Result := FThumbSize + 38;
end;

function TfrmPicView.VTCols(V: TVirtualStringTree): Integer;
begin
  Result := Max(1, (V.ClientWidth - VT_MARGIN * 2) div VTCellW);
end;

function TfrmPicView.VTRootCount(V: TVirtualStringTree; ATotal: Integer): Integer;
begin
  if ATotal <= 0 then
    Result := 0
  else
    Result := (ATotal + VTCols(V) - 1) div VTCols(V);
end;

function TfrmPicView.VTItemAt(V: TVirtualStringTree; X, Y: Integer): Integer;
var
  N: PVirtualNode;
  Col: Integer;
begin
  Result := -1;
  N := V.GetNodeAt(X, Y);
  if N = nil then Exit;
  
  Col := (X - VT_MARGIN) div VTCellW;
  if (Col < 0) or (Col >= VTCols(V)) then Exit;
  
  Result := Integer(N.Index) * VTCols(V) + Col;
end;

function TfrmPicView.VTSelected(V: TVirtualStringTree): Integer;
begin
  if V = lvBrowse then
    Result := FSelBrowse
  else
    Result := FSelThumbs;
end;

procedure TfrmPicView.VTSetSelected(V: TVirtualStringTree; AIndex: Integer);
begin
  if V = lvBrowse then
    FSelBrowse := AIndex
  else
    FSelThumbs := AIndex;
end;

function TfrmPicView.VTNodeOfRow(V: TVirtualStringTree; ARow: Integer): PVirtualNode;
var
  N: PVirtualNode;
begin
  Result := nil;
  if ARow < 0 then Exit;
  
  N := V.GetFirst();
  while (N <> nil) and (Integer(N.Index) < ARow) do N := V.GetNext(N);
  Result := N;
end;

function TfrmPicView.VTVisibleRows(out AFirstRow, ALastRow: Integer): Boolean;
var
  V: TVirtualStringTree;
  N1, N2: PVirtualNode;
begin
  Result    := False;
  AFirstRow := 0;
  ALastRow  := -1;
  if FTab = nil then Exit;
  V := ThumbView;
  if not V.HandleAllocated then Exit;
  N1 := V.GetNodeAt(2, 0);
  if N1 = nil then Exit;
  
  AFirstRow := Integer(N1.Index);
  ALastRow := AFirstRow;
  if V.ClientHeight > 2 then
  begin
    N2 := V.GetNodeAt(2, V.ClientHeight - 2);
    if N2 <> nil then
      ALastRow := Integer(N2.Index)
    else
      ALastRow := V.RootNodeCount - 1;  { content shorter than viewport: all rows visible }
  end;
  if ALastRow < AFirstRow then ALastRow := AFirstRow;
  Result := True;
end;

function TfrmPicView.VTVisibleRange(out AFrom, ATo: Integer): Boolean;
var
  V: TVirtualStringTree;
  FirstRow, LastRow: Integer;
  Cols, Total: Integer;
begin
  Result := False;
  AFrom  := 0;
  ATo    := -1;
  if FTab = nil then Exit;
  V := ThumbView;
  if not V.HandleAllocated then Exit;
  
  Total := ItemOffset + Length(FTab.Files);
  if Total <= 0 then Exit;
  if not VTVisibleRows(FirstRow, LastRow) then Exit;
  
  Cols := VTCols(V);
  AFrom := Max(0, FirstRow * Cols - Cols);
  ATo := Min(Total - 1, LastRow * Cols + Cols - 1 + Cols * THUMB_PREFETCH_ROWS);
  Result := ATo >= AFrom;
end;

procedure TfrmPicView.SetupVT(V: TVirtualStringTree);
begin
  V.NodeDataSize      := 0;
  V.Indent            := 0;
  V.TextMargin        := 0;
  V.DefaultText       := '';
  V.DefaultNodeHeight := VTCellH;
  V.Header.Options    := V.Header.Options - [hoVisible];
  V.Color             := 2105636;
  V.Colors.FocusedSelectionColor := RGB(30, 58, 95);
  V.TreeOptions.PaintOptions     := V.TreeOptions.PaintOptions - [toShowTreeLines, toShowButtons, toShowHorzGridLines, toShowVertGridLines, toAlwaysHideSelection];
end;

function TfrmPicView.AllocSlot(AIndex: Integer): Integer;
var
  I, Best, VisFrom, VisTo: Integer;
  BestTick: Int64;
begin
  if FIndexSlot.TryGetValue(AIndex, Result) then Exit;
  for I := 0 to THUMB_SLOTS - 1 do
    if FSlotOwner[I] = -1 then
    begin
      Result := I;
      Exit;
    end;
	
  VTVisibleRange(VisFrom, VisTo);
  Best := -1;
  BestTick := High(Int64);
  for I := 0 to THUMB_SLOTS - 1 do
    if (FSlotTick[I] < BestTick) and
       ((FSlotOwner[I] < VisFrom) or (FSlotOwner[I] > VisTo)) then
    begin
      Best := I;
      BestTick := FSlotTick[I];
    end;
  if Best < 0 then
  begin
    BestTick := High(Int64);
    for I := 0 to THUMB_SLOTS - 1 do
      if FSlotTick[I] < BestTick then
      begin
        Best := I;
        BestTick := FSlotTick[I];
      end;
  end;
  if Best < 0 then Best := 0;
  FEvictedIdx := -1;
  if FSlotOwner[Best] >= 0 then
  begin
    FEvictedIdx := FSlotOwner[Best];
    FIndexSlot.Remove(FEvictedIdx);
  end;
  Result := Best;
end;

procedure TfrmPicView.TouchSlot(ASlot: Integer);
begin
  Inc(FSlotClock);
  if (ASlot >= 0) and (ASlot < THUMB_SLOTS) then FSlotTick[ASlot] := FSlotClock;
end;

function TfrmPicView.ItemCaption(AIndex: Integer): string;
var
  Ofs, J: Integer;
  N: string;
begin
  Result := '';
  if FTab = nil then Exit;
  if FCaptionCache.TryGetValue(AIndex, Result) then Exit;
  
  Ofs := ItemOffset;
  if (AIndex >= 0) and (AIndex < Ofs) and (AIndex <= High(FTab.Folders)) then N := FTab.Folders[AIndex].Name
  else
  begin
    J := AIndex - Ofs;
    if (J < 0) or (J > High(FTab.Files)) then Exit;
    N := FTab.Files[J].Name;
  end;
  Result := ElideCaption(N);
  if FCaptionCache.Count > 6000 then FCaptionCache.Clear;
  FCaptionCache.AddOrSetValue(AIndex, Result);
end;

function TfrmPicView.ItemImageIndex(AIndex: Integer): Integer;
var 
  Slot: Integer;
begin
  Slot := -1;
  if (FTab <> nil) and (FTab.Mode = tmBrowse) and (AIndex < ItemOffset) then
  begin
    if (AIndex >= 0) and (AIndex < Length(FTab.Folders)) then
    begin
      { ".." 上一级项用独立的向上箭头图标, 方便一眼找到回退入口 }
      if FTab.Folders[AIndex].IsParent then Exit(FUpIconIdx);
      if FTab.Folders[AIndex].IsDrive then Exit(FDriveIconIdx);
    end;
    Exit(FFolderIconIdx);
  end;
  
  if FIndexSlot.TryGetValue(AIndex, Slot) then
  begin
    Inc(FSlotClock);
    FSlotTick[Slot] := FSlotClock;
    Result := THUMB_RESERVED + Slot;
  end
  else
    Result := FPlaceholderIdx;
end;

procedure TfrmPicView.VTListPaintCell(Sender: TBaseVirtualTree; TargetCanvas: TCanvas; Node: PVirtualNode; Column: TColumnIndex; CellPaintMode: TVTCellPaintMode; CellRect: TRect; var ContentRect: TRect);
var
  V: TVirtualStringTree;
  L: TImageList;
  Total, Cols, Base, I, Col, ImgIdx, IX, IY, X0: Integer;
  S: string;
  R: TRect;
begin
  if FTab = nil then Exit;
  
  V := Sender as TVirtualStringTree;
  if V <> ThumbView then Exit;
  
  Total := ItemOffset + Length(FTab.Files);
  if Total <= 0 then Exit;
  
  L := ThumbList;
  Cols := VTCols(V);
  Base := Integer(Node.Index) * Cols;
  TargetCanvas.Font.Assign(V.Font);
  TargetCanvas.Font.Color := clWhite;
  for Col := 0 to Cols - 1 do
  begin
    I := Base + Col;
    if I >= Total then Break;
    X0 := VT_MARGIN + Col * VTCellW;
    if I = VTSelected(V) then
    begin
      TargetCanvas.Brush.Color := V.Colors.FocusedSelectionColor;
      TargetCanvas.FillRect(Rect(X0 + 1, CellRect.Top, X0 + VTCellW - 1, CellRect.Bottom));
    end;
    IX := X0 + (VTCellW - FThumbSize) div 2;
    IY := CellRect.Top + 2;
    ImgIdx := ItemImageIndex(I);
    L.Draw(TargetCanvas, IX, IY, ImgIdx);
    S := ItemCaption(I);
    R := Rect(X0 + 2, CellRect.Top + FThumbSize + 6, X0 + VTCellW - 2, CellRect.Bottom);
    TargetCanvas.Brush.Style := bsClear;
    DrawTextW(TargetCanvas.Handle, PWideChar(S), Length(S), R, DT_CENTER or DT_SINGLELINE or DT_NOPREFIX);
    TargetCanvas.Brush.Style := bsSolid;
    QueueThumbData(I);
  end;
end;

procedure TfrmPicView.QueueThumbData(AIndex: Integer);
var
  J: Integer;
  T: UInt64;
begin
  { 记录本轮绘制过的索引; 定时器按连续簇取真正的可见区间, 避免把滚动前后两段相差 20 万的索引合并成一个巨型范围。 }
  if FRebuilding or FClosing or (FTab = nil) or (FThumbEngine = nil) then Exit;
  J := AIndex - ItemOffset;
  if (J < 0) or (J > High(FTab.Files)) then Exit;
  if FIndexSlot.ContainsKey(AIndex) or FThumbFailed.ContainsKey(AIndex) then Exit;
  { 超过 700ms 仍无结果就重提, 滚动/换尺寸时丢失的请求可自愈 }
  if FThumbRequested.TryGetValue(AIndex, T) and (GetTickCount64 - T < 700) then Exit;
  if FThumbEngine.PendingCount > 96 then Exit;
  
  FThumbRequested.AddOrSetValue(AIndex, GetTickCount64);
  FThumbEngine.Submit(FThumbGen, AIndex, FThumbSize, FTab.Files[J].Path);
end;

procedure TfrmPicView.PruneRequested(AFrom, ATo: Integer);
var
  Keys: TArray<Integer>;
  I, N: Integer;
  K: Integer;
begin
  N := FThumbRequested.Count;
  if N = 0 then Exit;
  
  SetLength(Keys, N);
  I := 0;
  for K in FThumbRequested.Keys do
  begin
    Keys[I] := K;
    Inc(I);
  end;
  for I := 0 to N - 1 do
    if (Keys[I] < AFrom) or (Keys[I] > ATo) then FThumbRequested.Remove(Keys[I]);
end;

procedure TfrmPicView.VTGetHint(Sender: TBaseVirtualTree; Node: PVirtualNode; Column: TColumnIndex; var LineBreakStyle: TVTTooltipLineBreakStyle; var HintText: string);
var
  V: TVirtualStringTree;
  P: TPoint;
  I, Ofs: Integer;
begin
  if FTab = nil then  Exit;
  
  V := Sender as TVirtualStringTree;
  P := V.ScreenToClient(Mouse.CursorPos);
  I := VTItemAt(V, P.X, P.Y);
  if I < 0 then Exit;
  
  LineBreakStyle := hlbForceMultiLine;
  Ofs            := ItemOffset;
  if (V = lvBrowse) and (I < Ofs) and (I < Length(FTab.Folders)) then
    HintText := FTab.Folders[I].Name + #13#10 + FTab.Folders[I].Path
  else
  begin
    I := I - Ofs;
    if (I >= 0) and (I <= High(FTab.Files)) then HintText := FTab.Files[I].Name + #13#10 + FTab.Files[I].Path;
  end;
end;

procedure TfrmPicView.ApplyThumbResult(const AResult: TThumbResult);
var
  B: TBitmap;
  Slot: Integer;
begin
  Slot := -1;
  FThumbRequested.Remove(AResult.Index);
  if (AResult.Gen <> FThumbGen) or (FTab = nil) then Exit;
  
  if Length(AResult.Pixels) = 0 then
  begin
    FThumbFailed.AddOrSetValue(AResult.Index, True);
    Exit;
  end;
  
  B := PixelsToBitmap(AResult.Pixels, AResult.Size);
  if B = nil then
  begin
    FThumbFailed.AddOrSetValue(AResult.Index, True);
    Exit;
  end;
  
  try
    Slot := AllocSlot(AResult.Index);
    FSlotOwner[Slot] := AResult.Index;
    FIndexSlot.AddOrSetValue(AResult.Index, Slot);
    TouchSlot(Slot);
    ThumbList.Replace(THUMB_RESERVED + Slot, B, nil);
    FChangedIdx.Add(AResult.Index);
    { 槽位被抢占的旧格子必须一起重绘, 否则它会停留在已被替换的图片上, 表现为滚动/加载时图片跳动闪烁 }
    if (FEvictedIdx >= 0) and (FEvictedIdx <> AResult.Index) then FChangedIdx.Add(FEvictedIdx);
  except
    FIndexSlot.Remove(AResult.Index);
    if (Slot >= 0) and (Slot < THUMB_SLOTS) then FSlotOwner[Slot] := -1;
  end;
  B.Free;
end;

procedure TfrmPicView.SubmitVisibleThumbs;
var
  V: TVirtualStringTree;
  Ofs, Total, First, Last, J, G, Count: Integer;
  T: UInt64;
begin
  if (FTab = nil) or (FThumbEngine = nil) or FClosing then Exit;
  V := ThumbView;
  if not V.HandleAllocated then Exit;
  
  Ofs := ItemOffset;
  Total := Ofs + Length(FTab.Files);
  if (FVisibleFrom >= 0) and (FVisibleTo >= FVisibleFrom) then
  begin
    First := FVisibleFrom;
    Last := FVisibleTo;
  end
  else if not VTVisibleRange(First, Last) then Exit;
  if First < Ofs then First := Ofs;
  if Last > Total - 1 then Last := Total - 1;
  if First > Last then Exit;
  
  Count := 0;
  for G := First to Last do
  begin
    J := G - Ofs;
    if (J < 0) or (J > High(FTab.Files)) then Continue;
    if FIndexSlot.ContainsKey(G) or FThumbFailed.ContainsKey(G) then Continue;
    if FThumbRequested.TryGetValue(G, T) and (GetTickCount64 - T < 700) then Continue;
    if FThumbEngine.PendingCount > 96 then
    begin
      FNeedSubmit := True;
      Break;
    end;
    FThumbRequested.AddOrSetValue(G, GetTickCount64);
    FThumbEngine.Submit(FThumbGen, G, FThumbSize, FTab.Files[J].Path);
    Inc(Count);
    if Count >= 48 then Break;
  end;
end;

procedure TfrmPicView.PrepareThumbs;
var
  L: TImageList;
  V: TVirtualStringTree;
  B, FB, DB, UB: TBitmap;
  I, Ofs, Total: Integer;
begin
  if (FTab = nil) or (FThumbEngine = nil) then Exit;
  FThumbEngine.Reset;
  FThumbGen := FThumbEngine.Generation;
  ResetThumbSlots;
  FVisibleFrom := -1;
  FVisibleTo   := -1;
  FNeedSubmit  := True;
  L            := ThumbList;
  V            := ThumbView;
  Ofs          := ItemOffset;
  Total        := Ofs + Length(FTab.Files);
  if (L.Count <> THUMB_RESERVED + THUMB_SLOTS) or (L.Width <> FThumbSize) or (L.Height <> FThumbSize) then
  begin
    L.Clear;
    L.Width      := FThumbSize;
    L.Height     := FThumbSize;
    L.ColorDepth := cd32Bit;
    B := PlaceholderBitmap(FThumbSize);
    FB := nil;
    DB := nil;
    try
      FPlaceholderIdx := L.Add(B, nil);
      if FTab.Mode = tmBrowse then
        FB := MakeFolderIconBitmap(FThumbSize, FTab.Folder)
      else
        FB := PlaceholderBitmap(FThumbSize);
      FFolderIconIdx := L.Add(FB, nil);
      DB := MakeDriveIconBitmap(FThumbSize);
      try
        FDriveIconIdx := L.Add(DB, nil);
      finally
        FreeAndNil(DB);
      end;
      UB := MakeUpIconBitmap(FThumbSize);
      try
        FUpIconIdx := L.Add(UB, nil);
      finally
        FreeAndNil(UB);
      end;
      for I := 0 to THUMB_SLOTS - 1 do
        L.Add(B, nil);
    finally
      FreeAndNil(FB);
      FreeAndNil(B);
    end;
    if FPlaceholderIdx < 0 then FPlaceholderIdx := 0;
    if FFolderIconIdx < 0 then FFolderIconIdx := FPlaceholderIdx;
    if FDriveIconIdx < 0 then FDriveIconIdx := FFolderIconIdx;
    if FUpIconIdx < 0 then FUpIconIdx := FFolderIconIdx;
  end;
  FRebuilding := True;
  FChangedIdx.Clear;
  try
    V.DefaultNodeHeight := VTCellH;
    V.RootNodeCount := VTRootCount(V, Total);
    VTSetSelected(V, -1);
  finally
    FRebuilding := False;
  end;
  V.Invalidate;
  TimerThumbs.Enabled := True;
  TimerRepaint.Enabled := True;
end;

procedure TfrmPicView.TimerThumbsTimer(Sender: TObject);
var
  Results: TThumbResultArray;
  I, NewFrom, NewTo: Integer;
begin
  if FClosing or (FTab = nil) or (FThumbEngine = nil) then Exit;
  if FThumbEngine.FetchResults(Results, THUMB_APPLY_BUDGET) then
  begin
    for I := 0 to High(Results) do
      if Results[I].Gen = FThumbGen then
      begin
        ApplyThumbResult(Results[I]);
      end;
    FNeedSubmit := True;
  end;
  if VTVisibleRange(NewFrom, NewTo) then
    if (NewFrom <> FVisibleFrom) or (NewTo <> FVisibleTo) then
    begin
      FVisibleFrom := NewFrom;
      FVisibleTo := NewTo;
      FThumbEngine.ClearRequests;
      PruneRequested(NewFrom, NewTo);
      FNeedSubmit := True;
    end;
  if FNeedSubmit or (FThumbEngine.PendingCount = 0) then
  begin
    SubmitVisibleThumbs;
    FNeedSubmit := False;
  end;
end;

procedure TfrmPicView.TimerRepaintTimer(Sender: TObject);
var
  V: TVirtualStringTree;
  I, R, Cols, FirstRow, LastRow: Integer;
  N: PVirtualNode;
begin
  if FClosing or (FTab = nil) or (FChangedIdx.Count = 0) then Exit;
  V := ThumbView;
  if not V.HandleAllocated then Exit;
  if not VTVisibleRows(FirstRow, LastRow) then Exit;
  Cols := VTCols(V);
  N := V.GetNodeAt(2, 0);
  while (N <> nil) and (Integer(N.Index) <= LastRow) do
  begin
    R := Integer(N.Index) * Cols;
    for I := 0 to FChangedIdx.Count - 1 do
      if (FChangedIdx[I] >= R) and (FChangedIdx[I] < R + Cols) then
      begin
        V.InvalidateNode(N);
        Break;
      end;
    N := V.GetNextVisible(N);
  end;
  FChangedIdx.Clear;
end;

procedure TfrmPicView.SelectThumb(AIndex: Integer);
var
  V       : TVirtualStringTree;
  G, Total: Integer;
  Node    : PVirtualNode;
begin
  FSelectingThumb := True;
  try
    V     := ThumbView;
    Total := ItemOffset + Length(FTab.Files);
    G     := AIndex + ItemOffset;
    if (AIndex >= 0) and (G >= 0) and (G < Total) then
    begin
      VTSetSelected(V, G);
      V.Invalidate;
      Node := VTNodeOfRow(V, G div VTCols(V));
      if Node <> nil then V.ScrollIntoView(Node, False);
    end
    else
    begin
      VTSetSelected(V, -1);
      V.Invalidate;
    end;
  finally
    FSelectingThumb := False;
  end;
end;

function TfrmPicView.FindBrowseTab(const AFolder: string): TTabInfo;
var
  T: TTabInfo;
begin
  Result := nil;
  for T in FTabs do
    if (T.Mode = tmBrowse) and SameText(T.Folder, AFolder) then Exit(T);
	
  for T in FTabs do
    if T.Mode = tmBrowse then Exit(T);
end;

function TfrmPicView.ItemOffset: Integer;
begin
  if (FTab <> nil) and (FTab.Mode = tmBrowse) then
    Result := Length(FTab.Folders)
  else
    Result := 0;
end;

procedure TfrmPicView.EnterFolder(const APath: string);
begin
  if (FTab = nil) or (FTab.Mode <> tmBrowse) then Exit;
  if APath = '' then Exit;
  if (not IsDrivesRoot(APath)) and (not TDirectory.Exists(APath)) then Exit;
  if SameText(APath, FTab.Folder) then Exit;
  
  LoadFolderIntoTab(FTab, APath, '');
  ActivateTab(FTab);
end;

procedure TfrmPicView.NavigateToFolder(AIndex: Integer);
begin
  if (FTab = nil) or (FTab.Mode <> tmBrowse) then Exit;
  if (AIndex < 0) or (AIndex >= Length(FTab.Folders)) then Exit;
  FPendingFolder := FTab.Folders[AIndex].Path;
  PostMessage(Handle, WM_OPENFOLDER, 0, 0);
end;

procedure TfrmPicView.VTListKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
var
  V             : TVirtualStringTree;
  Total, Cols, I: Integer;
  Node          : PVirtualNode;
begin
  V := Sender as TVirtualStringTree;
  if FTab = nil then Exit;
  
  Total := ItemOffset + Length(FTab.Files);
  Cols := VTCols(V);
  I := VTSelected(V);
  case Key of
    VK_LEFT: Dec(I);
    VK_RIGHT: Inc(I);
    VK_UP: Dec(I, Cols);
    VK_DOWN: Inc(I, Cols);
    VK_HOME: I := 0;
    VK_END: I := MaxInt;
  else
    Exit;
  end;
  
  Key := 0;
  if Total <= 0 then
    I := -1
  else
  begin
    if I < 0 then I := 0;
    if I > Total - 1 then I := Total - 1;
  end;
  
  if I <> VTSelected(V) then
  begin
    VTSetSelected(V, I);
    V.Invalidate;
    Node := VTNodeOfRow(V, I div Cols);
    if Node <> nil then
      V.ScrollIntoView(Node, False);
    if V = lvBrowse then
      HandleBrowseSelect(I)
    else
      HandleThumbsSelect(I);
  end;
end;

procedure TfrmPicView.VTListResize(Sender: TObject);
var
  V    : TVirtualStringTree;
  Total: Integer;
begin
  V := Sender as TVirtualStringTree;
  V.DefaultNodeHeight := VTCellH;
  if FTab = nil then Exit;
  
  Total := ItemOffset + Length(FTab.Files);
  V.RootNodeCount := VTRootCount(V, Total);
end;

procedure TfrmPicView.lvBrowseMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
var
  I: Integer;
begin
  if (FTab = nil) or (FTab.Mode <> tmBrowse) then Exit;
  I := VTItemAt(lvBrowse, X, Y);
  if (I < 0) or (I = FSelBrowse) then Exit;
  FSelBrowse := I;
  lvBrowse.Invalidate;
  HandleBrowseSelect(I);
end;

procedure TfrmPicView.PopupMenuBrowsePopup(Sender: TObject);
var
  I: Integer;
  HasSel, IsFolder: Boolean;
begin
  HasSel := False;
  IsFolder := False;
  if (FTab <> nil) and (FTab.Mode = tmBrowse) then
  begin
    I := FSelBrowse;
    HasSel := I >= 0;
    IsFolder := HasSel and (I < ItemOffset);
  end;
  miPbView.Enabled := HasSel and (not IsFolder);
  miPbOpenFolder.Enabled := IsFolder;
  miPbOpenFolder.Visible := IsFolder;
  miPbProperties.Enabled := HasSel and (not IsFolder);
  miPbCopyPath.Enabled := HasSel;
  miPbExplore.Enabled := HasSel;
  miPbDelete.Enabled := HasSel and (not IsFolder);
end;

procedure TfrmPicView.miPbOpenFolderClick(Sender: TObject);
var
  I: Integer;
begin
  if (FTab = nil) or (FTab.Mode <> tmBrowse) then Exit;
	
  I := FSelBrowse;
  if I < 0 then Exit;
	
  NavigateToFolder(I);
end;

procedure TfrmPicView.actPropertiesExecute(Sender: TObject);
var
  P: string;
begin
  P := CurrentPath;
  if (P = '') or (not TFile.Exists(P)) then
  begin
    ShowMessage('请先选中一张图像, 再查看属性。');
    Exit;
  end;
  
  ShowImageProperties(Self, P);
end;

procedure TfrmPicView.WMOpenFolder(var Msg: TMessage);
var
  P: string;
begin
  P := FPendingFolder;
  FPendingFolder := '';
  if P <> '' then EnterFolder(P);
  Msg.Result := 0;
end;

{ 模式显示 }

procedure TfrmPicView.ShowBrowseTab;
begin
  if FTab = nil then Exit;
  
  cbPath.Text := FolderDisplayName(FTab.Folder);
  LabelCount.Caption := Format('共 %d 张图像 / %d 个文件夹', [Length(FTab.Files), Length(FTab.Folders)]);
  LabelBrowseHint.Caption := '双击进入子目录, ..返回上级, 双击图像查看';
  PrepareThumbs;
  UpdateInfo;
  UpdateStatus;
end;

procedure TfrmPicView.ShowViewTab;
begin
  if FTab = nil then Exit;
  LabelFilmCount.Caption := Format('同文件夹共 %d 张', [Length(FTab.Files)]);
  PrepareThumbs;
  if (FTab.Base = nil) and (FTab.Index >= 0) and (FTab.Index <= High(FTab.Files)) then
    LoadCurrentImage
  else
    ApplyZoom;
  UpdateInfo;
  UpdateStatus;
end;

procedure TfrmPicView.UpdateCaption;
begin
  if FTab = nil then Caption := APP_TITLE
  else if FTab.Mode = tmBrowse then
    Caption := APP_TITLE + ' - 浏览 - ' + FolderDisplayName(FTab.Folder)
  else
    Caption := APP_TITLE + ' - 查看 - ' + FTab.CurrentPath;
end;

{ 图像查看 }

procedure TfrmPicView.PrevImage(ALoop: Boolean);
begin
  if (FTab = nil) or (FTab.Mode <> tmView) then Exit;
  if Length(FTab.Files) = 0 then Exit;
  
  if FTab.Index <= 0 then
  begin
    if not ALoop then Exit;
    FTab.Index := Length(FTab.Files);
  end;
  
  Dec(FTab.Index);
  FreeAndNil(FTab.Wic);
  FreeAndNil(FTab.Base);
  FTab.Rotation := 0;
  LoadCurrentImage;
  SelectThumb(FTab.Index);
  UpdateInfo;
  UpdateStatus;
  UpdateCaption;
  FlashHint(ExtractFileName(FTab.CurrentPath));
end;

procedure TfrmPicView.NextImage(ALoop: Boolean);
begin
  if (FTab = nil) or (FTab.Mode <> tmView) then Exit;
  if Length(FTab.Files) = 0 then Exit;
  
  if FTab.Index >= High(FTab.Files) then
  begin
    if not ALoop then Exit;
    FTab.Index := -1;
  end;
  
  Inc(FTab.Index);
  FreeAndNil(FTab.Wic);
  FreeAndNil(FTab.Base);
  FTab.Rotation := 0;
  LoadCurrentImage;
  SelectThumb(FTab.Index);
  UpdateInfo;
  UpdateStatus;
  UpdateCaption;
  FlashHint(ExtractFileName(FTab.CurrentPath));
end;

procedure TfrmPicView.ClearViewer;
begin
  ImageMain.Picture.Graphic := nil;
  UpdateImagePosition;
end;

procedure TfrmPicView.LoadCurrentImage;
var
  S: string;
  SW: TStopwatch;
begin
  if FTab = nil then Exit;
  
  FreeAndNil(FTab.Wic);
  FreeAndNil(FTab.Base);
  FTab.Rotation := 0;
  FTab.ZoomMode := FZoomMode;   { 换图时恢复默认缩放, 不继承上一张的自定义比例 }
  FTab.LoadError := '';
  FTab.DecodeMs := 0;
  if (FTab.Index < 0) or (FTab.Index > High(FTab.Files)) then
  begin
    ClearViewer;
    Exit;
  end;
  
  S := FTab.Files[FTab.Index].Path;
  { 页签标题随当前图片同步 }
  FTab.Caption := ShortCaption(ExtractFileName(S));
  if FTab.Sheet <> nil then FTab.Sheet.Caption := FTab.Caption;
  if PageControl1.HandleAllocated then PageControl1.Invalidate;
  SW := TStopwatch.StartNew;
  try
    LoadImageFile(S, FTab.Base, FTab.Wic);
  except
    on E: Exception do
    begin
      FTab.DecodeMs := 0;
      FreeAndNil(FTab.Base);
      FreeAndNil(FTab.Wic);
      ClearViewer;
      FTab.LoadError := '无法打开: ' + E.Message;
      StatusBar1.Panels[4].Text := FTab.LoadError;
      Exit;
    end;
  end;
  FTab.DecodeMs := SW.Elapsed.TotalMilliseconds;
  ApplyZoom;
end;

procedure TfrmPicView.ApplyZoom;
var
  OW, OH, SW, SH, CW, CH: Integer;
  FitZ, MaxZ: Double;
  Src, Disp: TBitmap;
  Scaled: TWICImage;
begin
  if (FTab = nil) or (FTab.Mode <> tmView) or (FTab.Base = nil) then Exit;
  
  OW := FTab.Base.Width;
  OH := FTab.Base.Height;
  CW := ScrollBoxViewer.ClientWidth - 4;
  CH := ScrollBoxViewer.ClientHeight - 4;
  if CW < 32 then CW := 32;
  if CH < 32 then CH := 32;

  if (FTab.Rotation = 1) or (FTab.Rotation = 3) then
    FitZ := Min(CW / OH, CH / OW)
  else
    FitZ := Min(CW / OW, CH / OH);
  case FTab.ZoomMode of
    zmFit: FTab.Zoom := FitZ;
    zmActual: FTab.Zoom := 1;
  end;

  MaxZ := Min(8.0, Sqrt(MAX_VIEW_PIXELS / (OW * 1.0 * OH)));
  if MaxZ < 0.02 then MaxZ := 0.02;
  if FTab.Zoom < 0.02 then FTab.Zoom := 0.02;
  if FTab.Zoom > MaxZ then FTab.Zoom := MaxZ;

  SW := Max(1, Round(OW * FTab.Zoom));
  SH := Max(1, Round(OH * FTab.Zoom));

  Src := nil;
  Disp := nil;
  Scaled := nil;
  try
    if Abs(FTab.Zoom - 1) > 0.005 then
    begin
      if FTab.Wic <> nil then
      begin
        try
          Scaled := FTab.Wic.CreateScaledCopy(SW, SH, wipmHighQualityCubic);
          Src := TBitmap.Create;
          Src.Assign(Scaled);
        except
          FreeAndNil(Scaled);
          FreeAndNil(Src);
        end;
      end;
      if Src = nil then
        Src := ScaleBitmap(FTab.Base, SW, SH);
    end
    else
    begin
      Src := TBitmap.Create;
      Src.Assign(FTab.Base);
    end;

    if FTab.Rotation = 0 then
    begin
      Disp := Src;
      Src := nil;
    end
    else
      Disp := RotateBitmap(Src, FTab.Rotation);

    ImageMain.Picture.Bitmap.Assign(Disp);
  finally
    FreeAndNil(Scaled);
    FreeAndNil(Src);
    FreeAndNil(Disp);
  end;
  UpdateImagePosition;
  UpdateStatus;
end;

procedure TfrmPicView.ZoomStep(AFactor: Double);
begin
  if (FTab = nil) or (FTab.Mode <> tmView) then Exit;
  
  FTab.ZoomMode := zmCustom;
  FTab.Zoom := FTab.Zoom * AFactor;
  if FTab.Zoom < 0.02 then FTab.Zoom := 0.02;
  if FTab.Zoom > 16 then FTab.Zoom := 16;
  ApplyZoom;
end;

procedure TfrmPicView.SetZoomMode(AMode: TZoomMode);
begin
  if (FTab = nil) or (FTab.Mode <> tmView) then Exit;
  
  FTab.ZoomMode := AMode;
  FZoomMode := AMode;
  ApplyZoom;
end;

procedure TfrmPicView.UpdateImagePosition;
var
  L, T: Integer;
begin
  if (ImageMain.Picture.Graphic = nil) or ImageMain.Picture.Graphic.Empty then Exit;
  
  if ImageMain.Width < ScrollBoxViewer.ClientWidth then
    L := (ScrollBoxViewer.ClientWidth - ImageMain.Width) div 2
  else
    L := 0;
  if ImageMain.Height < ScrollBoxViewer.ClientHeight then
    T := (ScrollBoxViewer.ClientHeight - ImageMain.Height) div 2
  else
    T := 0;
  ImageMain.Left := L;
  ImageMain.Top := T;
end;

procedure TfrmPicView.UpdateInfo;
var
  E   : string;
  W, H: Integer;
begin
  if (FTab = nil) or (FTab.Index < 0) or (FTab.Index > High(FTab.Files)) then Exit;
  
  E := UpperCase(ExtractFileExt(FTab.Files[FTab.Index].Name));
  if (E <> '') and (E[1] = '.') then Delete(E, 1, 1);
  W := 0;
  H := 0;
  if FTab.Base <> nil then
  begin
    W := FTab.Base.Width;
    H := FTab.Base.Height;
  end;
  vleInfo.Values['文件名'] := FTab.Files[FTab.Index].Name;
  vleInfo.Values['格式'] := E;
  if (FTab.Mode = tmView) and (FTab.Base <> nil) then
    vleInfo.Values['尺寸'] := Format('%d x %d', [W, H])
  else
    vleInfo.Values['尺寸'] := '-';
  vleInfo.Values['大小'] := FormatFileSize(FTab.Files[FTab.Index].Size);
  vleInfo.Values['修改时间'] := FormatDateTime('yyyy-MM-dd hh:nn:ss', FTab.Files[FTab.Index].Modified);
  vleInfo.Values['旋转'] := IntToStr(FTab.Rotation * 90) + ' 度';
  if FTab.Mode = tmView then
  begin
    if FTab.Wic <> nil then
      vleInfo.Values['帧数'] := IntToStr(FTab.Wic.FrameCount)
    else
      vleInfo.Values['帧数'] := '1';
  end
  else
    vleInfo.Values['帧数'] := '-';
  vleInfo.Values['文件夹'] := FolderDisplayName(FTab.Folder);
end;

procedure TfrmPicView.UpdateStatus;
var
  W, H, T: Integer;
begin
  if FTab = nil then Exit;
  
  if FTab.Mode = tmBrowse then
  begin
    if IsDrivesRoot(FTab.Folder) then
      StatusBar1.Panels[0].Text := Format('本机磁盘  %d 个', [Length(FTab.Folders)])
    else
      StatusBar1.Panels[0].Text := Format('浏览模式  %d 张图像 / %d 个文件夹', [Length(FTab.Files), Length(FTab.Folders)]);
    if FSelectedFolderPath <> '' then
      StatusBar1.Panels[1].Text := '文件夹: ' + FSelectedFolderPath
    else if (FTab.Index >= 0) and (FTab.Index <= High(FTab.Files)) then
      StatusBar1.Panels[1].Text := FTab.Files[FTab.Index].Name
    else
      StatusBar1.Panels[1].Text := '';
    StatusBar1.Panels[2].Text := Format('缩略图 %d px', [FThumbSize]);
    StatusBar1.Panels[4].Text := FolderDisplayName(FTab.Folder);
    StatusBar1.Panels[3].Text := '';
    Exit;
  end;
  
  if (FTab.Index < 0) or (FTab.Index > High(FTab.Files)) then
  begin
    StatusBar1.Panels[0].Text := '无图像';
    StatusBar1.Panels[1].Text := '';
    StatusBar1.Panels[2].Text := '';
    StatusBar1.Panels[4].Text := FTab.Folder;
    StatusBar1.Panels[3].Text := '';
    Exit;
  end;
  
  StatusBar1.Panels[0].Text := Format('查看模式  %d / %d', [FTab.Index + 1, Length(FTab.Files)]);
  W := 0;
  H := 0;
  if FTab.Base <> nil then
  begin
    W := FTab.Base.Width;
    H := FTab.Base.Height;
    if (FTab.Rotation = 1) or (FTab.Rotation = 3) then
    begin
      T := W;
      W := H;
      H := T;
    end;
  end;
  StatusBar1.Panels[1].Text := Format('%d x %d    %d%%', [W, H, Round(FTab.Zoom * 100)]);
  StatusBar1.Panels[2].Text := FormatFileSize(FTab.Files[FTab.Index].Size);
  if FTab.LoadError <> '' then
  begin
    StatusBar1.Panels[4].Text := FTab.LoadError;
    StatusBar1.Panels[3].Text := '-';
  end
  else
  begin
    StatusBar1.Panels[4].Text := FTab.Files[FTab.Index].Path;
    StatusBar1.Panels[3].Text := Format('解码用时 %.1f ms', [FTab.DecodeMs]);
  end;
end;

{ 全屏与幻灯片 }

procedure TfrmPicView.FlashHint(const AText: string);
begin
  if not FFullScreen then Exit;
  PanelHint.Caption := AText;
  PanelHint.Visible := True;
  TimerHint.Enabled := False;
  TimerHint.Enabled := True;
end;

procedure TfrmPicView.SetFullScreen(AOn: Boolean);
begin
  if FFullScreen = AOn then Exit;
  
  FFullScreen := AOn;
  if AOn then
  begin
    FSaveBounds := BoundsRect;
    MenuMain.Visible := False;
    PanelTabs.Visible := False;
    PanelToolBarHost.Visible := False;
    ToolBarBrowse.Visible := False;
    ToolBarView.Visible := False;
    PanelAddress.Visible := False;
    StatusBar1.Visible := False;
    PanelRight.Visible := False;
    Splitter2.Visible := False;
    PanelThumbs.Visible := False;
    Splitter3.Visible := False;
    BorderStyle := bsNone;
    WindowState := wsMaximized;
    FlashHint(ExtractFileName(CurrentPath));
  end
  else
  begin
    TimerHint.Enabled := False;
    PanelHint.Visible := False;
    WindowState := wsNormal;
    BorderStyle := bsSizeable;
    DragAcceptFiles(Handle, True);
    ApplyModeUI;
    BoundsRect := FSaveBounds;
  end;
  if (FTab <> nil) and (FTab.Mode = tmView) then
  begin
    if FTab.ZoomMode = zmFit then
      ApplyZoom
    else
      UpdateImagePosition;
  end;
end;

procedure TfrmPicView.TimerSlideTimer(Sender: TObject);
begin
  { 幻灯片仍循环播放, 手动翻页(滚轮/按键/菜单)到头即停 }
  NextImage(True);
end;

procedure TfrmPicView.TimerHintTimer(Sender: TObject);
begin
  TimerHint.Enabled := False;
  PanelHint.Visible := False;
end;

{ 鼠标与键盘 }

procedure TfrmPicView.FormMouseWheel(Sender: TObject; Shift: TShiftState; WheelDelta: Integer; MousePos: TPoint; var Handled: Boolean);
begin
  if (FTab = nil) or (FTab.Mode <> tmView) then
  begin
    Handled := False;
    Exit;
  end;
  
  Handled := True;
  if ssCtrl in Shift then
  begin
    if WheelDelta > 0 then
      ZoomStep(1.2)
    else
      ZoomStep(1 / 1.2);
  end
  else if WheelDelta > 0 then
    PrevImage
  else
    NextImage;
end;

procedure TfrmPicView.ImageMainMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  if Button <> mbLeft then Exit;
  
  FDragging := True;
  FDragLast := Mouse.CursorPos;
end;

procedure TfrmPicView.ImageMainMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);
var
  P: TPoint;
  DX, DY: Integer;
begin
  if not FDragging then Exit;
  
  P := Mouse.CursorPos;
  DX := P.X - FDragLast.X;
  DY := P.Y - FDragLast.Y;
  FDragLast := P;
  with ScrollBoxViewer do
  begin
    if HorzScrollBar.Range > ClientWidth then
      HorzScrollBar.Position := HorzScrollBar.Position - DX;
    if VertScrollBar.Range > ClientHeight then
      VertScrollBar.Position := VertScrollBar.Position - DY;
  end;
end;

procedure TfrmPicView.ImageMainMouseUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  FDragging := False;
end;

procedure TfrmPicView.ImageMainDblClick(Sender: TObject);
begin
  { 查看模式下双击图片: 关闭当前查看页签, 回到浏览模式 }
  if (FTab <> nil) and (FTab.Mode = tmView) then CloseActiveTab;
end;

procedure TfrmPicView.ScrollBoxViewerResize(Sender: TObject);
begin
  if (not FLoaded) or (FTab = nil) or (FTab.Mode <> tmView) then Exit;
  if FTab.ZoomMode = zmFit then
    ApplyZoom
  else
    UpdateImagePosition;
end;

procedure TfrmPicView.FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
var
  C: TWinControl;
begin
  C := ActiveControl;
  if (Key = VK_RETURN) and (ssAlt in Shift) then Exit;
  if (C is TCustomEdit) or (C is TCustomComboBox) then Exit;
  if FTab = nil then Exit;

  if (C = lvBrowse) and (Key = VK_RETURN) and (FTab <> nil) and (FTab.Mode = tmBrowse) and (FSelBrowse >= 0) and (FSelBrowse < ItemOffset) then
  begin
    NavigateToFolder(FSelBrowse);
    Key := 0;
    Exit;
  end;

  if FTab.Mode = tmBrowse then
  begin
    case Key of
      VK_RETURN:
        actViewSelectedExecute(nil);
      VK_BACK:
        actGoUpExecute(nil);
      VK_DELETE:
        actDeleteExecute(nil);
    else
      Exit;
    end;
    Key := 0;
    Exit;
  end;

  case Key of
    VK_LEFT, VK_UP, VK_PRIOR:
      PrevImage;
    VK_RIGHT, VK_DOWN, VK_NEXT, VK_SPACE:
      NextImage;
    VK_HOME:
      if ssCtrl in Shift then
      begin
        FTab.Index := 0;
        LoadCurrentImage;
        SelectThumb(0);
        UpdateInfo;
        UpdateStatus;
        UpdateCaption;
      end
      else
        Exit;
    VK_END:
      if ssCtrl in Shift then
      begin
        FTab.Index := High(FTab.Files);
        LoadCurrentImage;
        SelectThumb(FTab.Index);
        UpdateInfo;
        UpdateStatus;
        UpdateCaption;
      end
      else
        Exit;
    VK_OEM_PLUS, VK_ADD:
      ZoomStep(1.25);
    VK_OEM_MINUS, VK_SUBTRACT:
      ZoomStep(1 / 1.25);
    VK_RETURN:
      SetFullScreen(not FFullScreen);
    VK_BACK:
      actBackToBrowseExecute(nil);
    VK_ESCAPE:
      begin
        actSlideShow.Checked := False;
        TimerSlide.Enabled := False;
        SetFullScreen(False);
      end;
  else
    Exit;
  end;
  Key := 0;
end;

procedure TfrmPicView.WMDropFiles(var Msg: TMessage);
var
  HD : HDROP;
  Cnt: Integer;
  Buf: array[0..MAX_PATH] of Char;
  S  : string;
begin
  HD := HDROP(Msg.WParam);
  try
    Cnt := DragQueryFile(HD, $FFFFFFFF, nil, 0);
    if Cnt > 0 then
    begin
      DragQueryFile(HD, 0, Buf, Length(Buf));
      S := StrPas(Buf);
      if TDirectory.Exists(S) then
        OpenFolder(S)
      else if TFile.Exists(S) then
        OpenViewTab(ExtractFileDir(S), S);
    end;
  finally
    DragFinish(HD);
  end;
  Msg.Result := 0;
end;

procedure TfrmPicView.PvMenuItemMeasure(Sender: TObject; ACanvas: TCanvas; var Width, Height: Integer);
begin
  { 分隔线少加一些，避免过高 }
  if (Sender is TMenuItem) and (TMenuItem(Sender).Caption = '-') then
    Inc(Height, PV_MENU_ITEM_VPAD div 2)
  else
    Inc(Height, PV_MENU_ITEM_VPAD);
end;

procedure TfrmPicView.SetupDarkPopup(AMenu: TPopupMenu);
var
  I: Integer;
begin
  if AMenu = nil then Exit;
  AMenu.OwnerDraw := True;
  for I := 0 to AMenu.Items.Count - 1 do
  begin
    AMenu.Items[I].OnMeasureItem := PvMenuItemMeasure;
    AMenu.Items[I].OnAdvancedDrawItem := PvMenuItemDraw;
  end;
end;

procedure TfrmPicView.PvMenuItemDraw(Sender: TObject; ACanvas: TCanvas; ARect: TRect; State: TOwnerDrawState);
var
  It     : TMenuItem;
  LImages: TCustomImageList;
  S, K   : string;
  R, KR  : TRect;
  CY     : Integer;
begin
  if not (Sender is TMenuItem) then Exit;
  It := TMenuItem(Sender);

  ACanvas.Brush.Style := bsSolid;
  if odSelected in State then
    ACanvas.Brush.Color := PV_DARK_ACCENT
  else
    ACanvas.Brush.Color := PV_DARK_BAR;
  ACanvas.FillRect(ARect);

  CY := (ARect.Top + ARect.Bottom) div 2;
  if It.IsLine then
  begin
    ACanvas.Pen.Color := PV_DARK_BORDER;
    ACanvas.Pen.Width := 1;
    ACanvas.MoveTo(ARect.Left + 8, CY);
    ACanvas.LineTo(ARect.Right - 8, CY);
    Exit;
  end;

  if It.Checked then
  begin
    ACanvas.Pen.Color := clWhite;
    ACanvas.Pen.Width := 2;
    ACanvas.MoveTo(ARect.Left + 7, CY - 1);
    ACanvas.LineTo(ARect.Left + 11, CY + 3);
    ACanvas.LineTo(ARect.Left + 18, CY - 5);
  end;

  LImages := It.GetImageList;
  if (LImages <> nil) and (It.ImageIndex >= 0) and (It.ImageIndex < LImages.Count) then
    LImages.Draw(ACanvas, ARect.Left + 26, CY - LImages.Height div 2, It.ImageIndex, It.Enabled);

  if odDisabled in State then
    ACanvas.Font.Color := PV_DARK_TEXT_DIM
  else
    ACanvas.Font.Color := clWhite;

  R := ARect;
  R.Left := R.Left + 52;
  R.Right := R.Right - 12;
  KR := R;
  K := '';
  if It.ShortCut <> 0 then
  begin
    K := ShortCutToText(It.ShortCut);
    KR.Left := KR.Right - 96;
    ACanvas.Brush.Style := bsClear;
    DrawTextW(ACanvas.Handle, PWideChar(K), Length(K), KR, DT_RIGHT or DT_VCENTER or DT_SINGLELINE or DT_NOPREFIX);
    R.Right := KR.Left - 6;
  end;

  S := StringReplace(It.Caption, '&', '', [rfReplaceAll]);
  ACanvas.Brush.Style := bsClear;
  DrawTextW(ACanvas.Handle, PWideChar(S), Length(S), R, DT_LEFT or DT_VCENTER or DT_SINGLELINE or DT_NOPREFIX or DT_END_ELLIPSIS);
  ACanvas.Brush.Style := bsSolid;
end;

procedure TfrmPicView.PvToolBarDraw(Sender: TToolBar; Button: TToolButton; State: TCustomDrawState; var DefaultDraw: Boolean);
var
  C: TCanvas;
  R: TRect;
begin
  DefaultDraw := False;
  C := Sender.Canvas;
  R := Rect(Button.Left, Button.Top, Button.Left + Button.Width, Button.Top + Button.Height);

  C.Brush.Style := bsSolid;
  if (cdsSelected in State) or Button.Down or (cdsChecked in State) then
    C.Brush.Color := PV_DARK_ACCENT
  else if cdsHot in State then
    C.Brush.Color := PV_DARK_PANEL
  else
    C.Brush.Color := PV_DARK_BAR;
  C.FillRect(R);

  if Button.Style in [tbsSeparator, tbsDivider] then
  begin
    C.Pen.Color := PV_DARK_BORDER;
    C.Pen.Width := 1;
    if Button.Style = tbsDivider then
    begin
      C.MoveTo(R.Left + 2, R.Top + 4);
      C.LineTo(R.Left + 2, R.Bottom - 4);
    end
    else
    begin
      C.MoveTo((R.Left + R.Right) div 2, R.Top + 6);
      C.LineTo((R.Left + R.Right) div 2, R.Bottom - 6);
    end;
    Exit;
  end;

  if (Sender.Images <> nil) and (Button.ImageIndex >= 0) and  (Button.ImageIndex < Sender.Images.Count) then
  begin
    Sender.Images.Draw(C, R.Left + 4, (R.Top + R.Bottom - Sender.Images.Height) div 2, Button.ImageIndex, Button.Enabled);
    R.Left := R.Left + Sender.Images.Width + 6;
  end;

  if cdsFocused in State then
  begin
    C.Pen.Color := PV_DARK_BORDER;
    C.Pen.Width := 1;
    C.DrawFocusRect(R);
  end;

  if Button.Caption <> '' then
  begin
    if cdsDisabled in State then
      C.Font.Color := PV_DARK_TEXT_DIM
    else
      C.Font.Color := clWhite;
    C.Brush.Style := bsClear;
    DrawTextW(C.Handle, PWideChar(Button.Caption), Length(Button.Caption), R, DT_CENTER or DT_VCENTER or DT_SINGLELINE or DT_NOPREFIX or DT_END_ELLIPSIS);
    C.Brush.Style := bsSolid;
  end;
end;

type
  TButtonColorAccess = class(TButton);

procedure TfrmPicView.ApplyDarkTheme;
var
  I: Integer;
  P: TPanel;
begin
  Color := PV_DARK_BG;
  Font.Color := clWhite;

  for I := 0 to ComponentCount - 1 do
  begin
    if Components[I] is TPanel then
    begin
      P := TPanel(Components[I]);
      P.ParentBackground := False;
      P.StyleElements := [];
      P.Font.Color := clWhite;
      if (P = PanelRightHead) or (P = PanelBrowseHead) or (P = PanelThumbsHead) then
        P.Color := PV_DARK_PANEL
      else if (P = PanelToolBarHost) or (P = PanelTabs) or (P = PanelAddress) then
        P.Color := PV_DARK_BAR
      else
        P.Color := PV_DARK_BG;
    end
    else if Components[I] is TLabel then
    begin
      TLabel(Components[I]).StyleElements := [];
      TLabel(Components[I]).Font.Color := clWhite;
    end
    else if Components[I] is TButton then
    begin
      TButton(Components[I]).StyleElements := [];
      TButtonColorAccess(Components[I]).Color := PV_DARK_PANEL;
      TButton(Components[I]).Font.Color := clWhite;
    end
    else if Components[I] is TSpeedButton then
    begin
      TSpeedButton(Components[I]).Font.Color := clWhite;
    end
    else if Components[I] is TComboBox then
    begin
      TComboBox(Components[I]).StyleElements := [];
      TComboBox(Components[I]).Color := PV_DARK_SURFACE;
      TComboBox(Components[I]).Font.Color := clWhite;
    end;
  end;

  ActionManager1.Style := StandardStyle;
  MenuMain.OnGetPopupClass := PvMenuGetPopupClass;
  MenuMain.HorzMargin := PV_MENU_HORZ_MARGIN;  { 菜单条/下拉弹窗整体离左边缘 }
  MenuMain.Color := PV_DARK_BAR;
  MenuMain.Font.Color := clWhite;
  if MenuMain.ColorMap <> nil then
  begin
    MenuMain.ColorMap.Color := PV_DARK_BAR;
    MenuMain.ColorMap.MenuColor := PV_DARK_BAR;
    MenuMain.ColorMap.FontColor := clWhite;
    MenuMain.ColorMap.HotFontColor := clWhite;
    MenuMain.ColorMap.SelectedFontColor := clWhite;
    MenuMain.ColorMap.BtnSelectedFont := clWhite;
    MenuMain.ColorMap.DisabledFontColor := PV_DARK_TEXT_DIM;
    MenuMain.ColorMap.DisabledFontShadow := PV_DARK_BAR;
    MenuMain.ColorMap.SelectedColor := PV_DARK_ACCENT;
    MenuMain.ColorMap.HighlightColor := PV_DARK_ACCENT;
    MenuMain.ColorMap.BtnSelectedColor := PV_DARK_ACCENT;
    MenuMain.ColorMap.BtnFrameColor := PV_DARK_BORDER;
    MenuMain.ColorMap.HotColor := PV_DARK_ACCENT;
    MenuMain.ColorMap.UnusedColor := PV_DARK_BAR;
    MenuMain.ColorMap.FrameTopLeftInner := PV_DARK_BORDER;
    MenuMain.ColorMap.FrameTopLeftOuter := PV_DARK_BORDER;
    MenuMain.ColorMap.FrameBottomRightInner := PV_DARK_BORDER;
    MenuMain.ColorMap.FrameBottomRightOuter := PV_DARK_BORDER;
    MenuMain.ColorMap.ShadowColor := PV_DARK_BG;
  end;
  MenuMain.Invalidate;

  ToolBarBrowse.Color := PV_DARK_BAR;
  ToolBarView.Color := PV_DARK_BAR;
  ToolBarBrowse.ParentColor := False;
  ToolBarView.ParentColor := False;
  ToolBarBrowse.Font.Color := clWhite;
  ToolBarView.Font.Color := clWhite;
  ToolBarBrowse.OnCustomDrawButton := PvToolBarDraw;
  ToolBarView.OnCustomDrawButton := PvToolBarDraw;

  lvBrowse.Color := PV_DARK_SURFACE;
  lvThumbs.Color := PV_DARK_SURFACE;
  lvBrowse.Colors.FocusedSelectionColor := PV_DARK_ACCENT;
  lvThumbs.Colors.FocusedSelectionColor := PV_DARK_ACCENT;
  ScrollBoxViewer.Color := PV_DARK_BAR;
  PanelHint.Color       := PV_DARK_BG;
  vleInfo.Color         := PV_DARK_SURFACE;
  vleInfo.FixedColor    := PV_DARK_BAR;
  vleInfo.Font.Color    := clWhite;
  StatusBar1.Font.Color := clWhite;

  SetupDarkPopup(PopupMenuBrowse);
  SetupDarkPopup(PopupMenuThumbs);
  SetupDarkPopup(PopupMenuTabs);
  SetupDarkPopup(PopupMenuView);
end;

procedure TfrmPicView.EnableDarkTitleBar;
const
  DWMWA_USE_IMMERSIVE_DARK_MODE_OLD = 19;
  DWMWA_USE_IMMERSIVE_DARK_MODE_NEW = 20;
var
  V: DWORD;
begin
  if not HandleAllocated then Exit;
  V := 1;
  if TOSVersion.Check(10) then
  begin
    if TOSVersion.Build >= 20348 then
      DwmSetWindowAttribute(Handle, DWMWA_USE_IMMERSIVE_DARK_MODE_NEW, @V, SizeOf(V))
    else
      DwmSetWindowAttribute(Handle, DWMWA_USE_IMMERSIVE_DARK_MODE_OLD, @V, SizeOf(V));
  end;
end;

procedure TfrmPicView.EnableNativeDarkMode;
type
  TSetPreferredAppMode = function(Mode: Integer): Integer; stdcall;
  TAllowDarkModeForWindow = function(AHandle: HWND; Allow: Boolean): Boolean; stdcall;
  TFlushMenuThemes = procedure; stdcall;
  TRefreshImmersiveColorPolicyState = procedure; stdcall;
var
  H: HMODULE;
  SetPreferredAppMode: TSetPreferredAppMode;
  AllowDarkModeForWindow: TAllowDarkModeForWindow;
  FlushMenuThemes: TFlushMenuThemes;
  RefreshImmersiveColorPolicyState: TRefreshImmersiveColorPolicyState;

  function ProcByOrd(AOrd: Integer): Pointer;
  var
    OrdValue: Cardinal;
    ProcName: PAnsiChar;
  begin
    OrdValue := Cardinal(AOrd);
    ProcName := PAnsiChar(@OrdValue);
    Result := GetProcAddress(H, ProcName);
  end;

begin
  if not TOSVersion.Check(10) then Exit;
  H := GetModuleHandle('uxtheme.dll');
  if H = 0 then Exit;
  try
    @SetPreferredAppMode := ProcByOrd(135);
    @AllowDarkModeForWindow := ProcByOrd(133);
    @FlushMenuThemes := ProcByOrd(136);
    @RefreshImmersiveColorPolicyState := ProcByOrd(104);
    if Assigned(SetPreferredAppMode) then SetPreferredAppMode(2);
    if Assigned(RefreshImmersiveColorPolicyState) then RefreshImmersiveColorPolicyState;
    if Assigned(AllowDarkModeForWindow) and HandleAllocated then
      AllowDarkModeForWindow(Handle, True);
    if Assigned(FlushMenuThemes) then FlushMenuThemes;
  except
  end;
end;

procedure TfrmPicView.FormCreate(Sender: TObject);
begin
  Screen.MenuFont.Name := 'Microsoft YaHei';
  Screen.MenuFont.Size := 14;
  MenuMain.AllowHiding := True;
  SetupDarkPopup(PopupMenuBrowse);
  SetupDarkPopup(PopupMenuThumbs);
  SetupDarkPopup(PopupMenuTabs);
  SetupDarkPopup(PopupMenuView);

  SetupVT(lvBrowse);
  SetupVT(lvThumbs);
  FSelBrowse := -1;
  FSelThumbs := -1;
  FTabs := TList<TTabInfo>.Create;
  SetLength(FTabCloseRects, 0);
  FTab := nil;
  FLoaded := False;
  FZoomMode := zmFit;
  FSortMode := smName;
  FThumbSize := 128;
  FPlaceholderIdx := 0;
  FFullScreen := False;
  FPendingFolder := '';
  FSelectedFolderPath := '';
  FFolderIconIdx := -1;
  FDriveIconIdx := -1;
  FUpIconIdx := -1;
  FRebuilding := False;
  FIndexSlot := TDictionary<Integer, Integer>.Create;
  FThumbFailed := TDictionary<Integer, Boolean>.Create;
  FThumbRequested := TDictionary<Integer, UInt64>.Create;
  FCaptionCache := TDictionary<Integer, string>.Create;
  FChangedIdx := TList<Integer>.Create;
  FEvictedIdx := -1;
  FMeasureBmp := nil;
  FSlotClock := 0;
  FThumbGen := 0;
  FLastTopIndex := -1;
  FVisibleFrom := -1;
  FVisibleTo := -1;
  FNeedSubmit := False;
  FThumbEngine := TThumbEngine.Create;
  ResetThumbSlots;
  actProperties.ShortCut := ShortCut(VK_RETURN, [ssAlt]);
  OpenDialog1.Filter := ImageOpenFilter;
  SaveDialog1.Filter := ImageSaveFilter;
  SaveDialog1.DefaultExt := 'png';
  LoadSettings;
  ApplyDarkTheme;
end;

procedure TfrmPicView.FormShow(Sender: TObject);
var
  S, D: string;
  T: TTabInfo;
begin
  FLoaded := True;
  DragAcceptFiles(Handle, True);
  EnableDarkTitleBar;
  EnableNativeDarkMode;
  { 上次浏览过的目录保留在地址栏历史里, 随时可以一键回去 }
  if (FFolder <> '') and (not IsDrivesRoot(FFolder)) then
    if cbPath.Items.IndexOf(FFolder) < 0 then
      cbPath.Items.Insert(0, FFolder);
  S := '';
  if ParamCount > 0 then S := ParamStr(1);
  if (S <> '') and TFile.Exists(S) then
    D := ExtractFileDir(S)
  else if (S <> '') and TDirectory.Exists(S) then
    D := S
  else if (FFolder <> '') and (not IsDrivesRoot(FFolder)) and  TDirectory.Exists(FFolder) then
    D := FFolder        { 没有命令行参数: 直接打开上次关闭时保存的目录 }
  else
    D := DRIVES_ROOT;   { 根目录: 本机磁盘 }
  if (D <> DRIVES_ROOT) and (not TDirectory.Exists(D)) then D := DRIVES_ROOT;

  { 启动时永远是缩略图浏览模式 }
  T := AddTab(tmBrowse, D, '');
  T.CanClose := False;   { 启动浏览页签为根页签, 不允许关闭 }
  ActivateTab(T);

  if (S <> '') and TFile.Exists(S) then OpenViewTab(D, S);
end;

procedure TfrmPicView.FormDestroy(Sender: TObject);
var
  T: TTabInfo;
begin
  FClosing             := True;
  TimerThumbs.Enabled  := False;
  TimerRepaint.Enabled := False;
  TimerSlide.Enabled   := False;
  TimerHint.Enabled    := False;
  SaveSettings;
  FTab := nil;
  for T in FTabs do T.Free;
  FTabs.Clear;
  FTabs.Free;
  FreeAndNil(FThumbEngine);
  FreeAndNil(FMeasureBmp);
  FreeAndNil(FCaptionCache);
  FreeAndNil(FChangedIdx);
  FreeAndNil(FThumbRequested);
  FreeAndNil(FThumbFailed);
  FreeAndNil(FIndexSlot);
end;

procedure TfrmPicView.cbPathKeyPress(Sender: TObject; var Key: Char);
begin
  if Key = #13 then
  begin
    Key := #0;
    actGoExecute(nil);
  end;
end;

procedure TfrmPicView.cbThumbSizeChange(Sender: TObject);
begin
  if (not FLoaded) or FUpdatingUI then Exit;
  SetThumbSize(StrToIntDef(cbThumbSize.Text, 128));
end;

procedure TfrmPicView.cbSortChange(Sender: TObject);
begin
  if (not FLoaded) or FUpdatingUI then Exit;
  if (cbSort.ItemIndex >= 0) and (cbSort.ItemIndex <= Ord(smType)) then SetSortMode(TSortMode(cbSort.ItemIndex));
end;

procedure TfrmPicView.HandleBrowseSelect(I: Integer);
var
  Ofs: Integer;
begin
  if FSelectingThumb or FRebuilding then Exit;
  if (FTab = nil) or (FTab.Mode <> tmBrowse) then Exit;
  
  Ofs := ItemOffset;
  if (I >= 0) and (I < Ofs) and (I < Length(FTab.Folders)) then
  begin
    FSelectedFolderPath := FTab.Folders[I].Path;
    FTab.Index          := -1;
    UpdateStatus;
    Exit;
  end;
  
  FSelectedFolderPath := '';
  FTab.Index := I - Ofs;
  if (FTab.Index < 0) or (FTab.Index > High(FTab.Files)) then FTab.Index := -1;
  UpdateInfo;
  UpdateStatus;
end;

procedure TfrmPicView.HandleThumbsSelect(I: Integer);
begin
  if FSelectingThumb then Exit;
  if (FTab = nil) or (FTab.Mode <> tmView) then Exit;
  
  if I <> FTab.Index then
  begin
    FTab.Index := I;
    LoadCurrentImage;
    UpdateInfo;
    UpdateStatus;
    UpdateCaption;
  end;
end;

procedure TfrmPicView.lvBrowseDblClick(Sender: TObject);
var
  I, Ofs: Integer;
begin
  if (FTab = nil) or (FTab.Mode <> tmBrowse) then Exit;
  
  Ofs := ItemOffset;
  I := FSelBrowse;
  if I < 0 then Exit;
  
  if (I >= 0) and (I < Ofs) then
  begin
    NavigateToFolder(I);
    Exit;
  end;
  
  I := I - Ofs;
  if (I < 0) or (I > High(FTab.Files)) then Exit;
  
  FTab.Index := I;
  OpenViewTab(FTab.Folder, FTab.Files[I].Path);
end;

{ 动作 }

procedure TfrmPicView.actOpenFolderExecute(Sender: TObject);
var
  D: string;
begin
  if not IsDrivesRoot(FFolder) then FileOpenDialog1.DefaultFolder := FFolder;
  if not FileOpenDialog1.Execute then Exit;
  
  D := FileOpenDialog1.FileName;
  if (FTab <> nil) and (FTab.Mode = tmBrowse) then
  begin
    LoadFolderIntoTab(FTab, D, '');
    ActivateTab(FTab);
  end
  else
    ActivateTab(AddTab(tmBrowse, D, ''));
end;

procedure TfrmPicView.actOpenFileExecute(Sender: TObject);
var
  F: string;
begin
  OpenDialog1.InitialDir := FFolder;
  if not OpenDialog1.Execute then Exit;
  
  F := OpenDialog1.FileName;
  OpenViewTab(ExtractFileDir(F), F);
end;

procedure TfrmPicView.actNewBrowseTabExecute(Sender: TObject);
var
  D: string;
begin
  if FTab <> nil then
    D := FTab.Folder
  else
    D := FFolder;
  ActivateTab(AddTab(tmBrowse, D, ''));
end;

procedure TfrmPicView.actCloseTabExecute(Sender: TObject);
begin
  CloseActiveTab;
end;

procedure TfrmPicView.actCloseOthersExecute(Sender: TObject);
var
  Keep: TTabInfo;
  I: Integer;
begin
  Keep := FTab;
  if Keep = nil then Exit;
  
  for I := FTabs.Count - 1 downto 0 do
    if (FTabs[I] <> Keep) and FTabs[I].CanClose then
      RemoveTab(FTabs[I]);
  ActivateTab(Keep);
end;

procedure TfrmPicView.actCloseAllExecute(Sender: TObject);
var
  D   : string;
  Keep: TTabInfo;
  I   : Integer;
begin
  Keep := nil;
  for I := 0 to FTabs.Count - 1 do
    if not FTabs[I].CanClose then
    begin
      Keep := FTabs[I];
      Break;
    end;
	
  if Keep = nil then
  begin
    if FTab <> nil then
      D := FTab.Folder
    else
      D := FFolder;
    Keep := AddTab(tmBrowse, D, '');
    Keep.CanClose := False;
  end;
  
  for I := FTabs.Count - 1 downto 0 do
    if (FTabs[I] <> Keep) and FTabs[I].CanClose then
      RemoveTab(FTabs[I]);
  ActivateTab(Keep);
end;

procedure TfrmPicView.actExitExecute(Sender: TObject);
begin
  Close;
end;

procedure TfrmPicView.actRefreshExecute(Sender: TObject);
var
  T: TTabInfo;
begin
  if FTab = nil then Exit;
  
  for T in FTabs do
    if SameText(T.Folder, FTab.Folder) then
      RebuildTabFiles(T, T.CurrentPath, T.Mode = tmView);
  ActivateTab(FTab);
end;

procedure TfrmPicView.actViewSelectedExecute(Sender: TObject);
var
  I, Ofs: Integer;
begin
  if (FTab = nil) or (FTab.Mode <> tmBrowse) then Exit;
  
  Ofs := ItemOffset;
  I := FSelBrowse;
  if I < 0 then I := FTab.Index + Ofs;
  if (I >= 0) and (I < Ofs) then
  begin
    NavigateToFolder(I);
    Exit;
  end;
  
  I := I - Ofs;
  if (I < 0) or (I > High(FTab.Files)) then Exit;
  
  FTab.Index := I;
  OpenViewTab(FTab.Folder, FTab.Files[I].Path);
end;

procedure TfrmPicView.actBackToBrowseExecute(Sender: TObject);
var
  T: TTabInfo;
begin
  if FTab = nil then Exit;
  
  T := FindBrowseTab(FTab.Folder);
  if T = nil then T := AddTab(tmBrowse, FTab.Folder, '');
  ActivateTab(T);
end;

procedure TfrmPicView.actGoExecute(Sender: TObject);
var
  P: string;
begin
  if (FTab = nil) or (FTab.Mode <> tmBrowse) then Exit;
  
  P := Trim(cbPath.Text);
  if SameText(P, DRIVES_LABEL) then P := DRIVES_ROOT;
  if P = '' then Exit;
  
  LoadFolderIntoTab(FTab, P, '');
  ActivateTab(FTab);
end;

procedure TfrmPicView.actGoUpExecute(Sender: TObject);
var
  P: string;
begin
  if (FTab = nil) or (FTab.Mode <> tmBrowse) then Exit;
  
  P := ParentFolderOf(FTab.Folder);
  if P = '' then Exit;
  
  LoadFolderIntoTab(FTab, P, '');
  ActivateTab(FTab);
end;

procedure TfrmPicView.actPrevExecute(Sender: TObject);
begin
  PrevImage;
end;

procedure TfrmPicView.actNextExecute(Sender: TObject);
begin
  NextImage;
end;

procedure TfrmPicView.actFirstExecute(Sender: TObject);
begin
  if (FTab = nil) or (FTab.Mode <> tmView) or (Length(FTab.Files) = 0) then Exit;
  FTab.Index := 0;
  LoadCurrentImage;
  SelectThumb(0);
  UpdateInfo;
  UpdateStatus;
  UpdateCaption;
end;

procedure TfrmPicView.actLastExecute(Sender: TObject);
begin
  if (FTab = nil) or (FTab.Mode <> tmView) or (Length(FTab.Files) = 0) then Exit;
  FTab.Index := High(FTab.Files);
  LoadCurrentImage;
  SelectThumb(FTab.Index);
  UpdateInfo;
  UpdateStatus;
  UpdateCaption;
end;

procedure TfrmPicView.actFitExecute(Sender: TObject);
begin
  SetZoomMode(zmFit);
end;

procedure TfrmPicView.actActualExecute(Sender: TObject);
begin
  SetZoomMode(zmActual);
end;

procedure TfrmPicView.actZoomInExecute(Sender: TObject);
begin
  ZoomStep(1.25);
end;

procedure TfrmPicView.actZoomOutExecute(Sender: TObject);
begin
  ZoomStep(1 / 1.25);
end;

procedure TfrmPicView.actRotateCWExecute(Sender: TObject);
begin
  if (FTab = nil) or (FTab.Mode <> tmView) then Exit;
  FTab.Rotation := (FTab.Rotation + 1) mod 4;
  ApplyZoom;
  UpdateInfo;
end;

procedure TfrmPicView.actRotateCCWExecute(Sender: TObject);
begin
  if (FTab = nil) or (FTab.Mode <> tmView) then Exit;
  FTab.Rotation := (FTab.Rotation + 3) mod 4;
  ApplyZoom;
  UpdateInfo;
end;

procedure TfrmPicView.actSlideShowExecute(Sender: TObject);
begin
  if (FTab = nil) or (FTab.Mode <> tmView) then
  begin
    actSlideShow.Checked := False;
    Exit;
  end;
  
  TimerSlide.Enabled := actSlideShow.Checked;
  if actSlideShow.Checked then
    SetFullScreen(True)
  else
    SetFullScreen(False);
end;

procedure TfrmPicView.actFullScreenExecute(Sender: TObject);
begin
  Exit;

  if (FTab = nil) or (FTab.Mode <> tmView) then
  begin
    actFullScreen.Checked := False;
    Exit;
  end;
  
  SetFullScreen(actFullScreen.Checked);
  if not actFullScreen.Checked then
  begin
    actSlideShow.Checked := False;
    TimerSlide.Enabled := False;
  end;
end;

procedure TfrmPicView.actDeleteExecute(Sender: TObject);
var
  S, NextName, Pref: string;
  T: TTabInfo;
begin
  S := CurrentPath;
  if (S = '') or (not TFile.Exists(S)) then Exit;
  if MessageDlg('确定把下面这个文件删除到回收站吗?' + #13#10 + S, mtConfirmation, [mbYes, mbNo], 0) <> mrYes then Exit;
  
  NextName := '';
  if FTab.Index + 1 <= High(FTab.Files) then
    NextName := FTab.Files[FTab.Index + 1].Path
  else if FTab.Index - 1 >= 0 then
    NextName := FTab.Files[FTab.Index - 1].Path;
  DeleteToRecycleBin(S);
  for T in FTabs do
    if SameText(T.Folder, FTab.Folder) then
    begin
      if T = FTab then
        Pref := NextName
      else
        Pref := T.CurrentPath;
      RebuildTabFiles(T, Pref, T.Mode = tmView);
    end;
  ActivateTab(FTab);
end;

procedure TfrmPicView.actSaveAsExecute(Sender: TObject);
var
  S, E: string;
  Bmp: TBitmap;
  Png: TPngImage;
  Jpg: TJPEGImage;
begin
  if (FTab = nil) or (FTab.Base = nil) or (FTab.Index < 0) or (FTab.Index > High(FTab.Files)) then Exit;
  
  SaveDialog1.InitialDir := FTab.Folder;
  SaveDialog1.FileName := ChangeFileExt(FTab.Files[FTab.Index].Name, '.png');
  if not SaveDialog1.Execute then Exit;
  
  S := SaveDialog1.FileName;
  E := LowerCase(ExtractFileExt(S));
  Bmp := nil;
  try
    if FTab.Rotation = 0 then
      Bmp := FTab.Base
    else
      Bmp := RotateBitmap(FTab.Base, FTab.Rotation);
    if E = '.png' then
    begin
      Png := TPngImage.Create;
      try
        Png.Assign(Bmp);
        Png.SaveToFile(S);
      finally
        Png.Free;
      end;
    end
    else if (E = '.jpg') or (E = '.jpeg') then
    begin
      Jpg := TJPEGImage.Create;
      try
        Jpg.Assign(Bmp);
        Jpg.CompressionQuality := 92;
        Jpg.SaveToFile(S);
      finally
        Jpg.Free;
      end;
    end
    else
      Bmp.SaveToFile(S);
    StatusBar1.Panels[4].Text := '已保存: ' + S;
  except
    on Ex: Exception do
      ShowMessage('保存失败: ' + Ex.Message);
  end;
  if Bmp <> FTab.Base then Bmp.Free;
end;

procedure TfrmPicView.actCopyImageExecute(Sender: TObject);
begin
  if (FTab <> nil) and (FTab.Base <> nil) then Clipboard.Assign(FTab.Base);
end;

procedure TfrmPicView.actCopyPathExecute(Sender: TObject);
begin
  if CurrentPath <> '' then Clipboard.AsText := CurrentPath;
end;

procedure TfrmPicView.actExploreExecute(Sender: TObject);
begin
  if CurrentPath = '' then Exit;
  
  ShellExecute(Handle, 'open', 'explorer.exe', PChar('/select,' + CurrentPath), nil, SW_SHOWNORMAL);
end;

procedure TfrmPicView.actPanelsExecute(Sender: TObject);
begin
  if FTab <> nil then ApplyModeUI;
end;

procedure TfrmPicView.actComputerExecute(Sender: TObject);
begin
  { 跳到根目录: 本机磁盘列表 }
  if (FTab <> nil) and (FTab.Mode = tmBrowse) then
  begin
    LoadFolderIntoTab(FTab, DRIVES_ROOT, '');
    ActivateTab(FTab);
  end
  else
    ActivateTab(AddTab(tmBrowse, DRIVES_ROOT, ''));
end;

procedure TfrmPicView.actSortExecute(Sender: TObject);
begin
  if Sender = actSortSize then
    SetSortMode(smSize)
  else if Sender = actSortDate then
    SetSortMode(smDate)
  else if Sender = actSortType then
    SetSortMode(smType)
  else
    SetSortMode(smName);
end;

procedure TfrmPicView.actThumbSizeExecute(Sender: TObject);
begin
  if Sender is TAction then SetThumbSize(TAction(Sender).Tag);
end;

procedure TfrmPicView.actThumbStepExecute(Sender: TObject);
var
  I, Cur: Integer;
begin
  Cur := 2;
  for I := 0 to High(THUMB_STEPS) do
    if THUMB_STEPS[I] = FThumbSize then
    begin
      Cur := I;
      Break;
    end;
  if Sender = actThumbSmaller then
    Dec(Cur)
  else
    Inc(Cur);
  if Cur < 0 then Cur := 0;
  if Cur > High(THUMB_STEPS) then Cur := High(THUMB_STEPS);
  SetThumbSize(THUMB_STEPS[Cur]);
end;

procedure TfrmPicView.actAboutExecute(Sender: TObject);
begin
  var F := TAboutForm.Create(Self);
  try
    F.ShowModal;
  finally
    F.Free;
  end;
end;

procedure TfrmPicView.OpenFolder(const APath: string; const ASelectFile: string);
var
  T: TTabInfo;
begin
  if (FTab <> nil) and (FTab.Mode = tmBrowse) then
    T := FTab
  else
    T := AddTab(tmBrowse, APath, '');
  LoadFolderIntoTab(T, APath, ASelectFile);
  ActivateTab(T);
end;

procedure TfrmPicView.OpenViewTab(const AFolder, AFile: string);
begin
  ActivateTab(AddTab(tmView, AFolder, AFile));
end;

procedure TfrmPicView.CloseActiveTab;
begin
  CloseTab(FTab);
end;

function TfrmPicView.TabCount: Integer;
begin
  Result := FTabs.Count;
end;

function TfrmPicView.ActiveMode: TTabMode;
begin
  if FTab <> nil then
    Result := FTab.Mode
  else
    Result := tmBrowse;
end;

initialization
  RegisterClasses([TVirtualStringTree]);

end.
