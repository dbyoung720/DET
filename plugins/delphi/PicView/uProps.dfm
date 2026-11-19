object PropsForm: TPropsForm
  Left = 0
  Top = 0
  BorderStyle = bsSizeable
  Caption = #22270#20687#23646#24615
  ClientHeight = 430
  ClientWidth = 560
  Color = 1579032
  Font.Charset = GB2312_CHARSET
  Font.Color = clWhite
  Font.Height = -12
  Font.Name = #23435#20307
  Font.Style = []
  Position = poScreenCenter
  PixelsPerInch = 96
  TextHeight = 13
  object PanelBottom: TPanel
    Left = 0
    Top = 388
    Width = 560
    Height = 42
    Align = alBottom
    BevelOuter = bvNone
    TabOrder = 0
    object btnCopy: TButton
      Left = 8
      Top = 8
      Width = 100
      Height = 26
      Caption = #22797#21046#20449#24687
      TabOrder = 0
      OnClick = btnCopyClick
    end
    object btnOK: TButton
      Left = 462
      Top = 8
      Width = 90
      Height = 26
      Caption = #30830#23450
      ModalResult = 1
      TabOrder = 1
    end
  end
  object vle: TValueListEditor
    Left = 0
    Top = 0
    Width = 560
    Height = 388
    Align = alClient
    DisplayOptions = [doColumnTitles, doAutoColResize, doKeyColFixed]
    KeyOptions = []
    Options = [goFixedVertLine, goFixedHorzLine, goVertLine, goHorzLine, goColSizing, goThumbTracking]
    TabOrder = 1
    TitleCaptions.Strings = (
      #39033#30446
      #20540)
    Strings.Strings = (
      #25991#20214#21517'='
      #25991#20214#31867#22411'='
      #25152#22312#25991#20214#22841'='
      #23436#25972#36335#24452'='
      #25991#20214#22823#23567'='
      #21019#24314#26102#38388'='
      #20462#25913#26102#38388'='
      #22270#20687#23610#23544'='
      #24103#25968'='
      #35299#30721#26041#24335'='
      #25991#20214#23646#24615'='
      )
  end
end
