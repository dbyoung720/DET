library dcv;
{$IF CompilerVersion >= 21.0}
{$WEAKLINKRTTI ON}
{$RTTI EXPLICIT METHODS([]) PROPERTIES([]) FIELDS([])}
{$IFEND}

uses
  Vcl.Forms,
  cv4d   in '..\..\..\tools\opencv\cv4d.pas',
  cvtype in '..\..\..\tools\opencv\cvtype.pas',
  uMainForm in 'uMainForm.pas' {frmOpenCV4Delphi};

{$R *.res}

type
 TLangStyle = (lsDelphi, lsVCDLG, lsVCMFC, lsQT, lsEXE);

procedure db_ShowDllForm_Plugins(var ls: TLangStyle; var frm: TFormClass; var strModuleName: PAnsiChar); stdcall;
begin
  ls            := lsDelphi;
  frm           := TfrmOpenCV4Delphi;
  strModuleName := '开发工具/OpenCV4Delphi';
end;

exports
  db_ShowDllForm_Plugins;

begin

end.
