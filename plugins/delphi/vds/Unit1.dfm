object frmVideoCapture: TfrmVideoCapture
  Left = 0
  Top = 0
  BorderIcons = [biSystemMenu]
  Caption = #35270#39057#25429#33719' v5.0'
  ClientHeight = 620
  ClientWidth = 974
  Color = clBlack
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  Position = poScreenCenter
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  DesignSize = (
    974
    620)
  TextHeight = 13
  object grp1: TGroupBox
    Left = 15
    Top = 13
    Width = 426
    Height = 76
    Caption = '1'#12289#35270#39057#35774#22791#21015#34920#65306
    DefaultHeaderFont = False
    HeaderFont.Charset = GB2312_CHARSET
    HeaderFont.Color = clWhite
    HeaderFont.Height = -19
    HeaderFont.Name = #24494#36719#38597#40657
    HeaderFont.Style = []
    TabOrder = 0
    DesignSize = (
      426
      76)
    object cbbVideoDevice: TComboBox
      Left = 24
      Top = 30
      Width = 386
      Height = 29
      Style = csDropDownList
      Anchors = [akLeft, akTop, akRight]
      Font.Charset = GB2312_CHARSET
      Font.Color = clWindowText
      Font.Height = -16
      Font.Name = #24494#36719#38597#40657
      Font.Style = []
      ParentFont = False
      TabOrder = 0
    end
  end
  object grp11: TGroupBox
    Left = 463
    Top = 13
    Width = 490
    Height = 76
    Anchors = [akLeft, akTop, akRight]
    Caption = '2'#12289#35270#39057#20998#36776#29575#21015#34920#65306
    DefaultHeaderFont = False
    HeaderFont.Charset = GB2312_CHARSET
    HeaderFont.Color = clWhite
    HeaderFont.Height = -19
    HeaderFont.Name = #24494#36719#38597#40657
    HeaderFont.Style = []
    TabOrder = 1
    DesignSize = (
      490
      76)
    object cbbVideoSupportPixel: TComboBox
      Left = 24
      Top = 30
      Width = 450
      Height = 29
      Style = csDropDownList
      Anchors = [akLeft, akTop, akRight]
      Font.Charset = GB2312_CHARSET
      Font.Color = clWindowText
      Font.Height = -16
      Font.Name = #24494#36719#38597#40657
      Font.Style = []
      ParentFont = False
      TabOrder = 0
    end
  end
  object grp12: TGroupBox
    Left = 15
    Top = 109
    Width = 426
    Height = 492
    Anchors = [akLeft, akTop, akBottom]
    DefaultHeaderFont = False
    HeaderFont.Charset = GB2312_CHARSET
    HeaderFont.Color = clWhite
    HeaderFont.Height = -19
    HeaderFont.Name = #24494#36719#38597#40657
    HeaderFont.Style = []
    TabOrder = 2
  end
  object pnlVideo: TPanel
    Left = 463
    Top = 109
    Width = 490
    Height = 492
    Anchors = [akLeft, akTop, akRight, akBottom]
    BevelOuter = bvNone
    BorderStyle = bsSingle
    Caption = 'pnlVideo'
    Color = clGray
    Ctl3D = False
    ParentBackground = False
    ParentCtl3D = False
    ShowCaption = False
    TabOrder = 3
  end
end
