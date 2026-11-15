library vds;
{$IF CompilerVersion >= 21.0}
{$WEAKLINKRTTI ON}
{$RTTI EXPLICIT METHODS([]) PROPERTIES([]) FIELDS([])}
{$IFEND}



uses
  Vcl.Forms,
  System.SysUtils,
  System.Classes,
  Unit1 in 'Unit1.pas' {frmVideoCapture};

{$R *.res}

type
 TLangStyle = (lsDelphi, lsVCDLG, lsVCMFC, lsQT, lsEXE);

procedure db_ShowDllForm_Plugins(var ls: TLangStyle; var frm: TFormClass; var strModuleName: PAnsiChar); stdcall;
begin
	ls            := lsDelphi;
  frm           := TfrmVideoCapture;
  strModuleName := '多媒体管理/视频捕获 v5.0';
end;

exports
  db_ShowDllForm_Plugins;

begin

end.
