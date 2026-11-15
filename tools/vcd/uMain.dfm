object frmVCD: TfrmVCD
  Left = 0
  Top = 0
  BorderIcons = [biSystemMenu, biMinimize, biMaximize, biHelp]
  BorderStyle = bsNone
  Caption = 'frmVCD'
  ClientHeight = 280
  ClientWidth = 448
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  Position = poDesigned
  OnClose = FormClose
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  OnResize = FormResize
  DesignSize = (
    448
    280)
  TextHeight = 15
  object pnlDLL: TPanel
    Left = 8
    Top = 6
    Width = 432
    Height = 266
    Anchors = [akLeft, akTop, akRight, akBottom]
    BevelOuter = bvNone
    Caption = 'pnlDLL'
    Color = clWhite
    ParentBackground = False
    ShowCaption = False
    TabOrder = 0
  end
end
