unit uDllVCDLG;

interface

uses Winapi.Windows, Winapi.Messages, System.Classes, System.SysUtils, System.IOUtils, Vcl.Forms, Vcl.Controls, Vcl.ExtCtrls, uCommon;

{ 创建 VC DLG DLL 窗体 }
procedure CreateVCDLGDllForm(const strDllFileName: string);

{ 销毁 VC DLG DLL 窗体 }
procedure FreeVcDlgFormDll;

implementation

function CheckPlatFormVCEXE: string;
begin
  Result := TPath.GetTempPath + {$IFDEF CPUX64} 'vcx64.exe' {$ELSE} 'vcx86.exe' {$IFEND};
  if not FileExists(Result) then
  begin
    var memVCDLG := TResourceStream.Create(HInstance, {$IFDEF CPUX64} 'VCX64' {$ELSE} 'VCX86' {$IFEND}, RT_RCDATA);
    try
      memVCDLG.SaveToFile(Result);
    finally
      memVCDLG.free;
    end;
  end;
end;

procedure SetParentWithoutChangingPosition(hChild, hNewParent: THandle);
var
  childRect: TRect;
  newPos   : TPoint;
begin
  if GetWindowRect(hChild, childRect) then
  begin
    SetParent(hChild, hNewParent);
    newPos.x := childRect.left;
    newPos.y := childRect.Top;
    ScreenToClient(hNewParent, newPos);
    SetWindowPos(hChild, 0, newPos.x, newPos.y, childRect.Right - childRect.left, childRect.Bottom - childRect.Top, SWP_NOZORDER or SWP_NOACTIVATE);
  end;
end;

{ 查找 VC DLG DLL 的主窗体是否成功创建 }
procedure FindVcDlgDllFormCreate(hWnd: THandle; uMsg: UINT; idEvent: UINT_PTR; dwTime: DWORD); stdcall;
begin
  var rzTab := FindTabSheetByHandle(THandle(idEvent));
  if rzTab = nil then Exit;
  if Trim(rzTab.Hint) = '' then Exit;

  var hVCDLGDllForm := FindWindow('TfrmVCD', PChar(rzTab.Hint.Split([';'])[2]));
  if hVCDLGDllForm = 0 then Exit;

  { 关闭定时器 }
  KillTimer(Application.MainForm.Handle, idEvent);

  rzTab.DisabledIndex := hVCDLGDllForm; // 窗体句柄
  SetParentWithoutChangingPosition(hVCDLGDllForm, rzTab.Handle);
end;

procedure CreateVCDLGDllForm(const strDllFileName: string);
var
  si : TStartupInfo;
  pi : TProcessInformation;
  rct: TRect;
begin
  { 查找 VC DLG DLL 的主窗体是否成功创建 }
  var rzTab := GetActiveTabSheet;
  SetTimer(Application.MainForm.Handle, rzTab.Handle, 100, @FindVcDlgDllFormCreate);

  var strFileName := CheckPlatFormVCEXE;
  GetWindowRect(rzTab.Parent.Handle, rct);
  rct.left           := rct.left   + 1;
  rct.Top            := rct.Top    + 1;
  rct.Right          := rct.Right  - 1;
  rct.Bottom         := rct.Bottom - 1;
  var strCommandLine := '"' + strFileName + '" "' + strDllFileName + '"' + ' ' + IntToStr(rct.left) + ' ' + IntToStr(rct.Top) + ' ' + IntToStr(rct.Width) + ' ' + IntToStr(rct.Height);
  ZeroMemory(@si, SizeOf(si));
  si.cb := SizeOf(TStartupInfo);
  if CreateProcess(nil, PChar(strCommandLine), nil, nil, False, 0, nil, nil, si, pi) then 
  begin
    CloseHandle(pi.hProcess);
    CloseHandle(pi.hThread);
  end
  else
  begin
    KillTimer(Application.MainForm.Handle, rzTab.Handle);
  end;
  rzTab.ImageIndex := SetTabSheetExeIcon(strDllFileName, rzTab);
end;

procedure FreeVcDlgFormDll;
begin
  var rzTab := GetActiveTabSheet;
  if rzTab = nil then Exit;
  if rzTab.DisabledIndex = -1 then Exit;
  
  { 销毁可能存在的计时器 }
  KillTimer(Application.MainForm.Handle, rzTab.Handle);

  { 关闭窗体 }
  PostMessage(rzTab.DisabledIndex, WM_SYSCOMMAND, SC_CLOSE, 0);
end;

end.
