unit Unit1;
{$WARN SYMBOL_PLATFORM OFF}

interface

uses Winapi.DirectShow9, Winapi.GDIPAPI, Winapi.GDIPOBJ, System.SysUtils, System.Variants, System.Classes, Winapi.ActiveX, System.Win.ComObj,
     Vcl.Controls, Vcl.Forms, Vcl.StdCtrls, Vcl.ExtCtrls, DSUtil, uCommon;

type
  TfrmVideoCapture = class(TForm)
    grp1: TGroupBox;
    cbbVideoDevice: TComboBox;
    grp11: TGroupBox;
    cbbVideoSupportPixel: TComboBox;
    grp12: TGroupBox;
    pnlVideo: TPanel;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
  private
    { Private declarations }
    procedure EnumVideoDeviceList(cbb: TComboBox);
  public
    { Public declarations }
  end;

implementation

{$R *.dfm}

procedure TfrmVideoCapture.EnumVideoDeviceList(cbb: TComboBox);
var
  CapEnum: TSysDevEnum;
  I      : Integer;
begin
  CapEnum := TSysDevEnum.Create(CLSID_VideoInputDeviceCategory);
  try
    for I := 0 to CapEnum.CountFilters - 1 do
      cbb.Items.Add(string(CapEnum.Filters[I].FriendlyName));
    cbb.items.Add(c_strVirtualDesktopName);
    cbb.ItemIndex := 0;
  finally
    CapEnum.Free;
  end;
end;

procedure TfrmVideoCapture.FormCreate(Sender: TObject);
begin
  InitSDK;
  EnumVideoDeviceList(cbbVideoDevice);
end;

procedure TfrmVideoCapture.FormDestroy(Sender: TObject);
begin
  FreeSDK;
end;

end.
