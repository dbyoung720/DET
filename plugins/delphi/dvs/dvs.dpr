library dvs;
{$IF CompilerVersion >= 21.0}
{$WEAKLINKRTTI ON}
{$RTTI EXPLICIT METHODS([]) PROPERTIES([]) FIELDS([])}
{$IFEND}

uses
  Vcl.Forms,
  System.SysUtils,
  System.Classes,
  SiteIntf in 'SiteIntf.pas',
  SiteManager in 'SiteManager.pas',
  Site4kvm in 'Sites\4kvm\Site4kvm.pas',
  Site555 in 'Sites\555\Site555.pas',
  SiteGangju in 'Sites\gangju\SiteGangju.pas',
  SiteFeikuai in 'Sites\feikuai\SiteFeikuai.pas',
  SiteSyzljs in 'Sites\syzljs\SiteSyzljs.pas',
  SiteWhtqedu in 'Sites\whtqedu\SiteWhtqedu.pas',
  SiteIkanbot in 'Sites\ikanbot\SiteIkanbot.pas',
  SiteY2s52n7 in 'Sites\y2s52n7\SiteY2s52n7.pas',
  SiteMedvsm in 'Sites\medvsm\SiteMedvsm.pas',
  SiteVictoryyuly in 'Sites\victoryyuly\SiteVictoryyuly.pas',
  SiteFiilacurent in 'Sites\fiilacurent\SiteFiilacurent.pas',
  SiteRegistry in 'Sites\SiteRegistry.pas',
  MainUnit in 'MainUnit.pas' {frmVideoSearch};

{$R *.res}

type
 TLangStyle = (lsDelphi, lsVCDLG, lsVCMFC, lsQT, lsEXE);

procedure db_ShowDllForm_Plugins(var ls: TLangStyle; var frm: TFormClass; var strModuleName: PAnsiChar); stdcall;
begin
  ls            := lsDelphi;
  frm           := TfrmVideoSearch;
  strModuleName := '多媒体管理/视频搜索器 v1.0';
end;

exports
  db_ShowDllForm_Plugins;

begin

end.
