library plist;
{$IF CompilerVersion >= 21.0}
{$WEAKLINKRTTI ON}
{$RTTI EXPLICIT METHODS([]) PROPERTIES([]) FIELDS([])}
{$IFEND}

uses
  Vcl.Forms,
  System.SysUtils,
  System.Classes,
  Unit1 in 'Unit1.pas' {frmPeopoleList},
  udd in 'udd.pas',
  uApp in 'uApp.pas',
  uMod in 'uMod.pas' {Form3};

{$R *.res}

type
 TLangStyle = (lsDelphi, lsVCDLG, lsVCMFC, lsQT, lsEXE);

procedure db_ShowDllForm_Plugins(var ls: TLangStyle; var frm: TFormClass; var strModuleName: PAnsiChar); stdcall;
begin
  ls            := lsDelphi;
  frm           := TfrmPeopoleList;
  strModuleName := '人员管理/人员列表';
end;

exports
  db_ShowDllForm_Plugins;

begin

end.
