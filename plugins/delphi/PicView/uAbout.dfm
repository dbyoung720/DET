object AboutForm: TAboutForm
  Left = 0
  Top = 0
  BorderStyle = bsDialog
  Caption = #20851#20110' '#30475#22270#36719#20214' PicView'
  ClientHeight = 258
  ClientWidth = 440
  Color = 1579032
  Font.Charset = GB2312_CHARSET
  Font.Color = clWhite
  Font.Height = -12
  Font.Name = #23435#20307
  Font.Style = []
  KeyPreview = True
  OldCreateOrder = False
  Position = poScreenCenter
  OnCreate = FormCreate
  OnKeyDown = FormKeyDown
  PixelsPerInch = 96
  TextHeight = 13
  object ImageIcon: TImage
    Left = 24
    Top = 26
    Width = 48
    Height = 48
    AutoSize = False
    Stretch = True
    Transparent = True
  end
  object LabelTitle: TLabel
    Left = 88
    Top = 26
    Width = 320
    Height = 24
    Caption = #30475#22270#36719#20214' PicView'
    Font.Charset = GB2312_CHARSET
    Font.Color = clWhite
    Font.Height = -21
    Font.Name = #23435#20307
    Font.Style = [fsBold]
    ParentFont = False
  end
  object LabelVersion: TLabel
    Left = 88
    Top = 56
    Width = 320
    Height = 16
    Caption = #29256#26412' 1.0   '#22522#20110' Delphi 13.2 / VCL'
  end
  object Bevel1: TBevel
    Left = 24
    Top = 88
    Width = 392
    Height = 2
    Shape = bsTopLine
  end
  object LabelDesc: TLabel
    Left = 24
    Top = 104
    Width = 392
    Height = 76
    AutoSize = False
    Caption = #25991#20214#22841#26641' + '#32553#30053#22270#27983#35272' + '#39640#36136#37327#32553#25918#19982#26059#36716#12290#25903#25345#38190#30424#32763#39029#12289#40736#26631#28378#36718#12289#25302#25918#25171#24320#12289#24187#28783#29255#12289#20840#23631#27983#35272#12289#25490#24207#12289#21478#23384#20026#20197#21450#21024#38500#21040#22238#25910#31449#12290
    WordWrap = True
  end
  object LabelEngine: TLabel
    Left = 24
    Top = 186
    Width = 392
    Height = 18
    Caption = #22270#20687#35299#30721': Windows Imaging Component (WIC) + VCL '#22238#36864
    Font.Charset = GB2312_CHARSET
    Font.Color = 10526880
    Font.Height = -12
    Font.Name = #23435#20307
    Font.Style = []
    ParentFont = False
  end
  object ButtonOK: TButton
    Left = 336
    Top = 216
    Width = 80
    Height = 28
    Caption = #30830#23450
    Default = True
    TabOrder = 0
    OnClick = ButtonOKClick
  end
end
