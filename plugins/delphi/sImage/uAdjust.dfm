object frmAdjust: TfrmAdjust
  Left = 0
  Top = 0
  BorderStyle = bsDialog
  Caption = #21442#25968#35843#33410#65306
  ClientHeight = 58
  ClientWidth = 441
  Color = 3947580
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  OnClose = FormClose
  TextHeight = 15
  object lblType: TLabel
    Left = 8
    Top = 18
    Width = 48
    Height = 16
    Caption = #20142#24230#65306
    Font.Charset = GB2312_CHARSET
    Font.Color = clWhite
    Font.Height = -16
    Font.Name = #23435#20307
    Font.Style = []
    ParentFont = False
  end
  object lblAdjustValue: TLabel
    Left = 404
    Top = 15
    Width = 8
    Height = 16
    Caption = '0'
    Font.Charset = GB2312_CHARSET
    Font.Color = clYellow
    Font.Height = -16
    Font.Name = #23435#20307
    Font.Style = []
    ParentFont = False
  end
  object trckbrAdjust: TTrackBar
    Tag = 100
    Left = 62
    Top = 14
    Width = 331
    Height = 24
    Max = 255
    Min = -255
    ShowSelRange = False
    TabOrder = 0
    OnChange = trckbrAdjustChange
  end
end
