library PicView;
{$IF CompilerVersion >= 21.0}
{$WEAKLINKRTTI ON}
{$RTTI EXPLICIT METHODS([]) PROPERTIES([]) FIELDS([])}
{$IFEND}

{$R *.dres}

uses
  Vcl.Forms,
  System.SysUtils,
  System.Classes,
  uMain in 'uMain.pas' {frmPicView};

{$R *.res}

type
 TLangStyle = (lsDelphi, lsVCDLG, lsVCMFC, lsQT, lsEXE);

procedure db_ShowDllForm_Plugins(var ls: TLangStyle; var frm: TFormClass; var strModuleName: PAnsiChar); stdcall;
begin
  ls            := lsDelphi;
  frm           := TfrmPicView;
  strModuleName := 'Í¼ÐÎÍ¼Ïñ/Í¼Ïñ²é¿´Æ÷';
end;

exports
  db_ShowDllForm_Plugins;

begin

end.
