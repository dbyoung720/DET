unit uMain;

interface

uses Winapi.Windows, Winapi.Messages, Winapi.ShellAPI, System.SysUtils, System.Variants, System.Classes, System.Win.Crtl, Vcl.ComCtrls, Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.ExtCtrls, HookUtils;

type
  TfrmVCD = class(TForm)
    pnlDLL: TPanel;
    procedure FormDestroy(Sender: TObject);
    procedure FormResize(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure FormCreate(Sender: TObject);
  private
    function CheckInputParam: Boolean;
    procedure ThreadCreateVCModuleForm;
  public
    procedure CreateParams(var Params: TCreateParams); override;
    procedure WndProc(var Message: TMessage); override;
  end;

var
  frmVCD: TfrmVCD;

implementation

{$R *.dfm}

type
  TLangStyle                 = (lsDelphi, lsVCDLG, lsVCMFC, lsQT, lsEXE);
  Tdb_ShowDllForm_Plugins_VC = procedure(var ls: TLangStyle; var chrModuleName: PAnsiChar; var strClassName, strWindowName: PAnsiChar; const bShow: Boolean = False); stdcall; // VC

const
  c_strDllExportFuncName = 'db_ShowDllForm_Plugins';

var
  FOld_CreateWindowExW : function(dwExStyle: DWORD; lpClassName: LPCWSTR; lpWindowName: LPCWSTR; dwStyle: DWORD; X, Y, nWidth, nHeight: Integer; hWndParent: hWnd; hMenu: hMenu; hins: HINST; lpp: Pointer): hWnd; stdcall;
  FstrVCDLGDllClassName: LPCWSTR = nil;
  FstrVCDLGDllTitleName: LPCWSTR = nil;

function TfrmVCD.CheckInputParam: Boolean;
var
  strDllPathFileName    : string;
  chrModuleName         : PAnsiChar;
  chrClassName          : PAnsiChar;
  chrTitleName          : PAnsiChar;
  hDLL                  : HMODULE;
  ls                    : TLangStyle;
  pFunc                 : Tdb_ShowDllForm_Plugins_VC;
  hLargeIcon, hSmallIcon: HICON;
  intX, intY            : Integer;
  intWidth, intHeight   : Integer;
begin
  Result := False;

  strDllPathFileName := ParamStr(1);
  intX               := StrToIntDef(ParamStr(2), 0);
  intY               := StrToIntDef(ParamStr(3), 0);
  intWidth           := StrToIntDef(ParamStr(4), 0);
  intHeight          := StrToIntDef(ParamStr(5), 0);
  if Trim(strDllPathFileName) = '' then Exit;
  if not FileExists(strDllPathFileName) then Exit;

  hDLL := LoadLibrary(PChar(strDllPathFileName));
  if hDLL = 0 then Exit;

  try
    pFunc := GetProcAddress(hDLL, c_strDllExportFuncName);
    if not Assigned(pFunc) then
    begin
      FreeLibrary(hDLL);
      Exit;
    end;

    pFunc(ls, chrModuleName, chrClassName, chrTitleName);
    Hint    := strDllPathFileName;
    Caption := string(chrModuleName);
  finally
    FreeLibrary(hDLL);
  end;

  if ExtractIconEx(PChar(strDllPathFileName), -1, hLargeIcon, hSmallIcon, 0) > 0 then
  begin
    ExtractIconEx(PChar(strDllPathFileName), 0, hLargeIcon, hSmallIcon, 1);
    Icon.Handle := hSmallIcon;
  end;

  Left   := intX;
  Top    := intY;
  Width  := intWidth;
  Height := intHeight;

  Result := True;
  TThread.CreateAnonymousThread(ThreadCreateVCModuleForm).start;
end;

procedure TfrmVCD.FormCreate(Sender: TObject);
begin
  ShowWindow(Application.Handle, SW_HIDE);
  if not CheckInputParam then Halt;
end;

procedure TfrmVCD.CreateParams(var Params: TCreateParams);
begin
  inherited CreateParams(Params);
  Params.ExStyle := WS_EX_TOOLWINDOW;
end;

procedure TfrmVCD.WndProc(var Message: TMessage);
begin
  inherited WndProc(Message);
  if (not Application.MainFormOnTaskBar) and (Message.Msg = WM_SHOWWINDOW) then
  begin
    ShowWindow(Application.Handle, SW_HIDE);
    SetWindowLong(Application.Handle, GWL_EXSTYLE, WS_EX_TOOLWINDOW);
  end;
end;

procedure TfrmVCD.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  PostMessage(pnlDLL.tag, WM_SYSCOMMAND, SC_CLOSE, 0);

  while True do
  begin
    Application.ProcessMessages;
    if not IsWindow(pnlDLL.tag) then Break;
  end;

  Action := TCloseAction.caFree;
end;

procedure TfrmVCD.FormDestroy(Sender: TObject);
begin
  FreeLibrary(tag);
end;

procedure TfrmVCD.FormResize(Sender: TObject);
begin
  if pnlDLL.tag > 0 then
  begin
    if IsZoomed(pnlDLL.tag) then PostMessage(pnlDLL.tag, WM_SYSCOMMAND, SC_RESTORE, 0);
    PostMessage(pnlDLL.tag, WM_SYSCOMMAND, SC_MAXIMIZE, 0);
  end;
end;

{ 创建 VC DLL 窗体 }
procedure CreateVCDllForm(const hVC: THandle);
begin
  Winapi.Windows.SetParent(hVC, frmVCD.pnlDLL.Handle);                         // 设置父窗体为 TabSheet
  RemoveMenu(GetSystemMenu(hVC, False), 0, MF_BYPOSITION);                     // 删除移动菜单
  RemoveMenu(GetSystemMenu(hVC, False), 0, MF_BYPOSITION);                     // 删除移动菜单
  RemoveMenu(GetSystemMenu(hVC, False), 0, MF_BYPOSITION);                     // 删除移动菜单
  RemoveMenu(GetSystemMenu(hVC, False), 0, MF_BYPOSITION);                     // 删除移动菜单
  RemoveMenu(GetSystemMenu(hVC, False), 0, MF_BYPOSITION);                     // 删除移动菜单
  RemoveMenu(GetSystemMenu(hVC, False), 0, MF_BYPOSITION);                     // 删除移动菜单
  SetWindowLong(hVC, GWL_STYLE, GetWindowLong(hVC, GWL_STYLE) xor WS_CAPTION); // 去除标题栏
  PostMessage(Application.MainForm.Handle, WM_NCACTIVATE, 1, 0);               // 激活主窗体
  UnHook(@FOld_CreateWindowExW);                                               // UNHOOK
  FOld_CreateWindowExW := nil;                                                 // UNHOOK
  frmVCD.pnlDLL.tag    := hVC;
  frmVCD.Resize;
end;

function HookCreateWindowExW(dwExStyle: DWORD; lpClassName: LPCWSTR; lpWindowName: LPCWSTR; dwStyle: DWORD; X, Y, nWidth, nHeight: Integer; hWndParent: hWnd; hMenu: hMenu; hins: HINST; lpp: Pointer): hWnd; stdcall;
begin
  if (lpClassName <> nil) and (lpWindowName <> nil) and (SameText(lpClassName, FstrVCDLGDllClassName)) and (SameText(lpWindowName, FstrVCDLGDllTitleName)) then
  begin
    UnHook(@FOld_CreateWindowExW);
    Result := FOld_CreateWindowExW(dwExStyle, lpClassName, lpWindowName, dwStyle, X, Y, nWidth, nHeight, hWndParent, hMenu, hins, lpp);
    CreateVCDllForm(Result);
  end
  else
  begin
    Result := FOld_CreateWindowExW(dwExStyle, lpClassName, lpWindowName, dwStyle, X, Y, nWidth, nHeight, hWndParent, hMenu, hins, lpp);
  end;
end;

function AnsiToWide(const s: PAnsiChar; codePage: Cardinal = CP_ACP): PWideChar;
var
  len : Integer;
  wlen: Integer;
begin
  len    := Length(s);
  wlen   := MultiByteToWideChar(codePage, 0, s, len, nil, 0);
  Result := GetMemory((wlen + 1) * SizeOf(WideChar));
  MultiByteToWideChar(codePage, 0, s, len, Result, wlen);
  Result[wlen] := #0;
end;

procedure TfrmVCD.ThreadCreateVCModuleForm;
var
  strDllPathFileName: string;
  hDLL              : HMODULE;
  pFunc             : Tdb_ShowDllForm_Plugins_VC;
  chrModuleName     : PAnsiChar;
  chrClassName      : PAnsiChar;
  chrTitleName      : PAnsiChar;
  ls                : TLangStyle;
begin
  HookProcInModule(user32, 'CreateWindowExW', @HookCreateWindowExW, @FOld_CreateWindowExW);

  strDllPathFileName := Hint;
  hDLL               := LoadLibrary(PChar(strDllPathFileName));
  tag                := hDLL;
  pFunc              := GetProcAddress(hDLL, c_strDllExportFuncName);
  pFunc(ls, chrModuleName, chrClassName, chrTitleName, False);
  FstrVCDLGDllClassName := AnsiToWide(chrClassName);
  FstrVCDLGDllTitleName := AnsiToWide(chrTitleName);
  pFunc(ls, chrModuleName, chrClassName, chrTitleName, True);
  FreeMem(FstrVCDLGDllClassName);
  FreeMem(FstrVCDLGDllTitleName);
end;

end.
