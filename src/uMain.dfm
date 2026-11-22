object frmMain: TfrmMain
  Left = 0
  Top = 0
  Caption = 'DET v4.0'
  ClientHeight = 689
  ClientWidth = 1103
  Color = 2105375
  CustomTitleBar.Control = tlbrpnl1
  CustomTitleBar.Enabled = True
  CustomTitleBar.Height = 40
  CustomTitleBar.SystemHeight = False
  CustomTitleBar.ShowCaption = False
  CustomTitleBar.ShowIcon = False
  CustomTitleBar.SystemColors = False
  CustomTitleBar.SystemButtons = False
  CustomTitleBar.BackgroundColor = 2105375
  CustomTitleBar.ForegroundColor = clWhite
  CustomTitleBar.InactiveBackgroundColor = 2105375
  CustomTitleBar.InactiveForegroundColor = clWhite
  CustomTitleBar.ButtonForegroundColor = clWhite
  CustomTitleBar.ButtonBackgroundColor = 2105375
  CustomTitleBar.ButtonHoverForegroundColor = clWhite
  CustomTitleBar.ButtonHoverBackgroundColor = 3947580
  CustomTitleBar.ButtonPressedForegroundColor = clWhite
  CustomTitleBar.ButtonPressedBackgroundColor = clBlack
  CustomTitleBar.ButtonInactiveForegroundColor = clWhite
  CustomTitleBar.ButtonInactiveBackgroundColor = 2105375
  DoubleBuffered = True
  Font.Charset = GB2312_CHARSET
  Font.Color = clWhite
  Font.Height = -19
  Font.Name = #23435#20307
  Font.Style = []
  GlassFrame.Enabled = True
  GlassFrame.Top = 40
  Position = poScreenCenter
  WindowState = wsMinimized
  StyleElements = [seFont, seClient]
  OnClose = FormClose
  OnCreate = FormCreate
  OnResize = FormResize
  TextHeight = 19
  object tlbrpnl1: TTitleBarPanel
    Left = 0
    Top = 0
    Width = 1103
    Height = 39
    CustomButtons = <
      item
        ButtonType = sbCustom
        Hint = #21442#25968#35774#32622
        Width = 46
        ShowHint = True
        OnPaint = tlbrpnl1CustomButtons0Paint
        OnClick = tlbrpnl1CustomButtons0Click
      end
      item
        ButtonType = sbCustom
        Hint = #26368#23567#21270#21040#25176#30424#21306
        Width = 46
        ShowHint = True
        OnPaint = tlbrpnl1CustomButtons1Paint
        OnClick = tlbrpnl1CustomButtons1Click
      end>
    DesignSize = (
      1103
      39)
    object btnExpand: TSpeedButton
      Left = 0
      Top = 0
      Width = 49
      Height = 39
      Hint = #23558#27169#22359#21015#34920#25240#21472
      Align = alLeft
      Flat = True
      Glyph.Data = {
        36100000424D3610000000000000360000002800000020000000200000000100
        2000000000000010000000000000000000000000000000000000000000000000
        0000000000000000000000000000000000000000000000000000000000000000
        0000000000000000000000000000000000000000000000000000000000000000
        0000000000000000000000000000000000000000000000000000000000000000
        0000000000000000000000000000000000000000000000000000000000000000
        0000000000000000000000000000000000000000000000000000000000000000
        0000000000000000000000000000000000000000000000000000000000000000
        0000000000000000000000000000000000000000000000000000000000000000
        0000000000000000000000000000000000000000000000000000000000000000
        0000000000000000000000000000000000000000000000000000000000000000
        0000000000000000000000000000000000000000000000000000000000000000
        0000000000000000000000000000000000000000000000000000000000000000
        0000000000000000000000000000000000000000000000000000000000000000
        0000000000000000000000000000000000000000000000000000000000000000
        0000000000000000000000000000000000000000000000000000000000000000
        0000000000000000000000000000000000000000000000000000000000000000
        0000000000000000000000000000000000000000000000000000000000000000
        0000000000000000000000000000000000000000000000000000000000000000
        0000000000000000000000000000000000000000000000000000000000000000
        0000000000000000000000000000000000000000000000000000000000000000
        0000000000000000000000000000000000000000000000000000000000000000
        0000000000000000000000000000000000000000000000000000000000000000
        0000000000000000000000000000000000000000000000000000000000000000
        0000000000000000000000000000000000000000000000000000000000000000
        0000000000000000000000000000000000000000000000000000727272FF7272
        72FF727272FF727272FF727272FF727272FF727272FF727272FF727272FF7272
        72FF727272FF727272FF727272FF727272FF727272FF727272FF727272FF7272
        72FF727272FF727272FF727272FF727272FF727272FF727272FF727272FF7272
        72FF727272FF727272FF727272FF727272FF727272FF727272FF727272FF7272
        72FF727272FF727272FF727272FF727272FF727272FF727272FF727272FF7272
        72FF727272FF727272FF727272FF727272FF727272FF727272FF727272FF7272
        72FF727272FF727272FF727272FF727272FF727272FF727272FF727272FF7272
        72FF727272FF727272FF727272FF727272FF727272FF727272FF000000000000
        0000000000000000000000000000000000000000000000000000000000000000
        0000000000000000000000000000000000000000000000000000000000000000
        0000000000000000000000000000000000000000000000000000000000000000
        0000000000000000000000000000000000000000000000000000000000000000
        0000000000000000000000000000000000000000000000000000000000000000
        0000000000000000000000000000000000000000000000000000000000000000
        0000000000000000000000000000000000000000000000000000000000000000
        0000000000000000000000000000000000000000000000000000000000000000
        0000000000000000000000000000000000000000000000000000000000000000
        0000000000000000000000000000000000000000000000000000000000000000
        0000000000000000000000000000000000000000000000000000000000000000
        0000000000000000000000000000000000000000000000000000000000000000
        0000000000000000000000000000000000000000000000000000000000000000
        0000000000000000000000000000000000000000000000000000000000000000
        0000000000000000000000000000000000000000000000000000000000000000
        0000000000000000000000000000000000000000000000000000000000000000
        0000000000000000000000000000000000000000000000000000000000000000
        0000000000000000000000000000000000000000000000000000000000000000
        0000000000000000000000000000000000000000000000000000000000000000
        0000000000000000000000000000000000000000000000000000000000000000
        0000000000000000000000000000000000000000000000000000000000000000
        0000000000000000000000000000000000000000000000000000000000000000
        0000000000000000000000000000000000000000000000000000000000000000
        0000000000000000000000000000000000000000000000000000727272FF7272
        72FF727272FF727272FF727272FF727272FF727272FF727272FF727272FF7272
        72FF727272FF727272FF727272FF727272FF727272FF727272FF727272FF7272
        72FF727272FF727272FF727272FF727272FF727272FF727272FF727272FF7272
        72FF727272FF727272FF727272FF727272FF727272FF727272FF727272FF7272
        72FF727272FF727272FF727272FF727272FF727272FF727272FF727272FF7272
        72FF727272FF727272FF727272FF727272FF727272FF727272FF727272FF7272
        72FF727272FF727272FF727272FF727272FF727272FF727272FF727272FF7272
        72FF727272FF727272FF727272FF727272FF727272FF727272FF000000000000
        0000000000000000000000000000000000000000000000000000000000000000
        0000000000000000000000000000000000000000000000000000000000000000
        0000000000000000000000000000000000000000000000000000000000000000
        0000000000000000000000000000000000000000000000000000000000000000
        0000000000000000000000000000000000000000000000000000000000000000
        0000000000000000000000000000000000000000000000000000000000000000
        0000000000000000000000000000000000000000000000000000000000000000
        0000000000000000000000000000000000000000000000000000000000000000
        0000000000000000000000000000000000000000000000000000000000000000
        0000000000000000000000000000000000000000000000000000000000000000
        0000000000000000000000000000000000000000000000000000000000000000
        0000000000000000000000000000000000000000000000000000000000000000
        0000000000000000000000000000000000000000000000000000000000000000
        0000000000000000000000000000000000000000000000000000000000000000
        0000000000000000000000000000000000000000000000000000000000000000
        0000000000000000000000000000000000000000000000000000000000000000
        0000000000000000000000000000000000000000000000000000000000000000
        0000000000000000000000000000000000000000000000000000000000000000
        0000000000000000000000000000000000000000000000000000000000000000
        0000000000000000000000000000000000000000000000000000000000000000
        0000000000000000000000000000000000000000000000000000000000000000
        0000000000000000000000000000000000000000000000000000000000000000
        0000000000000000000000000000000000000000000000000000000000000000
        0000000000000000000000000000000000000000000000000000727272FF7272
        72FF727272FF727272FF727272FF727272FF727272FF727272FF727272FF7272
        72FF727272FF727272FF727272FF727272FF727272FF727272FF727272FF7272
        72FF727272FF727272FF727272FF727272FF727272FF727272FF727272FF7272
        72FF727272FF727272FF727272FF727272FF727272FF727272FF727272FF7272
        72FF727272FF727272FF727272FF727272FF727272FF727272FF727272FF7272
        72FF727272FF727272FF727272FF727272FF727272FF727272FF727272FF7272
        72FF727272FF727272FF727272FF727272FF727272FF727272FF727272FF7272
        72FF727272FF727272FF727272FF727272FF727272FF727272FF000000000000
        0000000000000000000000000000000000000000000000000000000000000000
        0000000000000000000000000000000000000000000000000000000000000000
        0000000000000000000000000000000000000000000000000000000000000000
        0000000000000000000000000000000000000000000000000000000000000000
        0000000000000000000000000000000000000000000000000000000000000000
        0000000000000000000000000000000000000000000000000000000000000000
        0000000000000000000000000000000000000000000000000000000000000000
        0000000000000000000000000000000000000000000000000000000000000000
        0000000000000000000000000000000000000000000000000000000000000000
        0000000000000000000000000000000000000000000000000000000000000000
        0000000000000000000000000000000000000000000000000000000000000000
        0000000000000000000000000000000000000000000000000000000000000000
        0000000000000000000000000000000000000000000000000000000000000000
        0000000000000000000000000000000000000000000000000000000000000000
        0000000000000000000000000000000000000000000000000000000000000000
        0000000000000000000000000000000000000000000000000000000000000000
        0000000000000000000000000000000000000000000000000000000000000000
        0000000000000000000000000000000000000000000000000000000000000000
        0000000000000000000000000000000000000000000000000000000000000000
        0000000000000000000000000000000000000000000000000000000000000000
        0000000000000000000000000000000000000000000000000000000000000000
        0000000000000000000000000000000000000000000000000000000000000000
        0000000000000000000000000000000000000000000000000000000000000000
        0000000000000000000000000000000000000000000000000000000000000000
        0000000000000000000000000000000000000000000000000000000000000000
        0000000000000000000000000000000000000000000000000000000000000000
        0000000000000000000000000000000000000000000000000000000000000000
        0000000000000000000000000000000000000000000000000000000000000000
        0000000000000000000000000000000000000000000000000000000000000000
        0000000000000000000000000000000000000000000000000000000000000000
        0000000000000000000000000000000000000000000000000000000000000000
        0000000000000000000000000000000000000000000000000000}
      ParentShowHint = False
      ShowHint = True
      OnClick = btnExpandClick
      OnMouseDown = btnExpandMouseDown
      ExplicitTop = -4
      ExplicitHeight = 30
    end
    object pgModule: TTabView
      AlignWithMargins = True
      Left = 49
      Top = 0
      Width = 824
      Height = 39
      Margins.Left = 0
      Margins.Top = 0
      Margins.Right = 230
      Margins.Bottom = 0
      Align = alClient
      BackgroundHitTestTransparent = True
      Font.Charset = GB2312_CHARSET
      Font.Color = clWhite
      Font.Height = -19
      Font.Name = #23435#20307
      Font.Style = []
      Images = vrtlmglstModule
      ParentColor = False
      ParentDoubleBuffered = False
      ParentFont = False
      Tabs = <>
      TabOptions.Draggable = True
      TabOptions.ShowCloseButton = True
      TabOptions.WordWrap = False
      TabOrder = 0
      ShowBottomLine = False
      OnChangeTab = pgModuleChange
      OnCloseTab = pgModuleCloseTab
    end
  end
  object pnlModule: TPanel
    Left = 0
    Top = 39
    Width = 400
    Height = 650
    Align = alLeft
    BevelOuter = bvNone
    Caption = 'pnlModule'
    Color = 2105375
    ParentBackground = False
    ShowCaption = False
    TabOrder = 1
    object tvModule: TTreeView
      Left = 0
      Top = 0
      Width = 400
      Height = 650
      Align = alClient
      AutoExpand = True
      BevelInner = bvNone
      BevelOuter = bvNone
      BorderStyle = bsNone
      Color = 2105375
      Font.Charset = GB2312_CHARSET
      Font.Color = clWhite
      Font.Height = -27
      Font.Name = #24494#36719#38597#40657
      Font.Style = []
      Images = vrtlmglstTreeView
      Indent = 35
      ParentFont = False
      ReadOnly = True
      RowSelect = True
      TabOrder = 0
      OnDblClick = tvModuleDblClick
      Items.NodeData = {
        070100000009540054007200650065004E006F00640065002700000000000000
        00000000FFFFFFFFFFFFFFFF000000000000000000010000000104FB7CDF7EA1
        7B067400002B0000000000000000000000FFFFFFFFFFFFFFFF00000000000000
        0000000000000106FB7CDF7EE14F6F60004EC889}
    end
  end
  object pnlPages: TPanel
    Left = 400
    Top = 39
    Width = 703
    Height = 650
    Align = alClient
    BevelOuter = bvNone
    Caption = 'pnlPages'
    Color = 3158064
    ParentBackground = False
    ShowCaption = False
    TabOrder = 2
    object pnlConfig: TPanel
      Left = 0
      Top = 0
      Width = 703
      Height = 650
      Align = alClient
      BevelOuter = bvNone
      Caption = 'pnlConfig'
      Color = 2829099
      ParentBackground = False
      ShowCaption = False
      TabOrder = 0
      Visible = False
      object rzpgcntrlConfig: TRzPageControl
        Left = 0
        Top = 0
        Width = 703
        Height = 650
        Hint = ''
        ActivePage = rztbshtSystem
        Align = alClient
        BackgroundColor = 2829099
        Color = 2829099
        Font.Charset = GB2312_CHARSET
        Font.Color = clWhite
        Font.Height = -24
        Font.Name = #24494#36719#38597#40657
        Font.Style = []
        ParentBackgroundColor = False
        ParentColor = False
        ParentFont = False
        ParentShowHint = False
        ShowCardFrame = False
        ShowFocusRect = False
        ShowFullFrame = False
        ShowHint = False
        ShowShadow = False
        SoftCorners = True
        TabColors.HighlightBar = clBlack
        TabColors.Shadow = 2829099
        TabColors.Unselected = 2829099
        TabHeight = 40
        TabIndex = 3
        TabOrder = 0
        TabSequence = tsReverse
        TabStyle = tsDoubleSlant
        TabWidth = 200
        TextColors.Selected = clWhite
        TextColors.Unselected = clWhite
        UseGradients = False
        OnPageChange = rzpgcntrlConfigPageChange
        FixedDimension = 40
        object rztbshtEXEPath: TRzTabSheet
          Color = 2829099
          Caption = #36335#24452#37197#32622
          DesignSize = (
            703
            610)
          object lblVlcPath: TLabel
            Left = 32
            Top = 32
            Width = 172
            Height = 31
            Caption = 'VLC        '#36335#24452#65306
          end
          object imgVLCOK: TImage
            Left = 1011
            Top = 37
            Width = 32
            Height = 32
            Anchors = [akTop, akRight]
            AutoSize = True
            Picture.Data = {
              0954506E67496D61676589504E470D0A1A0A0000000D49484452000000200000
              00200806000000737A7AF4000000017352474200AECE1CE90000000467414D41
              0000B18F0BFC6105000000097048597300000EC300000EC301C76FA864000000
              CA4944415478DAEDD4D10D832010C6716E0E1DC2ED6A27D06ED721740E5A4C4C
              0A0207DC77F541EF054C0CFFDFD3913979E8065C02F0EEBAD19DC3BACE7F07B8
              38114DEE6EAD7D860855C06F7C9F10A10688C5630815402EBE018C790DCB32AA
              006AE270406D1C0A6889C300AD710840121703A4711100114F0272BB1B198F02
              B8DD8D8C1F00DCEE46C73D00B7BBB79FC1711FD0F7F3F7E351FB8024EE015A11
              92F801508B90C6A3805204229E047008543C0B48219071161022D0F122C08E70
              273A5E0CD09C1B703AE0036A25AA21422182A40000000049454E44AE426082}
            Visible = False
            ExplicitLeft = 1063
          end
          object lblChromePath: TLabel
            Left = 32
            Top = 104
            Width = 170
            Height = 31
            Caption = 'Chrome '#36335#24452#65306
          end
          object imgChromeOK: TImage
            Left = 1011
            Top = 109
            Width = 32
            Height = 32
            Anchors = [akTop, akRight]
            AutoSize = True
            Picture.Data = {
              0954506E67496D61676589504E470D0A1A0A0000000D49484452000000200000
              00200806000000737A7AF4000000017352474200AECE1CE90000000467414D41
              0000B18F0BFC6105000000097048597300000EC300000EC301C76FA864000000
              CA4944415478DAEDD4D10D832010C6716E0E1DC2ED6A27D06ED721740E5A4C4C
              0A0207DC77F541EF054C0CFFDFD3913979E8065C02F0EEBAD19DC3BACE7F07B8
              38114DEE6EAD7D860855C06F7C9F10A10688C5630815402EBE018C790DCB32AA
              006AE270406D1C0A6889C300AD710840121703A4711100114F0272BB1B198F02
              B8DD8D8C1F00DCEE46C73D00B7BBB79FC1711FD0F7F3F7E351FB8024EE015A11
              92F801508B90C6A3805204229E047008543C0B48219071161022D0F122C08E70
              273A5E0CD09C1B703AE0036A25AA21422182A40000000049454E44AE426082}
            Visible = False
            ExplicitLeft = 1063
          end
          object lblChromePath1: TLabel
            Left = 32
            Top = 176
            Width = 168
            Height = 31
            Caption = 'scoop    '#36335#24452#65306
          end
          object lblJavaPath: TLabel
            Left = 32
            Top = 251
            Width = 149
            Height = 31
            Caption = 'Java    '#36335#24452#65306
          end
          object btnVlcPath: TRzButtonEdit
            Tag = 102
            Left = 248
            Top = 29
            Width = 440
            Height = 39
            Text = ''
            Anchors = [akLeft, akTop, akRight]
            Font.Charset = GB2312_CHARSET
            Font.Color = clBlack
            Font.Height = -24
            Font.Name = #24494#36719#38597#40657
            Font.Style = []
            ParentFont = False
            TabOrder = 1
            TextHint = 'vlc.exe '#36335#24452
            AltBtnNumGlyphs = 1
            ButtonNumGlyphs = 1
            AltBtnKind = bkFolder
            ButtonKind = bkFolder
            ButtonWidth = 32
            FlatButtons = True
          end
          object btnChromePath: TRzButtonEdit
            Tag = 103
            Left = 248
            Top = 101
            Width = 440
            Height = 39
            Text = ''
            Anchors = [akLeft, akTop, akRight]
            Font.Charset = GB2312_CHARSET
            Font.Color = clBlack
            Font.Height = -24
            Font.Name = #24494#36719#38597#40657
            Font.Style = []
            ParentFont = False
            TabOrder = 2
            TextHint = 'chrome.exe '#36335#24452
            AltBtnNumGlyphs = 1
            ButtonNumGlyphs = 1
            AltBtnKind = bkFolder
            ButtonKind = bkFolder
            ButtonWidth = 32
            FlatButtons = True
          end
          object btnChromePath1: TRzButtonEdit
            Tag = 103
            Left = 248
            Top = 173
            Width = 440
            Height = 39
            Text = ''
            Anchors = [akLeft, akTop, akRight]
            Font.Charset = GB2312_CHARSET
            Font.Color = clBlack
            Font.Height = -24
            Font.Name = #24494#36719#38597#40657
            Font.Style = []
            ParentFont = False
            ReadOnlyColor = clSilver
            TabOrder = 3
            TextHint = #33258#21160#26816#27979' scoop '#23433#35013#20301#32622
            AltBtnNumGlyphs = 1
            ButtonNumGlyphs = 1
            AltBtnKind = bkFolder
            ButtonKind = bkFolder
            ButtonWidth = 32
            FlatButtons = True
          end
          object btnJavaPath: TRzButtonEdit
            Tag = 103
            Left = 248
            Top = 248
            Width = 440
            Height = 39
            Text = ''
            Anchors = [akLeft, akTop, akRight]
            Font.Charset = GB2312_CHARSET
            Font.Color = clBlack
            Font.Height = -24
            Font.Name = #24494#36719#38597#40657
            Font.Style = []
            ParentFont = False
            ReadOnlyColor = clSilver
            TabOrder = 4
            TextHint = #33258#21160#26816#27979' Java '#23433#35013#20301#32622
            AltBtnNumGlyphs = 1
            ButtonNumGlyphs = 1
            AltBtnKind = bkFolder
            ButtonKind = bkFolder
            ButtonWidth = 32
            FlatButtons = True
          end
          object edtTemp: TEdit
            Left = 184
            Top = -1000
            Width = 121
            Height = 39
            TabOrder = 0
            Text = 'edtTemp'
            Visible = False
          end
        end
        object rztbshtDatabase: TRzTabSheet
          Color = 2829099
          Caption = #25968#25454#24211#37197#32622
          object rzpgcntrlDataBaseConfig: TRzPageControl
            Left = 0
            Top = 0
            Width = 703
            Height = 610
            Hint = ''
            ActivePage = rztbshtDataBaseLink
            Align = alClient
            BackgroundColor = 2829099
            Font.Charset = GB2312_CHARSET
            Font.Color = clWhite
            Font.Height = -19
            Font.Name = #24494#36719#38597#40657
            Font.Style = []
            HotTrackColor = 7817728
            HotTrackColorSource = htcsHotTrackColorProp
            ParentBackgroundColor = False
            ParentFont = False
            ShowFocusRect = False
            ShowFullFrame = False
            ShowShadow = False
            SoftCorners = True
            TabColors.HighlightBar = clBlack
            TabColors.Shadow = 2829099
            TabColors.Unselected = 2829099
            TabHeight = 42
            TabIndex = 0
            TabOrder = 0
            TabStyle = tsDoubleSlant
            TabWidth = 200
            TextColors.Selected = clWhite
            TextColors.Unselected = clWhite
            UseGradients = False
            FixedDimension = 42
            object rztbshtDataBaseLink: TRzTabSheet
              Color = 2829099
              Caption = #25968#25454#24211#36830#25509
              DesignSize = (
                703
                567)
              object grpLogin: TGroupBox
                Left = 24
                Top = 80
                Width = 713
                Height = 480
                Anchors = [akLeft, akTop, akBottom]
                Caption = #30331#24405#39564#35777#65306
                TabOrder = 0
                DesignSize = (
                  713
                  480)
                object lblLoginTable: TLabel
                  Left = 23
                  Top = 49
                  Width = 76
                  Height = 25
                  Caption = #30331#24405#34920#65306
                end
                object lblLoginNameField: TLabel
                  Left = 23
                  Top = 116
                  Width = 133
                  Height = 25
                  Caption = #30331#24405#21517#31216#23383#27573#65306
                end
                object lblLoginPassField: TLabel
                  Left = 23
                  Top = 184
                  Width = 133
                  Height = 25
                  Caption = #30331#24405#23494#30721#23383#27573#65306
                end
                object btnLoginCheckSave: TSpeedButton
                  Left = 572
                  Top = 368
                  Width = 125
                  Height = 50
                  Caption = #20445#23384
                  ImageIndex = 2
                  ImageName = 'save'
                  Enabled = False
                  Flat = True
                  OnClick = btnLoginCheckSaveClick
                end
                object lblLoginDLL: TLabel
                  Left = 23
                  Top = 240
                  Width = 129
                  Height = 25
                  Caption = #23494#30721#26657#39564'DLL'#65306
                end
                object lblLoginDLLFunc: TLabel
                  Left = 23
                  Top = 304
                  Width = 133
                  Height = 25
                  Caption = #23494#30721#26657#39564#20989#25968#65306
                end
                object cbbLoginTable: TComboBox
                  Left = 197
                  Top = 43
                  Width = 500
                  Height = 36
                  Style = csDropDownList
                  Anchors = [akLeft, akTop, akRight]
                  DropDownCount = 25
                  Font.Charset = GB2312_CHARSET
                  Font.Color = clBlack
                  Font.Height = -21
                  Font.Name = #24494#36719#38597#40657
                  Font.Style = []
                  ParentFont = False
                  TabOrder = 0
                  OnChange = cbbLoginTableChange
                end
                object cbbLoginNameField: TComboBox
                  Left = 197
                  Top = 113
                  Width = 500
                  Height = 36
                  Style = csDropDownList
                  Anchors = [akLeft, akTop, akRight]
                  DropDownCount = 20
                  Font.Charset = GB2312_CHARSET
                  Font.Color = clBlack
                  Font.Height = -21
                  Font.Name = #24494#36719#38597#40657
                  Font.Style = []
                  ParentFont = False
                  TabOrder = 1
                end
                object cbbLoginPassField: TComboBox
                  Left = 197
                  Top = 181
                  Width = 500
                  Height = 36
                  Style = csDropDownList
                  Anchors = [akLeft, akTop, akRight]
                  DropDownCount = 20
                  Font.Charset = GB2312_CHARSET
                  Font.Color = clBlack
                  Font.Height = -21
                  Font.Name = #24494#36719#38597#40657
                  Font.Style = []
                  ParentFont = False
                  TabOrder = 2
                end
                object btnLoginDLL: TRzButtonEdit
                  Tag = 100
                  Left = 197
                  Top = 241
                  Width = 500
                  Height = 36
                  Text = ''
                  Anchors = [akLeft, akTop, akRight]
                  Font.Charset = GB2312_CHARSET
                  Font.Color = clBlack
                  Font.Height = -21
                  Font.Name = #24494#36719#38597#40657
                  Font.Style = []
                  FrameVisible = True
                  ParentFont = False
                  TabOrder = 3
                  TextHint = #36827#34892#23494#30721#26657#39564#30340' DLL '#36335#24452
                  AltBtnNumGlyphs = 1
                  ButtonNumGlyphs = 1
                  AltBtnKind = bkFolder
                  ButtonKind = bkFolder
                  ButtonWidth = 32
                  FlatButtons = True
                  OnButtonClick = btnLoginDLLButtonClick
                end
                object cbbLoginDLLFunc: TComboBox
                  Left = 197
                  Top = 304
                  Width = 500
                  Height = 36
                  Style = csDropDownList
                  Anchors = [akLeft, akTop, akRight]
                  DropDownCount = 20
                  Font.Charset = GB2312_CHARSET
                  Font.Color = clBlack
                  Font.Height = -21
                  Font.Name = #24494#36719#38597#40657
                  Font.Style = []
                  ParentFont = False
                  ParentShowHint = False
                  ShowHint = False
                  TabOrder = 4
                  TextHint = 'function xxx(const Name, Pass:PChar):Boolean'
                end
              end
              object btnDBConnect: TButton
                Left = 24
                Top = 16
                Width = 200
                Height = 49
                Caption = #36830#25509
                ImageIndex = 3
                ImageName = 'db'
                Images = vrtlmglstButton
                TabOrder = 1
                OnClick = btnDBConnectClick
              end
              object btnDBDisconnect: TButton
                Left = 280
                Top = 16
                Width = 200
                Height = 49
                Caption = #26029#24320
                Enabled = False
                ImageIndex = 4
                ImageName = 'disconn.pnd'
                Images = vrtlmglstButton
                TabOrder = 2
                OnClick = btnDBDisconnectClick
              end
              object btnDelConnect: TButton
                Left = 537
                Top = 16
                Width = 200
                Height = 49
                Caption = #21024#38500
                Enabled = False
                ImageIndex = 5
                ImageName = 'del'
                Images = vrtlmglstButton
                TabOrder = 3
                OnClick = btnDelConnectClick
              end
            end
            object rztbshtDataBaseManager: TRzTabSheet
              Color = 2829099
              TabEnabled = False
              Caption = 'HeidiSQL'
              Enabled = False
            end
          end
        end
        object rztbshtModuleConfig: TRzTabSheet
          Color = 2829099
          Caption = #27169#22359#37197#32622
          object rzpgcntrlModuleSortAndExeManager: TRzPageControl
            Left = 0
            Top = 0
            Width = 703
            Height = 610
            Hint = ''
            ActivePage = rztbshtModuleEXE
            Align = alClient
            BackgroundColor = 2829099
            Font.Charset = GB2312_CHARSET
            Font.Color = clWhite
            Font.Height = -19
            Font.Name = #24494#36719#38597#40657
            Font.Style = []
            HotTrackColor = 7817728
            HotTrackColorSource = htcsHotTrackColorProp
            ParentBackgroundColor = False
            ParentFont = False
            ShowFullFrame = False
            ShowShadow = False
            SoftCorners = True
            TabColors.HighlightBar = clBlack
            TabColors.Shadow = 2829099
            TabColors.Unselected = 2829099
            TabHeight = 41
            TabIndex = 1
            TabOrder = 0
            TabStyle = tsDoubleSlant
            TabWidth = 200
            TextColors.Selected = clWhite
            TextColors.Unselected = clWhite
            UseGradients = False
            FixedDimension = 41
            object rztbshtModuleSort: TRzTabSheet
              Color = 2829099
              Caption = #27169#22359#26174#31034#39034#24207
              DesignSize = (
                703
                568)
              object pnlModuleMove: TPanel
                Left = 542
                Top = 15
                Width = 149
                Height = 508
                Anchors = [akTop, akRight, akBottom]
                BevelOuter = bvNone
                Caption = 'pnlModuleMove'
                Color = 2829099
                Font.Charset = GB2312_CHARSET
                Font.Color = clWhite
                Font.Height = -19
                Font.Name = #23435#20307
                Font.Style = []
                ParentBackground = False
                ParentFont = False
                ShowCaption = False
                TabOrder = 0
                object btnDown: TSpeedButton
                  Left = 12
                  Top = 80
                  Width = 125
                  Height = 50
                  Caption = #19979#31227
                  ImageIndex = 1
                  ImageName = 'down'
                  Images = vrtlmglstButton
                  Enabled = False
                  Flat = True
                  OnClick = btnDownClick
                end
                object btnUP: TSpeedButton
                  Left = 12
                  Top = 16
                  Width = 125
                  Height = 50
                  Caption = #19978#31227
                  ImageIndex = 0
                  ImageName = 'up'
                  Images = vrtlmglstButton
                  Enabled = False
                  Flat = True
                  OnClick = btnUPClick
                end
                object btnModuleMoveSave: TSpeedButton
                  Left = 12
                  Top = 159
                  Width = 125
                  Height = 50
                  Caption = #20445#23384
                  ImageIndex = 2
                  ImageName = 'save'
                  Images = vrtlmglstButton
                  Enabled = False
                  Flat = True
                  OnClick = btnModuleMoveSaveClick
                end
              end
              object tvModuleSort: TTreeView
                Left = 15
                Top = 15
                Width = 514
                Height = 540
                Anchors = [akLeft, akTop, akRight, akBottom]
                AutoExpand = True
                BevelInner = bvNone
                BevelOuter = bvNone
                BorderStyle = bsNone
                Color = 3947580
                Font.Charset = GB2312_CHARSET
                Font.Color = clWhite
                Font.Height = -35
                Font.Name = #24494#36719#38597#40657
                Font.Style = []
                HideSelection = False
                Images = vrtlmglstTreeView
                Indent = 35
                ParentFont = False
                ReadOnly = True
                RightClickSelect = True
                TabOrder = 1
                OnChange = tvModuleSortChange
              end
            end
            object rztbshtModuleEXE: TRzTabSheet
              Color = 2829099
              Caption = 'EXE '#27169#22359#31649#29702
              DesignSize = (
                703
                568)
              object lvModuleEXE: TListView
                Left = 15
                Top = 15
                Width = 514
                Height = 540
                Anchors = [akLeft, akTop, akRight, akBottom]
                BevelInner = bvNone
                BevelOuter = bvNone
                Color = 3947580
                Columns = <
                  item
                    Caption = #21517#31216
                    Width = 400
                  end
                  item
                    Caption = #27169#22359
                    Width = 400
                  end
                  item
                    Caption = #31867#21517
                    Width = 300
                  end
                  item
                    Caption = #26631#39064#21517
                    Width = 400
                  end>
                Ctl3D = False
                Font.Charset = GB2312_CHARSET
                Font.Color = clWhite
                Font.Height = -24
                Font.Name = #24494#36719#38597#40657
                Font.Style = []
                GridLines = True
                ReadOnly = True
                RowSelect = True
                ParentFont = False
                TabOrder = 0
                ViewStyle = vsReport
              end
              object pnlModuleEXE: TPanel
                Left = 542
                Top = 15
                Width = 149
                Height = 508
                Anchors = [akTop, akRight, akBottom]
                BevelOuter = bvNone
                Caption = 'pnlModuleMove'
                Color = 2829099
                Font.Charset = GB2312_CHARSET
                Font.Color = clWhite
                Font.Height = -19
                Font.Name = #23435#20307
                Font.Style = []
                ParentBackground = False
                ParentFont = False
                ShowCaption = False
                TabOrder = 1
                object btnAddModuleEXE: TSpeedButton
                  Left = 12
                  Top = 16
                  Width = 125
                  Height = 50
                  Caption = #28155#21152
                  ImageIndex = 6
                  ImageName = 'addexe'
                  Images = vrtlmglstButton
                  Flat = True
                end
                object btnDelModuleEXE: TSpeedButton
                  Left = 12
                  Top = 80
                  Width = 125
                  Height = 50
                  Caption = #21024#38500
                  ImageIndex = 7
                  ImageName = 'delexe'
                  Images = vrtlmglstButton
                  Enabled = False
                  Flat = True
                end
              end
            end
          end
        end
        object rztbshtSystem: TRzTabSheet
          Color = 2829099
          Caption = #31995#32479#37197#32622
          DesignSize = (
            703
            610)
          object lblWelcome: TLabel
            Left = 48
            Top = 32
            Width = 192
            Height = 31
            Caption = #31243#24207#26631#39064#26639#25991#26412#65306
          end
          object lblOnlyOneInstance: TLabel
            Left = 48
            Top = 88
            Width = 240
            Height = 31
            Caption = #21482#20801#35768#36816#34892#19968#20010#23454#20363#65306
          end
          object edtAppTile: TEdit
            Left = 304
            Top = 29
            Width = 384
            Height = 39
            Anchors = [akLeft, akTop, akRight]
            Font.Charset = GB2312_CHARSET
            Font.Color = clBlack
            Font.Height = -24
            Font.Name = #24494#36719#38597#40657
            Font.Style = []
            ParentFont = False
            TabOrder = 0
          end
          object tglswtchOnlyOneRunInstance: TToggleSwitch
            Left = 304
            Top = 88
            Height = 33
            Color = clWhite
            Font.Charset = GB2312_CHARSET
            Font.Color = 3947580
            Font.Height = -24
            Font.Name = #24494#36719#38597#40657
            Font.Style = []
            ParentFont = False
            StateCaptions.CaptionOn = #26159
            StateCaptions.CaptionOff = #21542
            TabOrder = 1
          end
        end
      end
    end
    object pnlWelcome: TPanel
      Left = 0
      Top = 0
      Width = 703
      Height = 650
      Align = alClient
      BevelOuter = bvNone
      Caption = 'pnlWelcome'
      Color = 2829099
      ParentBackground = False
      ShowCaption = False
      TabOrder = 1
      object lblTitle: TLabel
        Left = 176
        Top = 216
        Width = 131
        Height = 52
        Caption = 'lblTitle'
        Font.Charset = GB2312_CHARSET
        Font.Color = clYellow
        Font.Height = -40
        Font.Name = 'Microsoft YaHei UI'
        Font.Style = []
        ParentFont = False
      end
      object lblTime: TLabel
        Left = 176
        Top = 274
        Width = 131
        Height = 52
        Caption = 'lblTitle'
        Font.Charset = GB2312_CHARSET
        Font.Color = clWhite
        Font.Height = -40
        Font.Name = 'Microsoft YaHei UI'
        Font.Style = []
        ParentFont = False
      end
      object lblLoginUser: TLabel
        Left = 176
        Top = 332
        Width = 131
        Height = 52
        Caption = 'lblTitle'
        Font.Charset = GB2312_CHARSET
        Font.Color = clLime
        Font.Height = -40
        Font.Name = 'Microsoft YaHei UI'
        Font.Style = []
        ParentFont = False
      end
    end
  end
  object tmrStart: TTimer
    Interval = 100
    OnTimer = tmrStartTimer
    Left = 256
    Top = 760
  end
  object imlToolImages: TImageList
    ColorDepth = cd32Bit
    Left = 63
    Top = 578
    Bitmap = {
      494C010102001400040010001000FFFFFFFF2110FFFFFFFFFFFFFFFF424D3600
      0000000000003600000028000000400000001000000001002000000000000010
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000010080114D77610FFD77610FF140B0119000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000004525
      05521E10022300000000361D0441D77610FFD77610FF371E0342000000002615
      032E4B29055A0000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      000000000000000000000000000000000000000000000000000046260553D474
      10FDCB700FF26838087BA85C0DC8D77610FFD77610FFAF5F0DD0743F0989CF71
      0EF7D57510FE4827055500000000000000000000000000000000000000000000
      0000000000000000000061350874D77610FFD77610FFD77610FFD77610FFD776
      10FFD77610FF0000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      000000000000000000000000000000000000000000000000000022120228CD70
      0FF5D77610FFD77610FFD77610FFD77610FFD77610FFD77610FFD77610FFD776
      10FFC96F0FF01B0F022000000000000000000000000000000000000000000000
      000000000000000000000000000061350874D77610FFD77610FFD77610FFD776
      10FFD77610FF0000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000006C3B
      0981D77610FFD77610FFD77610FFD77610FFD77610FFD77610FFD77610FFD776
      10FF663808790000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000006C3C0980D77610FFD77610FFD776
      10FFD77610FF0000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      00000000000000000000000000000000000000000000140A0118361D0441AA5E
      0ECBD77610FFD77610FF92510BAF110A0114100900128D4E0BA9D77610FFD776
      10FFAC5E0ECC3E210449160C021B000000000000000000000000000000000000
      000000000000000000000000000010080114AF5F0DD0D77610FFD77610FFD776
      10FFD77610FF0000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      00000000000000000000000000000000000000000000D77610FFD77610FFD776
      10FFD77610FFD77610FF160B021A000000000000000010080013D77610FFD776
      10FFD77610FFD77610FFD77610FF000000000000000000000000000000000000
      0000000000000000000010080114AF5F0DD0D77610FFAF5F0DD06C3C0980D776
      10FFD77610FF0000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      00000000000000000000000000000000000000000000D77610FFD77610FFD776
      10FFD77610FFD77610FF180C021D000000000000000010090015D77610FFD776
      10FFD77610FFD77610FFD77610FF000000000000000000000000000000000000
      00000000000010080114AF5F0DD0D77610FFAF5F0DD010080114000000006135
      0874D77610FF0000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000010090012361D0441AA5E
      0ECBD77610FFD77610FF99530AB5180C011C160B021A92510BAFD77610FFD776
      10FFAC5F0DCD301A043A0E070011000000000000000000000000000000000000
      000010080114AF5F0DD0D77610FFAF5F0DD01008011400000000000000000000
      0000613508740000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000006C3C
      0980D77610FFD77610FFD77610FFD77610FFD77610FFD77610FFD77610FFD776
      10FF7540098B0000000000000000000000000000000000000000000000001008
      0114AF5F0DD0D77610FFAF5F0DD0100801140000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      000000000000000000000000000000000000000000000000000020110226CD70
      0FF3D77610FFD77610FFD77610FFD77610FFD77610FFD77610FFD77610FFD776
      10FFD27210F92B17023300000000000000000000000000000000000000009C55
      0CB9D77610FFAF5F0DD010080114000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      000000000000000000000000000000000000000000000000000046260553D474
      10FDCE700FF56E3C0982A75C0DC8D77610FFD77610FFA65C0BC75E340771C76C
      0FECD47410FD4827065600000000000000000000000000000000000000002313
      032B9C550CB91008011400000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000004626
      055322120228000000002E190439D77610FFD77610FF3C20054800000000160C
      021B4224044E0000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      000000000000000000000D070110D77610FFD77610FF160B021A000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      000000000000000000000000000000000000424D3E000000000000003E000000
      2800000040000000100000000100010000000000800000000000000000000000
      000000000000000000000000FFFFFF00FFFFFFFF00000000FC3FFFFF00000000
      E427FFFF00000000C003FC0700000000C003FE0700000000E007FF0700000000
      8001FE07000000008181FC07000000008181F827000000008001F07700000000
      E007E0FF00000000C003E1FF00000000C003E3FF00000000E427FFFF00000000
      FC3FFFFF00000000FFFFFFFF0000000000000000000000000000000000000000
      000000000000}
  end
  object vrtlmglstTreeView: TVirtualImageList
    Images = <
      item
        CollectionIndex = 0
        CollectionName = '02'
        Name = '02'
      end
      item
        CollectionIndex = 1
        CollectionName = '01'
        Name = '01'
      end
      item
        CollectionIndex = 5
        CollectionName = '06'
        Name = '06'
      end
      item
        CollectionIndex = 2
        CollectionName = '05'
        Name = '05'
      end
      item
        CollectionIndex = 3
        CollectionName = '03'
        Name = '03'
      end
      item
        CollectionIndex = 4
        CollectionName = '04'
        Name = '04'
      end>
    ImageCollection = imgclctnTreeViewModule
    Width = 32
    Height = 32
    Left = 64
    Top = 512
  end
  object imgclctnTreeViewModule: TImageCollection
    Images = <
      item
        Name = '02'
        SourceImages = <
          item
            Image.Data = {
              89504E470D0A1A0A0000000D4948445200000020000000200806000000737A7A
              F4000000017352474200AECE1CE90000000467414D410000B18F0BFC61050000
              00097048597300000EC300000EC301C76FA864000001EB494441545847ED9731
              4BC34014C7CF24EDC7507A67A5A3202E057112D45D5737573F4207077787427A
              693F801FA1206E0E8A20088E45ED2A58050B8250DF8B4F4E9317936B735B7FF0
              A7257DF7FE49EEDDDDAB98634310D6D67DAD8EBD48F5E1F301F4122B9243B876
              EE77D44910AAA69888051A520290CCEBAA7D4FAB5B3F52936292F79E9607A225
              3CCA3225A15C8C9F8C35C917DCC465B527EB94CD8EA053DBF0B57CE612DB49BE
              C2346D53DA62C4E6917A4F279B525A7EF85DB943E97380D75ECE9327A4E59B08
              971AE4920116DC0C739E2728E46B71267C724B83D5CE0D2C537013876497C66E
              A94D2B39609767D0834D861DE040BAB645B606DCE1D86017EACA53B2357891EC
              B3C10E04857E45B606F8E13119E85023B2357C1F2A6CB01391AD012E8E92412E
              45B606581E4F5CA013E1AE98C4E50E981414FC0DD91AB099E0821DA94DB686A0
              A79A4CA01B69B94BB6BF8083083B197640A9924371B11990EB5FB08DE2079527
              98FF23B263804302DB286E6029D2EA4E846B1572CB007AB8B88DE212CCA671A5
              535F2597FFC11E2E6EA3F844F6D2EAD38F96F7287D31B087C30D834D68A7B1B5
              F90FD570A5816D1493B49860CE0BBFF64CA087C3360A120E520699C27F4A50ED
              B9056703AC10EC64B099C0F31C8CCCE1055385DB2B7C6FC79B4C2B639DCF4921
              C417E6225A0131D71AAA0000000049454E44AE426082}
          end>
      end
      item
        Name = '01'
        SourceImages = <
          item
            Image.Data = {
              89504E470D0A1A0A0000000D4948445200000020000000200806000000737A7A
              F4000000017352474200AECE1CE90000000467414D410000B18F0BFC61050000
              00097048597300000EC300000EC301C76FA864000001F5494441545847ED96BB
              4BC35014C66F7D8CD6A4DDDD0447972E0547A1BAD7D5ADAB4B7313A70E0EEE1D
              FC63047173500B429BDC4CE263157C80858210CF0947AF36A76D92DE6CFDC147
              697BCEF992FB3C624116AA5E58B3657062B9EADC76D503E81505DF9F6DA92E2C
              E99FC2675D88A8442926884AB6F40FA0F01D984569040F14583238149D68898A
              E4C376071BF8669C491AC1835CAD39FE2695CB86E5F83B60FEC215CE22CB0DDE
              EDF6A04165D381E696549F5CC15C926A04D3B847E5A743C33EF79B8F0B46E2A3
              7A1C6E91CD2470C1E59FF3D90A6E44335A26B324F16A67130DCA512DB24B026F
              9F7AABE55770CF6ECFB2D7AFF109E65596C12ED96AF084E3820B910CBB64AB81
              3FF078E5134C4BAA6BB2D5C0BE7F64838BD11BD96AE047BC58B8E04244B61AF8
              F16D3CA84891AD062E8E272EB008E1A948B69A624FC0847A64AB899B093ED8B8
              60C19F91AD0646A0CE051722C7DF27DBBF4425EC64D80483C2F64D742E57C8F4
              3FD84671492665B9FE11D931C025816D1497684250BB2F5AB7ABE4C6833D5CDC
              463105E611980FD7DB836DB2998EED850D589423AE504E7D553CBF49E5D3813D
              1C1E184CB14C821AC3CCE63F600F876D1457388D70CE530FFB44A087B33DD5C2
              4E8633E1845B2D5EEDB3165C26608754A09381C6A58BF7393CD0EFE54553D5C3
              132E3E6426EDF3050984F806FEC6EE2E5AAB10140000000049454E44AE426082}
          end>
      end
      item
        Name = '05'
        SourceImages = <
          item
            Image.Data = {
              89504E470D0A1A0A0000000D4948445200000020000000200806000000737A7A
              F4000000017352474200AECE1CE90000000467414D410000B18F0BFC61050000
              00097048597300000EC300000EC301C76FA864000001EB494441545847ED96BD
              4A03511085AF7F0F919DBBE9044B21D808924A48ECB54D679B87B0B04F9187F0
              1104B14B6192CD8F9032A8698518414110E21919BD64778CBB9BDD2E073E48B2
              3373367BEF9D1DB3561205D61EF4892E06D65E838701D194E95B3BC1F79B9EB5
              9781E71DCE8DD99094D5C5C57ABE7F06833E98C76434F0BC1A7237A54C3A750A
              85228ADD848A27A11510ED4AB9641AF8FE110A3C870AA6618625AA48D97812F3
              B750A1D460DF7C60AF54A5FC72C963CFE29F2F80A7F03A2C14F6C446176F3804
              AFB2E6CB216A5F19B3257651C96ED79333A247742E76512120C9514B07D1583D
              9EDC64D4841C087CFF586C9DFABECF1D4E4DC81CA286D83AE102B7573D216B88
              EEC4D609171E23817941F422B64EF871AA06E784D83AF15D69817921B64EE854
              4F5A601E7057145B275CC8AF0386C00D74C5D68987092D380F86D636C5D62928
              160FB5E03CC08C7022B64EF2221A8583B3068F7F725B2E6F8BEDA23007D4B4A4
              4C21AA8B5D54FC9240502B92941544F79D526947EC74F10C87E05924795588DE
              7B9EB72F36CB8575AA7C8F515AA1747C620E3895F2F1843BAE72C3508A2583FF
              7952F31FF10C87026DB5701CB0E6B11FFB5FE2198EC728141BAB260A7CD4105F
              FF77C325119F109E6450B801EEC0EFCB8B970A74F1B9C94DE6D618FD9CAF1591
              315F189610A581D588A20000000049454E44AE426082}
          end>
      end
      item
        Name = '03'
        SourceImages = <
          item
            Image.Data = {
              89504E470D0A1A0A0000000D4948445200000020000000200806000000737A7A
              F4000000017352474200AECE1CE90000000467414D410000B18F0BFC61050000
              00097048597300000EC300000EC301C76FA86400000083494441545847ED8EC1
              0980301004538269D658820DAAE5288B0922AE10F1CC22DCC0423E9799E0388E
              1531CD437E6A886959A5117B8030E20810459C030411D780C6113C006B14C1E5
              650F22F80716AB8CE0C756AB88E08736EBFA69CC9A7BD8A1C5AAE46F60D2B2CF
              E58089B12672209503A91C48E5402A07523990CA1DE7C784B00138437EE64A75
              A8C00000000049454E44AE426082}
          end>
      end
      item
        Name = '04'
        SourceImages = <
          item
            Image.Data = {
              89504E470D0A1A0A0000000D4948445200000020000000200806000000737A7A
              F4000000017352474200AECE1CE90000000467414D410000B18F0BFC61050000
              00097048597300000EC300000EC301C76FA86400000070494441545847ED8E41
              0A80300C04F304FDAC7EC10F8ACFA914BA50A4489B2611640772C9616784102D
              EB7EA5FACA3B0E063080010C600003DC0396ED3C9E12EDE5AD323B8645845A0E
              6622A6E540136126072311E672D013E126076F11EE72D08A0893833A225C0EB2
              F83339F9092237A61E7F68252B6E3A0000000049454E44AE426082}
          end>
      end
      item
        Name = '06'
        SourceImages = <
          item
            Image.Data = {
              89504E470D0A1A0A0000000D4948445200000020000000200806000000737A7A
              F4000000017352474200AECE1CE90000000467414D410000B18F0BFC61050000
              00097048597300000EC300000EC301C76FA864000001F5494441545847ED574D
              4B0251149DBE7E816F8436ED84966DDC042D056D9F5B776EFD092D5CB86F21F4
              172253A79D10ED5A284210B88CCA6DA0090542BCD779E3AD47E35567C6793B0F
              1C94F1DE73EEFB9CABB34114482F95956DB72A5BA223DBE205DF47C4A16CB977
              B2296AB2E91E2BE56C51CAFAD062302B828FAAEDAA30444103B0A4CE9D6D9289
              07E5ED1FE89171266188A21FE4ADC8905C34603A4F20F0CE09472106F081D9C8
              936C38F8E62DF1C909C6210A98CA1B5120F9E5F0A73D819107892226CA4B1D92
              0D0F7FC379F1D77C1551444F5D393B64370F4C53914B4C96E932D9CD23CA518B
              4BECAD67F678CA462ACB25D8A06CA473646B80F5A972C136283D7141B60678D8
              E1826D1083ED92AD01D6E6950BB6C431D91AA0AA1113688D646B8087E360904D
              92AD0166E08D0BB441784DC8D6C0E60D18240AE893AD012EA11A176C83387175
              B235F03B1926D806F1B63D255B8359E7E30EB88424098FA1BA7776C9F63FF063
              894B4A92B86F2A64370FFD92D06D14979804A1FDA42E9D3DB2E321AF4546B751
              9CC03A84F9976ABA4764B31C588A3C38E584E2105ADFF83C23F970C051292071
              12148B4A7FE451CD7FA17B3814D10B8A86A5BFE661A77D11740FA7DAA2EC7732
              8C0947148D7F4AA2B272C345C1EC84A473BA99C026EDC2E8EFE5A5970ACFFA30
              ADEB4B66E139DF600E8EF303CB5AF6E4842F21970000000049454E44AE426082}
          end>
      end>
    Left = 64
    Top = 440
  end
  object tmrTime: TTimer
    OnTimer = tmrTimeTimer
    Left = 496
    Top = 286
  end
  object trycnModule: TTrayIcon
    PopupMenu = pmModule
    OnDblClick = mniShowClick
    Left = 64
    Top = 371
  end
  object pmModule: TPopupMenu
    AutoHotkeys = maManual
    Left = 64
    Top = 315
    object mniShow: TMenuItem
      Caption = #26174#31034
      OnClick = mniShowClick
    end
    object mniLine01: TMenuItem
      Caption = '-'
    end
    object mniExit: TMenuItem
      Caption = #36864#20986
      OnClick = mniExitClick
    end
  end
  object vrtlmglstModule: TVirtualImageList
    Images = <
      item
        CollectionIndex = 0
        CollectionName = 'DET'
        Name = 'DET'
      end>
    ImageCollection = imgclctnModule
    Left = 496
    Top = 438
  end
  object imgclctnModule: TImageCollection
    Images = <
      item
        Name = 'DET'
        SourceImages = <
          item
            Image.Data = {
              0000010002001010000001002000280500002600000020200000010020002814
              00004E0500002800000010000000200000000100200000000000000500000000
              00000000000000000000000000000700D9000700D9000700D9000700D9000700
              D9000700D9000700D9000700D9000700D9000700D9000700D9000700D9000700
              D9000700D9000700D9000700D9000801DB000801DB000801DB000801DB000801
              DB140801DB860801DBD30801DBFA0801DBF40801DBCE0801DB830801DB140801
              DB000801DB000801DB000801DB000A03DD000A03DD000A03DD000A03DD540A03
              DDF20A03DDFF0A03DDFF0A03DDFF0A03DDFF0A03DDFF0A03DDFF0A03DDF20A03
              DD530A03DD000A03DD000A03DD000B04DF000B04DF000B04DF530B04DFFE0B04
              DFFF0B04DFFF0B04DFFF0B04DFFF0B04DFFF0B04DFFF0B04DFFF0B04DFFF0B04
              DFFE0B04DF530B04DF000B04DF000D06E2000D06E2160D06E2F10D06E2FF0D06
              E2FF0D06E2FF0D06E2FF0D06E2FF0D06E2FF0D06E2FF0D06E2FF0D06E2FF0D06
              E2FF0D06E2F10D06E2160D06E2000F08E5000F08E5820F08E5FF0F08E5FFFAFA
              FEFF7D79F1FF0F08E5FF0F08E5FF0F08E5FF0F08E5FF7D79F1FFFBFBFFFF0F08
              E5FF0F08E5FF0F08E5860F08E500120BE900120BE9D0120BE9FF120BE9FFFFFF
              FFFF827EF3FF130CE9FF9794F5FF9794F5FF130CE9FF827EF3FFFFFFFFFF120B
              E9FF120BE9FF120BE9D1120BE900140DEC00140DECF8140DECFF140DECFFFFFF
              FFFF8480F5FF9B99F7FFFFFFFFFFFFFFFFFF9B99F7FF8480F5FFFFFFFFFF140D
              ECFF140DECFF140DECF3140DEC00160FEF00160FEFF8160FEFFF160FEFFFFFFF
              FFFFE6E6FDFFFFFFFFFFA09DF8FF9F9CF8FFFFFFFFFFE6E6FDFFFFFFFFFF160F
              EFFF160FEFFF160FEFF9160FEF001912F3001912F3D01912F3FF1912F3FFFFFF
              FFFFFFFFFFFFA4A1FAFF1A13F3FF1A13F3FFA4A1FAFFFFFFFFFFFFFFFFFF1912
              F3FF1912F3FF1912F3D21912F3001B14F6001B14F6821B14F6FF1B14F6FFFBFA
              FFFFA6A4FCFF1C15F6FF1B14F6FF1B14F6FF1C15F6FFA6A3FBFFFBFAFFFF1B14
              F6FF1B14F6FF1B14F6861B14F6001D16F9001D16F9151D16F9F11D16F9FF1D16
              F9FF1D16F9FF1D16F9FF1D16F9FF1D16F9FF1D16F9FF1D16F9FF1D16F9FF1D16
              F9FF1D16F9F11D16F9161D16F9001E17FB001E17FB001E17FB531E17FBFE1E17
              FBFF1E17FBFF1E17FBFF1E17FBFF1E17FBFF1E17FBFF1E17FBFF1E17FBFF1E17
              FBFE1E17FB531E17FB001E17FB002019FD002019FD002019FD002019FD532019
              FDF02019FDFF2019FDFF2019FDFF2019FDFF2019FDFF2019FDFF2019FDF12019
              FD532019FD002019FD002019FD00211AFF00211AFF00211AFF00211AFF00211A
              FF14211AFF86211AFFD2211AFFF8211AFFF8211AFFD0211AFF82211AFF14211A
              FF00211AFF00211AFF00211AFF00211AFF00211AFF00211AFF00211AFF00211A
              FF00211AFF00211AFF00211AFF00211AFF00211AFF00211AFF00211AFF00211A
              FF00211AFF00211AFF00211AFF00000000000000000000000000000000000000
              0000000000000000000000000000000000000000000000000000000000000000
              0000000000000000000000000000000000000000000000000000000000000000
              0000000000000000000000000000000000000000000000000000000000000000
              0000000000000000000000000000000000000000000000000000000000000000
              0000000000000000000000000000000000000000000000000000000000000000
              0000000000000000000000000000000000000000000000000000000000000000
              0000000000000000000000000000000000000000000000000000000000000000
              0000000000000000000000000000280000002000000040000000010020000000
              000000140000000000000000000000000000000000000700D9000700D9000700
              D9000700D9000700D9000700D9000700D9000700D9000700D9000700D9000700
              D9000700D9000700D9000700D9000700D9000700D9000700D9000700D9000700
              D9000700D9000700D9000700D9000700D9000700D9000700D9000700D9000700
              D9000700D9000700D9000700D9000700D9000700D9000700DA000700DA000700
              DA000700DA000700DA000700DA000700DA000700DA000700DA000700DA000700
              DA050700DA4C0700DA920700DAC70700DAE90700DAFA0700DAFA0700DAE90700
              DAC70700DA920700DA4C0700DA060700DA000700DA000700DA000700DA000700
              DA000700DA000700DA000700DA000700DA000700DA000801DB000801DB000801
              DB000801DB000801DB000801DB000801DB000801DB000801DB100801DB810801
              DBEC0801DBFF0801DBFF0801DBFF0801DBFF0801DBFF0801DBFF0801DBFF0801
              DBFF0801DBFF0801DBFF0801DBEC0801DB810801DB100801DB000801DB000801
              DB000801DB000801DB000801DB000801DB000801DB000902DB000902DB000902
              DB000902DB000902DB000902DB000902DB000902DB580902DBE90902DBFF0902
              DBFF0902DBFF0902DBFF0902DBFF0902DBFF0902DBFF0902DBFF0902DBFF0902
              DBFF0902DBFF0902DBFF0902DBFF0902DBFF0902DBE90902DB580902DB000902
              DB000902DB000902DB000902DB000902DB000902DB000902DC000902DC000902
              DC000902DC000902DC000902DC030902DC960902DCFF0902DCFF0902DCFF0902
              DCFF0902DCFF0902DCFF0902DCFF0902DCFF0902DCFF0902DCFF0902DCFF0902
              DCFF0902DCFF0902DCFF0902DCFF0902DCFF0902DCFF0902DCFF0902DC960902
              DC030902DC000902DC000902DC000902DC000902DC000A03DE000A03DE000A03
              DE000A03DE000A03DE030A03DEAD0A03DEFF0A03DEFF0A03DEFF0A03DEFF0A03
              DEFF0A03DEFF0A03DEFF0A03DEFF0A03DEFF0A03DEFF0A03DEFF0A03DEFF0A03
              DEFF0A03DEFF0A03DEFF0A03DEFF0A03DEFF0A03DEFF0A03DEFF0A03DEFF0A03
              DEAD0A03DE030A03DE000A03DE000A03DE000A03DE000B04DF000B04DF000B04
              DF000B04DF000B04DF940B04DFFF0B04DFFF0B04DFFF0B04DFFF0B04DFFF0B04
              DFFF0B04DFFF0B04DFFF0B04DFFF0B04DFFF0B04DFFF0B04DFFF0B04DFFF0B04
              DFFF0B04DFFF0B04DFFF0B04DFFF0B04DFFF0B04DFFF0B04DFFF0B04DFFF0B04
              DFFF0B04DF940B04DF000B04DF000B04DF000B04DF000C05E0000C05E0000C05
              E0000C05E0570C05E0FF0C05E0FF0C05E0FF0C05E0FF0C05E0FF0C05E0FF0C05
              E0FF0C05E0FF0C05E0FF0C05E0FF0C05E0FF0C05E0FF0C05E0FF0C05E0FF0C05
              E0FF0C05E0FF0C05E0FF0C05E0FF0C05E0FF0C05E0FF0C05E0FF0C05E0FF0C05
              E0FF0C05E0FF0C05E0580C05E0000C05E0000C05E0000D06E1000D06E1000D06
              E1100D06E1E90D06E1FF0D06E1FF0D06E1FF0D06E1FF0D06E1FF0D06E1FF0D06
              E1FF0D06E1FF0D06E1FF0D06E1FF0D06E1FF0D06E1FF0D06E1FF0D06E1FF0D06
              E1FF0D06E1FF0D06E1FF0D06E1FF0D06E1FF0D06E1FF0D06E1FF0D06E1FF0D06
              E1FF0D06E1FF0D06E1EA0D06E1100D06E1000D06E1000E07E3000E07E3000E07
              E3800E07E3FF0E07E3FF0E07E3FF0E07E3FF0E07E3FF0E07E3FF0E07E3FF0E07
              E3FF0E07E3FF0E07E3FF0E07E3FF0E07E3FF0E07E3FF0E07E3FF0E07E3FF0E07
              E3FF0E07E3FF0E07E3FF0E07E3FF0E07E3FF0E07E3FF0E07E3FF0E07E3FF0E07
              E3FF0E07E3FF0E07E3FF0E07E3800E07E3000E07E3000F08E4000F08E4060F08
              E4EC0F08E4FF0F08E4FF0F08E4FF0F08E4FF0F08E4FFF4F3FEFFFFFFFFFFE4E3
              FCFF0F08E4FF0F08E4FF0F08E4FF0F08E4FF0F08E4FF0F08E4FF0F08E4FF0F08
              E4FF0F08E4FF0F08E4FFE7E6FCFFFFFFFFFFF4F3FEFF0F08E4FF0F08E4FF0F08
              E4FF0F08E4FF0F08E4FF0F08E4EA0F08E4060F08E4001009E6001009E64C1009
              E6FF1009E6FF1009E6FF1009E6FF1009E6FF1009E6FFFFFFFFFFFFFFFFFFF1F1
              FEFF1009E6FF1009E6FF1009E6FF1009E6FF1009E6FF1009E6FF1009E6FF1009
              E6FF1009E6FF1009E6FFF1F1FEFFFFFFFFFFFFFFFFFF1009E6FF1009E6FF1009
              E6FF1009E6FF1009E6FF1009E6FF1009E64D1009E600110AE700110AE792110A
              E7FF110AE7FF110AE7FF110AE7FF110AE7FF110AE7FFFFFFFFFFFFFFFFFFF1F1
              FEFF110AE7FF110AE7FF110AE7FF160FE7FF9D9AF5FF9D9AF5FF150EE7FF110A
              E7FF110AE7FF110AE7FFF1F1FEFFFFFFFFFFFFFFFFFF110AE7FF110AE7FF110A
              E7FF110AE7FF110AE7FF110AE7FF110AE793110AE700120BE900120BE9C5120B
              E9FF120BE9FF120BE9FF120BE9FF120BE9FF120BE9FFFFFFFFFFFFFFFFFFF1F1
              FEFF120BE9FF120BE9FF150EE9FFB0AEF8FFFFFFFFFFFFFFFFFFB0AEF8FF150E
              E9FF120BE9FF120BE9FFF1F1FEFFFFFFFFFFFFFFFFFF120BE9FF120BE9FF120B
              E9FF120BE9FF120BE9FF120BE9FF120BE9C5120BE900130CEA00130CEAEA130C
              EAFF130CEAFF130CEAFF130CEAFF130CEAFF130CEAFFFFFFFFFFFFFFFFFFF1F1
              FEFF130CEAFF160FEAFFAEACF8FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFAEAB
              F8FF160FEAFF130CEAFFF1F1FEFFFFFFFFFFFFFFFFFF130CEAFF130CEAFF130C
              EAFF130CEAFF130CEAFF130CEAFF130CEAEA130CEA00140DEC00140DECF9140D
              ECFF140DECFF140DECFF140DECFF140DECFF140DECFFFFFFFFFFFFFFFFFFF1F1
              FEFF1710ECFFACAAF8FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF
              FFFFABA9F8FF1710ECFFF1F1FEFFFFFFFFFFFFFFFFFF140DECFF140DECFF140D
              ECFF140DECFF140DECFF140DECFF140DECF9140DEC00150EEE00150EEEF9150E
              EEFF150EEEFF150EEEFF150EEEFF150EEEFF150EEEFFFFFFFFFFFFFFFFFFF5F5
              FEFFA9A6F9FFFFFFFFFFFFFFFFFFFFFFFFFFB3B1F9FFB4B2FAFFFFFFFFFFFFFF
              FFFFFFFFFFFFA9A6F9FFF5F5FEFFFFFFFFFFFFFFFFFF150EEEFF150EEEFF150E
              EEFF150EEEFF150EEEFF150EEEFF150EEEF9150EEE00160FEF00160FEFEA160F
              EFFF160FEFFF160FEFFF160FEFFF160FEFFF160FEFFFFFFFFFFFFFFFFFFFFFFF
              FFFFFFFFFFFFFFFFFFFFFFFFFFFFB3B1FAFF1B14EFFF1B14EFFFB3B1FAFFFFFF
              FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF160FEFFF160FEFFF160F
              EFFF160FEFFF160FEFFF160FEFFF160FEFEA160FEF001710F1001710F1C41710
              F1FF1710F1FF1710F1FF1710F1FF1710F1FF1710F1FFFFFFFFFFFFFFFFFFFFFF
              FFFFFFFFFFFFFFFFFFFFB6B4FBFF1C16F1FF1710F1FF1710F1FF1C16F1FFB6B4
              FBFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF1710F1FF1710F1FF1710
              F1FF1710F1FF1710F1FF1710F1FF1710F1C51710F1001811F2001811F2921811
              F2FF1811F2FF1811F2FF1811F2FF1811F2FF1811F2FFFFFFFFFFFFFFFFFFFFFF
              FFFFFFFFFFFFB9B7FBFF1D17F2FF1811F2FF1811F2FF1811F2FF1811F2FF1D17
              F2FFB9B7FBFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF1811F2FF1811F2FF1811
              F2FF1811F2FF1811F2FF1811F2FF1811F2931811F2001912F4001912F44C1912
              F4FF1912F4FF1912F4FF1912F4FF1912F4FF1912F4FFFFFFFFFFFFFFFFFFFFFF
              FFFFBCBAFCFF1E18F4FF1912F4FF1912F4FF1912F4FF1912F4FF1912F4FF1912
              F4FF1E18F4FFBCBAFCFFFFFFFFFFFFFFFFFFFFFFFFFF1912F4FF1912F4FF1912
              F4FF1912F4FF1912F4FF1912F4FF1912F44C1912F4001A13F5001A13F5061A13
              F5EA1A13F5FF1A13F5FF1A13F5FF1A13F5FF1A13F5FFF4F4FFFFFFFFFFFFB7B5
              FCFF2019F5FF1A13F5FF1A13F5FF1A13F5FF1A13F5FF1A13F5FF1A13F5FF1A13
              F5FF1A13F5FF1F19F5FFB9B7FCFFFFFFFFFFF4F4FFFF1A13F5FF1A13F5FF1A13
              F5FF1A13F5FF1A13F5FF1A13F5EA1A13F5061A13F5001B14F7001B14F7001B14
              F7801B14F7FF1B14F7FF1B14F7FF1B14F7FF1B14F7FF1B14F7FF1B14F7FF1B14
              F7FF1B14F7FF1B14F7FF1B14F7FF1B14F7FF1B14F7FF1B14F7FF1B14F7FF1B14
              F7FF1B14F7FF1B14F7FF1B14F7FF1B14F7FF1B14F7FF1B14F7FF1B14F7FF1B14
              F7FF1B14F7FF1B14F7FF1B14F7801B14F7001B14F7001C15F8001C15F8001C15
              F8101C15F8E91C15F8FF1C15F8FF1C15F8FF1C15F8FF1C15F8FF1C15F8FF1C15
              F8FF1C15F8FF1C15F8FF1C15F8FF1C15F8FF1C15F8FF1C15F8FF1C15F8FF1C15
              F8FF1C15F8FF1C15F8FF1C15F8FF1C15F8FF1C15F8FF1C15F8FF1C15F8FF1C15
              F8FF1C15F8FF1C15F8E91C15F8101C15F8001C15F8001D16F9001D16F9001D16
              F9001D16F9571D16F9FF1D16F9FF1D16F9FF1D16F9FF1D16F9FF1D16F9FF1D16
              F9FF1D16F9FF1D16F9FF1D16F9FF1D16F9FF1D16F9FF1D16F9FF1D16F9FF1D16
              F9FF1D16F9FF1D16F9FF1D16F9FF1D16F9FF1D16F9FF1D16F9FF1D16F9FF1D16
              F9FF1D16F9FF1D16F9571D16F9001D16F9001D16F9001E17FA001E17FA001E17
              FA001E17FA001E17FA931E17FAFF1E17FAFF1E17FAFF1E17FAFF1E17FAFF1E17
              FAFF1E17FAFF1E17FAFF1E17FAFF1E17FAFF1E17FAFF1E17FAFF1E17FAFF1E17
              FAFF1E17FAFF1E17FAFF1E17FAFF1E17FAFF1E17FAFF1E17FAFF1E17FAFF1E17
              FAFF1E17FA941E17FA001E17FA001E17FA001E17FA001F18FC001F18FC001F18
              FC001F18FC001F18FC031F18FCAD1F18FCFF1F18FCFF1F18FCFF1F18FCFF1F18
              FCFF1F18FCFF1F18FCFF1F18FCFF1F18FCFF1F18FCFF1F18FCFF1F18FCFF1F18
              FCFF1F18FCFF1F18FCFF1F18FCFF1F18FCFF1F18FCFF1F18FCFF1F18FCFF1F18
              FCAD1F18FC031F18FC001F18FC001F18FC001F18FC001F18FD001F18FD001F18
              FD001F18FD001F18FD001F18FD031F18FD961F18FDFF1F18FDFF1F18FDFF1F18
              FDFF1F18FDFF1F18FDFF1F18FDFF1F18FDFF1F18FDFF1F18FDFF1F18FDFF1F18
              FDFF1F18FDFF1F18FDFF1F18FDFF1F18FDFF1F18FDFF1F18FDFF1F18FD961F18
              FD031F18FD001F18FD001F18FD001F18FD001F18FD002019FD002019FD002019
              FD002019FD002019FD002019FD002019FD002019FD582019FDE82019FDFF2019
              FDFF2019FDFF2019FDFF2019FDFF2019FDFF2019FDFF2019FDFF2019FDFF2019
              FDFF2019FDFF2019FDFF2019FDFF2019FDFF2019FDE82019FD582019FD002019
              FD002019FD002019FD002019FD002019FD002019FD00211AFE00211AFE00211A
              FE00211AFE00211AFE00211AFE00211AFE00211AFE00211AFE10211AFE80211A
              FEEA211AFEFF211AFEFF211AFEFF211AFEFF211AFEFF211AFEFF211AFEFF211A
              FEFF211AFEFF211AFEFF211AFEEB211AFE80211AFE10211AFE00211AFE00211A
              FE00211AFE00211AFE00211AFE00211AFE00211AFE00211AFF00211AFF00211A
              FF00211AFF00211AFF00211AFF00211AFF00211AFF00211AFF00211AFF00211A
              FF05211AFF4C211AFF91211AFFC6211AFFE8211AFFF8211AFFF8211AFFE8211A
              FFC6211AFF91211AFF4C211AFF05211AFF00211AFF00211AFF00211AFF00211A
              FF00211AFF00211AFF00211AFF00211AFF00211AFF00211AFF00211AFF00211A
              FF00211AFF00211AFF00211AFF00211AFF00211AFF00211AFF00211AFF00211A
              FF00211AFF00211AFF00211AFF00211AFF00211AFF00211AFF00211AFF00211A
              FF00211AFF00211AFF00211AFF00211AFF00211AFF00211AFF00211AFF00211A
              FF00211AFF00211AFF00211AFF00211AFF00211AFF0000000000000000000000
              0000000000000000000000000000000000000000000000000000000000000000
              0000000000000000000000000000000000000000000000000000000000000000
              0000000000000000000000000000000000000000000000000000000000000000
              0000000000000000000000000000000000000000000000000000000000000000
              0000000000000000000000000000000000000000000000000000000000000000
              0000000000000000000000000000000000000000000000000000000000000000
              0000000000000000000000000000000000000000000000000000000000000000
              0000000000000000000000000000000000000000000000000000000000000000
              0000000000000000000000000000000000000000000000000000000000000000
              0000000000000000000000000000000000000000000000000000000000000000
              0000000000000000000000000000000000000000000000000000000000000000
              0000000000000000000000000000000000000000000000000000000000000000
              0000000000000000000000000000000000000000000000000000000000000000
              0000000000000000000000000000000000000000000000000000000000000000
              0000000000000000000000000000000000000000000000000000000000000000
              0000000000000000000000000000000000000000000000000000000000000000
              0000000000000000000000000000000000000000000000000000000000000000
              0000000000000000000000000000000000000000000000000000000000000000
              0000000000000000000000000000000000000000000000000000000000000000
              0000000000000000000000000000000000000000000000000000000000000000
              0000000000000000000000000000000000000000000000000000000000000000
              0000000000000000000000000000000000000000000000000000000000000000
              0000000000000000000000000000000000000000000000000000000000000000
              0000000000000000000000000000000000000000000000000000000000000000
              0000000000000000000000000000000000000000000000000000000000000000
              0000000000000000000000000000000000000000000000000000000000000000
              0000000000000000000000000000000000000000000000000000000000000000
              0000000000000000000000000000000000000000000000000000000000000000
              0000000000000000000000000000000000000000000000000000000000000000
              0000000000000000000000000000000000000000000000000000000000000000
              0000000000000000000000000000000000000000000000000000000000000000
              00000000000000000000000000000000000000000000}
          end>
      end>
    Left = 496
    Top = 366
  end
  object imgclctnButton: TImageCollection
    Images = <
      item
        Name = 'up'
        SourceImages = <
          item
            Image.Data = {
              89504E470D0A1A0A0000000D4948445200000020000000200806000000737A7A
              F4000000017352474200AECE1CE90000000467414D410000B18F0BFC61050000
              00097048597300000EC300000EC301C76FA864000000D1494441545847ED8E5D
              0AC230108483DE24BD8907F03C9EC5F69A3EF8A4D9321B92CD0F294D22C87E30
              686769E7338A7286CB6A1F143CCE8586AFDBF2A14C9708C7A74BE4C639C3256A
              E39C61122DE39CEE1247C639DD24B2E3AB7D27DDB6BC64775AA2327E4FFAA7BD
              B9DF7E12B571BACBDBDEF594901F09C70979475D94C0B99DE803629C88EE2EA8
              77721238B5E35FCE8C13FE8EA0F64809D4EDEC2F16C609FE300775442881AA9D
              DA38C1C31CD4092C81C776DC4BC571221CA7A0CE4212F8DB8F23024350011550
              819F0B287F82315FD516527E00807BFA0000000049454E44AE426082}
          end>
      end
      item
        Name = 'down'
        SourceImages = <
          item
            Image.Data = {
              89504E470D0A1A0A0000000D4948445200000020000000200806000000737A7A
              F4000000017352474200AECE1CE90000000467414D410000B18F0BFC61050000
              00097048597300000EC300000EC301C76FA864000000CD494441545847ED8E5B
              0A02310C450B75250EAEC17F57E71A7CECD11FBFB5955C6933694DA5AD203910
              98C9A5B9C719C6B7F8CBF24887D6F33001133081E102FEB43DD0A7488BC0E6BA
              DBD3A79E70F45E93D00AC4F290DFE8570F1D2E4AA01843EB0C9497F22AC97151
              22C94581B45CCA3F8287342B09966705BC9CE72AD2C7349904CF692D96A7B91A
              7F5E8EFC4898B704CFE2AE541E6FC5BC999A04DF772F074589F5AE7F392848D4
              A757396892E85D0E5412A3CA415562743910256695834C6276397849FCAADCF8
              139C7B02FFDD53166C7603400000000049454E44AE426082}
          end>
      end
      item
        Name = 'save'
        SourceImages = <
          item
            Image.Data = {
              89504E470D0A1A0A0000000D4948445200000020000000200806000000737A7A
              F4000000017352474200AECE1CE90000000467414D410000B18F0BFC61050000
              00097048597300000EC300000EC301C76FA864000000EC494441545847ED8ED1
              490351140517ED24295B4BB183D881C5680E4C3CB23BFE3CBC289881F948CEF0
              EE6E776E3C3C9D5F1E9FCFEF7B9937DBBE4A76C0DAEBAD0B73B13032FFE80744
              E6625164FEDCF979E8F9FBC0BEBBC95C2C8ACCF70FF83B1FF09D6407AC8DCCC5
              A2C8FCFB1FB08ABD19998B459179197B3332178B26E56CB16852CE168B26E56C
              B16852CE168B26E56CB16852CE168B22F332F666642E1645E665ECCDC85C2C8A
              CCCBD89B91B958149997B1372373B128322F636F46E66251645EC6DE8CCCC5A2
              49395B2C9A94B3C5A249395B2C9A94B3C5A249395BAE7FBEEEA3394F6F9CFDF7
              6CDB070B04FFA3284ED8F60000000049454E44AE426082}
          end>
      end
      item
        Name = 'db'
        SourceImages = <
          item
            Image.Data = {
              89504E470D0A1A0A0000000D4948445200000020000000200806000000737A7A
              F4000000017352474200AECE1CE90000000467414D410000B18F0BFC61050000
              00097048597300000EC300000EC301C76FA864000006D5494441545847AD970D
              54936514C7EDCB4C4B4D941033528BF2E8D1B4237DFA8176CC3CA5651F66462A
              9A759010E31C8F951FA558A86928A21CCD30118D0F4DC48081A6030414954D40
              60B8B98D0D843936BEC6B677DBBF7BD1157A6263D63DE77F9E9DBDEF7BEFEFBD
              CF7DEEF3BC3DBA69F774D2BD77E8BE4EBAF39AF399BB32673076FC00A927E941
              522FD243A4DEA43E5D88AFF37DFCCCFD24274CB7CC199883F612277C3AFE4A5A
              58A8222B3C5E255A715A250A9728B342A535A2B0A61A512854992190A77FD65C
              7534585A95BA485A9A1424BE70605EC2E99DB356FCF24DE0CBE4A31F8961D91F
              FB75691CFCBE75CB67F7AFCA5CBE5A7B2AA2A6A168231ACB7E468BF2384C75A7
              60AE3F83761A85C642D88D45B01BF260ADCF84497E086DD5BFA2B97C37F4C551
              D0E4444096BA00257B676BB3374FDF3073B29F0FF9E68CB88460809EB505EB0B
              8C558721B45C8143D0C061BD06BBB912F63609ECCD14D428865D7F12B68674D8
              EA9261AB4980A08E874DB90F827C37AC576320906CF258982AA2A1CE0C43DED6
              A9E7C9775F124F6997C674BD2A5317C36137C261D3C261A982C35C0A47BB048E
              B6620228B805900D9BEE046CD78FC0A63D0C9B7A3F04E51E0ABA1342F5360855
              9B60AD8884B5EC5B1A37223FEA15906F2F124F4597F5C000BDCB9396C0A22BA6
              B727005B3DA996B2A020900ACA4209419C87BD290FF61B59B0D5A751165260D3
              50163487605331C83E1AE3292B07E9F74134154742FCC34406F026F1347409C0
              E9E9537A68118C97A261D18820B4AB60B3D6C12E90AC341D669A0E134D8D590E
              87494659A980A3450A73CD0998D5C7605625A3FD6A3C4C92AD68142D83267E3A
              5489EFE24C6447069C75E012E061E98120182EFE440059B09A94B05AAEC32AE8
              60312B6169CAA762DC8DE6AA30D49D980CF5C100C8624643F2DD08946C7C1AF2
              F889A8CFFC04FA8C25684899F737C09FDFBDDC6D804724F1F361B8B00D969A8C
              4E000DB700F260AA8D4553E5328F0072D6BEC400BE24EE252E01FA5EDC3B1786
              E21F6151A713C03502A8BB05700D16632E01C4A0A9E2738F00445F0730C01092
              4B00EE5AFD4EFF308300B6C0A24ABB1DA09D01C4306977C058BEC4238094CF47
              33C0E324B700FD13978C492CFF75215A2B0F128082006A09A09E001404708600
              A2612C5BD82D00C5AE29285C3301DB5FF74D24DF43496E011E3D1F1704F9EF11
              283DF019AEE4C44125CDC0F56B8568D416C2A84EC58DF2353048E7DF0670F6CB
              A1C85FE907C9967128DF350D97374D425ED848E42C1A8AE2C85791B6620267E0
              0912EF112E0106E46D7D0B46E92E581B0AD0DEACA2C097512BCB87FC5C126427
              235196361FE2A8E1C85AE68DF4A001487EA73F8E7EE08D231F0EC2A9707F4863
              A643BE7F2EB4C994A5A4F7A14E9A87A3A1E318C08FE416C04B1C3503FAA2EF61
              A6FECE352058751004038DF510DACA61694CA3428C46CB9575309C8F40C3C960
              2812DE803C6106B4E91F439FFB250C27C3A13B12D4A906C632C093249700DC26
              BD4EAD7F0DFAC2C80E004BAB8C6A40032B35234B7B352C861CB4AA22D158F2AE
              474598B4740C030C23B9051898BD662AF4051B6E0154D2F2D3C0420066023037
              8AD0AA5CE731C0E1E08E55309CC467857F05E03F19C0FB48E804E8CFAEEF04A0
              26805A98A9F59AF51977051037E729061841720BF0D8CE59C3124B7F9E8B163A
              07FC03A025804A02F8C32300E7325CFBC2205E864F915C02709FF611AD7D1DD5
              295FA074FF629467C74029398E3A451EF49A5C181407A0932E47E3A5DB01DC2D
              C35F3E1AC519F027F1E9C825C0E063612F5227DC4A279D7CB43729287009B432
              31AE1625A0327B35CA52DFA6EDF5498F96E1DEF7FD19E019925B00DFA321CF43
              97BBFA660DB455776C4682A0BFD9115B2530DF48F27819EE99D301F02CC92500
              B7C921294BC74127FEFA8E22BCBB1A7002EC9E3D82014692DC03FC163C9600BE
              FA5F0162DF1CEE04E0637B97001D537068C168E8CEACFA5F0176CC1CE62CC22E
              57011BB7E28171EFF99F3B1B3513864B71FF1940B63310C742C623E499472F91
              6FB7BB61C7A17482EF23FE1BA70D89D933EB095D6AC844E4C586A3F4442C94C5
              C9D05ED805957819F417E7FC0D50B5633472238641BC72388ABE7F1EB9918138
              1E1A80D8197E5833CE4BBFD4BFEF3EDFDE0F3C47BEF923C5E5B19CC9F8062E94
              8124BFB9A3FABFB9EA15EFCD1B26FBA46D99E223FD31D047B669924FF5F6A983
              EDD1530663DB241F6C99E863FF3660A07C5D80D7D5D5E3BD4AC3C70CC808F6EF
              B73DF0B15E1F900FAE7C3E09F13781CB237967E34CF0CD3C5FFC20C30C26710A
              7947E396CAF3C9CE59BCBE9F2671A7E37ECFFB3E1F400790B8E8B8B6F8C5BA15
              BCB33933C2B5C14E78FE78376330CE128B03F0C8FFB1F83ADFC72FC0CFF2CB78
              1CD895B1B3EECA8DF5E8F1170D26D93168735F8D0000000049454E44AE426082}
          end>
      end
      item
        Name = 'disconn.pnd'
        SourceImages = <
          item
            Image.Data = {
              89504E470D0A1A0A0000000D4948445200000020000000200806000000737A7A
              F4000000017352474200AECE1CE90000000467414D410000B18F0BFC61050000
              00097048597300000EC300000EC301C76FA864000007F2494441545847AD9709
              5494D715C74D138902268D0B146D6B41F0B8554D1323555164D381108450AA88
              ECA21628C5062446D942D42888800A621940822018564728B2282041D6C00C20
              44A82C03030C20C3C0B0CCF0CF7B53A0683DC7C178CFF99FEF3BDF7B73EFEFBB
              F7BEF7BE992783BD25A3DE984D3BFC15D1DB2FE89D17347B8CCEFF4530D2A03E
              4E1FC997455933AA63ACFD6AE36C13D837EC2A6BE36CAAD8B1363CF60D1BD412
              FD1863CDAB621EACAA242A8F3C90581ABEDFBF28F473C63FAD362A101FB36164
              B6B7B283CC1713E797EA131CFB5B73BF4177550C9E35A56384FB80281F63BD0F
              2119AC8064A004639DD9187A9288A1A638F02B42C0BDEF87C6EF5D511EB9BFBF
              38CC22E4DAF15D4B894F0A219351D2B7EBE2EDCBF8F5A99810B66072BC1D93A2
              279008D9900C5542F2EC21C4038590F0EF41D2C38284970671570AC4DC644C74
              DCC4445B1C269E4663B4291C9DF92751126A5E4E7CCE9FF2FD4AA393DE2909F9
              1C2432262778981CE6105591E065981CFC81001441D25F0049DF3D887BB320EE
              CE80B893022461A23D1E13ADB104E05F9868B98689E6ABC8FD9A01E2538E48A6
              2C5080F9C5C1A6981034615222241A02C609C828C902819108CA212620E2BE7C
              92856C48BA3321966681489A855B5290F16626061FF923C7D780022C20921940
              AE30D004CFAA42487DF3211EE3424201A8E8FD08011191D28C346352D840CA51
              8191FFA443D4721B234D5118E68462F0BE273A638DD076F32FC8F6D69B13009D
              2477FFBCF114402EC6473B303EDE8371528E31610D44DDB11034FD1DBCACDD68
              8BDB82C7C1EB50E5A30A76D07A74A498A02FC709FC546B7063F64A01B24EEA50
              808553BE5F6974D2BBF9678DDE18C01DAFDD7307C80D60BC31800C8F9D730760
              79EB9774E5FB42D496FDDA006D5106A8BDA88364B76D3F109FF253BE5F6974D2
              827F7B1BA023C707CD197E78FA80096E55067A1AF3D0DF92053E3B100375CE33
              00F5816B517AE2F7A8F87A353897B5C00ED143E9571FA1C0551D55E7B491E2B6
              8D66607A577CA551808577BFD2C5606D24C6BA8BF18C5B2905F829FB32AA992E
              280F35419EC75AB01C7E8374AB6548B35C0A968D12B20E2FC743EFCD608731F0
              F4C601F0922DC1FDDE16B79DB752004522D901585EDAB37A804B4AC027252065
              186EC028FF36844F7DC02FB440571A032D4C2D708236E371E47674DDB5425FBE
              1BF8E90E333D9074F4939701D0E54EF57F4627C9677AEC9A7313728237A1AF2C
              1082FA24086AE231F028121DA9479178F8630AB068CA370D4A5F72FAF4A4F7CF
              81D007F2E9C7B5E606E0A781D6BB5F825F1D8B6ACFBFA1D6D9096D2941E8ABFE
              0EA91E7B29C07B44D2633B71F7EE9D65870EF1583AFA594E6A6AEF9367D36052
              9366E096CB9F4BE7B20A9A935CD09E7F0915EE8EE8CD8EC6585D162AFE71048D
              37BF4511D3BF85F8FC35D182B8EDBBB48B9DEC4644B599E0A54722C3606FA1CD
              CA95746C0682DE28DC76D5947915D45D588B964C7F94B8D8A03BE33AC6CB5231
              961B8771360BA5CE8E280EF6A11950BAAAA9A957E8683B32569301615A384672
              A2D19E188A5BDBB432C8F8CC69490114938F7D22F32A4825AB8013EF8D1C1363
              0CDD8FC748E6750C9300C2F4088C56A5A3F8A81DAE6ED97AEABE83F588A83215
              83372FE259CC390C449F43CF774148D0DCC12331E9693903B028F1C816995741
              739416B8058168480CC01DD37D1848BB06C1AD100CC6079260411096DC4281FB
              B1496169120662CEA02FC217FC081F7486F9227ACB8EC1132AAB779098B43FA4
              00F4E6BD9B0E7F9A5313D65CD0243D70817C099D478A91217A62BF457F5400FA
              AEF9A22FD21FC21C267AC34FA3E7D20974079F40EB99E3607EBC6DD04345438B
              C49BFE56F85F06E26D37CF7919D64568A3B73A0A8F53495DF50DD01EEC05EE59
              57F0CEBBA38BA8F31B57B4791FC6132F47303FDC2A70535EA54D62D1637AA601
              A9499721F3E08647D5CC2310B6DC9119A036703DDA59F6E8A9494059D097C8B3
              34459B9F139A9C3E43D36163341235BBED07EBD33D9367D66C384EE2D0A5499B
              8FC69C314A2267FAC715BFBD62BE262AD672A3203BE0102A932EE0A7A2047471
              52C1AD20E9E5CC5A0581EB50E4A9860A72F0B41444A034C20FACBF9A81171D80
              4627633CB637C4633B4334D8FE576D415F2099B147E4A9AA614462D153F2B90C
              D01B4A44C914362A2B28F9E8AB9A071BAFBA18F6D9EA8C70130D36D575D3D5C3
              D7CD5623D25403E126EAC34CDBED0D79574E7393DC1D9A324C8DC5DDB167D1E0
              688C06EBBDA8B761A0E99839EAAC18A8B3D447BDF51EB4067A20414F57E4B552
              C390C4792904157D4841689DE8714AB753BA73D18DE303A2C5535A42B4EC8B95
              1AA629C646A2AEEBFEA8B73502C7D2009C837BC07630C38DAD9A93F52E07C03E
              408E680B1D72D5438B9F0BE2766A89DC57A8518877899E2B05B569103A404581
              A4DBE90BA25DAC7865EDA6AED6CBA7D1606308F67E5D223DD4DAEEC3E5759B04
              CE4B7FE716B6E14301E7A8056ACD755063BA136C72ADF774C4D93FACE922BF97
              F97B611A6AB628D8C2D3CAAB580F0E9991B7FF146C0B5DD4581B236CED2681DD
              E2E57A64FC03DBC52AFA61EB370BD8F666F8D14C9B80E8E19E911E4E29A9DE25
              E33203BCCC28C4FC358B162DF15551CFBB67CA40A5F53E127CA3C07EC9725D32
              463F46688A15284C18C948859509B20C76C15B45BD404D4141898CCDEC84AF6B
              945E4E5D5171D92925B5245F65F556C7252B74C833FA66B44C749C5EE529141D
              3FA9A496ACAAA0A04C9EBDB4FEAF63D4096D5A1A74FAAD677737BD5208DAD474
              9C6AD63FA679F37E06BEFCBC4E1303D5A00000000049454E44AE426082}
          end>
      end
      item
        Name = 'del'
        SourceImages = <
          item
            Image.Data = {
              89504E470D0A1A0A0000000D4948445200000020000000200806000000737A7A
              F4000000017352474200AECE1CE90000000467414D410000B18F0BFC61050000
              00097048597300000EC300000EC301C76FA86400000197494441545847ED97B1
              4AC35014863BB80B6EBE81A04BDA14B3058AAEEDE21C70EBD8B18B425FC1AD2F
              2242077D01916EBE84530B0E0EFAFDE544D3E486D8DC9608F6879F7BEEB9E7FC
              E73637E792B6F6F8F3E8743A87ED76BB0747D853C6197C856FF0C3285BBE99C5
              8C604FB926B339C2303C43E4063E23F45987CA9586B44CF677207900E759314F
              4A6B60F2D5B00497900FE7265F0D8217B9E46D7061F2D5E0DCDE1D025E94A6C9
              57A3F10D90D0EC1110DCF84BD8781B8EB93CFABA44E0362EA23EF3B1C95783E0
              05892F8C13922FB06B5DC5CA9506B6B46AB7E192F913BCC31EC24B781245D151
              1CC707A26CF96C6DA858E5602F61FA34F66DB86FC37FD486F00AFB58243F603E
              C0BE37F96A10ECDB86E7A6732BCAC69F6814B27E2758F46DC34405D279B65899
              7F0D2CFAB6610227599F8A658B1B2756721D2CF876C083E9AC6D224777718145
              AF36E4973E32AECE9CD1B589F2E229787B6B7F966B0341105C4BC7F1D8CBCFDE
              051236FE63D2ED764F95CBBC503CA5D65605760547711D45E1C5B4F0ED2357EC
              FBCCCBFC3B81152B14F9F1B75A5F3E1C65AEE8CEE1EC0000000049454E44AE42
              6082}
          end>
      end
      item
        Name = 'addexe'
        SourceImages = <
          item
            Image.Data = {
              89504E470D0A1A0A0000000D4948445200000020000000200806000000737A7A
              F4000000017352474200AECE1CE90000000467414D410000B18F0BFC61050000
              00097048597300000EC300000EC301C76FA8640000009D494441545847EDD331
              0E80200C8561CE67E2A58011AEC039BC0C938987D041F3926A5C34A574D0A47F
              D24DCA37A0B3ACCF1663DC1B67F6DE0F74BC3F2C6D09DFE79CB7528A0E4202A8
              B5EA212400A4869002900AA20780804829AD62442F009D08D1DF21013C4D0861
              A1B5FC70502BECA2B5FC0C60805F03463F5D830C6000446BF97101F7CBB84357
              BC6700AD3740EBDA0340326A809E0CC00738770068CD77065EAA0D8E00000000
              49454E44AE426082}
          end>
      end
      item
        Name = 'delexe'
        SourceImages = <
          item
            Image.Data = {
              89504E470D0A1A0A0000000D4948445200000020000000200806000000737A7A
              F4000000017352474200AECE1CE90000000467414D410000B18F0BFC61050000
              00097048597300000EC300000EC301C76FA86400000157494441545847ED94BB
              4AC4401486F36E195184F51D4C045BF182A0A090A44C5E21850B8B96ABA28F60
              6B9758A412ACB295A0A8459C7F3D83B9189D3999C2221F9C227326E7FF727546
              46FE2D51145586F51804C13A9D3E1C0C3501FB9324F948D3D48E0447A0280A7B
              121C01604D822B00AC480C11009088E3F89D2D3154002809D6D7C111E8AB300C
              9F68AC3E38D116984563F519054681518023F07C7F5795D7333A6A8299992F8E
              337F65B20CF80B5301843F6CAF55B92FAAF26A4AABDFE49E38452FF7DDB7CC13
              1B14D38FA9C0E2F66219AEAA2E51CECF1ABDDC737729A61FCE2358DC9C3782CA
              CB69275C5EFD3E45FC0E4700B425EAA51D0EB802E02709A3703044A0F3CCBFEA
              8446EBC115E80957A52F0101DD52745E385FECC9CFEFB0BE26CBEC4EE8829F4C
              3D08E1D472DA12F27D38A2963DB22DB12A435FDAE10A25217BAFD84BCB76C1E0
              7C53ECD06187CC730F9AE18EF309F56FD0508368865B0000000049454E44AE42
              6082}
          end>
      end>
    Left = 192
    Top = 514
  end
  object vrtlmglstButton: TVirtualImageList
    Images = <
      item
        CollectionIndex = 0
        CollectionName = 'up'
        Name = 'up'
      end
      item
        CollectionIndex = 1
        CollectionName = 'down'
        Name = 'down'
      end
      item
        CollectionIndex = 2
        CollectionName = 'save'
        Name = 'save'
      end
      item
        CollectionIndex = 3
        CollectionName = 'db'
        Name = 'db'
      end
      item
        CollectionIndex = 4
        CollectionName = 'disconn.pnd'
        Name = 'disconn.pnd'
      end
      item
        CollectionIndex = 5
        CollectionName = 'del'
        Name = 'del'
      end
      item
        CollectionIndex = 6
        CollectionName = 'addexe'
        Name = 'addexe'
      end
      item
        CollectionIndex = 7
        CollectionName = 'delexe'
        Name = 'delexe'
      end>
    ImageCollection = imgclctnButton
    Width = 32
    Height = 32
    Left = 192
    Top = 586
  end
  object UniConnection: TUniConnection
    AutoCommit = False
    SpecificOptions.Strings = (
      'SQL Server.ForceCreateDatabase=True'
      'SQL Server.Provider=prAuto'
      'SQL Server.ConnectionTimeout=15'
      'SQL Server.IPVersion=ivIPv4'
      'SQL Server.Authentication=auServer'
      'SQL Server.ApplicationIntent=aiReadWrite'
      'SQL Server.AutoTranslate=True'
      'SQL Server.MultipleConnections=True'
      'SQL Server.PacketSize=4096'
      'SQL Server.MultipleActiveResultSets=False'
      'SQL Server.HttpTrustServerCertificate=False'
      'SQL Server.PersistSecurityInfo=False'
      'SQL Server.MultiSubnetFailover=False'
      'SQL Server.TrustServerCertificate=False'
      'SQL Server.Encrypt=False')
    ConnectDialog = UniConnectDialog
    AfterConnect = UniConnectionAfterConnect
    AfterDisconnect = UniConnectionAfterDisconnect
    Left = 651
    Top = 413
  end
  object UniConnectDialog: TUniConnectDialog
    DatabaseLabel = #24211#21517#31216
    PortLabel = #31471#21475
    ProviderLabel = #25968#25454#24211#31867#22411
    SavePassword = True
    Caption = #25968#25454#24211#36830#25509
    UsernameLabel = #29992#25143#21517#31216
    PasswordLabel = #23494#30721
    ServerLabel = #26381#21153#22120'IP'
    ConnectButton = #36830#25509
    CancelButton = #21462#28040
    LabelSet = lsCustom
    Left = 651
    Top = 341
  end
  object SQLServerUniProvider1: TSQLServerUniProvider
    Left = 648
    Top = 543
  end
  object MySQLUniProvider1: TMySQLUniProvider
    Left = 1041
    Top = 543
  end
  object OracleUniProvider1: TOracleUniProvider
    Left = 779
    Top = 623
  end
  object ODBCUniProvider1: TODBCUniProvider
    Left = 649
    Top = 623
  end
  object DB2UniProvider1: TDB2UniProvider
    Left = 779
    Top = 543
  end
  object InterBaseUniProvider1: TInterBaseUniProvider
    Left = 910
    Top = 543
  end
  object PostgreSQLUniProvider1: TPostgreSQLUniProvider
    Left = 910
    Top = 623
  end
  object dlgOpenLoginCheck: TOpenDialog
    Filter = 'DLL(*.DLL)|*.DLL'
    Left = 1140
    Top = 449
  end
end
