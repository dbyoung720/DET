program Demo7zStatic;

uses
  Vcl.Forms,
  MainForm in 'MainForm.pas' {FormMain},
  SevenZip.Static in '..\SevenZip.Static.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TFormMain, FormMain);
  Application.Run;
end.
