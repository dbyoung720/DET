unit uMain;

interface

uses
  Winapi.Windows, Winapi.Messages, System.IniFiles, System.SysUtils, System.Variants, System.Classes, System.Math, System.StrUtils, System.Types, System.ImageList,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.TitleBarCtrls, Vcl.ExtCtrls,Vcl.BaseImageCollection, Vcl.ImageCollection,
  Vcl.VirtualImageList, Vcl.ImgList, Vcl.StdCtrls, Vcl.Menus, Vcl.Imaging.pngimage, Vcl.Mask, Vcl.WinXCtrls, Vcl.ComCtrls, Vcl.Buttons, Vcl.TabView,
  Data.DB, DBAccess, UniDacVcl,Uni, PostgreSQLUniProvider, InterBaseUniProvider, DB2UniProvider, ODBCUniProvider, OracleUniProvider, MySQLUniProvider, UniProvider, SQLServerUniProvider,
  RzTabs, RzEdit, RzBtnEdt, uCommon, uLogger, uTabView;

type
  TfrmMain = class(TForm)
    tlbrpnl1: TTitleBarPanel;
    tmrStart: TTimer;
    pnlModule: TPanel;
    pnlPages: TPanel;
    pgModule: uTabView.TTabView;
    pnlWelcome: TPanel;
    pnlConfig: TPanel;
    tvModule: TTreeView;
    imlToolImages: TImageList;
    vrtlmglstTreeView: TVirtualImageList;
    imgclctnTreeViewModule: TImageCollection;
    lblTitle: TLabel;
    lblTime: TLabel;
    tmrTime: TTimer;
    trycnModule: TTrayIcon;
    pmModule: TPopupMenu;
    mniShow: TMenuItem;
    mniLine01: TMenuItem;
    mniExit: TMenuItem;
    vrtlmglstModule: TVirtualImageList;
    imgclctnModule: TImageCollection;
    rzpgcntrlConfig: TRzPageControl;
    rztbshtSystem: TRzTabSheet;
    lblWelcome: TLabel;
    lblOnlyOneInstance: TLabel;
    edtAppTile: TEdit;
    tglswtchOnlyOneRunInstance: TToggleSwitch;
    rztbshtModuleConfig: TRzTabSheet;
    rzpgcntrlModuleSortAndExeManager: TRzPageControl;
    rztbshtModuleEXE: TRzTabSheet;
    lvModuleEXE: TListView;
    pnlModuleEXE: TPanel;
    btnAddModuleEXE: TSpeedButton;
    btnDelModuleEXE: TSpeedButton;
    rztbshtModuleSort: TRzTabSheet;
    pnlModuleMove: TPanel;
    btnDown: TSpeedButton;
    btnUP: TSpeedButton;
    btnModuleMoveSave: TSpeedButton;
    tvModuleSort: TTreeView;
    rztbshtDatabase: TRzTabSheet;
    rztbshtEXEPath: TRzTabSheet;
    lblVlcPath: TLabel;
    imgVLCOK: TImage;
    lblChromePath: TLabel;
    imgChromeOK: TImage;
    btnVlcPath: TRzButtonEdit;
    btnChromePath: TRzButtonEdit;
    rzpgcntrlDataBaseConfig: TRzPageControl;
    rztbshtDataBaseManager: TRzTabSheet;
    rztbshtDataBaseLink: TRzTabSheet;
    grpLogin: TGroupBox;
    lblLoginTable: TLabel;
    lblLoginNameField: TLabel;
    lblLoginPassField: TLabel;
    btnLoginCheckSave: TSpeedButton;
    lblLoginDLL: TLabel;
    lblLoginDLLFunc: TLabel;
    cbbLoginTable: TComboBox;
    cbbLoginNameField: TComboBox;
    cbbLoginPassField: TComboBox;
    btnLoginDLL: TRzButtonEdit;
    cbbLoginDLLFunc: TComboBox;
    imgclctnButton: TImageCollection;
    vrtlmglstButton: TVirtualImageList;
    btnDBConnect: TButton;
    btnDBDisconnect: TButton;
    btnDelConnect: TButton;
    lblChromePath1: TLabel;
    btnChromePath1: TRzButtonEdit;
    UniConnection: TUniConnection;
    UniConnectDialog: TUniConnectDialog;
    SQLServerUniProvider1: TSQLServerUniProvider;
    MySQLUniProvider1: TMySQLUniProvider;
    OracleUniProvider1: TOracleUniProvider;
    ODBCUniProvider1: TODBCUniProvider;
    DB2UniProvider1: TDB2UniProvider;
    InterBaseUniProvider1: TInterBaseUniProvider;
    PostgreSQLUniProvider1: TPostgreSQLUniProvider;
    lblJavaPath: TLabel;
    btnJavaPath: TRzButtonEdit;
    edtTemp: TEdit;
    dlgOpenLoginCheck: TOpenDialog;
    lblLoginUser: TLabel;
    btnExpand: TSpeedButton;
    procedure tlbrpnl1CustomButtons0Click(Sender: TObject);
    procedure tlbrpnl1CustomButtons0Paint(Sender: TObject);
    procedure tlbrpnl1CustomButtons1Click(Sender: TObject);
    procedure tlbrpnl1CustomButtons1Paint(Sender: TObject);
    procedure tmrStartTimer(Sender: TObject);
    procedure btnExpandClick(Sender: TObject);
    procedure FormResize(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure tmrTimeTimer(Sender: TObject);
    procedure pgModuleCloseTab(Sender: TObject; ATab: TTabViewTab; var ACanClose: Boolean);
    procedure mniShowClick(Sender: TObject);
    procedure mniExitClick(Sender: TObject);
    procedure tvModuleDblClick(Sender: TObject);
    procedure pgModuleChange(Sender: TObject);
    procedure btnExpandMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
    procedure btnDBConnectClick(Sender: TObject);
    procedure UniConnectionAfterConnect(Sender: TObject);
    procedure UniConnectionAfterDisconnect(Sender: TObject);
    procedure btnDBDisconnectClick(Sender: TObject);
    procedure btnDelConnectClick(Sender: TObject);
    procedure cbbLoginTableChange(Sender: TObject);
    procedure rzpgcntrlConfigPageChange(Sender: TObject);
    procedure tvModuleSortChange(Sender: TObject; Node: TTreeNode);
    procedure btnUPClick(Sender: TObject);
    procedure btnDownClick(Sender: TObject);
    procedure btnModuleMoveSaveClick(Sender: TObject);
    procedure btnLoginCheckSaveClick(Sender: TObject);
    procedure btnLoginDLLButtonClick(Sender: TObject);
  private
    FbExit : Boolean;
    { 当前激活的页签内容容器 }
    function  ActivePage: TTabPage;
    { 模块页签数量（不含参数配置页签） }
    function  ModuleTabCount: Integer;
    { 参数配置页签是否已打开 }
    function  ConfigTabOpen: Boolean;
    { 参数配置页签的序号；未打开时返回 -1 }
    function  ConfigTabIndex: Integer;
    { 显示当前激活页签的内容 }
    procedure ShowActiveTabPage;
    { 显示欢迎页面（没有激活的页签） }
    procedure ShowWelcomePage;
    { 打开 / 关闭参数配置页签 }
    procedure ActivateConfigPage;
    procedure CloseConfigTab;
    { 激活指定序号的页签（强制触发 OnChangeTab） }
    procedure ActivateTabIndex(AIndex: Integer);
    { 绘制自定义按钮 }
    procedure DrawTitleBarButton(Sender: TObject; const iIndex: Integer);
  	{ 居中显示 }
    procedure CenterTitle;
  	{检查 DLL 窗体模块是否已经创建了 }
    function CheckExistModule(const strModuleInfo : string) : Boolean;
  	{ 创建 DLL 窗体模块 }
    procedure CreateDllForm(const strModuleInfo : string);
  	{ 销毁 DLL 窗体模块 }
    procedure FreeDllForm;
    procedure ModuleMenuItemOnClick(Sender: TObject);
    { 程序退出时，销毁所有的 DLL 模块 }
    procedure FreeAllDllForm;
    { 配置页面初始化 }
    procedure InitConfigPage;
  	{ 数据库连接 }
    procedure LinkDataBase;
    { 调整模块位置时，上移、下移按钮的可用状态 }
    procedure UpdateModuleMoveButtonState;
    { 页签销毁之后 }
    procedure AfterTabFree;
  protected
    { 绘制非客户区 }
    procedure WMNCACTIVE(var msg: TWMNCActivate); message WM_NCACTIVATE;
    { 销毁所有的 DLL Form 模块 }
    procedure WMFREEALLDLLFORM(var msg: TMessage); message WM_FREEALLDLLFORM;
  end;

var
  frmMain: TfrmMain;

implementation

uses uDllDelphi, uDllExe, uDllVCDLG;

{$R *.dfm}
{$I config.inc}

{ 使用定时器，避免界面初始化时界面的闪烁；窗口默认最小化，初始化完成后最大化显示 }
procedure TfrmMain.tmrStartTimer(Sender: TObject);
begin
  tmrStart.Enabled      := False;
  FbExit                := False;
  var strTitle          := '欢迎使用' + GetTitleText;
  Caption               := strTitle;
  Application.Title     := strTitle;
  lblTitle.Caption      := strTitle;
  trycnModule.Hint      := strTitle;
  Color                 := CH_TAB_ACTIVE;
  CustomTitleBar.Height := cTitleBarHeight;
  lblTime.Caption       := GetCurrentTime;
  lblLoginUser.Caption  := IfThen(Hint.IsEmpty, '', '当前登录用户：' + Hint);
  CenterTitle;
  AddDllDirectory(PChar(ExtractFilePath(ParamStr(0)) + c_strPlugIns));

  ShowWelcomePage;
  btnExpand.Hint  := c_strExpandHint;
  pnlModule.Width := c_intModuleMaxWidth;

  { 加载模块列表 }
  var strMouduleFileName := ChangeFileExt(ParamStr(0), '.dat');
  if FileExists(strMouduleFileName) then
  begin
    with TMemoryStream.Create do
    begin
      LoadFromFile(strMouduleFileName);
      Position := 0;
      ReadComponent(tvModule);
      tvModule.Visible := True;
      Free;
    end;
  end
  else
  begin
    LoadModuleList(tvModule);
  end;
  Winapi.Windows.SetFocus(tvModule.Handle);
  if tvModule.Items.Count > 0 then tvModule.Selected := tvModule.Items[0];
  LoadModuleToPopMenu(tvModule, pmModule, ModuleMenuItemOnClick);

  { 配置页面初始化 }
  InitConfigPage;

  { 程序初始化完毕，最大化显示窗体 }
  WindowState := TWindowState.wsMaximized;
end;

{ 配置页面初始化 }
procedure TfrmMain.InitConfigPage;
begin
  rzpgcntrlConfig.ActivePageIndex                  := 3;
  rzpgcntrlModuleSortAndExeManager.ActivePageIndex := 0;
  edtAppTile.Text                                  := GetTitleText;
  rzpgcntrlDataBaseConfig.ActivePageIndex          := 1;
  LinkDataBase;
end;

procedure TfrmMain.tmrTimeTimer(Sender: TObject);
begin
  lblTime.Caption := GetCurrentTime;
end;

procedure TfrmMain.btnExpandClick(Sender: TObject);
begin
  tvModule.Visible := False;
  pnlModule.Width  := Ifthen(btnExpand.Hint = c_strExpandHint, c_intModuleMinWidth, c_intModuleMaxWidth);
  tvModule.Visible := pnlModule.Width <> c_intModuleMinWidth;
  btnExpand.Hint   := IfThen(pnlModule.Width = c_intModuleMinWidth, c_strCollapHint, c_strExpandHint);
  OnResize(nil);
end;

procedure TfrmMain.btnExpandMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  if Button = TMouseButton.mbRight then
  begin
    if (pmModule.Items.Count > 0) and (SameText(pmModule.Items[0].Caption, '显示')) then
    begin
      pmModule.Items[0].Visible := False;
      pmModule.Items[1].Visible := False;
      pmModule.Items[pmModule.Items.Count - 1].Visible := False;
      pmModule.Items[pmModule.Items.Count - 2].Visible := False;
    end;
    pmModule.Popup(Mouse.CursorPos.X, Mouse.CursorPos.Y);
  end;
end;

{ 居中显示 }
procedure TfrmMain.CenterTitle;
begin
  lblTitle.Left     := (lblTitle.Parent.Width - lblTitle.Width) div 2;
  lblTitle.Top      := (Height - lblTitle.Height - tlbrpnl1.Height) div 2 - 100;
  lblTime.Top       := lblTitle.Top  + lblTitle.Height + 20;
  lblTime.Left      := lblTitle.Left + lblTitle.Width  - lblTime.Width;
  lblLoginUser.Top  := lblTime.Top   + lblTime.Height  + 20;
  lblLoginUser.Left := lblTitle.Left + lblTitle.Width  - lblLoginUser.Width;
end;

{ 绘制自定义按钮 }
procedure TfrmMain.DrawTitleBarButton(Sender: TObject; const iIndex: Integer);
begin
  var SysButton := TSystemTitleBarButton(Sender);
  var X         := SysButton.ClientRect.Left + (SysButton.ClientRect.Width - 16) div 2;
  var Y         := SysButton.ClientRect.Top  + (SysButton.ClientRect.Height - 16) div 2;
  imlToolImages.Draw(SysButton.Canvas, X, Y, iIndex);
end;

{ 窗体关闭时，销毁所有的 DLL 窗体模块 }
procedure TfrmMain.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  if not FbExit then
  begin
    Action := TCloseAction.caNone;
    Hide;
    PostMessage(Handle, WM_FREEALLDLLFORM, 0, 0);
  end
  else
  begin
    Action := TCloseAction.caFree;
  end;
end;

procedure TfrmMain.FormCreate(Sender: TObject);
begin
  Constraints.MinHeight := 900;
  Constraints.MinWidth  := 1500;
end;

procedure TfrmMain.FormResize(Sender: TObject);
var
  rt1, rt2: TRect;
begin
  CenterTitle;

  var LPage := ActivePage;
  if LPage = nil then Exit;

  var hDllForm := LPage.DisabledIndex;
  if hDllForm = -1 then Exit;

  { DLL 窗体最大化；判断窗体大小是否发生改变，如果发生改变，刷新界面大小，否则不刷新。目的是减少界面闪烁 }
  GetWindowRect(LPage.Handle, rt1);
  GetWindowRect(hDllForm, rt2);
  if rt1 <> rt2 then SetWindowPos(hDllForm, 0, 0, 0, LPage.ClientWidth, LPage.ClientHeight, SWP_NOZORDER + SWP_NOACTIVATE);
end;

procedure TfrmMain.mniExitClick(Sender: TObject);
begin
   tmrTime.Enabled := False;
   Close;
end;

procedure TfrmMain.mniShowClick(Sender: TObject);
begin
  Show;
  PostMessage(Handle, WM_SYSCOMMAND, SC_RESTORE, 0);
  trycnModule.Visible := False;
end;

procedure TfrmMain.ModuleMenuItemOnClick(Sender: TObject);
begin
  var iTag := TMenuItem(Sender).Tag;
  if iTag < c_iMinModuleIndex then Exit;

  for var I := 0 to tvModule.Items.Count - 1 do
  begin
    if (not (tvModule.Items[I].HasChildren)) and (tvModule.Items[I].ExpandedImageIndex = iTag) then
    begin
      tvModule.Items[I].Selected := True;
      tvModule.OnDblClick(nil);
      if not Visible then mniShowClick(nil);
      Break;
    end;
  end;
end;

procedure TfrmMain.tlbrpnl1CustomButtons0Paint(Sender: TObject);
begin
  DrawTitleBarButton(Sender, 0);
end;

procedure TfrmMain.tlbrpnl1CustomButtons1Paint(Sender: TObject);
begin
  DrawTitleBarButton(Sender, 1);
end;

procedure TfrmMain.tlbrpnl1CustomButtons0Click(Sender: TObject);
begin
  if tvModule.Visible then btnExpandClick(nil);
  ActivateConfigPage;
end;

procedure TfrmMain.tlbrpnl1CustomButtons1Click(Sender: TObject);
begin
  if not SameText(pmModule.Items[0].Caption, '显示') then
  begin
    var mmItem1     := TMenuItem.Create(Self);
    mmItem1.Caption := '显示';
    mmItem1.OnClick := mniShowClick;
    pmModule.Items.Insert(0, mmItem1);

    var mmItem2     := TMenuItem.Create(Self);
    mmItem2.Caption := '-';
    pmModule.Items.Insert(1, mmItem2);

    var mmItem3     := TMenuItem.Create(Self);
    mmItem3.Caption := '-';
    pmModule.Items.Add(mmItem3);

    var mmItem4     := TMenuItem.Create(Self);
    mmItem4.Caption := '退出';
    mmItem4.OnClick := mniExitClick;
    pmModule.Items.Add(mmItem4);
  end
  else
  begin
    pmModule.Items[0].Visible := True;
    pmModule.Items[1].Visible := True;
    pmModule.Items[pmModule.Items.Count - 1].Visible := True;
    pmModule.Items[pmModule.Items.Count - 2].Visible := True;
  end;

  WindowState := TWindowState.wsMinimized;
  Hide;
  trycnModule.Visible := True;
end;

{ 销毁所有的 DLL Form 模块 }
procedure TfrmMain.WMFREEALLDLLFORM(var msg: TMessage);
begin
  FreeAllDllForm;
  FbExit := True;
  Close;
end;

{ 程序退出时，销毁所有的 DLL 模块 }
procedure TfrmMain.FreeAllDllForm;
begin
  for var I := 0 to pgModule.Tabs.Count - 1 do
  begin
    ActivateTabIndex(I); // 设置激活页面
    DelayTime(100);      // 等待页签切换完成
    FreeDllForm;         // 销毁激活页面 DLL Form 模块
  end;
end;

{ 销毁 DLL 窗体模块 }
procedure TfrmMain.FreeDllForm;
begin
  var LPage := ActivePage;
  if LPage = nil then Exit;
  var strInfo := LPage.Hint;
  if Trim(strInfo).IsEmpty then Exit;
  if tvModule.Selected = nil then Exit;
  
  FLogger.Log('销毁模块：' + tvModule.Selected.Text + '(' + strInfo.Split([';'])[0] + ')'); 
  var lsDll := TLangStyle(StrToInt(strInfo.Split([';'])[1]));
  case lsDll of
    lsDelphi: FreeDelphiFormDll;
    lsEXE   : FreeEXEForm;
    lsVCDLG : FreeVcDlgFormDll;
    lsQT    : FreeVcDlgFormDll;
    lsVCMFC : ;
  end;
end;

procedure TfrmMain.WMNCACTIVE(var msg: TWMNCActivate);
begin
  msg.Result := 1;
end;

procedure TfrmMain.pgModuleChange(Sender: TObject);
begin
  ShowActiveTabPage;
  OnResize(nil);

  if pgModule.ActiveTab = nil then Exit;
  var iTag := pgModule.ActiveTab.Tag;
  if iTag < c_iMinModuleIndex then Exit;
  for var I := 0 to tvModule.Items.Count - 1 do
  begin
    if (not (tvModule.Items[I].HasChildren)) and (tvModule.Items[I].ExpandedImageIndex = iTag) then
    begin
      tvModule.Items[I].Selected := True;
      Break;
    end;
  end;
end;

{ 当前激活的页签内容容器 }
function TfrmMain.ActivePage: TTabPage;
begin
  Result := nil;
  if pgModule.ActiveTab = nil then Exit;
  var LControl := pgModule.ActiveTab.Control;
  if LControl is TTabPage then Result := TTabPage(LControl);
end;

{ 模块页签数量（不含参数配置页签） }
function TfrmMain.ModuleTabCount: Integer;
begin
  Result := pgModule.Tabs.Count;
  if ConfigTabOpen then Dec(Result);
end;

{ 参数配置页签的序号；未打开时返回 -1 }
function TfrmMain.ConfigTabIndex: Integer;
begin
  Result := -1;
  for var I := 0 to pgModule.Tabs.Count - 1 do
    if pgModule.Tabs[I].Control = pnlConfig then Exit(I);
end;

{ 参数配置页签是否已打开 }
function TfrmMain.ConfigTabOpen: Boolean;
begin
  Result := ConfigTabIndex >= 0;
end;

{ 显示当前激活页签的内容 }
procedure TfrmMain.ShowActiveTabPage;
begin
  pgModule.ShowPage(pgModule.ActiveTab);
  if pgModule.ActiveTab <> nil then pnlWelcome.Visible := False;
end;

{ 显示欢迎页面（没有激活的页签） }
procedure TfrmMain.ShowWelcomePage;
begin
  pgModule.ShowPage(nil);
  pgModule.TabIndex := -1;
  pnlWelcome.Visible := True;
end;

{ 激活指定序号的页签（强制触发 OnChangeTab） }
procedure TfrmMain.ActivateTabIndex(AIndex: Integer);
begin
  if (AIndex < 0) or (AIndex >= pgModule.Tabs.Count) then Exit;
  pgModule.TabIndex := -1;
  pgModule.TabIndex := AIndex;
end;

{ 打开参数配置页签 }
procedure TfrmMain.ActivateConfigPage;
begin
  if not ConfigTabOpen then
  begin
    var LTab := pgModule.AddTabPage(pnlConfig, 'Config / 配置', -1);
    LTab.Tag   := 1;
    { 参数配置页签固定在最左边 }
    LTab.Index := 0;
  end;
  ActivateTabIndex(ConfigTabIndex);
end;

{ 关闭参数配置页签（只隐藏，不销毁内容） }
procedure TfrmMain.CloseConfigTab;
var
  LIndex: Integer;
begin
  LIndex := ConfigTabIndex;
  if LIndex < 0 then Exit;

  pgModule.Tabs.Delete(LIndex);
  pnlConfig.Visible := False;

  if ModuleTabCount > 0 then
    ActivateTabIndex(pgModule.Tabs.Count - 1)
  else
  begin
    if not tvModule.Visible then btnExpandClick(nil);
    ShowWelcomePage;
  end;
end;

{ 页签销毁之后 }
procedure TfrmMain.AfterTabFree;
begin
  if ModuleTabCount > 0 then Exit;

  if ConfigTabOpen then
    ActivateTabIndex(ConfigTabIndex)
  else
  begin
    if not tvModule.Visible then btnExpandClick(nil);
    ShowWelcomePage;
  end;
end;

procedure TfrmMain.pgModuleCloseTab(Sender: TObject; ATab: TTabViewTab; var ACanClose: Boolean);
begin
  { 配置页签不允许销毁，只隐藏 }
  if ATab.Control = pnlConfig then
  begin
    ACanClose := False;
    CloseConfigTab;
    Exit;
  end;

  { 关闭的不是当前激活页签时，先激活它，确保销毁的是对应的 DLL 窗体 }
  if (ATab <> pgModule.ActiveTab) and (ATab.Index >= 0) then
    ActivateTabIndex(ATab.Index);

  { 销毁激活页面 DLLForm 模块 }
  FreeDllForm;

  { 销毁页签的内容容器（页签本身由 TTabView 销毁） }
  if ATab.Control is TTabPage then
  begin
    var LPage := TTabPage(ATab.Control);
    ATab.Control := nil;
    LPage.Free;
  end;

  { 销毁页签 }
  ACanClose := True;

  { 延迟到消息队列中执行，不阻碍页签的销毁；等待页签销毁完毕 }
  TThread.ForceQueue(nil, procedure begin AfterTabFree; end);
end;

{检查 DLL 窗体模块是否已经创建了 }
function TfrmMain.CheckExistModule(const strModuleInfo: string): Boolean;
begin
  Result := False;
  for var I := 0 to pgModule.Tabs.Count - 1 do
  begin
    if SameText(pgModule.Tabs[I].Hint, strModuleInfo) then
    begin
       Result := True;
       ActivateTabIndex(I);
    end;
  end;
end;

procedure TfrmMain.tvModuleDblClick(Sender: TObject);
begin
  if tvModule.Selected = nil then Exit;
  if tvModule.Selected.HasChildren then Exit;
  if tvModule.Selected.ExpandedImageIndex < c_iMinModuleIndex then Exit;
  var strModuleInfo := tvModule.Selected.Hint;
  if Trim(strModuleInfo).IsEmpty then Exit;
  if CheckExistModule(strModuleInfo) then Exit;

  CreateDllForm(strModuleInfo);
end;

{ 创建 DLL 窗体模块 }
procedure TfrmMain.CreateDllForm(const strModuleInfo: string);
begin
  var strArrInfo     := strModuleInfo.Split([';']);
  var lsDll          := TLangStyle(StrToInt(strArrInfo[1]));
  var strDllFileName := Ifthen(lsDll = lsEXE, WhereIs(strArrInfo[0]), ExtractFilePath(ParamStr(0)) + c_strPlugins + strArrInfo[0]);

  if tvModule.Visible then
  begin
    btnExpandClick(nil);
    DelayTime(100);
  end;

  var LPage           := TTabPage.Create(pnlPages);
  LPage.Parent        := pnlPages;
  LPage.Caption       := strArrInfo[2].Substring(strArrInfo[2].LastIndexOf('/') + 1);
  LPage.Hint          := strModuleInfo;                        // 判断模块是否已经创建时使用；
  LPage.Tag           := tvModule.Selected.ExpandedImageIndex; // 菜单和模块列表关联时使用；
  LPage.DisabledIndex := -1;                                   // 存放 DLL 模块主窗体句柄；暂时置为 -1；
  pgModule.AddTabPage(LPage, LPage.Caption, -1);

  FLogger.Log('运行模块：' + tvModule.Selected.Text + '(' + strArrInfo[0] + ')'); 
  case lsDll of
    lsDelphi: CreateDelphiFormDll(strDllFileName);
    lsEXE   : CreateEXEForm(strDllFileName);
    lsVCDLG : CreateVCDLGDllForm(strDllFileName);
    lsQT    : CreateVCDLGDllForm(strDllFileName);
  end;
end;

end.
