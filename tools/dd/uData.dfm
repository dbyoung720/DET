object frmDataDll: TfrmDataDll
  Left = 0
  Top = 0
  Caption = 'frmDataDll'
  ClientHeight = 736
  ClientWidth = 1745
  Color = 3947580
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  KeyPreview = True
  Position = poScreenCenter
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  OnKeyDown = FormKeyDown
  TextHeight = 15
  object rzpgcntrlData: TRzPageControl
    Left = 0
    Top = 0
    Width = 1745
    Height = 736
    Hint = ''
    ActivePage = rztbshtShow
    Align = alClient
    Color = 3947580
    UseColoredTabs = True
    Font.Charset = GB2312_CHARSET
    Font.Color = clWindowText
    Font.Height = -16
    Font.Name = #24494#36719#38597#40657
    Font.Style = []
    ParentColor = False
    ParentFont = False
    TabHeight = 30
    TabIndex = 1
    TabOrder = 0
    TabWidth = 200
    FixedDimension = 30
    object rztbshtDesign: TRzTabSheet
      Color = 3947580
      Caption = #35774#35745
      OnDblClick = rztbshtDesignDblClick
      ExplicitLeft = 0
      ExplicitTop = 0
      ExplicitWidth = 0
      ExplicitHeight = 0
      DesignSize = (
        1741
        702)
      object grpTable: TGroupBox
        Left = 24
        Top = 16
        Width = 537
        Height = 65
        Caption = '1'#65306#36873#25321#35201#26174#31034#30340#34920
        DefaultHeaderFont = False
        HeaderFont.Charset = GB2312_CHARSET
        HeaderFont.Color = clYellow
        HeaderFont.Height = -16
        HeaderFont.Name = #24494#36719#38597#40657
        HeaderFont.Style = []
        TabOrder = 0
        object cbbTable: TComboBox
          Left = 16
          Top = 23
          Width = 505
          Height = 29
          Style = csDropDownList
          DropDownCount = 40
          TabOrder = 0
          OnChange = cbbTableChange
        end
      end
      object grpFields: TGroupBox
        Left = 24
        Top = 88
        Width = 1089
        Height = 600
        Anchors = [akLeft, akTop, akBottom]
        Caption = '2'#65306#36873#25321#35201#26174#31034#30340#23383#27573
        DefaultHeaderFont = False
        HeaderFont.Charset = GB2312_CHARSET
        HeaderFont.Color = clYellow
        HeaderFont.Height = -16
        HeaderFont.Name = #24494#36719#38597#40657
        HeaderFont.Style = []
        TabOrder = 1
        DesignSize = (
          1089
          600)
        object grpSelectField: TGroupBox
          Left = 16
          Top = 24
          Width = 257
          Height = 560
          Anchors = [akLeft, akTop, akBottom]
          Caption = 'A'#65306#36873#25321#23383#27573
          DefaultHeaderFont = False
          HeaderFont.Charset = GB2312_CHARSET
          HeaderFont.Color = clWhite
          HeaderFont.Height = -16
          HeaderFont.Name = #24494#36719#38597#40657
          HeaderFont.Style = []
          TabOrder = 0
          DesignSize = (
            257
            560)
          object chklstFields: TCheckListBox
            Left = 16
            Top = 24
            Width = 225
            Height = 521
            Anchors = [akLeft, akTop, akRight, akBottom]
            ItemHeight = 21
            TabOrder = 0
            OnClick = chklstFieldsClick
          end
        end
        object grpFieldDisplayTitle: TGroupBox
          Left = 288
          Top = 24
          Width = 249
          Height = 560
          Anchors = [akLeft, akTop, akBottom]
          Caption = 'B'#65306#23383#27573#26174#31034#21517#31216
          DefaultHeaderFont = False
          HeaderFont.Charset = GB2312_CHARSET
          HeaderFont.Color = clWhite
          HeaderFont.Height = -16
          HeaderFont.Name = #24494#36719#38597#40657
          HeaderFont.Style = []
          TabOrder = 1
          DesignSize = (
            249
            560)
          object mmoFieldShowTitle: TMemo
            Left = 16
            Top = 24
            Width = 217
            Height = 521
            Anchors = [akLeft, akTop, akRight, akBottom]
            HideSelection = False
            Lines.Strings = (
              '')
            ScrollBars = ssVertical
            TabOrder = 0
          end
        end
        object grpRelate: TGroupBox
          Left = 552
          Top = 24
          Width = 513
          Height = 560
          Anchors = [akLeft, akTop, akBottom]
          Caption = 'C'#65306#20851#32852#35774#32622
          DefaultHeaderFont = False
          HeaderFont.Charset = GB2312_CHARSET
          HeaderFont.Color = clWhite
          HeaderFont.Height = -16
          HeaderFont.Name = #24494#36719#38597#40657
          HeaderFont.Style = []
          TabOrder = 2
          DesignSize = (
            513
            560)
          object lbl1: TLabel
            Left = 16
            Top = 48
            Width = 64
            Height = 21
            Caption = #20027#23383#27573#65306
            Font.Charset = GB2312_CHARSET
            Font.Color = clWhite
            Font.Height = -16
            Font.Name = #24494#36719#38597#40657
            Font.Style = []
            ParentFont = False
          end
          object lbl2: TLabel
            Left = 16
            Top = 88
            Width = 64
            Height = 21
            Caption = #20851#32852#34920#65306
            Font.Charset = GB2312_CHARSET
            Font.Color = clWhite
            Font.Height = -16
            Font.Name = #24494#36719#38597#40657
            Font.Style = []
            ParentFont = False
          end
          object lbl3: TLabel
            Left = 16
            Top = 128
            Width = 80
            Height = 21
            Caption = #20851#32852#23383#27573#65306
            Font.Charset = GB2312_CHARSET
            Font.Color = clWhite
            Font.Height = -16
            Font.Name = #24494#36719#38597#40657
            Font.Style = []
            ParentFont = False
          end
          object lbl4: TLabel
            Left = 16
            Top = 168
            Width = 80
            Height = 21
            Caption = #26174#31034#23383#27573#65306
            Font.Charset = GB2312_CHARSET
            Font.Color = clWhite
            Font.Height = -16
            Font.Name = #24494#36719#38597#40657
            Font.Style = []
            ParentFont = False
          end
          object lblMasterFieldName: TLabel
            Left = 152
            Top = 48
            Width = 6
            Height = 26
            Font.Charset = GB2312_CHARSET
            Font.Color = clRed
            Font.Height = -19
            Font.Name = #24494#36719#38597#40657
            Font.Style = [fsBold]
            ParentFont = False
          end
          object btnAddRelate: TButton
            Left = 152
            Top = 216
            Width = 145
            Height = 41
            Caption = #28155#21152#20851#32852
            TabOrder = 0
            OnClick = btnAddRelateClick
          end
          object btnDelRelate: TButton
            Left = 365
            Top = 216
            Width = 137
            Height = 41
            Caption = #21024#38500#20851#32852
            TabOrder = 1
            OnClick = btnDelRelateClick
          end
          object lvRelate: TListView
            Left = 16
            Top = 272
            Width = 486
            Height = 273
            Anchors = [akLeft, akTop, akBottom]
            Columns = <
              item
                Caption = #20027#23383#27573
                Width = 120
              end
              item
                Caption = #20851#32852#34920
                Width = 120
              end
              item
                Caption = #20851#32852#23383#27573
                Width = 80
              end
              item
                Caption = #26174#31034#23383#27573
                Width = 140
              end>
            GridLines = True
            ReadOnly = True
            RowSelect = True
            TabOrder = 2
            ViewStyle = vsReport
          end
          object cbbRelateTable: TComboBox
            Left = 152
            Top = 88
            Width = 350
            Height = 29
            Style = csDropDownList
            DropDownCount = 30
            TabOrder = 3
            OnChange = cbbRelateTableChange
          end
          object cbbRelateField: TComboBox
            Left = 152
            Top = 126
            Width = 350
            Height = 29
            Style = csDropDownList
            DropDownCount = 30
            TabOrder = 4
          end
          object cbbDisplayField: TComboBox
            Left = 152
            Top = 166
            Width = 350
            Height = 29
            Style = csDropDownList
            DropDownCount = 30
            TabOrder = 5
          end
        end
      end
      object grpSave: TGroupBox
        Left = 1129
        Top = 88
        Width = 595
        Height = 65
        Anchors = [akLeft, akTop, akRight]
        Caption = '3'#12289#36873#25321#25490#24207#23383#27573
        DefaultHeaderFont = False
        HeaderFont.Charset = GB2312_CHARSET
        HeaderFont.Color = clYellow
        HeaderFont.Height = -16
        HeaderFont.Name = #24494#36719#38597#40657
        HeaderFont.Style = []
        TabOrder = 2
        DesignSize = (
          595
          65)
        object lblOrder: TLabel
          Left = 16
          Top = 29
          Width = 80
          Height = 21
          Caption = #25490#24207#23383#27573#65306
          Font.Charset = GB2312_CHARSET
          Font.Color = clWhite
          Font.Height = -16
          Font.Name = #24494#36719#38597#40657
          Font.Style = []
          ParentFont = False
        end
        object cbbOrder: TComboBox
          Left = 128
          Top = 24
          Width = 451
          Height = 29
          Style = csDropDownList
          Anchors = [akLeft, akTop, akRight]
          DropDownCount = 30
          TabOrder = 0
        end
      end
      object grpWhere: TGroupBox
        Left = 1129
        Top = 164
        Width = 595
        Height = 165
        Anchors = [akLeft, akTop, akRight]
        Caption = '4'#12289#36873#25321#26465#20214#23383#27573'('#23383#31526#20018#23383#27573#31867#22411#38656#35201#21152#24341#21495')'
        DefaultHeaderFont = False
        HeaderFont.Charset = GB2312_CHARSET
        HeaderFont.Color = clYellow
        HeaderFont.Height = -16
        HeaderFont.Name = #24494#36719#38597#40657
        HeaderFont.Style = []
        TabOrder = 3
        DesignSize = (
          595
          165)
        object lblWhere: TLabel
          Left = 16
          Top = 36
          Width = 80
          Height = 21
          Caption = #26465#20214#23383#27573#65306
          Font.Charset = GB2312_CHARSET
          Font.Color = clWhite
          Font.Height = -16
          Font.Name = #24494#36719#38597#40657
          Font.Style = []
          ParentFont = False
        end
        object lblWhereSQL: TLabel
          Left = 16
          Top = 116
          Width = 80
          Height = 21
          Caption = #26465#20214#35821#21477#65306
          Font.Charset = GB2312_CHARSET
          Font.Color = clWhite
          Font.Height = -16
          Font.Name = #24494#36719#38597#40657
          Font.Style = []
          ParentFont = False
        end
        object lblWhere1: TLabel
          Left = 16
          Top = 76
          Width = 48
          Height = 21
          Caption = #26465#20214#65306
          Font.Charset = GB2312_CHARSET
          Font.Color = clWhite
          Font.Height = -16
          Font.Name = #24494#36719#38597#40657
          Font.Style = []
          ParentFont = False
        end
        object cbbWhere: TComboBox
          Left = 128
          Top = 36
          Width = 451
          Height = 29
          Style = csDropDownList
          Anchors = [akLeft, akTop, akRight]
          DropDownCount = 30
          TabOrder = 0
          OnChange = cbbWhereChange
        end
        object cbbWhereEqu: TComboBox
          Left = 128
          Top = 74
          Width = 145
          Height = 29
          Style = csDropDownList
          ItemIndex = 0
          TabOrder = 1
          Text = #31561#20110
          OnChange = cbbWhereEquChange
          Items.Strings = (
            #31561#20110
            #22823#20110
            #22823#20110#31561#20110
            #23567#20110
            #23567#20110#31561#20110
            #21253#21547
            #22312#26102#38388#20043#38388)
        end
        object edtWhereSQL: TEdit
          Left = 128
          Top = 114
          Width = 451
          Height = 29
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 2
        end
        object rzpgcntrlWhere: TRzPageControl
          Left = 285
          Top = 70
          Width = 295
          Height = 66
          Hint = ''
          ActivePage = rztbshtWhereNum
          Anchors = [akLeft, akTop, akRight]
          ShowCardFrame = False
          ShowFocusRect = False
          ShowFullFrame = False
          ShowShadow = False
          TabIndex = 0
          TabOrder = 3
          TabWidth = 150
          FixedDimension = 27
          object rztbshtWhereNum: TRzTabSheet
            Color = 3947580
            Caption = #25968#20540#21644#23383#31526#20018
            ExplicitTop = 0
            ExplicitWidth = 0
            ExplicitHeight = 0
            DesignSize = (
              295
              39)
            object edtWhereValue: TEdit
              Left = 3
              Top = 3
              Width = 292
              Height = 29
              Anchors = [akLeft, akTop, akRight]
              TabOrder = 0
              OnChange = edtWhereValueChange
            end
          end
          object rztbshtWhereTime: TRzTabSheet
            Color = 3947580
            Caption = #26102#38388
            ExplicitTop = 0
            ExplicitWidth = 0
            ExplicitHeight = 0
            object dtpEndDate: TDateTimePicker
              Left = 211
              Top = 3
              Width = 200
              Height = 29
              Date = 45855.000000000000000000
              Time = 0.392505196759884700
              Kind = dtkDateTime
              TabOrder = 0
              OnChange = dtpStartDateChange
            end
            object dtpStartDate: TDateTimePicker
              Left = 3
              Top = 3
              Width = 200
              Height = 29
              Date = 45855.000000000000000000
              Time = 0.392505196759884700
              Kind = dtkDateTime
              TabOrder = 1
              OnChange = dtpStartDateChange
            end
          end
        end
      end
      object grpSave1: TGroupBox
        Left = 1129
        Top = 504
        Width = 595
        Height = 184
        Anchors = [akLeft, akRight, akBottom]
        Caption = '5'#12289#20445#23384#35774#35745#24182#39044#35272
        DefaultHeaderFont = False
        HeaderFont.Charset = GB2312_CHARSET
        HeaderFont.Color = clYellow
        HeaderFont.Height = -16
        HeaderFont.Name = #24494#36719#38597#40657
        HeaderFont.Style = []
        TabOrder = 4
        DesignSize = (
          595
          184)
        object btnSave: TButton
          Left = 16
          Top = 40
          Width = 563
          Height = 128
          Anchors = [akLeft, akTop, akRight, akBottom]
          Caption = #20445#23384'/'#39044#35272
          TabOrder = 0
          OnClick = btnSaveClick
        end
      end
    end
    object rztbshtShow: TRzTabSheet
      Color = 3947580
      Caption = #26174#31034
      object cxgrd: TcxGrid
        Left = 0
        Top = 0
        Width = 1741
        Height = 702
        Align = alClient
        BevelInner = bvNone
        BevelOuter = bvNone
        BorderStyle = cxcbsNone
        Font.Charset = GB2312_CHARSET
        Font.Color = clWindowText
        Font.Height = -14
        Font.Name = #23435#20307
        Font.Style = []
        ParentFont = False
        TabOrder = 0
        LookAndFeel.NativeStyle = False
        object cxgrdbtblvwGrid1DBTableView1: TcxGridDBTableView
          OnDblClick = cxgrdbtblvwGrid1DBTableView1DblClick
          DateTimeHandling.MonthFormat = 'MM'
          DateTimeHandling.YearFormat = 'yyyy'
          DateTimeHandling.DateFormat = 'dd'
          DateTimeHandling.HourFormat = 'hh'
          OptionsCustomize.ColumnsQuickCustomization = True
          OptionsSelection.CellSelect = False
          OptionsView.GroupByBox = False
          OptionsView.Indicator = True
          OptionsView.IndicatorWidth = 40
          Styles.Background = cxstyl
          Styles.Content = cxstyl1
          Styles.FindPanel = cxstyl3
          Styles.OnGetContentStyle = cxgrdbtblvwGrid1DBTableView1StylesGetContentStyle
          Styles.Header = cxstyl4
          Styles.Inactive = cxstyl2
          OnCustomDrawIndicatorCell = cxgrdbtblvwGrid1DBTableView1CustomDrawIndicatorCell
        end
        object cxgrdlvlGrid1Level1: TcxGridLevel
          GridView = cxgrdbtblvwGrid1DBTableView1
        end
      end
    end
  end
  object SQLServerUniProvider1: TSQLServerUniProvider
    Left = 712
    Top = 471
  end
  object cxstylrpstry: TcxStyleRepository
    Left = 152
    Top = 208
    PixelsPerInch = 96
    object cxstyl: TcxStyle
      AssignedValues = [svColor]
      Color = 2829099
    end
    object cxstyl1: TcxStyle
      AssignedValues = [svColor, svFont, svTextColor]
      Color = 2829099
      Font.Charset = GB2312_CHARSET
      Font.Color = clWindowText
      Font.Height = -19
      Font.Name = #24494#36719#38597#40657
      Font.Style = []
      TextColor = clWhite
    end
    object cxstyl2: TcxStyle
      AssignedValues = [svColor, svTextColor]
      Color = 14120960
      TextColor = clWhite
    end
    object cxstyl4: TcxStyle
      AssignedValues = [svColor, svFont, svTextColor]
      Color = 33023
      Font.Charset = GB2312_CHARSET
      Font.Color = clLime
      Font.Height = -21
      Font.Name = #24494#36719#38597#40657
      Font.Style = []
      TextColor = clWhite
    end
    object StyleEven: TcxStyle
      AssignedValues = [svColor]
      Color = clBlack
    end
    object StyleOdd: TcxStyle
    end
    object cxstyl3: TcxStyle
      AssignedValues = [svColor, svFont, svTextColor]
      Color = 3947580
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWhite
      Font.Height = -19
      Font.Name = 'Segoe UI'
      Font.Style = []
      TextColor = clWhite
    end
  end
  object DB2UniProvider1: TDB2UniProvider
    Left = 843
    Top = 471
  end
  object InterBaseUniProvider1: TInterBaseUniProvider
    Left = 974
    Top = 471
  end
  object MySQLUniProvider1: TMySQLUniProvider
    Left = 1105
    Top = 471
  end
  object ODBCUniProvider1: TODBCUniProvider
    Left = 713
    Top = 551
  end
  object OracleUniProvider1: TOracleUniProvider
    Left = 843
    Top = 551
  end
  object PostgreSQLUniProvider1: TPostgreSQLUniProvider
    Left = 974
    Top = 551
  end
  object SQLiteUniProvider1: TSQLiteUniProvider
    Left = 1105
    Top = 551
  end
  object UniConnection1: TUniConnection
    AfterConnect = UniConnection1AfterConnect
    Left = 145
    Top = 311
  end
end
