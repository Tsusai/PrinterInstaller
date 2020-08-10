object MainApp: TMainApp
  Left = 0
  Top = 0
  BorderIcons = [biSystemMenu, biMinimize]
  BorderStyle = bsSingle
  Caption = 'Printer Installer'
  ClientHeight = 220
  ClientWidth = 635
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  PixelsPerInch = 96
  TextHeight = 13
  object PrintersLbl: TLabel
    Left = 216
    Top = 4
    Width = 114
    Height = 13
    Caption = 'Check Printers to Install'
  end
  object DefaultLbl: TLabel
    Left = 423
    Top = 4
    Width = 102
    Height = 13
    Caption = 'Select Default Printer'
  end
  object PresetsLbl: TLabel
    Left = 8
    Top = 8
    Width = 36
    Height = 13
    Caption = 'Presets'
  end
  object PrinterCheckBox: TCheckListBox
    Left = 216
    Top = 23
    Width = 201
    Height = 113
    OnClickCheck = PrinterCheckBoxClickCheck
    ItemHeight = 13
    TabOrder = 0
  end
  object DefaultBox: TListBox
    Left = 424
    Top = 23
    Width = 201
    Height = 113
    ItemHeight = 13
    TabOrder = 1
  end
  object InstallBtn: TButton
    Left = 550
    Top = 187
    Width = 75
    Height = 25
    Caption = 'Install'
    TabOrder = 2
    OnClick = InstallBtnClick
  end
  object PresetsBox: TListBox
    Left = 8
    Top = 23
    Width = 201
    Height = 113
    ItemHeight = 13
    TabOrder = 3
    OnClick = PresetsBoxClick
  end
  object DuplexRadio: TRadioGroup
    Left = 8
    Top = 142
    Width = 185
    Height = 70
    Caption = 'Duplex Settings'
    ItemIndex = 0
    Items.Strings = (
      'Disable for All Users'
      'Disable for Current User'
      'Leave Default Settings')
    TabOrder = 4
  end
end
