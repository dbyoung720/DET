library sImage;

{$IF CompilerVersion >= 21.0}
{$WEAKLINKRTTI ON}
{$RTTI EXPLICIT METHODS([]) PROPERTIES([]) FIELDS([])}
{$IFEND}

uses
  Vcl.Forms,
  Vcl.Graphics in 'Vcl.Graphics.pas',
  Winapi.GDIPOBJ in 'Winapi.GDIPOBJ.pas',
  uImage in 'uImage.pas',
  Unit1 in 'Unit1.pas' {frmDIP} ,
  uAdjust in 'uAdjust.pas' {frmAdjust};

{$R *.res}

type
  TLangStyle = (lsDelphi, lsVCDLG, lsVCMFC, lsQT, lsEXE);

procedure db_ShowDllForm_Plugins(var ls: TLangStyle; var frm: TFormClass; var strModuleName: PAnsiChar); stdcall;
begin
  ls            := lsDelphi;
  frm           := TfrmDIP;
  strModuleName := '图形图像/数字图像处理';
end;

exports
  db_ShowDllForm_Plugins;

begin

end.
