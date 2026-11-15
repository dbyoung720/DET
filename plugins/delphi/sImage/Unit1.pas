unit Unit1;

interface

uses
  System.SysUtils, System.Variants, System.Classes, Winapi.ActiveX, System.Win.ComObj, System.Diagnostics,
  Vcl.Controls, Vcl.Forms, Vcl.StdCtrls, Vcl.ExtCtrls, Vcl.Dialogs, Vcl.Graphics, uImage;

type
  TDIP = procedure(bmp: TBitmap) of object;

type
  TfrmDIP = class(TForm)
    pnlImage: TPanel;
    pnlControl: TPanel;
    imgShow: TImage;
    btnOpen: TButton;
    btnRestore: TButton;
    btnGray: TButton;
    btnInvert: TButton;
    btnHMirror: TButton;
    btnVMirror: TButton;
    btnZhuangZhi: TButton;
    btnRomate: TButton;
    btnContrast: TButton;
    btnSaturation: TButton;
    btnBlend: TButton;
    btnEmboss: TButton;
    btnExposure: TButton;
    btnEngrave: TButton;
    btnRestore111: TButton;
    btnLight: TButton;
    lblTime: TLabel;
    procedure FormCreate(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure btnOpenClick(Sender: TObject);
    procedure btnRestoreClick(Sender: TObject);
    procedure btnInvertClick(Sender: TObject);
    procedure btnGrayClick(Sender: TObject);
    procedure btnHMirrorClick(Sender: TObject);
    procedure btnVMirrorClick(Sender: TObject);
    procedure btnZhuangZhiClick(Sender: TObject);
    procedure btnLightClick(Sender: TObject);
    procedure btnContrastClick(Sender: TObject);
    procedure btnSaturationClick(Sender: TObject);
    procedure btnBlendClick(Sender: TObject);
    procedure btnExposureClick(Sender: TObject);
    procedure btnRomateClick(Sender: TObject);
    procedure btnEmbossClick(Sender: TObject);
    procedure btnEngraveClick(Sender: TObject);
  private
    Fimage: TdbImage;
    procedure CalcTime(func: TDIP);
  public
    procedure RefreshImage(var iSpeedTime: Int64);
  end;

implementation

{$R *.dfm}

procedure TfrmDIP.FormCreate(Sender: TObject);
var
  I : Integer;
  wc: TControl;
begin
  Fimage := TdbImage.Create;

  for I := 0 to pnlControl.ControlCount - 1 do
  begin
    wc := pnlControl.Controls[I];
    if wc is TButton then
    begin
      TButton(wc).Enabled := False;
    end;
  end;
  btnOpen.Enabled := True;
end;

procedure TfrmDIP.RefreshImage(var iSpeedTime: Int64);
begin
  lblTime.Caption := Format('耗费时间：%d 毫秒', [iSpeedTime]);
  imgShow.Invalidate;
end;

procedure TfrmDIP.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  Fimage.free;
end;

procedure TfrmDIP.CalcTime(func: TDIP);
begin
  with TStopWatch.StartNew do
  begin
    func(imgShow.Picture.Bitmap);
    lblTime.Caption := Format('耗费时间：%d 毫秒', [ElapsedMilliseconds]);
  end;
  imgShow.Invalidate;
end;

procedure TfrmDIP.btnGrayClick(Sender: TObject);
begin
  CalcTime(Fimage.Gray);
end;

procedure TfrmDIP.btnHMirrorClick(Sender: TObject);
begin
  CalcTime(Fimage.HorizMirror);
end;

procedure TfrmDIP.btnVMirrorClick(Sender: TObject);
begin
  CalcTime(Fimage.VertiMirror);
end;

procedure TfrmDIP.btnZhuangZhiClick(Sender: TObject);
begin
  CalcTime(Fimage.HAndVMirror);
end;

procedure TfrmDIP.btnInvertClick(Sender: TObject);
begin
  CalcTime(Fimage.Invert);
end;

procedure TfrmDIP.btnLightClick(Sender: TObject);
begin
  Fimage.Brightness(imgShow.Picture.Bitmap, RefreshImage);
end;

procedure TfrmDIP.btnBlendClick(Sender: TObject);
var
  bmpBlend  : TBitmap;
  iSpendTime: Integer;
begin
  if not Fimage.LoadImage(bmpBlend, iSpendTime) then
    Exit;

  if bmpBlend.Width > imgShow.Picture.Bitmap.Width then
    Exit;

  if bmpBlend.Height > imgShow.Picture.Bitmap.Height then
    Exit;

  Fimage.Blend(bmpBlend, imgShow.Picture.Bitmap, RefreshImage);
end;

procedure TfrmDIP.btnContrastClick(Sender: TObject);
begin
  Fimage.Contrast(imgShow.Picture.Bitmap, RefreshImage);
end;

procedure TfrmDIP.btnEmbossClick(Sender: TObject);
begin
  CalcTime(Fimage.Emboss);
end;

procedure TfrmDIP.btnEngraveClick(Sender: TObject);
begin
  CalcTime(Fimage.Engrave);
end;

procedure TfrmDIP.btnExposureClick(Sender: TObject);
begin
  CalcTime(Fimage.Exposure);
end;

procedure TfrmDIP.btnRestoreClick(Sender: TObject);
begin
  CalcTime(Fimage.Restore);
end;

procedure TfrmDIP.btnRomateClick(Sender: TObject);
var
  iSpeedTime: Integer;
begin
  Fimage.Rotate(imgShow.Picture.Bitmap, 15, iSpeedTime);
  lblTime.Caption := Format('耗费时间：%d 毫秒', [iSpeedTime]);
  imgShow.Invalidate;
end;

procedure TfrmDIP.btnSaturationClick(Sender: TObject);
begin
  Fimage.Saturation(imgShow.Picture.Bitmap, RefreshImage);
end;

procedure TfrmDIP.btnOpenClick(Sender: TObject);
var
  bmp          : TBitmap;
  I, iSpendTime: Integer;
begin
  if not Fimage.LoadImage(bmp, iSpendTime, True) then
    Exit;

  lblTime.Caption := Format('耗费时间：%d 毫秒', [iSpendTime]);
  imgShow.Picture.Bitmap.Assign(bmp);

  for I := 0 to pnlControl.ControlCount - 1 do
  begin
    if pnlControl.Controls[I] is TButton then
    begin
      TButton(pnlControl.Controls[I]).Enabled := True;
    end;
  end;
end;

end.
