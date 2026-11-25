unit Unit1;

interface

uses Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.ExtCtrls, System.UITypes, ChromeScrollBar;

type
  TfrmEnv = class(TForm)
    Memo1: TMemo;
    tmrStart: TTimer;
    procedure tmrStartTimer(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormCreate(Sender: TObject);
  private
    FSBLV: TChromeScrollBar;
  end;

var
  frmEnv: TfrmEnv;

implementation

{$R *.dfm}

procedure TfrmEnv.FormCreate(Sender: TObject);
begin
  FSBLV                     := TChromeScrollBar.Create(nil);
  FSBLV.Target              := Memo1;
  FSBLV.TrackColor          := 2367776;
  FSBLV.ThumbColor          := 6841183;
  FSBLV.ThumbHoverColor     := 10920090;
  FSBLV.ThumbPressedColor   := 13881549;
  FSBLV.AutoHide            := False;
end;

procedure TfrmEnv.FormDestroy(Sender: TObject);
begin
  FSBLV.Free;
end;

procedure TfrmEnv.tmrStartTimer(Sender: TObject);
var
  EnvStrings: PChar;
  EnvVar    : string;
  P         : PChar;
begin
  tmrStart.Enabled := False;

  Memo1.Lines.BeginUpdate;
  EnvStrings := GetEnvironmentStrings;
  try
    P := EnvStrings;
    while P^ <> #0 do
    begin
      EnvVar := P;
      Memo1.Lines.Add(EnvVar);
      Inc(P, Length(EnvVar) + 1);
    end;
  finally
    FreeEnvironmentStrings(EnvStrings);
    Memo1.Lines.EndUpdate;
  end;
end;

end.
