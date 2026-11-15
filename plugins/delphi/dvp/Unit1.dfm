object frmVideoPlayer: TfrmVideoPlayer
  Left = 0
  Top = 0
  Caption = #35270#39057#25773#25918#22120' 1.0'
  ClientHeight = 525
  ClientWidth = 884
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  PopupMenu = pmMain
  Position = poScreenCenter
  TextHeight = 13
  object barMain: TActionMainMenuBar
    Left = 0
    Top = 0
    Width = 884
    Height = 31
    UseSystemFont = False
    ActionManager = ActionManager1
    Caption = 'barMain'
    Color = clMenuBar
    ColorMap.DisabledFontColor = 7171437
    ColorMap.HighlightColor = clWhite
    ColorMap.BtnSelectedFont = clBlack
    ColorMap.UnusedColor = clWhite
    EdgeInner = esNone
    EdgeOuter = esNone
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clBlack
    Font.Height = -27
    Font.Name = 'Microsoft YaHei'
    Font.Style = [fsBold]
    HorzMargin = 8
    Spacing = 24
    VertMargin = 4
  end
  object PnlVideo: TPanel
    Left = 0
    Top = 31
    Width = 884
    Height = 438
    Align = alClient
    BevelOuter = bvNone
    Caption = 'PnlVideo'
    Color = clBlack
    ParentBackground = False
    TabOrder = 1
    ExplicitLeft = 360
    ExplicitTop = 264
    ExplicitWidth = 185
    ExplicitHeight = 41
  end
  object PnlBottom: TPanel
    Left = 0
    Top = 469
    Width = 884
    Height = 56
    Align = alBottom
    BevelOuter = bvNone
    Caption = 'PnlBottom'
    ParentBackground = False
    ShowCaption = False
    TabOrder = 2
    ExplicitLeft = 32
    ExplicitTop = 475
    DesignSize = (
      884
      56)
    object LblTime: TLabel
      Left = 668
      Top = 14
      Width = 66
      Height = 13
      Anchors = [akTop, akRight]
      Caption = '00:00 / 00:00'
    end
    object LblState: TLabel
      Left = 8
      Top = 34
      Width = 700
      Height = 18
      Anchors = [akLeft, akTop, akRight]
      AutoSize = False
    end
    object SeekBar: TTrackBar
      Left = 8
      Top = 6
      Width = 560
      Height = 24
      Anchors = [akLeft, akTop, akRight]
      Max = 1000
      TabOrder = 0
      ThumbLength = 12
    end
    object BtnPlay: TButton
      Left = 576
      Top = 8
      Width = 40
      Height = 26
      Anchors = [akTop, akRight]
      Caption = #9664
      TabOrder = 1
    end
    object BtnStop: TButton
      Left = 620
      Top = 8
      Width = 40
      Height = 26
      Anchors = [akTop, akRight]
      Caption = #9632
      TabOrder = 2
    end
    object VolumeBar: TTrackBar
      Left = 790
      Top = 8
      Width = 140
      Height = 24
      Anchors = [akTop, akRight]
      Enabled = False
      Max = 100
      Position = 70
      TabOrder = 3
    end
  end
  object ActionManager1: TActionManager
    ActionBars = <
      item
        Items = <
          item
            Items = <
              item
                Action = actOpenVideo
              end
              item
                Action = actOpenSubtitle
              end
              item
                Caption = '-'
              end
              item
                Action = actExit
              end>
            Caption = '&'#25991#20214
          end
          item
            Items = <
              item
                Action = actPlayPause
              end
              item
                Action = actStop
              end
              item
                Caption = '-'
              end
              item
                Action = actSeekBack5
              end
              item
                Action = actSeekFwd5
              end
              item
                Action = actSeekBack30
              end
              item
                Action = actSeekFwd30
              end
              item
                Caption = '-'
              end
              item
                Items = <
                  item
                    Action = actRate025
                    ImageIndex = 0
                    ImageName = 'blank'
                  end
                  item
                    Action = actRate050
                    ImageIndex = 0
                    ImageName = 'blank'
                  end
                  item
                    Action = actRate075
                    ImageIndex = 0
                    ImageName = 'blank'
                  end
                  item
                    Action = actRate100
                    ImageIndex = 1
                    ImageName = 'check'
                  end
                  item
                    Action = actRate125
                    ImageIndex = 0
                    ImageName = 'blank'
                  end
                  item
                    Action = actRate150
                    ImageIndex = 0
                    ImageName = 'blank'
                  end
                  item
                    Action = actRate200
                    ImageIndex = 0
                    ImageName = 'blank'
                  end
                  item
                    Action = actRate300
                    ImageIndex = 0
                    ImageName = 'blank'
                  end
                  item
                    Action = actRate400
                    ImageIndex = 0
                    ImageName = 'blank'
                  end>
                Caption = '&'#20493#36895
              end
              item
                Action = actSpeedUp
              end
              item
                Action = actSpeedDown
              end
              item
                Action = actSpeedReset
                ShortCut = 16466
              end
              item
                Caption = '-'
              end
              item
                Action = actFullScreen
                ShortCut = 122
              end>
            Caption = '&'#25773#25918
          end
          item
            Items = <
              item
                Action = actVideoTrack
              end
              item
                Caption = '-'
              end
              item
                Items = <
                  item
                    Action = actRenderVMR9
                  end
                  item
                    Action = actRenderEVR
                  end>
                Caption = '&'#28210#26579#22120
              end
              item
                Caption = '-'
              end
              item
                Action = actLavVideoCfg
              end>
            Caption = '&'#35270#39057
          end
          item
            Items = <
              item
                Action = actAudioTrack
              end
              item
                Caption = '-'
              end
              item
                Action = actVolumeUp
              end
              item
                Action = actVolumeDown
              end
              item
                Action = actMute
              end
              item
                Caption = '-'
              end
              item
                Action = actLavAudioCfg
              end>
            Caption = '&'#38899#39057
          end
          item
            Items = <
              item
                Action = actSubtitleTrack
              end
              item
                Caption = '-'
              end
              item
                Action = actSubCloseExt
              end
              item
                Caption = '-'
              end
              item
                Action = actSubDelayPlus
              end
              item
                Action = actSubDelayMinus
              end
              item
                Caption = '-'
              end
              item
                Action = actSubGrow
                ShortCut = 114
              end
              item
                Action = actSubShrink
                ShortCut = 113
              end>
            Caption = '&'#23383#24149
          end>
        ActionBar = barMain
      end>
    Images = VirtualImageList1
    Left = 64
    Top = 160
    StyleName = 'Platform Default'
    object actPlayPause: TAction
      Tag = 101
      Category = #25773#25918
      Caption = '&'#25773#25918'/'#26242#20572'('#31354#26684#38190')'
      OnExecute = FormMenuCommand
    end
    object actStop: TAction
      Tag = 102
      Category = #25773#25918
      Caption = '&'#20572#27490
      OnExecute = FormMenuCommand
    end
    object actSeekBack5: TAction
      Tag = 103
      Category = #25773#25918
      Caption = '&'#21518#36864' 5 '#31186
      OnExecute = FormMenuCommand
    end
    object actSeekFwd5: TAction
      Tag = 104
      Category = #25773#25918
      Caption = '&'#24555#36827' 5 '#31186
      OnExecute = FormMenuCommand
    end
    object actSeekBack30: TAction
      Tag = 105
      Category = #25773#25918
      Caption = '&'#21518#36864' 30 '#31186
      OnExecute = FormMenuCommand
    end
    object actSeekFwd30: TAction
      Tag = 106
      Category = #25773#25918
      Caption = '&'#24555#36827' 30 '#31186
      OnExecute = FormMenuCommand
    end
    object actRate025: TAction
      Tag = 107
      Category = #20493#36895
      Caption = '&0.25x'
      ImageIndex = 0
      ImageName = 'blank'
      OnExecute = FormMenuCommand
    end
    object actRate050: TAction
      Tag = 108
      Category = #20493#36895
      Caption = '0.&50x'
      ImageIndex = 0
      ImageName = 'blank'
      OnExecute = FormMenuCommand
    end
    object actRate075: TAction
      Tag = 109
      Category = #20493#36895
      Caption = '0.&75x'
      ImageIndex = 0
      ImageName = 'blank'
      OnExecute = FormMenuCommand
    end
    object actRate100: TAction
      Tag = 110
      Category = #20493#36895
      Caption = '&1.00x'
      ImageIndex = 1
      ImageName = 'check'
      OnExecute = FormMenuCommand
    end
    object actRate125: TAction
      Tag = 111
      Category = #20493#36895
      Caption = '1.&25x'
      ImageIndex = 0
      ImageName = 'blank'
      OnExecute = FormMenuCommand
    end
    object actRate150: TAction
      Tag = 112
      Category = #20493#36895
      Caption = '1.50&x'
      ImageIndex = 0
      ImageName = 'blank'
      OnExecute = FormMenuCommand
    end
    object actRate200: TAction
      Tag = 113
      Category = #20493#36895
      Caption = '2.00x'
      ImageIndex = 0
      ImageName = 'blank'
      OnExecute = FormMenuCommand
    end
    object actRate300: TAction
      Tag = 114
      Category = #20493#36895
      Caption = '&3.00x'
      ImageIndex = 0
      ImageName = 'blank'
      OnExecute = FormMenuCommand
    end
    object actRate400: TAction
      Tag = 115
      Category = #20493#36895
      Caption = '&4.00x'
      ImageIndex = 0
      ImageName = 'blank'
      OnExecute = FormMenuCommand
    end
    object actSpeedUp: TAction
      Tag = 116
      Category = #25773#25918
      Caption = '&'#21152#36895#65288'+'#65289
      OnExecute = FormMenuCommand
    end
    object actSpeedDown: TAction
      Tag = 117
      Category = #25773#25918
      Caption = '&'#20943#36895#65288'-'#65289
      OnExecute = FormMenuCommand
    end
    object actSpeedReset: TAction
      Tag = 118
      Category = #25773#25918
      Caption = '&'#37325#32622#36895#24230
      ShortCut = 16466
      OnExecute = FormMenuCommand
    end
    object actFullScreen: TAction
      Tag = 119
      Category = #25773#25918
      Caption = '&'#20840#23631#65288'F11 / '#21452#20987#65289
      ShortCut = 122
      OnExecute = FormMenuCommand
    end
    object actVideoTrack: TAction
      Tag = 120
      Category = #35270#39057
      Caption = '&'#35270#39057#36712
      OnExecute = FormMenuCommand
    end
    object actRenderVMR9: TAction
      Tag = 121
      Category = #28210#26579#22120
      Caption = 'VMR9 '#31383#21475#27169#24335#65288#20860#23481#24615#22909#65289'(&V)'
      OnExecute = FormMenuCommand
    end
    object actRenderEVR: TAction
      Tag = 122
      Category = #28210#26579#22120
      Caption = 'EVR'#65288#25903#25345#35299#30721#22120#21407#29983#36755#20986#65289'(&E)'
      OnExecute = FormMenuCommand
    end
    object actLavVideoCfg: TAction
      Tag = 123
      Category = #35270#39057
      Caption = 'LAV '#35270#39057#35299#30721#22120#37197#32622#8230'(&L)'
      OnExecute = FormMenuCommand
    end
    object actAudioTrack: TAction
      Tag = 124
      Category = #38899#39057
      Caption = '&'#38899#39057#36712
      OnExecute = FormMenuCommand
    end
    object actVolumeUp: TAction
      Tag = 125
      Category = #38899#39057
      Caption = '&'#38899#37327' +'#65288#19978#65289
      OnExecute = FormMenuCommand
    end
    object actVolumeDown: TAction
      Tag = 126
      Category = #38899#39057
      Caption = '&'#38899#37327' -'#65288#19979#65289
      OnExecute = FormMenuCommand
    end
    object actMute: TAction
      Tag = 127
      Category = #38899#39057
      Caption = '&'#38745#38899
      OnExecute = FormMenuCommand
    end
    object actLavAudioCfg: TAction
      Tag = 128
      Category = #38899#39057
      Caption = 'LAV '#38899#39057#35299#30721#22120#37197#32622#8230'(&L)'
      OnExecute = FormMenuCommand
    end
    object actOpenVideo: TAction
      Tag = 129
      Category = #25991#20214
      Caption = '&'#25171#24320#35270#39057#25991#20214'...'
      OnExecute = FormMenuCommand
    end
    object actOpenSubtitle: TAction
      Tag = 130
      Category = #25991#20214
      Caption = '&'#25171#24320#23383#24149#25991#20214'...'
      OnExecute = FormMenuCommand
    end
    object actExit: TAction
      Tag = 131
      Category = #25991#20214
      Caption = '&'#20851#38381
      OnExecute = FormMenuCommand
    end
    object actSubtitleTrack: TAction
      Tag = 132
      Category = #23383#24149
      Caption = '&'#23383#24149#36712#65288#20869#23884#65289
      OnExecute = FormMenuCommand
    end
    object actSubCloseExt: TAction
      Tag = 133
      Category = #23383#24149
      Caption = '&'#20851#38381#22806#25346#23383#24149
      OnExecute = FormMenuCommand
    end
    object actSubDelayPlus: TAction
      Tag = 134
      Category = #23383#24149
      Caption = '&'#23383#24149#24310#36831' +100ms'
      OnExecute = FormMenuCommand
    end
    object actSubDelayMinus: TAction
      Tag = 135
      Category = #23383#24149
      Caption = '&'#23383#24149#24310#36831' -100ms'
      OnExecute = FormMenuCommand
    end
    object actSubGrow: TAction
      Tag = 136
      Category = #23383#24149
      Caption = '&'#23383#24149#22686#22823#65288'F3'#65289
      ShortCut = 114
      OnExecute = FormMenuCommand
    end
    object actSubShrink: TAction
      Tag = 137
      Category = #23383#24149
      Caption = '&'#23383#24149#20943#23567#65288'F2'#65289
      ShortCut = 113
      OnExecute = FormMenuCommand
    end
  end
  object pmMain: TPopupMenu
    AutoHotkeys = maManual
    Left = 64
    Top = 232
  end
  object ImageCollection1: TImageCollection
    Images = <
      item
        Name = 'blank'
        SourceImages = <
          item
            Image.Data = {
              89504E470D0A1A0A0000000D49484452000000140000001408060000008D891D
              0D0000003049444154789CEDCCB11100300C0231CCFE43E752BAE63BA3013492
              462093D9D73067E0581AE60C1C4BC39C8143C7C3078B3400299189F328000000
              0049454E44AE426082}
          end>
      end
      item
        Name = 'check'
        SourceImages = <
          item
            Image.Data = {
              89504E470D0A1A0A0000000D49484452000000140000001408060000008D891D
              0D0000006F4944415478DACDD24D0E0031040650EEE7B873BF4E6633E90FFD50
              8BDAB4095E44301507DF073ED4FEBF109F813D760CCED85DA0817D4F1CDC6035
              A08C460C04D38DE0744F19CC06B562948760DFE49C6EDDA1D6A885D8BBF7EDCA
              89E9204253A0850A3EB37D013AA530988872F0059955261547F2C1C000000000
              49454E44AE426082}
          end>
      end>
    Left = 176
    Top = 168
  end
  object VirtualImageList1: TVirtualImageList
    AutoFill = True
    Images = <
      item
        CollectionIndex = 0
        CollectionName = 'blank'
        Name = 'blank'
      end
      item
        CollectionIndex = 1
        CollectionName = 'check'
        Name = 'check'
      end>
    ImageCollection = ImageCollection1
    Width = 20
    Height = 20
    Left = 176
    Top = 232
  end
  object FTimer: TTimer
    Enabled = False
    Interval = 100
    Left = 64
    Top = 319
  end
end
