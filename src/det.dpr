program det;

uses
  uLogger in 'uLogger.pas',
  Vcl.Forms,
  uMain       in 'uMain.pas' { frmMain  },
  login       in 'login.pas' { frmLogin },
  uProcessAPI in '..\plugins\delphi\pm\uProcessAPI.pas',
  uDllDelphi  in 'uDll\uDllDelphi.pas',
  uDllExe     in 'uDll\uDllExe.pas',
  uDllVCDLG   in 'uDll\uDllVCDLG.pas',
  uDllVCMFC   in 'uDll\uDllVCMFC.pas',
  uTabView    in 'uTabView.pas',
  uCommon     in 'uCommon.pas';

{$R *.res}

{$IFDEF CPUX86}
  {$R res\7zX86.res}
  {$R res\vcx86.res}
{$ELSE}
  {$R res\7zX64.res}
  {$R res\vcx64.res}
{$ENDIF}

function GetMainFormApplication: TApplication; stdcall; begin Result := Application;       end; exports GetMainFormApplication;
function Get7zipPath : PChar;                  stdcall; begin Result := PChar(Check7zDll); end; exports Get7zipPath;
function CreateLogger: TLogger;                stdcall; begin Result := FLogger;           end; exports CreateLogger;

procedure CreateMainForm(const strLoginName : string);
begin
  FLogger.Log('登录用户：' + strLoginName);
  var pMain       := @Application.MainForm;
  Pointer(pMain^) := nil;
  Application.CreateForm(TfrmMain, frmMain);
  frmMain.Hint     := strLoginName;
  frmMain.ShowHint := False;
end;

begin
  FLogger.Log('程序初始化完成');
  FLogger.Log('程序开始运行');
  Application.Initialize;
  ReportMemoryLeaksOnShutdown := True;
  Application.MainFormOnTaskbar := True;
  if not CheckShowLoginForm(@CreateMainForm, @CheckLogin, @GetTitleText, @MyMsg) then
  Application.CreateForm(TfrmMain, frmMain);
  Application.Run;
  FLogger.Log('程序结束运行');
  FLogger.Log();
end.
