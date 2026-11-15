unit uDllExe;
{
  Func : EXE Form Excute / EXE Form Close;
  Auth : dbyoung@sina.com
  Time : 2023-02-15
}

interface

uses
  Winapi.Windows, Winapi.Messages, System.Classes, System.SysUtils, System.Math, System.StrUtils, System.Types, Vcl.Controls, Vcl.Forms, uCommon;

{ 创建 EXE Form }
procedure CreateEXEForm(const strFileName: string);

{ 销毁 EXE Form }
procedure FreeEXEForm();

implementation

{ 查找 EXE 的主窗体是否成功创建 }
procedure FindExeFormCreate(hWnd: THandle; uMsg, idEvent: UINT; dwTime: DWORD); stdcall;
var 
  strFileName         : string;
  hEXEFormHandle      : THandle;
  strTitle1, strTitle2: string;
  PID                 : DWORD;
begin
  var RzTab := FindTabSheetByHandle(THandle(idEvent));
  if RzTab = nil then Exit;

  var strInfo := RzTab.Hint;
  if Trim(strInfo) = '' then Exit;
  
  var strExeFormClassName := strInfo.Split([';'])[3];
  var strExeFormTitleName := strInfo.Split([';'])[4];
  if strExeFormTitleName.Contains('(') then
  begin
    var iPos  := strExeFormTitleName.IndexOf('(');
    strTitle1 := strExeFormTitleName.Substring(0, iPos);
    strTitle2 := strExeFormTitleName.Substring(iPos + 1, strExeFormTitleName.IndexOf(')') - iPos - 1);
  end
  else
  begin
    strTitle1 := strExeFormTitleName;
    strTitle2 := '';
  end;

  var hEXEFormHandle1 := FindWindow(PChar(strExeFormClassName), PChar(strTitle1));
  var hEXEFormHandle2 := FindWindow(PChar(strExeFormClassName), PChar(strTitle2));
  if (hEXEFormHandle1 = 0) and (hEXEFormHandle2 = 0) then Exit;

  { 窗体找到了 }
  hEXEFormHandle := Ifthen(hEXEFormHandle1 <> 0, hEXEFormHandle1, hEXEFormHandle2);

  { 关闭定时器 }
  KillTimer(Application.MainForm.Handle, idEvent);

  { 保存下窗体句柄，关闭是需要使用 }
  RzTab.DisabledIndex := hEXEFormHandle;

  { 页签图标 }
  GetWindowThreadProcessId(hEXEFormHandle, @PID);
  strFileName      := GetProcessName(PID, true);
  rzTab.ImageIndex := SetTabSheetExeIcon(strFileName, rzTab);

  { 将 EXE 主窗体放置到 Tab 窗口中 }
  SetParentForm(hEXEFormHandle, RzTab);
  Application.MainForm.OnResize(nil);

  { 恢复光标位置 }
  if Application.MainForm.Hint.Contains(';') then
  begin
    var X := StrToIntDef(Application.MainForm.Hint.Split([';'])[0], 0);
    var Y := StrToIntDef(Application.MainForm.Hint.Split([';'])[1], 0);
    Mouse.CursorPos := Point(X, Y);
  end;
end;

{ 创建 EXE Form }
procedure CreateEXEForm(const strFileName: string);
var
  si: TStartupInfo;
  pi: TProcessInformation;
begin
  ClearRegeditView;

  { 保存当前光标位置；有的程序会修改光标位置 }
  var pt := Mouse.CursorPos;
  Application.MainForm.Hint := Format('%d;%d', [pt.X, pt.Y]);

  { 查找 EXE 的主窗体是否成功创建 }
  SetTimer(Application.MainForm.Handle, GetActiveTabSheet.Handle, 100, @FindExeFormCreate);

  { 创建 EXE 进程，并隐藏窗体 }
  ZeroMemory(@si, SizeOf(si));
  si.cb          := SizeOf(TStartupInfo);
  si.dwFlags     := STARTF_USESHOWWINDOW + STARTF_USEPOSITION + STARTF_USESIZE;
  si.wShowWindow := SW_HIDE;
  si.dwX         := 0;
  si.dwY         := 0;
  si.dwXSize     := 800;
  si.dwYSize     := 600;
  if CreateProcess(nil, PChar(strFileName), nil, nil, False, 0, nil, nil, si, pi) then 
  begin
    CloseHandle(pi.hProcess);
    CloseHandle(pi.hThread);
  end
  else
  begin
    KillTimer(Application.MainForm.Handle, GetActiveTabSheet.Handle);
  end;
 end;

{ 销毁 EXE Form }
procedure FreeEXEForm();
begin
  var RzTab := GetActiveTabSheet;
  if RzTab = nil then Exit;
  if RzTab.DisabledIndex = -1 then Exit;

  { 销毁可能存在的计时器 }
  KillTimer(Application.MainForm.Handle, RzTab.Handle);

  { 关闭窗体 }
  PostMessage(RzTab.DisabledIndex, WM_SYSCOMMAND, SC_CLOSE, 0);
end;

end.
