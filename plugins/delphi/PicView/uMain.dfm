object frmPicView: TfrmPicView
  Left = 0
  Top = 0
  Caption = #30475#22270#36719#20214' PicView 2.0'
  ClientHeight = 800
  ClientWidth = 1280
  Color = 1579032
  Font.Charset = GB2312_CHARSET
  Font.Color = clWhite
  Font.Height = -12
  Font.Name = #23435#20307
  Font.Style = []
  KeyPreview = True
  Position = poScreenCenter
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  OnKeyDown = FormKeyDown
  OnMouseWheel = FormMouseWheel
  OnShow = FormShow
  TextHeight = 12
  object MenuMain: TActionMainMenuBar
    Left = 0
    Top = 0
    Width = 1280
    Height = 26
    UseSystemFont = False
    ActionManager = ActionManager1
    Caption = 'MenuMain'
    ColorMap.HighlightColor = clBtnHighlight
    ColorMap.UnusedColor = clWhite
    ColorMap.MenuColor = clMenu
    Font.Charset = GB2312_CHARSET
    Font.Color = clWindowText
    Font.Height = -16
    Font.Name = #23435#20307
    Font.Style = []
    ParentBiDiMode = False
    Spacing = 0
    ExplicitHeight = 25
  end
  object PanelToolBarHost: TPanel
    Left = 0
    Top = 26
    Width = 1280
    Height = 34
    Align = alTop
    BevelOuter = bvNone
    TabOrder = 0
    ExplicitTop = 25
    object ToolBarBrowse: TToolBar
      Left = 0
      Top = 0
      Width = 1280
      Height = 34
      Align = alClient
      ButtonHeight = 20
      ButtonWidth = 85
      Caption = 'ToolBarBrowse'
      ParentShowHint = False
      ShowCaptions = True
      ShowHint = True
      TabOrder = 0
      object tbBOpenFolder: TToolButton
        Left = 0
        Top = 0
        Action = actOpenFolder
      end
      object tbBOpenFile: TToolButton
        Left = 85
        Top = 0
        Action = actOpenFile
      end
      object tbBNewTab: TToolButton
        Left = 170
        Top = 0
        Action = actNewBrowseTab
      end
      object tbBSep1: TToolButton
        Left = 255
        Top = 0
        Width = 8
        Style = tbsSeparator
      end
      object tbBComputer: TToolButton
        Left = 263
        Top = 0
        Action = actComputer
      end
      object tbBUp: TToolButton
        Left = 348
        Top = 0
        Action = actGoUp
      end
      object tbBRefresh: TToolButton
        Left = 433
        Top = 0
        Action = actRefresh
      end
      object tbBSep2: TToolButton
        Left = 518
        Top = 0
        Width = 8
        Style = tbsSeparator
      end
      object tbBSmaller: TToolButton
        Left = 526
        Top = 0
        Action = actThumbSmaller
      end
      object tbBBigger: TToolButton
        Left = 611
        Top = 0
        Action = actThumbBigger
      end
      object tbBSep3: TToolButton
        Left = 696
        Top = 0
        Width = 8
        Style = tbsSeparator
      end
      object tbBView: TToolButton
        Left = 704
        Top = 0
        Action = actViewSelected
      end
      object tbBSep4: TToolButton
        Left = 789
        Top = 0
        Width = 8
        Style = tbsSeparator
      end
      object tbBClose: TToolButton
        Left = 797
        Top = 0
        Action = actCloseTab
      end
      object tbBSep5: TToolButton
        Left = 882
        Top = 0
        Width = 8
        Style = tbsSeparator
      end
      object tbBAbout: TToolButton
        Left = 890
        Top = 0
        Action = actAbout
      end
    end
    object ToolBarView: TToolBar
      Left = 0
      Top = 0
      Width = 1280
      Height = 34
      Align = alClient
      ButtonHeight = 20
      ButtonWidth = 79
      Caption = 'ToolBarView'
      Color = 2105376
      ParentColor = False
      ParentShowHint = False
      ShowCaptions = True
      ShowHint = True
      TabOrder = 1
      Visible = False
      object tbVBack: TToolButton
        Left = 0
        Top = 0
        Action = actBackToBrowse
      end
      object tbVPrev: TToolButton
        Left = 79
        Top = 0
        Action = actPrev
      end
      object tbVNext: TToolButton
        Left = 158
        Top = 0
        Action = actNext
      end
      object tbVSep1: TToolButton
        Left = 237
        Top = 0
        Width = 8
        Style = tbsSeparator
      end
      object tbVFit: TToolButton
        Left = 245
        Top = 0
        Action = actFit
      end
      object tbVActual: TToolButton
        Left = 324
        Top = 0
        Action = actActual
      end
      object tbVZoomIn: TToolButton
        Left = 403
        Top = 0
        Action = actZoomIn
      end
      object tbVZoomOut: TToolButton
        Left = 482
        Top = 0
        Action = actZoomOut
      end
      object tbVSep2: TToolButton
        Left = 561
        Top = 0
        Width = 8
        Style = tbsSeparator
      end
      object tbVRotateCW: TToolButton
        Left = 569
        Top = 0
        Action = actRotateCW
      end
      object tbVRotateCCW: TToolButton
        Left = 648
        Top = 0
        Action = actRotateCCW
      end
      object tbVSep3: TToolButton
        Left = 727
        Top = 0
        Width = 8
        Style = tbsSeparator
      end
      object tbVSlide: TToolButton
        Left = 735
        Top = 0
        Action = actSlideShow
      end
      object tbVFull: TToolButton
        Left = 814
        Top = 0
        Action = actFullScreen
        Visible = False
      end
      object tbVSep4: TToolButton
        Left = 893
        Top = 0
        Width = 8
        Style = tbsSeparator
      end
      object tbVSaveAs: TToolButton
        Left = 901
        Top = 0
        Action = actSaveAs
      end
      object tbVDelete: TToolButton
        Left = 980
        Top = 0
        Action = actDelete
      end
      object tbVSep5: TToolButton
        Left = 1059
        Top = 0
        Width = 8
        Style = tbsSeparator
      end
      object tbVClose: TToolButton
        Left = 1067
        Top = 0
        Action = actCloseTab
      end
      object tbVSep6: TToolButton
        Left = 1146
        Top = 0
        Width = 8
        Style = tbsSeparator
      end
      object tbVAbout: TToolButton
        Left = 1154
        Top = 0
        Action = actAbout
      end
    end
  end
  object PanelTabs: TPanel
    Left = 0
    Top = 60
    Width = 1280
    Height = 36
    Align = alTop
    BevelOuter = bvNone
    TabOrder = 1
    ExplicitTop = 59
    object PageControl1: TPageControl
      Left = 0
      Top = 0
      Width = 1280
      Height = 36
      Align = alClient
      OwnerDraw = True
      PopupMenu = PopupMenuTabs
      TabOrder = 0
      OnChange = PageControl1Change
      OnDrawTab = PageControl1DrawTab
      OnMouseDown = PageControl1MouseDown
    end
  end
  object PanelAddress: TPanel
    Left = 0
    Top = 96
    Width = 1280
    Height = 24
    Align = alTop
    BevelOuter = bvNone
    TabOrder = 2
    ExplicitTop = 95
    ExplicitWidth = 624
    object btnGo: TButton
      Left = 1184
      Top = 0
      Width = 48
      Height = 24
      Action = actGo
      Align = alRight
      TabOrder = 0
    end
    object btnUp: TButton
      Left = 1232
      Top = 0
      Width = 48
      Height = 24
      Action = actGoUp
      Align = alRight
      Caption = #19978#32423
      TabOrder = 1
    end
    object cbPath: TComboBox
      Left = 0
      Top = 0
      Width = 1184
      Height = 24
      Align = alClient
      Font.Charset = GB2312_CHARSET
      Font.Color = clWhite
      Font.Height = -16
      Font.Name = #23435#20307
      Font.Style = []
      ParentFont = False
      TabOrder = 2
      OnKeyPress = cbPathKeyPress
      ExplicitWidth = 528
    end
  end
  object PanelBody: TPanel
    Left = 0
    Top = 120
    Width = 1280
    Height = 657
    Align = alClient
    BevelOuter = bvNone
    TabOrder = 3
    ExplicitTop = 119
    ExplicitHeight = 658
    object Splitter2: TSplitter
      Left = 1030
      Top = 0
      Width = 5
      Height = 657
      Align = alRight
      Beveled = True
      MinSize = 150
      ResizeStyle = rsUpdate
      ExplicitHeight = 681
    end
    object PanelRight: TPanel
      Left = 1035
      Top = 0
      Width = 245
      Height = 657
      Align = alRight
      BevelOuter = bvNone
      TabOrder = 1
      ExplicitHeight = 658
      object PanelRightHead: TPanel
        Left = 0
        Top = 0
        Width = 245
        Height = 24
        Align = alTop
        Alignment = taLeftJustify
        BevelOuter = bvNone
        Caption = ' '#24403#21069#22270#20687#26694
        Font.Charset = GB2312_CHARSET
        Font.Color = clWhite
        Font.Height = -12
        Font.Name = #23435#20307
        Font.Style = [fsBold]
        ParentFont = False
        TabOrder = 0
      end
      object vleInfo: TValueListEditor
        Left = 0
        Top = 24
        Width = 245
        Height = 634
        Align = alClient
        DisplayOptions = [doColumnTitles, doAutoColResize]
        Strings.Strings = (
          #25991#20214#21517'='
          #26684#24335'='
          #23610#23544'='
          #22823#23567'='
          #20462#25913#26102#38388'='
          #26059#36716'='
          #24103#25968'='
          #25991#20214#22841'=')
        TabOrder = 1
        TitleCaptions.Strings = (
          #39033#30446
          #20540)
        Visible = False
        ColWidths = (
          119
          120)
      end
    end
    object PanelCenter: TPanel
      Left = 0
      Top = 0
      Width = 1030
      Height = 657
      Align = alClient
      BevelOuter = bvNone
      TabOrder = 0
      ExplicitHeight = 658
      object PanelBrowse: TPanel
        Left = 0
        Top = 0
        Width = 1030
        Height = 657
        Align = alClient
        BevelOuter = bvNone
        TabOrder = 0
        ExplicitHeight = 658
        object PanelBrowseHead: TPanel
          Left = 0
          Top = 0
          Width = 1030
          Height = 30
          Align = alTop
          BevelOuter = bvNone
          TabOrder = 0
          object LabelThumbs: TLabel
            Left = 8
            Top = 8
            Width = 36
            Height = 12
            Caption = #32553#30053#22270
          end
          object LabelSort: TLabel
            Left = 150
            Top = 8
            Width = 30
            Height = 12
            Caption = #25490#24207':'
          end
          object LabelCount: TLabel
            Left = 300
            Top = 8
            Width = 66
            Height = 12
            Caption = #20849' 0 '#24352#22270#20687
          end
          object LabelBrowseHint: TLabel
            Left = 460
            Top = 8
            Width = 246
            Height = 12
            Caption = #21452#20987#36827#20837#23376#30446#24405', '#39'..'#36820#22238#19978#32423', '#21452#20987#22270#20687#26597#30475
            Font.Charset = GB2312_CHARSET
            Font.Color = clWhite
            Font.Height = -12
            Font.Name = #23435#20307
            Font.Style = []
            ParentFont = False
          end
          object cbThumbSize: TComboBox
            Left = 62
            Top = 4
            Width = 72
            Height = 20
            Style = csDropDownList
            ItemIndex = 2
            TabOrder = 0
            Text = '128'
            OnChange = cbThumbSizeChange
            Items.Strings = (
              '64'
              '96'
              '128'
              '160'
              '192')
          end
          object cbSort: TComboBox
            Left = 190
            Top = 4
            Width = 96
            Height = 20
            Style = csDropDownList
            ItemIndex = 0
            TabOrder = 1
            Text = #25991#20214#21517
            OnChange = cbSortChange
            Items.Strings = (
              #25991#20214#21517
              #22823#23567
              #20462#25913#26102#38388
              #31867#22411)
          end
        end
        object lvBrowse: TVirtualStringTree
          Left = 0
          Top = 30
          Width = 1030
          Height = 627
          Align = alClient
          Color = 2105636
          DefaultNodeHeight = 16
          Header.AutoSizeIndex = 0
          Header.Height = 12
          Header.MainColumn = -1
          ParentShowHint = False
          PopupMenu = PopupMenuBrowse
          ShowHint = True
          TabOrder = 1
          OnBeforeCellPaint = VTListPaintCell
          OnDblClick = lvBrowseDblClick
          OnGetHint = VTGetHint
          OnKeyDown = VTListKeyDown
          OnMouseDown = lvBrowseMouseDown
          OnResize = VTListResize
          Touch.InteractiveGestures = [igPan, igPressAndTap]
          Touch.InteractiveGestureOptions = [igoPanSingleFingerHorizontal, igoPanSingleFingerVertical, igoPanInertia, igoPanGutter, igoParentPassthrough]
          ExplicitHeight = 628
          Columns = <>
        end
      end
      object PanelView: TPanel
        Left = 0
        Top = 0
        Width = 1030
        Height = 657
        Align = alClient
        BevelOuter = bvNone
        TabOrder = 1
        Visible = False
        ExplicitHeight = 658
        object Splitter3: TSplitter
          Left = 0
          Top = 492
          Width = 1030
          Height = 5
          Cursor = crVSplit
          Align = alBottom
          Beveled = True
          MinSize = 80
          ResizeStyle = rsUpdate
          ExplicitTop = 516
          ExplicitWidth = 795
        end
        object ScrollBoxViewer: TScrollBox
          Left = 0
          Top = 0
          Width = 1030
          Height = 492
          HorzScrollBar.Tracking = True
          VertScrollBar.Tracking = True
          Align = alClient
          BevelOuter = bvNone
          BorderStyle = bsNone
          DoubleBuffered = True
          Color = 2105376
          ParentColor = False
          ParentDoubleBuffered = False
          PopupMenu = PopupMenuView
          TabOrder = 0
          OnMouseDown = ImageMainMouseDown
          OnMouseMove = ImageMainMouseMove
          OnMouseUp = ImageMainMouseUp
          OnMouseWheel = FormMouseWheel
          OnResize = ScrollBoxViewerResize
          ExplicitHeight = 493
          object ImageMain: TImage
            Left = 0
            Top = 0
            Width = 1
            Height = 1
            Cursor = crHandPoint
            AutoSize = True
            PopupMenu = PopupMenuView
            OnDblClick = ImageMainDblClick
            OnMouseDown = ImageMainMouseDown
            OnMouseMove = ImageMainMouseMove
            OnMouseUp = ImageMainMouseUp
          end
        end
        object PanelThumbs: TPanel
          Left = 0
          Top = 497
          Width = 1030
          Height = 130
          Align = alBottom
          BevelOuter = bvNone
          TabOrder = 1
          ExplicitTop = 498
          object PanelThumbsHead: TPanel
            Left = 0
            Top = 0
            Width = 1030
            Height = 24
            Align = alTop
            BevelOuter = bvNone
            TabOrder = 0
            object LabelFilm: TLabel
              Left = 8
              Top = 5
              Width = 84
              Height = 12
              Caption = #21516#25991#20214#22841#32553#30053#22270
            end
            object LabelFilmCount: TLabel
              Left = 150
              Top = 5
              Width = 90
              Height = 12
              Caption = #21516#25991#20214#22841#20849' 0 '#24352
            end
          end
          object lvThumbs: TVirtualStringTree
            Left = 0
            Top = 24
            Width = 1030
            Height = 106
            Align = alClient
            Color = 2105636
            DefaultNodeHeight = 16
            Header.AutoSizeIndex = 0
            Header.Height = 12
            Header.MainColumn = -1
            ParentShowHint = False
            PopupMenu = PopupMenuThumbs
            ShowHint = True
            TabOrder = 1
            OnBeforeCellPaint = VTListPaintCell
            OnGetHint = VTGetHint
            OnKeyDown = VTListKeyDown
            OnResize = VTListResize
            Touch.InteractiveGestures = [igPan, igPressAndTap]
            Touch.InteractiveGestureOptions = [igoPanSingleFingerHorizontal, igoPanSingleFingerVertical, igoPanInertia, igoPanGutter, igoParentPassthrough]
            Columns = <>
          end
        end
        object PanelHint: TPanel
          Left = 0
          Top = 627
          Width = 1030
          Height = 30
          Align = alBottom
          BevelOuter = bvNone
          Color = 1579032
          Font.Charset = GB2312_CHARSET
          Font.Color = clWhite
          Font.Height = -16
          Font.Name = #23435#20307
          Font.Style = []
          ParentBackground = False
          ParentFont = False
          TabOrder = 2
          Visible = False
          ExplicitTop = 628
        end
      end
    end
  end
  object StatusBar1: TStatusBar
    Left = 0
    Top = 777
    Width = 1280
    Height = 23
    Panels = <
      item
        Width = 160
      end
      item
        Width = 220
      end
      item
        Width = 120
      end
      item
        Width = 160
      end
      item
        Width = 50
      end>
  end
  object ImageCollection1: TImageCollection
    Images = <
      item
        Name = 'doc'
        SourceImages = <
          item
            Image.Data = {
              89504E470D0A1A0A0000000D4948445200000020000000200806000000737A7A
              F40000008149444154789C63601805231D30E29278FDE1C77F6A5A242AC081D5
              2E267A588ECF4C465C0A4B97DCA3AA03BA6394B0860413C30003A611EF001642
              21303F5B93A2404A9C7A7D88874022011F500A98686AFA5070000B2105A38930
              713411D218B01052309A08134713E1702F8A19E9D528C5D532662256212D2C1F
              05A300140200D96425A1DAC2423C0000000049454E44AE426082}
          end>
      end
      item
        Name = 'flip'
        SourceImages = <
          item
            Image.Data = {
              89504E470D0A1A0A0000000D4948445200000020000000200806000000737A7A
              F4000000B749444154789CED57DB0DC3200CB42DA6E8389924A36512C6C91AA9
              FA574532F6D9505A95FB75EE01E6118816FE1D1C21D5E3BCB4DAB63F204DEE65
              1C0DC2BD8DD1101C317F17D6C27967A020E6687F3D9051E62FBEA775E211CB8C
              DC0A512C52C6DCC32D51F1ACB11AA026461F99AD82127A19438BB085ECD6149A
              0C5901E8DB5AB0392E9AA1013E0DD60ABD8E634B475091A8B906D10AF7B46808
              EF75CEA8504B2CF23D5B0134512FACF5C33FF1573CF25DB040B3F104E00E60F1
              7F6ED9B70000000049454E44AE426082}
          end>
      end
      item
        Name = 'nav'
        SourceImages = <
          item
            Image.Data = {
              89504E470D0A1A0A0000000D4948445200000020000000200806000000737A7A
              F40000009549444154789CEDD7B10D80300C445173CA64CC44C108299889D540
              29902863DF596E7235E13FA58BD9DADAC4CEFB7A2C69A846C0F3710602DE036A
              0422870642050173588100FB03160116C022A0003008A800510494800FE18140
              0DF8434A01B30858E2FA7E6C65803E111F6B55E1941BE8CEB8141089CB00D1B8
              04C0C469001B1F6B55E1F00D7461DC0D50C7A797F92E58B3EABD95E239F86346
              87C60000000049454E44AE426082}
          end>
      end
      item
        Name = 'panel'
        SourceImages = <
          item
            Image.Data = {
              89504E470D0A1A0A0000000D4948445200000020000000200806000000737A7A
              F40000006549444154789C63601805231D30A20BEC3B71E73F2D2D74B25041B1
              93896180010BB12EA514E00A59268601064CA30E6018E951C048EF72003D8731
              318CB472C069B095844CA30E60188D8201064CA30E60188D82C15A17ECA343AD
              0802039E0646C12800006F76143536EC45320000000049454E44AE426082}
          end>
      end
      item
        Name = 'play'
        SourceImages = <
          item
            Image.Data = {
              89504E470D0A1A0A0000000D4948445200000020000000200806000000737A7A
              F4000000BC49444154789CED97410EC2300C04E3553E060F6AAFE50570A50FA2
              4F03718D6A92756C2244F71A79679A544A9BD2917F8F5886A6C7F2D4D6D6F38D
              EA142FB05544BCC1AC0822E12DF38884B7F4201A5EEB83A5EC7EBA760B7D1498
              1A9EDE22B1D70BBAA590E8DD0D789C3D2351F6838579488408588F0429208C44
              F686CFDB65DC0ECC24FC9D3C0AACEEC04ADEE72CBCECCFD47407588B7CEB32D2
              76176970A02DB0EF422D5A1F2C435EF0AA8087446D5E7EE2AB38F2BFE0481A9D
              17D8E751DD3E27F18C0000000049454E44AE426082}
          end>
      end
      item
        Name = 'sort'
        SourceImages = <
          item
            Image.Data = {
              89504E470D0A1A0A0000000D4948445200000020000000200806000000737A7A
              F40000005249444154789C63601805A360148C74C0884FF2F5898AFFC418226A
              D181D71C7C8089618001D3403B60148C02466A64434AB225D340C701D3403B60
              140CCF5C404AAE60621860C034D00E1805A360148C020065AB0C1095C1021900
              00000049454E44AE426082}
          end>
      end
      item
        Name = 'stop'
        SourceImages = <
          item
            Image.Data = {
              89504E470D0A1A0A0000000D4948445200000020000000200806000000737A7A
              F4000000B449444154789CED964D1240300C852B37AA53B1E324EC381547623A
              63613A1149C47FDFD6EBFBDE94643897F477655B0F86AA982C4179DBA32CB802
              4E65C215702A1BDCCD825715F04D67E25115F04B3005E07854057C148801381E
              7581B12E492006C3CEA80B50258EC083441F212758021717D80348E1AA02D602
              E901CE187E7B11C5EF7C6F444F5944416BF09112C031C5000CC8F1A80BAC0339
              63F8ED45642D785C817CE3EFD5425836708D67C09392C20DCCD01C56300CC290
              4B0000000049454E44AE426082}
          end>
      end
      item
        Name = 'zoom'
        SourceImages = <
          item
            Image.Data = {
              89504E470D0A1A0A0000000D4948445200000020000000200806000000737A7A
              F4000000C649444154789CED964B0EC330084461EED0B5EF7F2CD63D44BA8D22
              DBFC13A9EDEC1299E141706CA2BF7E5DEC0D10791FB3F763BCB815401689B320
              5C95380AC2DEE42B63CF5A13805C0CAD1579E350FD5DBD3300AD8AC8749F63B4
              19023D2C5457EFED02A2093463AB904D9E854026F9EAB91D604C66230A814850
              250476C69AE10EC2BA9BE025F6405804CDD462B6ABB0E42C9024C463C7B1058E
              E986BFDD0E82BBAE64D6EEB1154003B1EE86EB3AA6666910E806D03A836E8019
              44E69E9152D58EA2AFD2074AFD8829F1923B880000000049454E44AE426082}
          end>
      end>
    Left = 808
    Top = 288
  end
  object VirtualImageList1: TVirtualImageList
    Images = <>
    ImageCollection = ImageCollection1
    Width = 32
    Height = 32
    Left = 808
    Top = 208
  end
  object ActionManager1: TActionManager
    ActionBars = <
      item
        Items = <
          item
            Items = <
              item
                Tag = 3
                Action = actOpenFolder
                Caption = #25171#24320#25991#20214#22841'(&O)...'
                ImageName = 'doc'
                ShortCut = 16463
              end
              item
                Tag = 1
                Action = actComputer
                Caption = #35745#31639#26426'(&P)'
                ImageName = 'doc'
              end
              item
                Tag = 3
                Action = actOpenFile
                Caption = #25171#24320#22270#29255'(&Q)...'
                ImageName = 'doc'
                ShortCut = 24655
              end
              item
                Tag = 3
                Action = actNewBrowseTab
                Caption = #26032#24314#27983#35272#39029#31614'(&R)'
                ImageName = 'doc'
                ShortCut = 16468
              end
              item
                Caption = '-'
              end
              item
                Tag = 2
                Action = actSaveAs
                Caption = #21478#23384#20026'(&S)...'
                ImageName = 'doc'
                ShortCut = 16467
              end
              item
                Tag = 2
                Action = actCopyImage
                Caption = #22797#21046#22270#20687'(&T)'
                ImageName = 'doc'
                ShortCut = 24643
              end
              item
                Tag = 3
                Action = actCopyPath
                Caption = #22797#21046#25991#20214#36335#24452'(&U)'
                ImageName = 'doc'
              end
              item
                Tag = 3
                Action = actExplore
                Caption = #22312#36164#28304#31649#29702#22120#20013#26174#31034'(&V)'
                ImageName = 'nav'
              end
              item
                Caption = '-'
              end
              item
                Tag = 3
                Action = actDelete
                Caption = #21024#38500#21040#22238#25910#31449'(&W)'
                ImageName = 'stop'
                ShortCut = 16430
              end
              item
                Tag = 2
                Action = actBackToBrowse
                Caption = #36820#22238#27983#35272#27169#24335'(&X)'
                ImageName = 'nav'
              end
              item
                Caption = '-'
              end
              item
                Tag = 3
                Action = actExit
                Caption = #36864#20986'(&Z)'
                ImageName = 'stop'
              end>
            Tag = 3
            Caption = #25991#20214'(&F)'
          end
          item
            Items = <
              item
                Tag = 3
                Action = actRefresh
                Caption = #21047#26032'(&K)'
                ImageName = 'zoom'
                ShortCut = 116
              end
              item
                Tag = 1
                Action = actGoUp
                Caption = #19978#32423#25991#20214#22841'(&L)'
                ImageName = 'nav'
              end
              item
                Tag = 1
                Action = actViewSelected
                Caption = #22312#26032#39029#31614#26597#30475'(&M)'
                ImageName = 'nav'
              end
              item
                Caption = '-'
              end
              item
                Items = <
                  item
                    Tag = 1
                    Action = actSize64
                    Caption = '&64 x 64'
                    ImageName = 'zoom'
                  end
                  item
                    Tag = 1
                    Action = actSize96
                    Caption = '&96 x 96'
                    ImageName = 'zoom'
                  end
                  item
                    Tag = 1
                    Action = actSize128
                    Caption = '&128 x 128'
                    ImageName = 'zoom'
                  end
                  item
                    Tag = 1
                    Action = actSize160
                    Caption = '16&0 x 160'
                    ImageName = 'zoom'
                  end
                  item
                    Tag = 1
                    Action = actSize192
                    Caption = '19&2 x 192'
                    ImageName = 'zoom'
                  end>
                Tag = 1
                Caption = #32553#30053#22270#22823#23567'(&Z)'
              end
              item
                Items = <
                  item
                    Tag = 1
                    Action = actSortName
                    Caption = #25353#21517#31216'(&W)'
                    ImageName = 'sort'
                  end
                  item
                    Tag = 1
                    Action = actSortSize
                    Caption = #25353#22823#23567'(&X)'
                    ImageName = 'sort'
                  end
                  item
                    Tag = 1
                    Action = actSortDate
                    Caption = #25353#20462#25913#26102#38388'(&Y)'
                    ImageName = 'sort'
                  end
                  item
                    Tag = 1
                    Action = actSortType
                    Caption = #25353#25991#20214#31867#22411'(&Z)'
                    ImageName = 'sort'
                  end>
                Tag = 1
                Caption = #25490#24207#26041#24335'(&Y)'
              end
              item
                Caption = '-'
              end
              item
                Tag = 2
                Action = actFit
                Caption = #36866#24212#31383#21475'(&N)'
                ImageName = 'zoom'
                ShortCut = 16432
              end
              item
                Tag = 2
                Action = actActual
                Caption = #23454#38469#22823#23567' 1:1(&1)'
                ImageName = 'zoom'
                ShortCut = 16433
              end
              item
                Tag = 2
                Action = actZoomIn
                Caption = #25918#22823'(&O)'
                ImageName = 'zoom'
                ShortCut = 16571
              end
              item
                Tag = 2
                Action = actZoomOut
                Caption = #32553#23567'(&P)'
                ImageName = 'zoom'
                ShortCut = 16573
              end
              item
                Caption = '-'
              end
              item
                Tag = 2
                Action = actRotateCW
                Caption = #39034#26102#38024#26059#36716'(&Q)'
                ImageName = 'flip'
                ShortCut = 16466
              end
              item
                Tag = 2
                Action = actRotateCCW
                Caption = #36870#26102#38024#26059#36716'(&R)'
                ImageName = 'flip'
                ShortCut = 16460
              end
              item
                Caption = '-'
              end
              item
                Tag = 2
                Action = actPrev
                Caption = #19978#19968#24352'(&S)'
                ImageName = 'nav'
              end
              item
                Tag = 2
                Action = actNext
                Caption = #19979#19968#24352'(&T)'
                ImageName = 'nav'
              end
              item
                Tag = 2
                Action = actFirst
                Caption = #31532#19968#24352'(&U)'
                ImageName = 'nav'
              end
              item
                Tag = 2
                Action = actLast
                Caption = #26368#21518#19968#24352'(&V)'
                ImageName = 'nav'
              end
              item
                Caption = '-'
              end
              item
                Tag = 2
                Action = actSlideShow
                Caption = #24187#28783#29255#25773#25918'(&W)'
                ImageName = 'play'
                ShortCut = 117
              end
              item
                Visible = False
                Tag = 2
                Action = actFullScreen
                Caption = #20840#23631#27983#35272'(&X)'
                ImageName = 'play'
                ShortCut = 122
              end>
            Tag = 3
            Caption = #26597#30475'(&V)'
          end
          item
            Items = <
              item
                Tag = 2
                Action = actShowThumbs
                Caption = #32553#30053#22270#26465'(&X)'
                ImageName = 'panel'
              end
              item
                Tag = 2
                Action = actShowInfo
                Caption = #22270#20687#20449#24687#38754#26495'(&Y)'
                ImageName = 'panel'
              end
              item
                Tag = 3
                Action = actShowStatus
                Caption = #29366#24577#26639'(&Z)'
                ImageName = 'panel'
              end>
            Tag = 3
            Caption = #38754#26495'(&P)'
          end
          item
            Items = <
              item
                Tag = 3
                Action = actNewBrowseTab
                Caption = #26032#24314#27983#35272#39029#31614'(&W)'
                ImageName = 'doc'
                ShortCut = 16468
              end
              item
                Tag = 3
                Action = actCloseTab
                Caption = #20851#38381#24403#21069#39029#31614'(&X)'
                ImageName = 'stop'
                ShortCut = 16471
              end
              item
                Tag = 3
                Action = actCloseOthers
                Caption = #20851#38381#20854#20182#39029#31614'(&Y)'
                ImageName = 'stop'
              end
              item
                Tag = 3
                Action = actCloseAll
                Caption = #20851#38381#25152#26377#39029#31614'(&Z)'
                ImageName = 'stop'
              end>
            Tag = 3
            Caption = #39029#31614'(&T)'
          end
          item
            Items = <
              item
                Tag = 3
                Action = actAbout
                Caption = #20851#20110'(&Z)...'
                ImageName = 'panel'
                ShortCut = 112
              end>
            Tag = 3
            Caption = #24110#21161'(&H)'
          end>
        Tag = 3
        ActionBar = MenuMain
        AutoSize = False
      end>
    Images = VirtualImageList1
    Left = 320
    Top = 184
    StyleName = 'Standard'
    object actOpenFolder: TAction
      Category = #25991#20214
      Caption = #25171#24320#25991#20214#22841'...'
      Hint = #25171#24320#25991#20214#22841' (Ctrl+O)'
      ImageName = 'doc'
      ShortCut = 16463
      OnExecute = actOpenFolderExecute
    end
    object actOpenFile: TAction
      Category = #25991#20214
      Caption = #25171#24320#22270#29255'...'
      Hint = #25171#24320#22270#29255#24182#26032#24314#26597#30475#39029#31614
      ImageName = 'doc'
      ShortCut = 24655
      OnExecute = actOpenFileExecute
    end
    object actNewBrowseTab: TAction
      Category = #39029#31614
      Caption = #26032#24314#27983#35272#39029#31614
      Hint = #26032#24314#27983#35272#39029#31614' (Ctrl+T)'
      ImageName = 'doc'
      ShortCut = 16468
      OnExecute = actNewBrowseTabExecute
    end
    object actCloseTab: TAction
      Category = #39029#31614
      Caption = #20851#38381#24403#21069#39029#31614
      Hint = #20851#38381#24403#21069#39029#31614' (Ctrl+W)'
      ImageName = 'stop'
      ShortCut = 16471
      OnExecute = actCloseTabExecute
    end
    object actCloseOthers: TAction
      Category = #39029#31614
      Caption = #20851#38381#20854#20182#39029#31614
      ImageName = 'stop'
      OnExecute = actCloseOthersExecute
    end
    object actCloseAll: TAction
      Category = #39029#31614
      Caption = #20851#38381#25152#26377#39029#31614
      ImageName = 'stop'
      OnExecute = actCloseAllExecute
    end
    object actExit: TAction
      Category = #25991#20214
      Caption = #36864#20986
      Hint = #36864#20986#31243#24207
      ImageName = 'stop'
      OnExecute = actExitExecute
    end
    object actRefresh: TAction
      Category = #27983#35272
      Caption = #21047#26032
      Hint = #21047#26032#24403#21069#25991#20214#22841' (F5)'
      ImageName = 'zoom'
      ShortCut = 116
      OnExecute = actRefreshExecute
    end
    object actViewSelected: TAction
      Category = #27983#35272
      Caption = #22312#26032#39029#31614#26597#30475
      Hint = #21452#20987#32553#30053#22270#25110#25353' Enter'#65292#22312#26032#39029#31614#20013#26597#30475
      ImageName = 'nav'
      OnExecute = actViewSelectedExecute
    end
    object actBackToBrowse: TAction
      Category = #26597#30475
      Caption = #36820#22238#27983#35272#27169#24335
      Hint = #20999#22238#32553#30053#22270#27983#35272#39029#31614
      ImageName = 'nav'
      OnExecute = actBackToBrowseExecute
    end
    object actGo: TAction
      Category = #27983#35272
      Caption = #36716#21040
      Hint = #36716#21040#22320#22336#26639#20013#30340#25991#20214#22841
      ImageName = 'nav'
      OnExecute = actGoExecute
    end
    object actGoUp: TAction
      Category = #27983#35272
      Caption = #19978#32423#25991#20214#22841
      Hint = #25171#24320#19978#32423#25991#20214#22841' (Backspace)'
      ImageName = 'nav'
      OnExecute = actGoUpExecute
    end
    object actComputer: TAction
      Category = #27983#35272
      Caption = #35745#31639#26426
      Hint = #36339#21040#26412#26426#30913#30424' ('#26681#30446#24405')'
      ImageName = 'doc'
      OnExecute = actComputerExecute
    end
    object actPrev: TAction
      Category = #26597#30475
      Caption = #19978#19968#24352
      Hint = #19978#19968#24352' ('#24038#26041#21521#38190' / '#28378#36718#19978')'
      ImageName = 'nav'
      OnExecute = actPrevExecute
    end
    object actNext: TAction
      Category = #26597#30475
      Caption = #19979#19968#24352
      Hint = #19979#19968#24352' ('#21491#26041#21521#38190' / '#28378#36718#19979')'
      ImageName = 'nav'
      OnExecute = actNextExecute
    end
    object actFirst: TAction
      Category = #26597#30475
      Caption = #31532#19968#24352
      Hint = #31532#19968#24352' (Ctrl+Home)'
      ImageName = 'nav'
      OnExecute = actFirstExecute
    end
    object actLast: TAction
      Category = #26597#30475
      Caption = #26368#21518#19968#24352
      Hint = #26368#21518#19968#24352' (Ctrl+End)'
      ImageName = 'nav'
      OnExecute = actLastExecute
    end
    object actFit: TAction
      Category = #26174#31034
      Caption = #36866#24212#31383#21475
      Hint = #36866#24212#31383#21475' (Ctrl+0)'
      ImageName = 'zoom'
      ShortCut = 16432
      OnExecute = actFitExecute
    end
    object actActual: TAction
      Category = #26174#31034
      Caption = #23454#38469#22823#23567' 1:1'
      Hint = #23454#38469#22823#23567' 1:1 (Ctrl+1)'
      ImageName = 'zoom'
      ShortCut = 16433
      OnExecute = actActualExecute
    end
    object actZoomIn: TAction
      Category = #26174#31034
      Caption = #25918#22823
      Hint = #25918#22823' (Ctrl++ / +)'
      ImageName = 'zoom'
      ShortCut = 16571
      OnExecute = actZoomInExecute
    end
    object actZoomOut: TAction
      Category = #26174#31034
      Caption = #32553#23567
      Hint = #32553#23567' (Ctrl+- / -)'
      ImageName = 'zoom'
      ShortCut = 16573
      OnExecute = actZoomOutExecute
    end
    object actRotateCW: TAction
      Category = #26174#31034
      Caption = #39034#26102#38024#26059#36716
      Hint = #39034#26102#38024#26059#36716' 90 '#24230' (Ctrl+R)'
      ImageName = 'flip'
      ShortCut = 16466
      OnExecute = actRotateCWExecute
    end
    object actRotateCCW: TAction
      Category = #26174#31034
      Caption = #36870#26102#38024#26059#36716
      Hint = #36870#26102#38024#26059#36716' 90 '#24230' (Ctrl+L)'
      ImageName = 'flip'
      ShortCut = 16460
      OnExecute = actRotateCCWExecute
    end
    object actSlideShow: TAction
      Category = #26174#31034
      AutoCheck = True
      Caption = #24187#28783#29255#25773#25918
      Hint = #24187#28783#29255#25773#25918' (F6)'
      ImageName = 'play'
      ShortCut = 117
      OnExecute = actSlideShowExecute
    end
    object actFullScreen: TAction
      Category = #26174#31034
      AutoCheck = True
      Caption = #20840#23631#27983#35272
      Hint = #20840#23631#27983#35272' (F11)'
      ImageName = 'play'
      ShortCut = 122
      OnExecute = actFullScreenExecute
    end
    object actDelete: TAction
      Category = #25991#20214
      Caption = #21024#38500#21040#22238#25910#31449
      Hint = #21024#38500#21040#22238#25910#31449' (Ctrl+Delete)'
      ImageName = 'stop'
      ShortCut = 16430
      OnExecute = actDeleteExecute
    end
    object actSaveAs: TAction
      Category = #25991#20214
      Caption = #21478#23384#20026'...'
      Hint = #21478#23384#20026' PNG / JPEG / BMP (Ctrl+S)'
      ImageName = 'doc'
      ShortCut = 16467
      OnExecute = actSaveAsExecute
    end
    object actCopyImage: TAction
      Category = #25991#20214
      Caption = #22797#21046#22270#20687
      Hint = #22797#21046#22270#20687#21040#21098#36148#26495' (Ctrl+Shift+C)'
      ImageName = 'doc'
      ShortCut = 24643
      OnExecute = actCopyImageExecute
    end
    object actCopyPath: TAction
      Category = #25991#20214
      Caption = #22797#21046#25991#20214#36335#24452
      Hint = #22797#21046#25991#20214#36335#24452
      ImageName = 'doc'
      OnExecute = actCopyPathExecute
    end
    object actExplore: TAction
      Category = #25991#20214
      Caption = #22312#36164#28304#31649#29702#22120#20013#26174#31034
      Hint = #22312#36164#28304#31649#29702#22120#20013#26174#31034
      ImageName = 'nav'
      OnExecute = actExploreExecute
    end
    object actShowThumbs: TAction
      Category = #38754#26495
      AutoCheck = True
      Caption = #32553#30053#22270#26465
      Hint = #26174#31034' / '#38544#34255#24213#37096#32553#30053#22270#26465#65288#26597#30475#27169#24335#65289
      ImageName = 'panel'
      OnExecute = actPanelsExecute
    end
    object actShowInfo: TAction
      Category = #38754#26495
      AutoCheck = True
      Caption = #22270#20687#20449#24687#38754#26495
      Hint = #26174#31034' / '#38544#34255#22270#20687#20449#24687#38754#26495#65288#26597#30475#27169#24335#65289
      ImageName = 'panel'
      OnExecute = actPanelsExecute
    end
    object actShowStatus: TAction
      Category = #38754#26495
      AutoCheck = True
      Caption = #29366#24577#26639
      Checked = True
      Hint = #26174#31034' / '#38544#34255#29366#24577#26639
      ImageName = 'panel'
      OnExecute = actPanelsExecute
    end
    object actSortName: TAction
      Category = #25490#24207
      AutoCheck = True
      Caption = #25353#21517#31216
      Checked = True
      GroupIndex = 1
      ImageName = 'sort'
      OnExecute = actSortExecute
    end
    object actSortSize: TAction
      Category = #25490#24207
      AutoCheck = True
      Caption = #25353#22823#23567
      GroupIndex = 1
      ImageName = 'sort'
      OnExecute = actSortExecute
    end
    object actSortDate: TAction
      Category = #25490#24207
      AutoCheck = True
      Caption = #25353#20462#25913#26102#38388
      GroupIndex = 1
      ImageName = 'sort'
      OnExecute = actSortExecute
    end
    object actSortType: TAction
      Category = #25490#24207
      AutoCheck = True
      Caption = #25353#25991#20214#31867#22411
      GroupIndex = 1
      ImageName = 'sort'
      OnExecute = actSortExecute
    end
    object actSize64: TAction
      Tag = 64
      Category = #32553#30053#22270
      AutoCheck = True
      Caption = '64 x 64'
      GroupIndex = 2
      ImageName = 'zoom'
      OnExecute = actThumbSizeExecute
    end
    object actSize96: TAction
      Tag = 96
      Category = #32553#30053#22270
      AutoCheck = True
      Caption = '96 x 96'
      GroupIndex = 2
      ImageName = 'zoom'
      OnExecute = actThumbSizeExecute
    end
    object actSize128: TAction
      Tag = 128
      Category = #32553#30053#22270
      AutoCheck = True
      Caption = '128 x 128'
      Checked = True
      GroupIndex = 2
      ImageName = 'zoom'
      OnExecute = actThumbSizeExecute
    end
    object actSize160: TAction
      Tag = 160
      Category = #32553#30053#22270
      AutoCheck = True
      Caption = '160 x 160'
      GroupIndex = 2
      ImageName = 'zoom'
      OnExecute = actThumbSizeExecute
    end
    object actSize192: TAction
      Tag = 192
      Category = #32553#30053#22270
      AutoCheck = True
      Caption = '192 x 192'
      GroupIndex = 2
      ImageName = 'zoom'
      OnExecute = actThumbSizeExecute
    end
    object actThumbSmaller: TAction
      Category = #32553#30053#22270
      Caption = #32553#23567#32553#30053#22270
      Hint = #32553#23567#32553#30053#22270#23610#23544
      ImageName = 'zoom'
      OnExecute = actThumbStepExecute
    end
    object actThumbBigger: TAction
      Category = #32553#30053#22270
      Caption = #25918#22823#32553#30053#22270
      Hint = #25918#22823#32553#30053#22270#23610#23544
      ImageName = 'zoom'
      OnExecute = actThumbStepExecute
    end
    object actProperties: TAction
      Caption = #23646#24615
      Hint = #26597#30475#36873#20013#22270#20687#30340#23646#24615
      ImageName = 'doc'
      ShortCut = 32781
      OnExecute = actPropertiesExecute
    end
    object actAbout: TAction
      Category = #24110#21161
      Caption = #20851#20110'...'
      Hint = #20851#20110#26412#31243#24207' (F1)'
      ImageName = 'panel'
      ShortCut = 112
      OnExecute = actAboutExecute
    end
  end
  object ImageListBrowse: TImageList
    ColorDepth = cd32Bit
    Height = 128
    Width = 128
    Left = 640
    Top = 48
  end
  object ImageListThumbs: TImageList
    ColorDepth = cd32Bit
    Height = 128
    Width = 128
    Left = 680
    Top = 48
  end
  object TimerThumbs: TTimer
    Enabled = False
    Interval = 40
    OnTimer = TimerThumbsTimer
    Left = 720
    Top = 48
  end
  object TimerRepaint: TTimer
    Enabled = False
    Interval = 120
    OnTimer = TimerRepaintTimer
    Left = 760
    Top = 80
  end
  object TimerSlide: TTimer
    Enabled = False
    Interval = 3000
    OnTimer = TimerSlideTimer
    Left = 760
    Top = 48
  end
  object TimerHint: TTimer
    Enabled = False
    Interval = 2200
    OnTimer = TimerHintTimer
    Left = 800
    Top = 48
  end
  object OpenDialog1: TOpenDialog
    Filter = #22270#20687#25991#20214'|*.*'
    Options = [ofHideReadOnly, ofFileMustExist, ofEnableSizing]
    Title = #25171#24320#22270#29255
    Left = 840
    Top = 48
  end
  object FileOpenDialog1: TFileOpenDialog
    FavoriteLinks = <>
    FileTypes = <>
    Options = [fdoPickFolders, fdoForceFileSystem, fdoPathMustExist]
    Title = #36873#25321#25991#20214#22841
    Left = 880
    Top = 48
  end
  object SaveDialog1: TSaveDialog
    DefaultExt = 'png'
    Filter = 'PNG '#22270#20687' (*.png)|*.png'
    Options = [ofOverwritePrompt, ofHideReadOnly, ofPathMustExist, ofEnableSizing]
    Title = #21478#23384#20026
    Left = 920
    Top = 48
  end
  object PopupMenuBrowse: TPopupMenu
    OwnerDraw = True
    OnPopup = PopupMenuBrowsePopup
    Left = 600
    Top = 170
    object miPbView: TMenuItem
      Action = actViewSelected
    end
    object miPbOpenFolder: TMenuItem
      Caption = #25171#24320#25991#20214#22841
      OnClick = miPbOpenFolderClick
    end
    object miPbSep0: TMenuItem
      Caption = '-'
    end
    object miPbCopyPath: TMenuItem
      Action = actCopyPath
    end
    object miPbExplore: TMenuItem
      Action = actExplore
    end
    object miPbSep1: TMenuItem
      Caption = '-'
    end
    object miPbProperties: TMenuItem
      Action = actProperties
    end
    object miPbDelete: TMenuItem
      Action = actDelete
    end
  end
  object PopupMenuThumbs: TPopupMenu
    Left = 600
    Top = 210
    object miPtCopyPath: TMenuItem
      Action = actCopyPath
    end
    object miPtExplore: TMenuItem
      Action = actExplore
    end
    object miPtSep1: TMenuItem
      Caption = '-'
    end
    object miPtDelete: TMenuItem
      Action = actDelete
    end
    object miPtSaveAs: TMenuItem
      Action = actSaveAs
    end
    object miPtProperties: TMenuItem
      Action = actProperties
    end
  end
  object PopupMenuTabs: TPopupMenu
    OwnerDraw = True
    Left = 600
    Top = 250
    object miTabNew: TMenuItem
      Action = actNewBrowseTab
    end
    object miTabClose: TMenuItem
      Action = actCloseTab
    end
    object miTabCloseOthers: TMenuItem
      Action = actCloseOthers
    end
    object miTabCloseAll: TMenuItem
      Action = actCloseAll
    end
  end
  object PopupMenuView: TPopupMenu
    OwnerDraw = True
    Left = 600
    Top = 290
    object miPvBack: TMenuItem
      Action = actBackToBrowse
    end
    object miPvSep1: TMenuItem
      Caption = '-'
    end
    object miPvPrev: TMenuItem
      Action = actPrev
    end
    object miPvNext: TMenuItem
      Action = actNext
    end
    object miPvSep2: TMenuItem
      Caption = '-'
    end
    object miPvFit: TMenuItem
      Action = actFit
    end
    object miPvActual: TMenuItem
      Action = actActual
    end
    object miPvZoomIn: TMenuItem
      Action = actZoomIn
    end
    object miPvZoomOut: TMenuItem
      Action = actZoomOut
    end
    object miPvRotateCW: TMenuItem
      Action = actRotateCW
    end
    object miPvRotateCCW: TMenuItem
      Action = actRotateCCW
    end
    object miPvSep3: TMenuItem
      Caption = '-'
    end
    object miPvSlide: TMenuItem
      Action = actSlideShow
      AutoCheck = True
    end
    object miPvFull: TMenuItem
      Action = actFullScreen
      AutoCheck = True
      Visible = False
    end
    object miPvSep4: TMenuItem
      Caption = '-'
    end
    object miPvSaveAs: TMenuItem
      Action = actSaveAs
    end
    object miPvCopyImage: TMenuItem
      Action = actCopyImage
    end
    object miPvCopyPath: TMenuItem
      Action = actCopyPath
    end
    object miPvExplore: TMenuItem
      Action = actExplore
    end
    object miPvSep5: TMenuItem
      Caption = '-'
    end
    object miPvProperties: TMenuItem
      Action = actProperties
    end
    object miPvDelete: TMenuItem
      Action = actDelete
    end
    object miPvSep6: TMenuItem
      Caption = '-'
    end
    object miPvClose: TMenuItem
      Action = actCloseTab
    end
  end
end
