unit uAdjust;

interface

uses Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.ComCtrls, Vcl.StdCtrls;

type
  tagRGBQUAD = record
    B: Byte;
    G: Byte;
    R: Byte;
    A: Byte;
  end;

  PRGBQuad = ^TRGBQuad;
  TRGBQuad = tagRGBQUAD;
  RGBQUAD  = tagRGBQUAD;

  TAlpha      = array [0 .. 255] of Integer;
  TGrays      = array [0 .. 767] of Integer;
  TAdjustFunc = procedure(var iSpeedTime: Int64) of object;
  TAdjustProc = procedure(const bmpSrc: TBitmap; BmpDst: TBitmap; const iPos: Integer; Refresh: TAdjustFunc) of object;

type
  TfrmAdjust = class(TForm)
    trckbrAdjust: TTrackBar;
    lblAdjustValue: TLabel;
    lblType: TLabel;
    procedure trckbrAdjustChange(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
  public
    FbmpSrc, FbmpDst: TBitmap;
    FAdjustProc     : TAdjustProc;
    FRefreshImage   : TAdjustFunc;
  end;

procedure ShowAdjustForm(const strTitle: string; const iMin, iMax, iPos: Integer; const bmpSrc: TBitmap; BmpDst: TBitmap; AdjustProc: TAdjustProc; RefreshImage: TAdjustFunc);

implementation

{$R *.dfm}

procedure ShowAdjustForm(const strTitle: string; const iMin, iMax, iPos: Integer; const bmpSrc: TBitmap; BmpDst: TBitmap; AdjustProc: TAdjustProc; RefreshImage: TAdjustFunc);
begin
  with TfrmAdjust.Create(nil) do
  begin
    Left                  := Screen.Width - Width - 10;
    Top                   := Screen.Height - Height - 10;
    FbmpSrc               := bmpSrc;
    FbmpDst               := BmpDst;
    FAdjustProc           := AdjustProc;
    FRefreshImage         := RefreshImage;
    lblType.Caption       := strTitle;
    trckbrAdjust.Max      := iMax;
    trckbrAdjust.Min      := iMin;
    trckbrAdjust.Position := iPos;
    ShowModal;
    Free;
  end;
end;

procedure TfrmAdjust.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  Action := TCloseAction.caFree;
end;

procedure TfrmAdjust.trckbrAdjustChange(Sender: TObject);
begin
  lblAdjustValue.Caption := Format('%d', [trckbrAdjust.Position]);
  FAdjustProc(FbmpSrc, FbmpDst, trckbrAdjust.Position, FRefreshImage);
end;

end.
