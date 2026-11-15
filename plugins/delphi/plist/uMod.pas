unit uMod;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Data.Win.ADODB, Data.DB;

type
  TForm3 = class(TForm)
    mmo1: TMemo;
  private
    { Private declarations }
  public
    { Public declarations }
  end;

function ShowModRecordForm(DataSet: TDataSet; const strTitle : string = '修改记录'): Boolean;

implementation

{$R *.dfm}

function ShowModRecordForm(DataSet: TDataSet; const strTitle : string = '修改记录'): Boolean;
var
  I: Integer;
begin
  Result := False;

  with TForm3.Create(nil) do
  begin
    BorderIcons := [TBorderIcon.biSystemMenu];
    BorderStyle := bsDialog;
    Position    := poScreenCenter;
    Caption     := strTitle;
    for I := 0 to DataSet.FieldCount - 1 do
    begin
      try
        mmo1.Lines.Add(Format('%-20s : %s', [DataSet.Fields[I].FieldName, DataSet.Fields[I].Value]));
      except
        mmo1.Lines.Add('');
      end;
    end;
    ShowModal;
    Free;
  end;
end;

end.
