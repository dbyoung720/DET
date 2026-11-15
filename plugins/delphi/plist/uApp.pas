unit uApp;

interface

uses Winapi.Windows, System.Classes, System.SysUtils, Vcl.Forms, Vcl.Controls, Vcl.StdCtrls, Vcl.ExtCtrls;

function GetMainFormApp: TApplication;

function FindForm(const strFormName: string): TForm;

implementation

type
  PAppInfo = ^TAppInfo;

  TAppInfo = record
    PID: DWORD;
    Handle: THandle;
  end;

function GetInstanceFromhWnd(const hWnd: THandle): TWinControl;
type
  PObjectInstance = ^TObjectInstance;

  TObjectInstance = packed record
    Code: Byte;
    Offset: Integer;
    Next: PObjectInstance;
    Form: Pointer;
  end;
var
  pForm: PObjectInstance;
begin
  Result := nil;
  pForm     := Pointer(GetWindowLong(hWnd, GWL_WNDPROC));
  if pForm <> nil then
  begin
    Result := pForm.Form;
  end;
end;

function _EnumApplicationProc(P_HWND: hWnd; LParam: LParam): Boolean; stdcall;
var
  PID         : DWORD;
  Buffer      : PAppInfo;
  chrClassName: array [0 .. 255] of Char;
  strClassName: String;
begin
  Result := True;
  Buffer := PAppInfo(LParam);

  GetWindowThreadProcessId(P_HWND, @PID);
  if Buffer^.PID <> PID then
  begin
    Result := True;
  end
  else
  begin
    GetClassName(P_HWND, chrClassName, 256);
    strClassName := chrClassName;
    if SameText(strClassName, 'TApplication') then
    begin
      Result         := False;
      Buffer^.Handle := P_HWND;
    end;
  end;
end;

function GetMainFormApp: TApplication;
var
  Buffer : TAppInfo;
begin
  Result        := nil;
  Buffer.PID    := GetCurrentProcessId;
  Buffer.Handle := 0;
  EnumWindows(@_EnumApplicationProc, Winapi.Windows.LParam(@Buffer));
  if Buffer.Handle > 0 then
  begin
    var AppHandle := Buffer.Handle;
    Result        := TApplication(GetInstanceFromhWnd(AppHandle));
  end;
end;

function FindForm(const strFormName: string): TForm;
begin
  Result := nil;
  for var I := 0 to Screen.FormCount - 1 do
  begin
    if SameText(Screen.Forms[I].Name, strFormName) then
    begin
      Result := TForm(Screen.Forms[I]);
      Break;
    end;
  end;
end;

end.
