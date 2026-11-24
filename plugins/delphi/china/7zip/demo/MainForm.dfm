object FormMain: TFormMain
  Left = 0
  Top = 0
  Caption = '7-Zip C '#26680#24515#38745#24577#38142#25509#28436#31034' (x86/x64)'
  ClientHeight = 560
  ClientWidth = 900
  Color = 2367776
  Font.Charset = DEFAULT_CHARSET
  Font.Color = 15592168
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  Position = poScreenCenter
  StyleElements = []
  TextHeight = 15
  object PanelTop: TPanel
    Left = 0
    Top = 0
    Width = 900
    Height = 60
    Align = alTop
    BevelOuter = bvNone
    Color = 3025706
    ParentBackground = False
    TabOrder = 0
    StyleElements = []
    object lblTitle: TLabel
      Left = 16
      Top = 20
      Width = 305
      Height = 17
      Caption = '7-Zip C '#26680#24515#38745#24577#38142#25509#65288#32431#38745#24577' OBJ'#65292#26080' DLL'#65289
      Font.Charset = DEFAULT_CHARSET
      Font.Color = 15592168
      Font.Height = -13
      Font.Name = 'Segoe UI'
      Font.Style = []
      ParentFont = False
    end
    object btnOpen: TButton
      Left = 314
      Top = 14
      Width = 96
      Height = 32
      Caption = #25171#24320' 7z'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = 2367776
      Font.Height = -12
      Font.Name = 'Segoe UI'
      Font.Style = []
      ParentFont = False
      TabOrder = 0
      StyleElements = []
      OnClick = btnOpenClick
    end
    object btnExtract: TButton
      Left = 417
      Top = 14
      Width = 96
      Height = 32
      Caption = #35299#21387#20840#37096
      Font.Charset = DEFAULT_CHARSET
      Font.Color = 2367776
      Font.Height = -12
      Font.Name = 'Segoe UI'
      Font.Style = []
      ParentFont = False
      TabOrder = 1
      StyleElements = []
      OnClick = btnExtractClick
    end
    object btnSelfTest: TButton
      Left = 520
      Top = 14
      Width = 110
      Height = 32
      Caption = 'LZMA '#33258#27979#35797
      Font.Charset = DEFAULT_CHARSET
      Font.Color = 2367776
      Font.Height = -12
      Font.Name = 'Segoe UI'
      Font.Style = []
      ParentFont = False
      TabOrder = 2
      StyleElements = []
      OnClick = btnSelfTestClick
    end
    object ProgressBar1: TProgressBar
      Left = 638
      Top = 20
      Width = 240
      Height = 20
      Smooth = True
      TabOrder = 3
      StyleElements = []
    end
  end
  object lvFiles: TListView
    Left = 0
    Top = 60
    Width = 900
    Height = 340
    Align = alClient
    Color = 2367776
    Columns = <
      item
        Caption = #21517#31216
        Width = 560
      end
      item
        Caption = #22823#23567
        Width = 150
      end
      item
        Caption = #31867#22411
        Width = 100
      end>
    HideSelection = False
    StyleElements = []
    ReadOnly = True
    RowSelect = True
    TabOrder = 1
    ViewStyle = vsReport
  end
  object MemoLog: TMemo
    Left = 0
    Top = 400
    Width = 900
    Height = 160
    Align = alBottom
    Color = 2367776
    Font.Charset = DEFAULT_CHARSET
    Font.Color = 15592168
    Font.Height = -12
    Font.Name = 'Consolas'
    Font.Style = []
    ParentFont = False
    ReadOnly = True
    ScrollBars = ssVertical
    TabOrder = 2
    StyleElements = []
  end
  object OpenDialog1: TOpenDialog
    Left = 24
    Top = 96
  end
end
