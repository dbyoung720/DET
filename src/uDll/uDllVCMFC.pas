unit uDllVCMFC;

interface

uses Winapi.Windows, Winapi.Messages, Winapi.ShellAPI, System.SysUtils, System.Classes, System.Threading, Vcl.Forms, Vcl.ComCtrls, Vcl.Graphics, HookUtils, uCommon;

{ 创建 VC MFC DLL 窗体 }
procedure CreateVCMFCDllForm(const strDllFileName: String);

{ 显示 VC MFC DLL 窗体 }
procedure ShowVCMFCDllForm(const hWnd: THandle);

{ 销毁 VC MFC DLL 窗体 }
procedure FreeVcMFCFormDll;

implementation

type
  TLangStyle                     = (lsDelphi, lsVCDLG, lsVCMFC, lsQT, lsEXE);                                                                                                       //
  Tdb_ShowDllForm_Plugins_VCForm = procedure(var vct: TLangStyle; var strModuleName: PAnsiChar; var strClassName, strWindowName: PAnsiChar; const bShow: Boolean = False); stdcall; // VC

var
  FOld_CreateWindowExW  : function(dwExStyle: DWORD; lpClassName: LPCWSTR; lpWindowName: LPCWSTR; dwStyle: DWORD; X, Y, nWidth, nHeight: Integer; hWndParent: hWnd; hMenu: hMenu; hins: HINST; lpp: Pointer): hWnd; stdcall;
  FstrVCMFCDllClassName : String = '';
  FstrVCMFCDllWindowName: String = '';
  FhRzHandle            : THandle;

procedure ShowVCMFCDllForm(const hWnd: THandle);
begin
  var rzTab           := GetActiveTabSheet;
  rzTab.DisabledIndex := hWnd;                                     // 保存下窗体句柄
  SetParentForm(hWnd, rzTab);                                      // 将主窗体放置到 Tab Dll 窗口中
  PostMessage(Application.MainForm.Handle, WM_NCACTIVATE, 1, 0);   // 激活主窗体
  UnHook(@FOld_CreateWindowExW);                                   // UNHOOK
  FOld_CreateWindowExW := nil;                                     // UNHOOK
end;

function HookCreateWindowExW(dwExStyle: DWORD; lpClassName: LPCWSTR; lpWindowName: LPCWSTR; dwStyle: DWORD; X, Y, nWidth, nHeight: Integer; hWndParent: hWnd; hMenu: hMenu; hins: HINST; lpp: Pointer): hWnd; stdcall;
begin
  { 是指定的 VC 窗体 }
  if (lpClassName <> nil) and (lpWindowName <> nil) and (SameText(lpClassName, FstrVCMFCDllClassName)) and (SameText(lpWindowName, FstrVCMFCDllWindowName)) then
  begin
    { 创建 VC MFC DLL 窗体。因为 MFC 窗体是在线程中创建的，所以这里不能加入任何 DELPHI 的代码，阻碍 VC 线程的执行 }
    Result := FOld_CreateWindowExW($00010101, lpClassName, lpWindowName, $96C80000, 0, 0, 0, 0, FhRzHandle, hMenu, hins, lpp);
    PostMessage(Application.MainForm.Handle, FhRzHandle, Result, 0);
  end
  else
  begin
    Result := FOld_CreateWindowExW(dwExStyle, lpClassName, lpWindowName, dwStyle, X, Y, nWidth, nHeight, hWndParent, hMenu, hins, lpp);
  end;
end;

{ 运行 VC MFC DLL Form 窗体 }
procedure CreateVCMFCDllForm(const strDllFileName: String);
var
  hDLL                       : HMODULE;
  ShowVCDllForm              : Tdb_ShowDllForm_Plugins_VCForm;
  strModuleName              : PAnsiChar;
  strClassName, strWindowName: PAnsiChar;
  ls                         : TLangStyle;
begin
  var rzTab  := GetActiveTabSheet;
  FhRzHandle := rzTab.Handle;

  { 只获取参数，不调用显示窗体。下 HOOK，HOOK 指定窗体 }
  hDLL := LoadLibrary(PChar(strDllFileName));
  try
    ShowVCDllForm := GetProcAddress(hDLL, c_strDllExportFuncName);
    ShowVCDllForm(ls, strModuleName, strClassName, strWindowName, False);
    FstrVCMFCDllClassName  := String(strClassName);
    FstrVCMFCDllWindowName := String(strWindowName);
    HookProcInModule(user32, 'CreateWindowExW', @HookCreateWindowExW, @FOld_CreateWindowExW);
  finally
    FreeLibrary(hDLL);
  end;

  { 加载 VC MFC DLL Form 非模态窗体 }
  hDLL          := LoadLibrary(PChar(strDllFileName));
  ShowVCDllForm := GetProcAddress(hDLL, c_strDllExportFuncName);
  ShowVCDllForm(ls, strModuleName, strClassName, strWindowName, True);
  rzTab.Tag := hDLL;
  SetTabSheetExeIcon(strDllFileName, rzTab);
end;

procedure FreeVcMFCFormDll;
begin
  var rzTab := GetActiveTabSheet;
  if rzTab = nil then Exit;
  if rzTab.DisabledIndex = -1 then Exit;

  var hDllModule := rzTab.Tag;

  { 关闭窗体 }
  PostMessage(rzTab.DisabledIndex, WM_CLOSE, 0, 0);

  { 窗口已关闭，释放 DLL }
  DelayTime(100);
  FreeLibrary(hDllModule);
end;

end.
