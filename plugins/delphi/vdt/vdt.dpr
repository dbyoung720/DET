library vdt;
{$IF CompilerVersion >= 21.0}
{$WEAKLINKRTTI ON}
{$RTTI EXPLICIT METHODS([]) PROPERTIES([]) FIELDS([])}
{$IFEND}

uses
  Vcl.Forms,
  System.SysUtils,
  System.Classes,
  dec01 in 'dec01.pas',
  dec02 in 'dec02.pas',
  dec03 in 'dec03.pas',
  dec04 in 'dec04.pas',
  dec05 in 'dec05.pas',
  dec06 in 'dec06.pas',
  Unit1 in 'Unit1.pas' {frmVideoDecode};

{$R *.res}

type
 TLangStyle = (lsDelphi, lsVCDLG, lsVCMFC, lsQT, lsEXE);

procedure db_ShowDllForm_Plugins(var ls: TLangStyle; var frm: TFormClass; var strModuleName: PAnsiChar); stdcall;
begin
	ls            := lsDelphi;
  frm           := TfrmVideoDecode;
  strModuleName := '多媒体管理/视频解码测试';
end;

exports
  db_ShowDllForm_Plugins;

begin

end.
