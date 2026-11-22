unit uCommon;

interface

uses
  Winapi.Windows, Winapi.Messages, Winapi.ShellAPI, System.Win.Registry, System.IniFiles, System.IOUtils, System.SysUtils, System.Types, System.Classes,
  Vcl.VirtualImageList, Vcl.ImageCollection, Vcl.Graphics, Vcl.Forms, Vcl.ComCtrls, Vcl.Menus, Vcl.Controls, uProcessAPI, CnAES, JNI, uTabView, uLogger;

const
  c_strTitle                      = '仁杰科技信息管理系统 v4.0';
  c_strPlugins                    = 'plugins\';
  c_strDllExportFuncName          = 'db_ShowDllForm_Plugins';
  c_strTip                        = '系统友情提示：';
  c_clrBackgroudColor             = $002B2B2B;// $003C3C3C;
  c_iMinModuleIndex               = 1000;
  WM_FREEALLDLLFORM               = WM_USER + $1000;
  c_strSE_DEBUG_NAME              = 'SeDebugPrivilege';
  c_strAESKey                     = 'dbyoung@sina.com';
  c_strExpandHint                 = '将模块列表折叠';
  c_strCollapHint                 = '展开模块列表(点击鼠标右键，弹出模块菜单)';
  c_intModuleMaxWidth             = 400;
  c_intModuleMinWidth             = 50;

{ 从 DLL 加载函数，进行用户登录校验 }
function CheckLogin(const strName, strPass: string): Boolean;

{ 简化的 MessageBox 提示框 }
procedure MyMSG(hWnd : THandle; const strTip: string);

{ 延时函数 }
procedure DelayTime(const intTime: Cardinal);

{ 7z.dll 保存到磁盘 }
function Check7zDll: string;

{ 标题栏文本 }
function GetTitleText: string;

{ 当前时间 }
function GetCurrentTime: string;

{ 加载模块列表到树形控件中 }
procedure LoadModuleList(tvModule: TTreeView);

{ 给页签设置图标 }
function SetTabSheetExeIcon(const strFileName: string; rzTab: TTabPage) : Integer;

{ 查询主窗体中当前激活的页签 }
function GetActiveTabSheet: TTabPage;

function FindTabSheetByHandle(const hTab: THandle): TTabPage;

{ 模拟 DOS 命令行的 where 功能 }
function WhereIs(const strFileName: string): string;

function NTSetPrivilege(sPrivilege: AnsiString; bEnabled: Boolean): Boolean;

{ 删除注册表编辑器记忆的位置 }
procedure ClearRegeditView;

{ 加载模块列表到弹出式菜单中 }
procedure LoadModuleToPopMenu(tv: TTreeView; pm: TPopupMenu; MenuItemClick: TNotifyEvent);

{ 加密字符串 }
function EncryptString(const strTemp, strKey: string): String;

{ 解密字符串 }
function DecryptString(const strTemp, strKey: string): String;

{ 检查 DLL 中是否有指定的导出函数 }
function CheckDllExportFunc(const strDllFileName: string; var ls: TStringList; const strExportFuncName: string = ''): Boolean;

procedure CopyTreeView(Source, Dest: TTreeView);

{ 子类回调函数; 拦截 Alt + F4 关闭窗体 }
function PluginFormWndProc(hWnd: HWND; Msg: UINT; wParam: WPARAM; lParam: LPARAM): LRESULT; stdcall;

{ 将 EXE 主窗体放置到 Tab Dll 窗口中 }
procedure SetParentForm(const hWnd: THandle; RzTab: TTabPage);

{ 通过 PID 获取进程名称 }
function GetProcessName(dwProcessID: LongInt; bFullPath: Bool): String;

const
  LOAD_LIBRARY_SEARCH_USER_DIRS   = $0400;
  LOAD_LIBRARY_SEARCH_SYSTEM32    = $0800;
  LOAD_LIBRARY_SEARCH_DEFAULT_DIRS= $1000;

function SetDefaultDllDirectories(DirectoryFlags: DWORD): BOOL; stdcall; external kernel32; // 设置默认搜索行为
function AddDllDirectory(const NewDirectory: LPCWSTR): Pointer; stdcall; external kernel32; // 将目录添加到进程的 DLL 搜索路径
function RemoveDllDirectory(Cookie: Pointer): BOOL;             stdcall; external kernel32; // 移除之前添加的目录（使用 AddDllDirectory 返回的 Cookie）

type
  TLangStyle                     = (lsDelphi, lsVCDLG, lsVCMFC, lsQT, lsEXE);                                                                                                      //
  Tdb_ShowDllForm_Plugins_Delphi = procedure(var ls: TLangStyle; var frm: TFormClass; var chrModuleName: PAnsiChar); stdcall;                                                      // Delphi
  Tdb_ShowDllForm_Plugins_VC     = procedure(var ls: TLangStyle; var chrModuleName: PAnsiChar; var strClassName, strWindowName: PAnsiChar; const bShow: Boolean = False); stdcall; // VC

implementation

{ 从 DLL 加载函数，进行用户登录校验 }
function CheckLogin(const strName, strPass: string): Boolean;
type
  TDLLCheck = function(const Name, Pass: PChar): Boolean; stdcall;
var
  hDLL              : HMODULE;
  pCheckDLLPassFunc : TDLLCheck;
begin
  Result := True;

  with TIniFile.Create(ExtractFilePath(ParamStr(0)) + 'config.ini') do
  begin
    var strLoginDllFileName := ReadString('DB', 'LoginCheckDll', '');
    var strLoginDllFunc     := ReadString('DB', 'LoginCheckFunc', '');
    if (strLoginDllFileName <> '') and (strLoginDllFunc <> '') then
    begin
      hDLL := LoadLibrary(PChar(strLoginDllFileName));
      if hDLL <> 0 then
      begin
        try
          pCheckDLLPassFunc := GetProcAddress(hDLL, PChar(strLoginDllFunc));
          if @pCheckDLLPassFunc <> nil then
          begin
            Result := pCheckDLLPassFunc(PChar(strName), PChar(strPass));
          end;
        finally
          FreeLibrary(hDLL);
        end;
      end;
    end;
    Free;
  end;
end;

{ 简化的 MessageBox 提示框 }
procedure MyMSG(hWnd : THandle; const strTip: string);
begin
  MessageBox(hWnd, PChar(strTip), c_strTip, MB_OK OR MB_ICONINFORMATION);
end;

{ 子类回调函数; 拦截 Alt + F4 关闭窗体 }
function PluginFormWndProc(hWnd: HWND; Msg: UINT; wParam: WPARAM; lParam: LPARAM): LRESULT; stdcall;
begin
  var FOldProc := TFNWndProc(GetWindowLongPtr(hWnd, GWLP_USERDATA));
  if Msg = WM_SYSCOMMAND then
  begin
    if (wParam and $FFF0) = SC_CLOSE then
    begin
      Result := 0;
      Exit;
    end;
  end;
  Result := CallWindowProc(FOldProc, hWnd, Msg, wParam, lParam);
end;

{ 延时函数 }
procedure DelayTime(const intTime: Cardinal);
begin
  var intST := GetTickCount;
  while True do
  begin
    Application.ProcessMessages;
    var intET := GetTickCount;
    if intET - intST >= intTime then Break;
  end;
end;

{ 将 EXE 主窗体放置到 Tab Dll 窗口中 }
procedure SetParentForm(const hWnd: THandle; RzTab: TTabPage);
begin
  SetWindowPos(hWnd, 0, -32000, -32000, 0, 0,  SWP_NOSIZE or SWP_NOZORDER or SWP_NOACTIVATE);
  SetWindowLongPtr(hWnd, GWL_STYLE,   $16000000);
  SetWindowLongPtr(hWnd, GWL_EXSTYLE, $00050000);
  if Winapi.Windows.SetParent(hWnd, RzTab.Handle) = 0 then
  begin
    DelayTime(100);
    if Winapi.Windows.SetParent(hWnd, RzTab.Handle) = 0 then
    begin
      DelayTime(100);
      if Winapi.Windows.SetParent(hWnd, RzTab.Handle) = 0 then
      begin
        DelayTime(100);
        Winapi.Windows.SetParent(hWnd, RzTab.Handle);
      end;
    end;
  end;
  if Winapi.Windows.SetParent(hWnd, RzTab.Handle) <> 0 then ShowWindow(hWnd, SW_MAXIMIZE);
end;

{ 通过 PID 获取进程名称 }
function GetProcessName(dwProcessID: LongInt; bFullPath: Bool): String;
var
  pinfo: PROCESS_INFO;
begin
  GetProcessInfo(dwProcessID, pinfo);
  Result := String(pinfo.ImagePathName);
end;

function NTSetPrivilege(sPrivilege: AnsiString; bEnabled: Boolean): Boolean;
var
  hToken       : THandle;
  TokenPriv    : TOKEN_PRIVILEGES;
  PrevTokenPriv: TOKEN_PRIVILEGES;
  ReturnLength : Cardinal;
begin
  if OpenProcessToken(GetCurrentProcess, TOKEN_ADJUST_PRIVILEGES or TOKEN_QUERY, hToken) then
  begin
    if LookupPrivilegeValueA(nil, PAnsiChar(sPrivilege), TokenPriv.Privileges[0].Luid) then
    begin
      TokenPriv.PrivilegeCount := 1;
      case bEnabled of
        True:
          TokenPriv.Privileges[0].Attributes := SE_PRIVILEGE_ENABLED;
        False:
          TokenPriv.Privileges[0].Attributes := 0;
      end;
      ReturnLength  := 0;
      PrevTokenPriv := TokenPriv;
      AdjustTokenPrivileges(hToken, False, TokenPriv, SizeOf(PrevTokenPriv), PrevTokenPriv, ReturnLength);
    end;
    CloseHandle(hToken);
  end;
  Result := GetLastError = ERROR_SUCCESS;
end;

{ 加密字符串 }
function EncryptString(const strTemp, strKey: string): String;
begin
  Result := string(AESEncryptEcbStrToHex(AnsiString(strTemp), AnsiString(strKey)));
end;

{ 解密字符串 }
function DecryptString(const strTemp, strKey: string): String;
begin
  Result := string(AESDecryptEcbStrFromHex(AnsiString(strTemp), AnsiString(strKey)));
end;

procedure FindTableFilePos(const sts: array of TImageSectionHeader; const intVA: Cardinal; var intRA: Cardinal);
begin
  intRA   := 0;
  var Count   := Length(sts);
  for var III := 0 to Count - 2 do
  begin
    if (intVA >= sts[III + 0].VirtualAddress) and (intVA < sts[III + 1].VirtualAddress) then
    begin
      intRA := (intVA - sts[III].VirtualAddress) + sts[III].PointerToRawData;
      Break;
    end;
  end;
end;

{ 检查 DLL 中是否有指定的导出函数 }
function CheckDllExportFunc(const strDllFileName: string; var ls: TStringList; const strExportFuncName: string = ''): Boolean;
var
  peHead     : TImageDosHeader;
  peNTHead32 : TImageNtHeaders32;
  peNTHead64 : TImageNtHeaders64;
  sts        : TArray<TImageSectionHeader>;
  intVA      : Cardinal;
  intRA      : Cardinal;
  intLen     : Integer;
  eft        : TImageExportDirectory;
  intFuncRA  : Cardinal;
  chrFuncName: array [0 .. 255] of AnsiChar;
begin
  Result  := False;
  if not FileExists(strDllFileName) then Exit;

  var fHandle := FileOpen(strDllFileName, fmShareDenyNone or fmOpenRead);
  if fHandle <= 0 then Exit;

  try
    FileRead(fHandle, peHead, SizeOf(TImageDosHeader));
    if peHead.e_magic <> IMAGE_DOS_SIGNATURE then Exit;

    var intOffset := peHead._lfanew;
    FileSeek(fHandle, intOffset, 0);
    FileRead(fHandle, peNTHead32, SizeOf(TImageNtHeaders));
    if peNTHead32.Signature <> IMAGE_NT_SIGNATURE then Exit;

    { 获取导出函数表 }
    if peNTHead32.FileHeader.Machine = IMAGE_FILE_MACHINE_AMD64 then
    begin
      { X64 Dll }
      FileSeek(fHandle, 0, 0);
      FileRead(fHandle, peHead, SizeOf(TImageDosHeader));
      intOffset := peHead._lfanew;
      FileSeek(fHandle, intOffset, 0);
      FileRead(fHandle, peNTHead64, SizeOf(TImageNtHeaders64));
      if peNTHead64.Signature <> IMAGE_NT_SIGNATURE then Exit;

      var Count := peNTHead64.FileHeader.NumberOfSections;
      SetLength(sts, Count);
      intLen := Count * SizeOf(TImageSectionHeader);
      FileSeek(fHandle, intOffset + SizeOf(TImageNtHeaders64), 0);
      FileRead(fHandle, sts[0], intLen);
      intVA := peNTHead64.OptionalHeader.DataDirectory[0].VirtualAddress;
      if intVA = 0 then Exit;
    end
    else
    begin
      { X86 Dll }
      var Count := peNTHead32.FileHeader.NumberOfSections;
      SetLength(sts, Count);
      intLen := Count * SizeOf(TImageSectionHeader);
      FileSeek(fHandle, intOffset + SizeOf(TImageNtHeaders32), 0);
      FileRead(fHandle, sts[0], intLen);
      intVA := peNTHead32.OptionalHeader.DataDirectory[0].VirtualAddress;
      if intVA = 0 then Exit;
    end;

    FindTableFilePos(sts, intVA, intRA);
    FileSeek(fHandle, intRA, 0);
    FileRead(fHandle, eft, SizeOf(TImageExportDirectory));
    if eft.NumberOfNames = 0 then Exit;

    { 导出函数 }
    for var I := 0 to eft.NumberOfNames - 1 do
    begin
      FileSeek(fHandle, eft.AddressOfNames - intVA + intRA + DWORD(4 * I), 0);
      FileRead(fHandle, intFuncRA, 4);
      FileSeek(fHandle, intFuncRA - intVA + intRA, 0);
      FileRead(fHandle, chrFuncName, 256);
      var strFuncName := string(chrFuncName);
      if Trim(strExportFuncName) <> '' then
      begin
        if SameText(strFuncName, strExportFuncName) then
        begin
          Result := True;
          Break;
        end;
      end
      else
      begin
        if (not SameText(strFuncName, '__dbk_fcall_wrapper')) and (not SameText(strFuncName, 'dbkFCallWrapperAddr')) then ls.Add(strFuncName);
      end;
    end;
  finally
    FileClose(fHandle);
  end;
end;

{ 删除注册表编辑器记忆的位置 }
procedure ClearRegeditView;
begin
  var Reg := TRegistry.Create(KEY_READ or KEY_WRITE);
  try
    Reg.RootKey := HKEY_CURRENT_USER;
    if Reg.OpenKey('Software\Microsoft\Windows\CurrentVersion\Applets\Regedit', False) then
    begin
      if Reg.DeleteValue('View') then
        OutputDebugString('Regedit View 键已删除')
      else
        OutputDebugString('Regedit View 键删除失败');
    end;
  finally
    Reg.Free;
  end;
end;

{ 7z.dll 保存到磁盘 }
function Check7zDll: string;
  procedure Unzip(const strFile: string);
  var
    mem7zRS: TResourceStream;
  begin
    mem7zRS := TResourceStream.Create(HInstance, '7ZDLL', RT_RCDATA);
    try
      mem7zRS.Position := 0;
      mem7zRS.SaveToFile(strFile);
    finally
      mem7zRS.Free;
    end;
  end;
var
  strPath: string;
begin
{$IFDEF CPUX64}
  strPath := TPath.GetHomePath + '\7zip\X64';
{$ELSE}
  strPath := TPath.GetHomePath + '\7zip\X86';
{$IFEND }
  var strFile := strPath + '\7z.dll';
  if not DirectoryExists(strPath) then ForceDirectories(strPath);
  if not FileExists(strFile) then Unzip(strFile); 
  Result := strFile;
end;

{ 在主窗体中按名称查找控件（含嵌套控件） }
function FindControlByName(AParent: TWinControl; const AName: string): TControl;
begin
  Result := nil;
  if AParent = nil then Exit;

  for var I := 0 to AParent.ControlCount - 1 do
  begin
    if SameText(AParent.Controls[I].Name, AName) then Exit(AParent.Controls[I]);
    if AParent.Controls[I] is TWinControl then
    begin
      Result := FindControlByName(TWinControl(AParent.Controls[I]), AName);
      if Result <> nil then Exit;
    end;
  end;
end;

{ 查询主窗体中当前激活的页签 }
function GetActiveTabSheet: TTabPage;
begin
  Result       := nil;
  var LControl := FindControlByName(Application.MainForm, 'pgModule');
  if not (LControl is TTabView) then Exit;

  var LTabView := TTabView(LControl);
  if LTabView.ActiveTab = nil then Exit;

  if LTabView.ActiveTab.Control is TTabPage then Result := TTabPage(LTabView.ActiveTab.Control);
end;

function FindTabSheetByHandle(const hTab: THandle): TTabPage;
begin
  Result       := nil;
  var LControl := FindControlByName(Application.MainForm, 'pgModule');
  if not (LControl is TTabView) then Exit;

  var LTabView := TTabView(LControl);
  for var I := 0 to LTabView.Tabs.Count - 1 do
  begin
    var LPage := LTabView.Tabs[I].Control;
    if (LPage is TTabPage) and TTabPage(LPage).HandleAllocated and (TTabPage(LPage).Handle = hTab) then
      Exit(TTabPage(LPage));
  end;
end;

{ 获取 DLL 模块类型、名称 }
function GetFuncParam(const strFileName : string; var strParam : string): Boolean; inline;
var
  strModuleName, strClassName, strTitleName: PAnsiChar;
  lsDll                                    : TLangStyle;
  cFunc                                    : Tdb_ShowDllForm_Plugins_VC;
  frm                                      : TFormClass;
  pFunc                                    : Pointer;
begin
  Result   := False;
  strParam := '';

  var hDLL := LoadLibrary(PChar(strFileName));
  if not((hDLL > 0) and (hDLL <> INVALID_HANDLE_VALUE)) then Exit;

  try
    pFunc := GetProcAddress(hDLL, c_strDllExportFuncName);
    if not Assigned(pFunc) then Exit;

    strModuleName := '';
    strClassName  := '';
    strTitleName  := '';
    cFunc         := Tdb_ShowDllForm_Plugins_VC(pFunc);
    try
      cFunc(lsDll, strModuleName, strClassName, strTitleName, False);
      strParam := IntToStr(Ord(lsDll)) + ';' + string(strModuleName) + ';' + string(strClassName) + ';' + string(strTitleName) + ';';
    except
      strTitleName := '';
      strParam     := '';
    end;

    if strTitleName = '' then
    begin
      strModuleName := '';
      strClassName  := '';
      strTitleName  := '';
      Tdb_ShowDllForm_Plugins_Delphi(pFunc)(lsDll, frm, strModuleName);
      strParam := IntToStr(Ord(lsDll)) + ';' + string(strModuleName) + ';';
    end;

    Result   := True;
  finally
    FreeLibrary(hDLL);
  end;
end;

procedure ScanPluginsDllModule(lstModule : TStringList);
var
  strParam : string;
begin
  var lstFuncs := TStringList.Create;
  try
    var strPath  := ExtractFilePath(ParamStr(0)) + c_strPlugins;
    var lstFiles := TDirectory.GetFiles(strPath, '*.dll');
    for var strFile in lstFiles do
    begin
      lstFuncs.Clear;
      if CheckDllExportFunc(strFile, lstFuncs, c_strDllExportFuncName) then
      begin
        if GetFuncParam(strFile, strParam) then
        begin
          var strTemp := ExtractFileName(strFile) + ';' + strParam;
          lstModule.Add(strTemp);
        end;
      end;
    end;
  finally
    lstFuncs.Free;
  end;
end;

{ 加载模块列表到树形控件中 }
procedure LoadModuleList(tvModule: TTreeView);
var
  lstModule     : TStringList;
  arrLevelName  : TArray<string>;
  ParentNode    : TTreeNode;
  FindNode      : TTreeNode;
  NodeCur       : TTreeNode;
begin
  lstModule := TStringList.Create;
  try
    { 1：读取配置文件中的 EXE 模块，添加到列表 }
    with TIniFile.Create(ExtractFilePath(ParamStr(0)) + 'config.ini') do
    begin
      var lstEXE := TStringList.Create();
      ReadSectionValues('EXE', lstEXE);
      lstModule.Text := lstEXE.Text.Replace('=', ';', [rfReplaceAll]);
      lstEXE.Free;
      Free;
    end;

    {2：读取 plguins 目录下的 DLL 模块，添加到列表 }
    ScanPluginsDllModule(lstModule);

    tvModule.Items.BeginUpdate;
    tvModule.Items.Clear;
    for var I := 0 to lstModule.Count - 1 do
    begin
      var strModuleName := lstModule.Strings[I].Split([';'])[2];
      arrLevelName  := strModuleName.Split(['/']);
      ParentNode    := nil;

      for var J := Low(arrLevelName) to High(arrLevelName) do
      begin
        if Assigned(ParentNode) then
          FindNode := ParentNode.getFirstChild
        else
          FindNode := tvModule.Items.GetFirstNode;

        while Assigned(FindNode) do
        begin
          if FindNode.Text = arrLevelName[J] then Break;
          FindNode := FindNode.getNextSibling;
        end;

        if not Assigned(FindNode) then
        begin
          if Assigned(ParentNode) then
            NodeCur := tvModule.Items.AddChild(ParentNode, arrLevelName[J])
          else
            NodeCur := tvModule.Items.Add(nil, arrLevelName[J]);
          if J = Length(arrLevelName) - 1 then
          begin
            NodeCur.ImageIndex         := 2;
            NodeCur.SelectedIndex      := 1;
            NodeCur.Hint               := lstModule.Strings[I];
            NodeCur.ExpandedImageIndex := c_iMinModuleIndex + I;
          end;
        end
        else
        begin
          NodeCur := FindNode;
        end;
        ParentNode := NodeCur;
      end;
    end;
    tvModule.Items.EndUpdate;
  finally
    lstModule.Free;
  end;
end;

{ 创建菜单项 }
function CreateMenuItemFromNode(Node: TTreeNode; ParentMenuItem: TMenuItem; MenuItemClick: TNotifyEvent): TMenuItem;
var
  ChildNode: TTreeNode;
begin
  Result         := TMenuItem.Create(nil);
  Result.Caption := Node.Text;
  Result.Tag     := Node.ExpandedImageIndex;
  Result.OnClick := MenuItemClick;

  if Node.HasChildren then
  begin
    ChildNode := Node.GetFirstChild;
    while ChildNode <> nil do
    begin
      CreateMenuItemFromNode(ChildNode, Result, MenuItemClick);
      ChildNode := ChildNode.GetNextSibling;
    end;
  end;

  if ParentMenuItem <> nil then ParentMenuItem.Add(Result);
end;

{ 加载模块列表到弹出式菜单中 }
procedure LoadModuleToPopMenu(tv: TTreeView; pm: TPopupMenu; MenuItemClick: TNotifyEvent);
var
  RootNode: TTreeNode;
begin
  pm.Items.Clear;
  RootNode := tv.Items.GetFirstNode;
  while RootNode <> nil do
  begin
    var MenuItem := CreateMenuItemFromNode(RootNode, nil, MenuItemClick);
    pm.Items.Add(MenuItem);
    RootNode := RootNode.GetNextSibling;
  end;
end;

{ 标题栏文本 }
function GetTitleText: string;
begin
  Result := 'DET v4.0';
  var strFileName := ExtractFilePath(ParamStr(0)) + 'config.ini';
  with TIniFile.Create(strFileName) do
  begin
    Result := ReadString('main', 'title', c_strTitle);
    Free;
  end;
end;

{ 当前时间 }
function GetCurrentTime: string;
const
  c_Day: array [1 .. 7] of string = ('星期日', '星期一', '星期二', '星期三', '星期四', '星期五', '星期六');
begin
  Result := FormatDateTime('yyyy-MM-dd hh:mm:ss', Now) + '  ' + c_Day[DayOfWeek(Now)];
end;

{ 给页签设置图标 }
function SetTabSheetExeIcon(const strFileName: string; rzTab: TTabPage) : Integer;
var
  hLargeIcon, hSmallIcon: HICON;
  ModuleIcon            : TIcon;
  msICO                 : TMemoryStream;
  intIndex              : Integer;
  strFullPathName       : string;
begin
  strFullPathName  := strFileName;
  Result           := 0;
  if ExtractIconEx(PChar(strFullPathName), -1, hLargeIcon, hSmallIcon, 0) > 0 then
  begin
    ExtractIconEx(PChar(strFullPathName), 0, hLargeIcon, hSmallIcon, 1);
    ModuleIcon := TIcon.Create;
    msICO      := TMemoryStream.Create;
    try
      ModuleIcon.Handle := hSmallIcon;
      ModuleIcon.SaveToStream(msICO);
      var LImages := TVirtualImageList(rzTab.TabView.Images);
      intIndex := TImageCollection(LImages.ImageCollection).GetIndexByName(ExtractFileName(strFullPathName));
      if intIndex = -1 then
      begin
        TImageCollection(LImages.ImageCollection).Add(ExtractFileName(strFullPathName), msICO);
        intIndex := TImageCollection(LImages.ImageCollection).Count - 1;
        LImages.Add(ExtractFileName(strFullPathName), intIndex);
      end;
      Result := intIndex;
    finally
      if hSmallIcon <> 0 then DestroyIcon(hSmallIcon);
      if hLargeIcon <> 0 then DestroyIcon(hLargeIcon);
      msICO.Free;
      ModuleIcon.Free;
    end; 
  end;
end;

procedure CopyTreeView(Source, Dest: TTreeView);
var
  Root: TTreeNode;

  procedure CopyNode(SourceNode: TTreeNode; DestParent: TTreeNode);
  var
    NewNode: TTreeNode;
    Child  : TTreeNode;
  begin
    // 创建目标节点
    if DestParent = nil then
      NewNode := Dest.Items.Add(nil, SourceNode.Text)
    else
      NewNode := Dest.Items.AddChild(DestParent, SourceNode.Text);

    // 复制节点属性
    NewNode.Hint               := SourceNode.Hint;
    NewNode.ImageIndex         := SourceNode.ImageIndex;
    NewNode.SelectedIndex      := SourceNode.SelectedIndex;
    NewNode.StateIndex         := SourceNode.StateIndex;
    NewNode.ExpandedImageIndex := SourceNode.ExpandedImageIndex;

    // 先递归复制子节点
    Child := SourceNode.GetFirstChild;
    while Child <> nil do
    begin
      CopyNode(Child, NewNode);
      Child := Child.GetNextSibling;
    end;

    // 子节点添加完成后再复制展开、选中状态
    NewNode.Expanded := SourceNode.Expanded;
    NewNode.Selected := SourceNode.Selected;
  end;

begin
  if (Source = nil) or (Dest = nil) then Exit;

  Dest.Items.BeginUpdate;
  try
    Dest.Items.Clear;

    // 复制图像列表，保证 ImageIndex / StateIndex 有效
    Dest.Images      := Source.Images;
    Dest.StateImages := Source.StateImages;

    // 复制常用外观/行为属性
    Dest.MultiSelect := Source.MultiSelect;
    Dest.ReadOnly    := Source.ReadOnly;
    Dest.ShowButtons := Source.ShowButtons;
    Dest.ShowLines   := Source.ShowLines;
    Dest.ShowRoot    := Source.ShowRoot;
    Dest.HotTrack    := Source.HotTrack;
    Dest.RowSelect   := Source.RowSelect;
    Dest.Indent      := Source.Indent;

    // 先禁用排序，避免添加节点时顺序被打乱
    Dest.SortType := stNone;

    // 从第一个根节点开始递归复制
    Root := Source.Items.GetFirstNode;
    while Root <> nil do
    begin
      CopyNode(Root, nil);
      Root := Root.GetNextSibling;
    end;

    // 如果需要保持源的排序方式
    Dest.SortType := Source.SortType;
  finally
    Dest.Items.EndUpdate;
  end;
end;

{ 模拟 DOS 命令行的 where 功能 }
function WhereIs(const strFileName: string): string;
var
  Buffer : array[0..MAX_PATH - 1] of Char;
  PathPtr: PChar;
begin
  if strFileName.Contains('\') then
  begin
    Result := strFileName;
  end
  else
  begin
    Result := '';
    if SearchPath(nil, PChar(strFileName), nil, MAX_PATH, Buffer, PathPtr) > 0 then Result := StrPas(Buffer);
  end;
end;

var
  FJavaVM: TJavaVM = nil;

{ 导出 Java 虚拟机，给 DLL 模块使用 }
function CreateJavaVM: TJavaVM; stdcall; begin Result := FJavaVM; end; exports CreateJavaVM;

{ 从注册表中查询 Java 的安装位置 }
function GetJavaExeFromRegistry: string;
const
    BaseKeys: array[0..3] of string = (
    'SOFTWARE\JavaSoft\Java Runtime Environment',
    'SOFTWARE\JavaSoft\Java Development Kit',
    'SOFTWARE\JavaSoft\JRE',
    'SOFTWARE\JavaSoft\JDK'
  );
var
  Reg           : TRegistry;
  JavaHome      : string;
  CurrentVersion: string;
  I             : Integer;
begin
  Result := '';

  {$IFDEF CPUX64}
  Reg := TRegistry.Create(KEY_READ or KEY_WOW64_64KEY); // 优先以64位视图读取
  try
    Reg.RootKey := HKEY_LOCAL_MACHINE;
    for I := Low(BaseKeys) to High(BaseKeys) do
    begin
      // 1. 检查基础路径是否存在
      if Reg.KeyExists(BaseKeys[I]) then
      begin
        // 2. 读取 CurrentVersion 值，确定当前版本
        if Reg.OpenKeyReadOnly(BaseKeys[I]) then
        begin
          CurrentVersion := Reg.ReadString('CurrentVersion');
          Reg.CloseKey;
          if CurrentVersion <> '' then
          begin
            // 3. 拼出版本子键路径并读取 JavaHome
            if Reg.OpenKeyReadOnly(BaseKeys[I] + '\' + CurrentVersion) then
            begin
              JavaHome := Reg.ReadString('JavaHome');
              Reg.CloseKey;
              if JavaHome <> '' then
              begin
                // 4. 拼接最终的 java.exe 路径并验证
                Result := IncludeTrailingPathDelimiter(JavaHome) + 'bin\java.exe';
                if FileExists(Result) then
                  Exit; // 找到即退出
              end;
            end;
          end;
        end;
      end;
    end;
  finally
    Reg.Free;
  end;
  {$ENDIF}

  {$IFDEF CPUX86}
  Reg := TRegistry.Create(KEY_READ or KEY_WOW64_32KEY);
  try
    Reg.RootKey := HKEY_LOCAL_MACHINE;
    for I := Low(BaseKeys) to High(BaseKeys) do
    begin
      if Reg.KeyExists(BaseKeys[I]) then
      begin
        if Reg.OpenKeyReadOnly(BaseKeys[I]) then
        begin
          CurrentVersion := Reg.ReadString('CurrentVersion');
          Reg.CloseKey;
          if CurrentVersion <> '' then
          begin
            if Reg.OpenKeyReadOnly(BaseKeys[I] + '\' + CurrentVersion) then
            begin
              JavaHome := Reg.ReadString('JavaHome');
              Reg.CloseKey;
              if JavaHome <> '' then
              begin
                Result := IncludeTrailingPathDelimiter(JavaHome) + 'bin\java.exe';
                if FileExists(Result) then
                  Exit;
              end;
            end;
          end;
        end;
      end;
    end;
  finally
    Reg.Free;
  end;
  {$ENDIF}
end;

{ 将 DLL 加载进 Java 虚拟机中；使用 JNI 的方式加载；不是对所有 DLL 都有效 }
function LoadDllToJava01(jvm: TJavaVM; const strFileName: string) : Boolean;
var
  SystemClass: jClass;
  LoadMethod : jMethodID;
  PathStr    : jString;
  jEnv       : TJNIEnv;
begin
  jEnv        := TJNIEnv.Create(jvm.Env);
  SystemClass := jEnv.FindClass('java/lang/System');
  LoadMethod  := jEnv.GetStaticMethodID(SystemClass, 'load', '(Ljava/lang/String;)V');
  PathStr     := jEnv.NewStringUTF(PAnsiChar(AnsiString(strFileName)));
  try
    jEnv.CallStaticVoidMethod(SystemClass, LoadMethod, [PathStr]);
    Result := not jEnv.ExceptionCheck;
    if not Result then
    begin
      jEnv.ExceptionDescribe;
      jEnv.ExceptionClear;
    end;
  finally
    jEnv.DeleteLocalRef(SystemClass);
    jEnv.DeleteLocalRef(PathStr);
    jEnv.Free;
  end;
end;

procedure GetJavaErrStr(jEnv: TJNIEnv; var strErr: string);
begin
  var exc := jEnv.ExceptionOccurred;
  if exc = nil then Exit;

  try
    var excClass := jEnv.GetObjectClass(exc);
    if excClass = nil then Exit;

    try
      var mid := jEnv.GetMethodID(excClass, 'getMessage', '()Ljava/lang/String;');
      if mid = nil then Exit;

      var msgObj := jEnv.CallObjectMethod(exc, mid, []);
      if msgObj <> nil then
      begin
        var bCopy : Boolean := True;
        var len   := jEnv.GetStringLength(msgObj);
        var chars := jEnv.GetStringChars(msgObj, bCopy);
        SetString(strErr, PChar(chars), len);
        jEnv.ReleaseStringChars(msgObj, chars);
        jEnv.DeleteLocalRef(msgObj);
      end;
    finally
      jEnv.DeleteLocalRef(excClass);
    end;
  finally
   jEnv.DeleteLocalRef(exc);
  end;
end;

{ 将 DLL 加载进 Java 虚拟机中；使用 Java 的 System.Load 比较万全 }
function LoadDllToJava02(jvm: TJavaVM; const strOpenCVJava: string) : Boolean;
var
  cls : JClass;
  mid : JMethodID;
  jEnv: TJNIEnv;
begin
  Result := False;
  if not FileExists(strOpenCVJava) then Exit;

  { 加载 OpenCV Java DLL }
  jEnv := TJNIEnv.Create(jvm.Env);
  try
    cls := jEnv.FindClass('lcv');
    try
      mid := jEnv.GetStaticMethodID(cls, 'LoadOpenJavaDll', '(Ljava/lang/String;)V');
      jEnv.CallStaticVoidMethod(cls, mid, [strOpenCVJava]);
      Result := True;
      if jEnv.ExceptionCheck then
      begin
       Result := False;
       var strDesc : string := '';
       GetJavaErrStr(jEnv, strDesc);
       FLogger.Log('初始化 OpenCV for Java 失败。原因：' + strDesc);
      end;
    finally
      jEnv.DeleteLocalRef(cls);
    end;
  finally
    jEnv.Free;
  end;
end;

{ 初始化 Opencv for java }
procedure InitOpenCVJava(jvm : TJavaVM);
begin
  var strFileName := ExtractFilePath(ParamStr(0)) + c_strPlugins + 'opencv\opencv_java510.dll';
  if not FileExists(strFileName) then Exit;

  if LoadDllToJava02(jvm, strFileName) then FLogger.Log('初始化 OpenCV for Java 成功');
end;

{ 初始化 java }
procedure InitJava;
const
{$IFDEF CPUX86}
  c_strJVMPath = 'client\jvm.dll';
{$ELSE}
  c_strJVMPath = 'server\jvm.dll';
{$ENDIF}
var
  strJava, strJavaVM : string;
  Options            : array [0 .. 1] of JavaVMOption;
  VM_args            : JavaVMInitArgs;
  ErrCode            : Integer;
begin
  if not DirectoryExists(ExtractFilePath(ParamStr(0)) + c_strPlugins + 'java') then Exit;

  { 从配置文件中读取 java 安装路径 }
  with TIniFile.Create(ExtractFilePath(ParamStr(0)) + 'config.ini') do
  begin
    strJava   := ReadString('Path', 'Java', '');
    strJavaVM := ExtractFilePath(strJava) + c_strJVMPath ;
    Free;
  end;

  { 从当前目录下搜索是否包含 java }
  if not ((not Trim(strJava).IsEmpty) and (FileExists(strJava)) and (FileExists(strJavaVM))) then
  begin
    strJava   := ExtractFilePath(ParamStr(0)) + c_strPlugins + 'jre\bin\java.exe';
    strJavaVM := ExtractFilePath(strJava) + c_strJVMPath ;
  end;

  { 从注册表中搜索 java 安装目录 }
  if not ((not Trim(strJava).IsEmpty) and (FileExists(strJava)) and (FileExists(strJavaVM))) then
  begin
    strJava   := GetJavaExeFromRegistry;
    strJavaVM := ExtractFilePath(strJava) + c_strJVMPath ;
  end;

  { 从系统环境变量中查询 java 安装目录 }
  if not ((not Trim(strJava).IsEmpty) and (FileExists(strJava)) and (FileExists(strJavaVM))) then
  begin
    strJava   := GetEnvironmentVariable('JAVA_HOME');
    strJavaVM := ExtractFilePath(strJava) + c_strJVMPath ;
  end;

  { 从系统搜索中查询 java 安装目录 }
  if not ((not Trim(strJava).IsEmpty) and (FileExists(strJava)) and (FileExists(strJavaVM))) then
  begin
    strJava   := WhereIs('java.exe');
    strJavaVM := ExtractFilePath(strJava) + c_strJVMPath ;
  end;

  if not ((not Trim(strJava).IsEmpty) and (FileExists(strJava)) and (FileExists(strJavaVM))) then Exit;

  FLogger.Log('JAVA 位置：' + strJavaVM);
  AddDllDirectory(PChar(ExtractFilePath(strJava)));
  FJavaVM := TJavaVM.Create(JNI_VERSION_1_8, strJavaVM);
  FillChar(Options, SizeOf(Options), #0);
  Options[0].optionString    := PAnsiChar(AnsiString('-Djava.class.path=' + ExtractFilePath(ParamStr(0)) + c_strPlugIns + 'java'));
  Options[1].optionString    := PAnsiChar(AnsiString('-verbose:jni'));
  VM_args.version            := JNI_VERSION_1_8;
  VM_args.Options            := @Options;
  VM_args.nOptions           := 2;
  VM_args.ignoreUnrecognized := False;
  ErrCode                    := FJavaVM.LoadVM(VM_args);
  if ErrCode < 0 then
  begin
    FLogger.Log('初始化 JAVA 虚拟机失败');
    FJavaVM := nil;
    Exit;
  end;

  FLogger.Log('初始化 JAVA 虚拟机成功');
  InitOpenCVJava(FJavaVM);
end;

{ 销毁 java 虚拟机 }
procedure FreeJava;
begin
  if FJavaVM = nil then Exit;

  FJavaVM.DestroyJavaVM;
  FJavaVM.Free;
end;

initialization
  SetDefaultDllDirectories(LOAD_LIBRARY_SEARCH_DEFAULT_DIRS OR LOAD_LIBRARY_SEARCH_USER_DIRS);
  AddDllDirectory(PChar(ExtractFilePath(ParamStr(0)) + c_strPlugins + 'opencv'));
  NTSetPrivilege(c_strSE_DEBUG_NAME, True);
  Check7zDll;
  InitJava;

finalization
  FreeJava;

end.
