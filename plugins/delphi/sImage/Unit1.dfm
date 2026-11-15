object frmDIP: TfrmDIP
  Left = 0
  Top = 0
  BorderIcons = [biSystemMenu]
  Caption = #31616#26131#25968#23383#22270#20687#22788#29702' v2.0'
  ClientHeight = 618
  ClientWidth = 936
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  Position = poScreenCenter
  OnClose = FormClose
  OnCreate = FormCreate
  DesignSize = (
    936
    618)
  TextHeight = 13
  object pnlImage: TPanel
    Left = 8
    Top = 8
    Width = 721
    Height = 602
    Anchors = [akLeft, akTop, akRight, akBottom]
    BevelOuter = bvNone
    BorderStyle = bsSingle
    Caption = 'pnlImage'
    Color = 3947580
    Ctl3D = False
    ParentBackground = False
    ParentCtl3D = False
    ShowCaption = False
    TabOrder = 0
    object imgShow: TImage
      Left = 0
      Top = 0
      Width = 719
      Height = 600
      Align = alClient
      Stretch = True
      ExplicitLeft = 128
      ExplicitTop = 136
      ExplicitWidth = 105
      ExplicitHeight = 105
    end
  end
  object pnlControl: TPanel
    Left = 743
    Top = 8
    Width = 185
    Height = 602
    Anchors = [akTop, akRight, akBottom]
    BevelOuter = bvNone
    BorderStyle = bsSingle
    Caption = 'pnlControl'
    Color = 3947580
    Ctl3D = False
    ParentBackground = False
    ParentCtl3D = False
    ShowCaption = False
    TabOrder = 1
    object lblTime: TLabel
      Left = 16
      Top = 8
      Width = 80
      Height = 16
      Caption = #32791#36153#26102#38388#65306
      Font.Charset = GB2312_CHARSET
      Font.Color = clLime
      Font.Height = -16
      Font.Name = #23435#20307
      Font.Style = []
      ParentFont = False
    end
    object btnOpen: TButton
      Left = 10
      Top = 31
      Width = 80
      Height = 30
      Caption = #25171#24320
      TabOrder = 0
      OnClick = btnOpenClick
    end
    object btnRestore: TButton
      Left = 96
      Top = 32
      Width = 80
      Height = 30
      Caption = #24674#22797
      TabOrder = 1
      OnClick = btnRestoreClick
    end
    object btnGray: TButton
      Left = 8
      Top = 67
      Width = 80
      Height = 30
      Caption = #28784#24230#22270
      TabOrder = 2
      OnClick = btnGrayClick
    end
    object btnInvert: TButton
      Left = 96
      Top = 67
      Width = 80
      Height = 30
      Caption = #21453#33394
      TabOrder = 3
      OnClick = btnInvertClick
    end
    object btnHMirror: TButton
      Left = 8
      Top = 102
      Width = 80
      Height = 30
      Caption = #27700#24179#38236#20687
      TabOrder = 4
      OnClick = btnHMirrorClick
    end
    object btnVMirror: TButton
      Left = 96
      Top = 102
      Width = 80
      Height = 30
      Caption = #22402#30452#38236#20687
      TabOrder = 5
      OnClick = btnVMirrorClick
    end
    object btnZhuangZhi: TButton
      Left = 8
      Top = 137
      Width = 80
      Height = 30
      Caption = #36716#32622
      TabOrder = 6
      OnClick = btnZhuangZhiClick
    end
    object btnRomate: TButton
      Left = 96
      Top = 137
      Width = 80
      Height = 30
      Caption = #26059#36716
      TabOrder = 7
      OnClick = btnRomateClick
    end
    object btnContrast: TButton
      Left = 96
      Top = 172
      Width = 80
      Height = 30
      Caption = #23545#27604#24230
      TabOrder = 8
      OnClick = btnContrastClick
    end
    object btnSaturation: TButton
      Left = 8
      Top = 207
      Width = 80
      Height = 30
      Caption = #39281#21644#24230
      TabOrder = 9
      OnClick = btnSaturationClick
    end
    object btnBlend: TButton
      Left = 96
      Top = 207
      Width = 80
      Height = 30
      Caption = #36879#26126#24230
      TabOrder = 10
      OnClick = btnBlendClick
    end
    object btnEmboss: TButton
      Left = 96
      Top = 242
      Width = 80
      Height = 30
      Caption = #28014#38613
      TabOrder = 11
      OnClick = btnEmbossClick
    end
    object btnExposure: TButton
      Left = 8
      Top = 242
      Width = 80
      Height = 30
      Caption = #26333#20809
      TabOrder = 12
      OnClick = btnExposureClick
    end
    object btnEngrave: TButton
      Left = 8
      Top = 278
      Width = 80
      Height = 30
      Caption = #38613#21051
      TabOrder = 13
      OnClick = btnEngraveClick
    end
    object btnRestore111: TButton
      Left = 96
      Top = 278
      Width = 80
      Height = 30
      Caption = 'btnOpen'
      TabOrder = 14
    end
    object btnLight: TButton
      Left = 8
      Top = 172
      Width = 80
      Height = 30
      Caption = #20142#24230
      TabOrder = 15
      OnClick = btnLightClick
    end
  end
end
