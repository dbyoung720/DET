library dvp;
{$IF CompilerVersion >= 21.0}
{$WEAKLINKRTTI ON}
{$RTTI EXPLICIT METHODS([]) PROPERTIES([]) FIELDS([])}
{$IFEND}

uses
  Vcl.Forms,
  System.SysUtils,
  System.Classes,
  Unit1 in 'Unit1.pas' {frmVideoPlayer},
  DSCommon   in 'LAVFilters\DSCommon.pas',
  DSPlayer   in 'LAVFilters\DSPlayer.pas',
  OsdWin     in 'LAVFilters\OsdWin.pas',
  SubGrabber in 'LAVFilters\SubGrabber.pas',
  SubOverlay in 'LAVFilters\SubOverlay.pas',
  Subtitles  in 'LAVFilters\Subtitles.pas';

{$R *.res}

type
 TLangStyle = (lsDelphi, lsVCDLG, lsVCMFC, lsQT, lsEXE);

procedure db_ShowDllForm_Plugins(var ls: TLangStyle; var frm: TFormClass; var strModuleName: PAnsiChar); stdcall;
begin
  ls            := lsDelphi;
  frm           := TfrmVideoPlayer;
  strModuleName := '多媒体管理/视频播放器 v1.0';
end;

exports
  db_ShowDllForm_Plugins;

begin

end.
