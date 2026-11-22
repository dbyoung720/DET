unit Unit1;

interface

uses Winapi.Windows, Winapi.ActiveX, System.SysUtils, System.Variants, System.Classes, System.Win.ComObj, System.Threading,
     Vcl.Controls, Vcl.Forms, Vcl.StdCtrls, Vcl.Graphics, Vcl.ExtCtrls, RzPanel, RzRadGrp, Vcl.Buttons;

type
  TfrmVideoDecode = class(TForm)
    pnlVideo: TPanel;
    pnl1: TPanel;
    rg1: TRzRadioGroup;
    pnl2: TPanel;
    btnStart: TSpeedButton;
    pnl21: TPanel;
    btnStop: TSpeedButton;
    procedure btnStartClick(Sender: TObject);
    procedure btnStopClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
  private
    FThread : TThread;
    FCookie : Pointer;
    procedure ImageProcessCallback(bmp : TBitmap);
    procedure ThreadFinished(Sender : TObject);
  end;

implementation

uses dec01, dec02, dec03, dec04, dec05, dec06;

{$R *.dfm}
{$I image.inc}

function AddDllDirectory(const NewDirectory: LPCWSTR): Pointer; stdcall; external kernel32;  { 将目录添加到进程的 DLL 搜索路径 }
function RemoveDllDirectory(Cookie: Pointer): BOOL;             stdcall; external kernel32;  { 移除之前添加的目录 }

procedure TfrmVideoDecode.FormCreate(Sender: TObject);
begin
  FCookie := AddDllDirectory(PChar(ExtractFilePath(ParamStr(0)) + 'plugins\ffmpeg'));
end;

procedure TfrmVideoDecode.FormDestroy(Sender: TObject);
begin
  RemoveDllDirectory(FCookie);
end;

{ 用户自己的处理过程；可以测试代码效率 }
procedure TfrmVideoDecode.ImageProcessCallback(bmp: TBitmap);
begin
  // GrayBmp32(bmp);
end;

procedure TfrmVideoDecode.btnStartClick(Sender: TObject);
begin
  var strFileName := ExtractFilePath(ParamStr(0)) + 'plugins\x265.mp4';

  if rg1.ItemIndex = 0 then
    FThread := TVideoDecode01.Create(strFileName, pnlVideo.Handle, ImageProcessCallback);
  if rg1.ItemIndex = 1 then
    FThread := TVideoDecode02.Create(strFileName, pnlVideo.Handle, 'CUDA', ImageProcessCallback);
  if rg1.ItemIndex = 2 then
    FThread := TVideoDecode02.Create(strFileName, pnlVideo.Handle, 'QSV',  ImageProcessCallback);
  if rg1.ItemIndex = 3 then
    FThread := TVideoDecode03.Create(strFileName, pnlVideo.Handle, ImageProcessCallback);
  if rg1.ItemIndex = 4 then
    FThread := TVideoDecode04.Create(strFileName, pnlVideo.Handle, ImageProcessCallback);
  if rg1.ItemIndex = 5 then
    FThread := TVideoDecode05.Create(strFileName, pnlVideo.Handle, ImageProcessCallback);
  if rg1.ItemIndex = 6 then
    FThread := TVideoDecode06.Create(strFileName, pnlVideo.Handle);

  FThread.OnTerminate := ThreadFinished;
  btnStart.Enabled    := False;
  btnStop.Enabled     := True;
end;

procedure TfrmVideoDecode.btnStopClick(Sender: TObject);
begin
  if Assigned(FThread) then
  begin
    FThread.Terminate;
    FThread := nil;
  end;

  btnStart.Enabled:= True;
  btnStop.Enabled := False;
  pnlVideo.Invalidate;
end;

procedure TfrmVideoDecode.ThreadFinished(Sender: TObject);
begin
  btnStopClick(nil);
end;


end.
