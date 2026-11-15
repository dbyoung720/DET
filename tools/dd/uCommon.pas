unit uCommon;
{$WARN SYMBOL_DEPRECATED OFF}

interface

uses Winapi.Windows, System.SysUtils, System.Classes, System.StrUtils, Vcl.Controls, Vcl.Forms, CnAES;

const
  c_strAESKey      = 'dbyoung@sina.com';
  c_strPlugInsPath = 'plugins\';

type
  TRelateInfo = packed record
    strPrimateField: string;
    strRelateTable: string;
    strRelateField: string;
    strDisplayField: string;
  end;

  TDisplayTableInfo = packed record
    strTableName: string;
    ArrFields: TArray<string>;
    ArrDisplayTitle: TArray<string>;
    RelateTable: TArray<TRelateInfo>;
    strOrderByFieldName: string;
    strWhereSQL:string;
  end;

function GetMainFormApp(): TApplication;

function DecryptString(const strTemp, strKey: string): String;

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
    Code  : Byte;
    Offset: Integer;
    Next  : PObjectInstance;
    Form  : Pointer;
  end;
var
  FormProc: PObjectInstance;
begin
  Result   := nil;
  FormProc := Pointer(GetWindowLong(hWnd, GWL_WNDPROC));
  if FormProc <> nil then
  begin
    Result := FormProc^.Form;
  end;
end;

function _EnumApplicationProc(P_HWND: hWnd; LParam: NativeInt): Boolean; stdcall;
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

function GetMainFormApp(): TApplication;
var
  Buffer   : TAppInfo;
  AppHandle: THandle;
begin
  Result        := nil;
  Buffer.PID    := GetCurrentProcessId;
  Buffer.Handle := 0;
  EnumWindows(@_EnumApplicationProc, Winapi.Windows.LParam(@Buffer));
  if Buffer.Handle > 0 then
  begin
    AppHandle := Buffer.Handle;
    Result    := TApplication(GetInstanceFromhWnd(AppHandle));
  end;
end;

function DecryptString(const strTemp, strKey: string): String;
begin
  Result := string(AESDecryptEcbStrFromHex(AnsiString(strTemp), AnsiString(strKey)));
end;

end.
