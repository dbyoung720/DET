unit uAbout;

interface

uses Winapi.Windows, System.SysUtils, System.Classes, Vcl.Forms, Vcl.Controls, Vcl.StdCtrls, Vcl.ExtCtrls, Vcl.Graphics;

type
  TAboutForm = class(TForm)
    ImageIcon: TImage;
    LabelTitle: TLabel;
    LabelVersion: TLabel;
    LabelDesc: TLabel;
    LabelEngine: TLabel;
    Bevel1: TBevel;
    ButtonOK: TButton;
    procedure ButtonOKClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
  end;

implementation

{$R *.dfm}

type
  TButtonColorAccess = class(TButton);

procedure TAboutForm.FormCreate(Sender: TObject);
var
  I: Integer;
begin
  ImageIcon.Picture.Icon.Assign(Application.Icon);

  { Dark look without VCL Styles: native colors and no themed client area }
  Color := TColor($181818);
  Font.Color := clWhite;
  for I := 0 to ComponentCount - 1 do
  begin
    if Components[I] is TLabel then
    begin
      TLabel(Components[I]).StyleElements := [];
      TLabel(Components[I]).Font.Color := clWhite;
    end
    else if Components[I] is TButton then
    begin
      TButton(Components[I]).StyleElements := [];
      TButtonColorAccess(Components[I]).Color := TColor($1C1C1C);
      TButton(Components[I]).Font.Color := clWhite;
    end;
  end;
  EnableImmersiveDarkMode(True);
end;

procedure TAboutForm.ButtonOKClick(Sender: TObject);
begin
  Close;
end;

procedure TAboutForm.FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
  if Key in [VK_RETURN, VK_ESCAPE] then Close;
end;

end.
