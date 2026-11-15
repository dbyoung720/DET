unit udd;

interface

uses Winapi.Windows, Winapi.Messages, System.Classes, System.SysUtils, Vcl.Forms, Vcl.Controls, Vcl.ExtCtrls, Data.DB, Data.Win.ADODB;

type
  TModifyRecordCallback = function(DataSet: TDataSet): Boolean of object;

type
  TfrmDataDll = class(TForm)
  public
    constructor Create(AOwner: TComponent); override;
    procedure Free;
    procedure DataDllFormResize;
  public
    procedure SearchRecord(const bShow: Boolean); virtual; abstract;
    procedure DetailRecord(DetailCallBack: TModifyRecordCallback); virtual; abstract;
    procedure AddRecord(AddRecordCallBack: TModifyRecordCallback); virtual; abstract;
    procedure ModRecord(ModRecordCallBack: TModifyRecordCallback); virtual; abstract;
    procedure DelRecord; virtual; abstract;
    procedure ExportRecord; virtual; abstract;
    procedure ImportRecord; virtual; abstract;
    procedure RefreshRecord; virtual; abstract;
  end;

  TfrmDataDllClass = class of TfrmDataDll;

var
  frmDataDLL: TfrmDataDll = nil;

implementation

var
  FDLLMainForm: TForm = nil;

procedure TimerProc(hWnd: THandle; uMsg, idEvent: UINT; dwTime: DWORD); stdcall;
var
  GetDataFormDLL : function: TfrmDataDllClass; stdcall;
begin
  KillTimer(0, idEvent);

  TPanel(FDLLMainForm.FindComponent('pnlTop')).Enabled := False;
  try
    var pnlData            := TPanel(FDLLMainForm.FindComponent('pnlData'));
    var strDataDllFileName := ExtractFilePath(ParamStr(0)) + 'plugins\dd.dll';
    var hDLL               := LoadLibrary(PChar(strDataDllFileName));
    @GetDataFormDLL        := GetProcAddress(hDLL, 'GetDataFormDLL');
    frmDataDLL             := TfrmDataDll(GetDataFormDLL.Create(nil));
    frmDataDLL.BorderStyle := bsNone;
    SetWindowPos(frmDataDLL.Handle, pnlData.Handle, 0, 0, pnlData.Width, pnlData.Height, SWP_NOZORDER OR SWP_NOACTIVATE);
    Winapi.Windows.SetParent(frmDataDLL.Handle, pnlData.Handle);
    frmDataDLL.Show;
    frmDataDLL.Tag    := hDLL;
    FDLLMainForm.Hint := ChangeFileExt(ExtractFileName(GetModuleName(HInstance)), '');
    FDLLMainForm.OnResize(nil);
  finally
    TPanel(FDLLMainForm.FindComponent('pnlTop')).Enabled := True;
  end;
end;

{ TfrmDataDll }

constructor TfrmDataDll.Create(AOwner: TComponent);
begin
  inherited;
  FDLLMainForm := Self;
  SetTimer(0, 100, 1, @TimerProc);
end;

procedure TfrmDataDll.DataDllFormResize;
begin
  if frmDataDLL = nil then Exit;

  var pnlData := TPanel(FDLLMainForm.FindComponent('pnlData'));
  SetWindowPos(frmDataDLL.Handle, pnlData.Handle, 0, 0, pnlData.Width, pnlData.Height, SWP_NOZORDER OR SWP_NOACTIVATE);
end;

procedure TfrmDataDll.Free;
var
  hDLL: HMODULE;
begin
  hDLL := frmDataDLL.Tag;
  frmDataDLL.Destroy;
  FreeLibrary(hDLL);
end;

end.
