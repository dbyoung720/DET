object frmVideoSearch: TfrmVideoSearch
  Left = 0
  Top = 0
  Caption = #35270#39057#25628#32034#22120' v2.0'
  ClientHeight = 680
  ClientWidth = 1180
  Color = 2105636
  Font.Charset = DEFAULT_CHARSET
  Font.Color = 15264493
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  Position = poScreenCenter
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  OnResize = FormResize
  TextHeight = 15
  object pnlTop: TPanel
    Left = 0
    Top = 0
    Width = 1180
    Height = 56
    Align = alTop
    Color = 2697773
    ParentBackground = False
    TabOrder = 0
    object lblStatus: TLabel
      Left = 970
      Top = 20
      Width = 200
      Height = 17
      AutoSize = False
      Caption = #35831#36755#20837#29255#21517#21518#28857#20987#25628#32034
      EllipsisPosition = epEndEllipsis
      Font.Charset = DEFAULT_CHARSET
      Font.Color = 15264493
      Font.Height = -12
      Font.Name = 'Segoe UI'
      Font.Style = []
      ParentFont = False
      Transparent = True
    end
    object lblUser: TLabel
      Left = 698
      Top = 20
      Width = 26
      Height = 15
      Caption = #29992#25143
      Font.Charset = DEFAULT_CHARSET
      Font.Color = 15264493
      Font.Height = -12
      Font.Name = 'Segoe UI'
      Font.Style = []
      ParentFont = False
      Transparent = True
    end
    object lblPass: TLabel
      Left = 834
      Top = 20
      Width = 26
      Height = 15
      Caption = #23494#30721
      Font.Charset = DEFAULT_CHARSET
      Font.Color = 15264493
      Font.Height = -12
      Font.Name = 'Segoe UI'
      Font.Style = []
      ParentFont = False
      Transparent = True
    end
    object cbbSite: TComboBox
      Left = 12
      Top = 16
      Width = 150
      Height = 23
      Style = csDropDownList
      Color = 3553599
      DropDownCount = 40
      Font.Charset = DEFAULT_CHARSET
      Font.Color = 15264493
      Font.Height = -12
      Font.Name = 'Segoe UI'
      Font.Style = []
      ParentFont = False
      TabOrder = 5
      StyleElements = []
      OnChange = cbbSiteChange
    end
    object edtKeyword: TEdit
      Left = 168
      Top = 14
      Width = 200
      Height = 23
      Color = 3553599
      Font.Charset = DEFAULT_CHARSET
      Font.Color = 15264493
      Font.Height = -12
      Font.Name = 'Segoe UI'
      Font.Style = []
      ParentFont = False
      TabOrder = 0
      StyleElements = []
      OnKeyPress = edtKeywordKeyPress
    end
    object btnSearch: TButton
      Left = 376
      Top = 13
      Width = 76
      Height = 30
      Caption = #25628#32034
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clBlack
      Font.Height = -12
      Font.Name = 'Segoe UI'
      Font.Style = [fsBold]
      ParentFont = False
      TabOrder = 1
      StyleElements = []
      OnClick = btnSearchClick
    end
    object cbbVideos: TComboBox
      Left = 460
      Top = 14
      Width = 230
      Height = 23
      Style = csDropDownList
      Color = 3553599
      DropDownCount = 40
      Font.Charset = DEFAULT_CHARSET
      Font.Color = 15264493
      Font.Height = -12
      Font.Name = 'Segoe UI'
      Font.Style = []
      ParentFont = False
      TabOrder = 2
      StyleElements = []
      OnChange = cbbVideosChange
    end
    object edtUsername: TEdit
      Left = 736
      Top = 14
      Width = 90
      Height = 23
      Color = 3553599
      Font.Charset = DEFAULT_CHARSET
      Font.Color = 15264493
      Font.Height = -12
      Font.Name = 'Segoe UI'
      Font.Style = []
      ParentFont = False
      TabOrder = 3
      StyleElements = []
    end
    object edtPassword: TEdit
      Left = 872
      Top = 14
      Width = 90
      Height = 23
      Color = 3553599
      Font.Charset = DEFAULT_CHARSET
      Font.Color = 15264493
      Font.Height = -12
      Font.Name = 'Segoe UI'
      Font.Style = []
      ParentFont = False
      PasswordChar = '*'
      TabOrder = 4
      StyleElements = []
    end
  end
  object pnlHint: TPanel
    Left = 0
    Top = 650
    Width = 1180
    Height = 30
    Align = alBottom
    Color = 2697773
    ParentBackground = False
    TabOrder = 1
    DesignSize = (
      1180
      30)
    object lblHint: TLabel
      Left = 88
      Top = 7
      Width = 222
      Height = 15
      Caption = #21452#20987#21015#34920#20013#30340#20219#24847#19968#38598#21363#21487#29992' VLC '#25773#25918
      Font.Charset = DEFAULT_CHARSET
      Font.Color = 15264493
      Font.Height = -12
      Font.Name = 'Segoe UI'
      Font.Style = []
      ParentFont = False
      Transparent = True
    end
    object imgProxy: TImage
      Left = 44
      Top = 5
      Width = 20
      Height = 20
      Transparent = True
    end
    object lblProxyText: TLabel
      Left = 12
      Top = 7
      Width = 26
      Height = 15
      Caption = #20195#29702
      Font.Charset = DEFAULT_CHARSET
      Font.Color = 15264493
      Font.Height = -12
      Font.Name = 'Segoe UI'
      Font.Style = []
      ParentFont = False
      Transparent = True
    end
    object btnDownload: TSpeedButton
      Left = 1112
      Top = 3
      Width = 56
      Height = 25
      Anchors = [akTop, akRight]
      Caption = #19979#36733
      Flat = True
      Font.Charset = DEFAULT_CHARSET
      Font.Color = 15264493
      Font.Height = -12
      Font.Name = 'Segoe UI'
      Font.Style = [fsBold]
      ParentFont = False
      OnClick = btnDownloadClick
    end
  end
  object lvEpisodes: TListView
    Left = 0
    Top = 56
    Width = 1180
    Height = 594
    Align = alClient
    Color = 2697773
    Columns = <
      item
        Caption = #38598#25968
        Width = 150
      end
      item
        Caption = #32447#36335
        Width = 150
      end
      item
        Caption = #20998#38598' ID'
        Width = 150
      end
      item
        Caption = #22320#22336
        Width = 730
      end>
    Font.Charset = DEFAULT_CHARSET
    Font.Color = 15264493
    Font.Height = -16
    Font.Name = 'Segoe UI'
    Font.Style = []
    GridLines = True
    HideSelection = False
    StyleElements = []
    ReadOnly = True
    RowSelect = True
    ParentFont = False
    TabOrder = 2
    ViewStyle = vsReport
    OnDblClick = lvEpisodesDblClick
  end
  object tmrProxy: TTimer
    Enabled = False
    Interval = 600
    OnTimer = tmrProxyTimer
    Left = 292
    Top = 8
  end
  object tmrDownload: TTimer
    Enabled = False
    Interval = 800
    OnTimer = tmrDownloadTimer
    Left = 348
    Top = 8
  end
end
