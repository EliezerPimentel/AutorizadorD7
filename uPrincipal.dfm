object formPrincipal: TformPrincipal
  Left = 279
  Top = 161
  Width = 694
  Height = 486
  BorderIcons = [biSystemMenu, biMaximize]
  Caption = 'AutorizadorD7'
  Color = clAppWorkSpace
  Ctl3D = False
  Font.Charset = ANSI_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  FormStyle = fsMDIForm
  Menu = MainMenu1
  OldCreateOrder = False
  WindowState = wsMaximized
  OnClose = FormClose
  OnCreate = FormCreate
  OnShow = FormShow
  PixelsPerInch = 96
  TextHeight = 13
  object MainMenu1: TMainMenu
    object Arquivo1: TMenuItem
      Caption = '&Arquivo'
      object Salvarnovasconfiguraes1: TMenuItem
        Caption = '&Salvar novas configura'#231#245'es'
        ShortCut = 16467
        OnClick = Salvarnovasconfiguraes1Click
      end
      object N2: TMenuItem
        Caption = '-'
      end
      object Encerrar1: TMenuItem
        Caption = '&Encerrar'
        ShortCut = 32883
        OnClick = Encerrar1Click
      end
    end
  end
end
