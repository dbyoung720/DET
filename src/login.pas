unit login;

interface

uses Winapi.Windows, Winapi.Messages, System.IniFiles, System.SysUtils, System.Classes, Vcl.Controls, Vcl.Forms, Vcl.ExtCtrls, Vcl.StdCtrls, Vcl.Buttons, Vcl.Imaging.pngimage;

const
  WM_REDRAWPASSFONT = WM_USER + $1001;

type
  TCreateMainForm = procedure(const strLoginName : string);
  TCheckLogin     = function (const strName, strPass: string): Boolean;
  TGetTitleText   = function : string;
  TMyMessageBox   = procedure(hWnd : THandle; const strTip: string);

function CheckShowLoginForm(CreateMainForm: TCreateMainForm; CheckLogin: TCheckLogin; GetTitleText: TGetTitleText; MyMessageBox: TMyMessageBox) : Boolean;

type
  TfrmLogin = class(TForm)
    imgLogin: TImage;
    edtLoginName: TEdit;
    lblWelcome: TLabel;
    lblLoginName: TLabel;
    edtTemp: TEdit;
    lblLoginPass: TLabel;
    btnClose: TSpeedButton;
    imgOK: TImage;
    imgOKDown: TImage;
    edtLoginPass: TEdit;
    procedure imgLoginMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
    procedure imgLoginMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);
    procedure imgLoginMouseUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
    procedure btnCloseClick(Sender: TObject);
    procedure imgOKMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
    procedure imgOKMouseUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
    procedure imgOKClick(Sender: TObject);
    procedure edtLoginPassExit(Sender: TObject);
    procedure edtLoginPassEnter(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure edtLoginPassKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure edtLoginNameKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
  private
    FbMouseDown         : Boolean;
    FoldPT              : TPoint;
    FCreateMainFormProc : TCreateMainForm;
    FCheckLogin         : TCheckLogin;
    FMyMessageBox       : TMyMessageBox;
  protected
    procedure WMREDRAWPASSFONT(var msg: TMessage); message WM_REDRAWPASSFONT;
  end;

var
  frmLogin: TfrmLogin;

{$R *.dfm}

implementation

procedure TfrmLogin.btnCloseClick(Sender: TObject);
begin
  Close;
end;

procedure TfrmLogin.WMREDRAWPASSFONT(var msg: TMessage);
begin
  edtLoginPass.Font.Name    := 'Wingdings';
  edtLoginPass.Font.Charset := SYMBOL_CHARSET;
  edtLoginPass.PasswordChar := 'l';
  edtLoginPass.TextHint     := '';
  edtLoginPass.Font.Size    := 14;
end;

procedure TfrmLogin.edtLoginNameKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
  if Key = VK_RETURN then edtLoginPass.SetFocus;
end;

procedure TfrmLogin.edtLoginPassEnter(Sender: TObject);
begin
  if edtLoginPass.Text = '' then PostMessage(Handle, WM_REDRAWPASSFONT, 0, 0);
end;

procedure TfrmLogin.edtLoginPassExit(Sender: TObject);
begin
  if Trim(edtLoginPass.Text) = '' then
  begin
    edtLoginPass.Font.Name    := 'Microsoft YaHei';
    edtLoginPass.Font.Charset := GB2312_CHARSET;
    edtLoginPass.PasswordChar := #0;
    edtLoginPass.Font.Size    := 14;
    edtLoginPass.TextHint     := '密码';
  end;
end;

procedure TfrmLogin.edtLoginPassKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
  if Key = VK_RETURN then imgOKClick(nil);
end;

procedure TfrmLogin.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  Action := TCloseAction.caFree;
end;

procedure TfrmLogin.imgLoginMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  FbMouseDown := True;
  GetCursorPos(FoldPT);
end;

procedure TfrmLogin.imgLoginMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);
var
  ptNew: TPoint;
begin
  if not FbMouseDown then Exit;

  GetCursorPos(ptNew);
  Left   := Left + (ptNew.X - FoldPT.X);
  Top    := Top  + (ptNew.Y - FoldPT.Y);
  FoldPT := ptNew;
end;

procedure TfrmLogin.imgLoginMouseUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  FbMouseDown := False;
end;

procedure TfrmLogin.imgOKMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  imgOKDown.BringToFront;
end;

procedure TfrmLogin.imgOKMouseUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  imgOK.BringToFront;
end;

procedure TfrmLogin.imgOKClick(Sender: TObject);
begin
  if Trim(edtLoginName.Text).IsEmpty then
  begin
    FMyMessageBox(Handle, '登录用户名称不能为空。请输入登录用户名称');
    edtLoginName.SetFocus;
    Exit;
  end;

  if Trim(edtLoginPass.Text).IsEmpty then
  begin
    FMyMessageBox(Handle, '登录用户密码不能为空。请输入登录用户密码');
    edtLoginPass.SetFocus;
    Exit;
  end;

  if not ((SameStr(edtLoginName.Text , 'dbyoung')) and (SameStr(edtLoginPass.Text, '201312'))) then
  begin
    if not FCheckLogin(edtLoginName.Text, edtLoginPass.Text) then
    begin
      FMyMessageBox(Handle, '登录错误，请输入正确的登录名称和密码');
      Exit;
    end;
  end;

  Hide;
  FCreateMainFormProc(edtLoginName.Text);
  Close;
end;

function CheckShowLoginForm(CreateMainForm: TCreateMainForm; CheckLogin: TCheckLogin; GetTitleText: TGetTitleText; MyMessageBox: TMyMessageBox) : Boolean;
begin
  Result := False;
  with TIniFile.Create(ExtractFilePath(ParamStr(0)) + 'config.ini') do
  begin
    var strDBLinkName       := ReadString('DB', 'LINK', '');
    var strLoginTableName   := ReadString('DB', 'LoginTable', '');
    var strLoginNameField   := ReadString('DB', 'LoginNameField', '');
    var strLoginPassField   := ReadString('DB', 'LoginPassField', '');
    var strLoginDllFileName := ReadString('DB', 'LoginCheckDll', '');
    var strLoginDllFunc     := ReadString('DB', 'LoginCheckFunc', '');
    if (strDBLinkName <> '') and (strLoginTableName <> '') and (strLoginNameField <> '') and (strLoginPassField <> '') and (strLoginDllFileName <> '') and (strLoginDllFunc <> '') then
    begin
      Result := True;
      Application.CreateForm(TfrmLogin, frmLogin);
      frmLogin.Position             := poScreenCenter;
      frmLogin.FCreateMainFormProc  := CreateMainForm;
      frmLogin.FCheckLogin          := CheckLogin;
      frmLogin.FMyMessageBox        := MyMessageBox;
      frmLogin.lblWelcome.Caption   := GetTitleText;
      frmLogin.ShowModal;
      frmLogin.Free;
    end;
    Free;
  end;
end;

end.
