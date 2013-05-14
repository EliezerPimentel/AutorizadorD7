unit uPrincipal;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, jpeg, ExtCtrls, StdCtrls, Menus, XPMan;

type
  TformPrincipal = class(TForm)
    MainMenu1: TMainMenu;
    Arquivo1: TMenuItem;
    Encerrar1: TMenuItem;
    Salvarnovasconfiguraes1: TMenuItem;
    N2: TMenuItem;
    procedure FormCreate(Sender: TObject);
    procedure Salvarnovasconfiguraes1Click(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure Encerrar1Click(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
  private
    { Private declarations }
   procedure DetalhePrincipal(const nivel: integer; const detalhe: string);
   procedure SalvarConfiguracoes;
   procedure RestauraConfiguracoes;
  public
    { Public declarations }
  end;

var
  formPrincipal: TformPrincipal;
  flag1: boolean;
  FN_ARQUIVO_INICIALIZACAO: string;

const
  MSG_SAIR = 'Você está prestes a encerrar o Autorizador. Isto poderá afetar o funcionamento de todo o sistema de autorização, você está certo que deseja finalizar?';

implementation

uses UServidor, uLogs;

{$R *.dfm}

//Funções
function BooleanToString(const b: boolean): String;
begin
   if b = true then result := '1' else result := '0';
end;

function StringToBoolean(const s: string): boolean;
begin
   if s = '1' then result := true else result := false;
end;


procedure TformPrincipal.FormCreate(Sender: TObject);
var dirLogs: string;
begin
  flag1                    := true;

  // Iniciando verificação do Path de Log
  dirLogs                  := ExtractFileDir(Application.ExeName) + '\Logs';
  FN_ARQUIVO_INICIALIZACAO := ExtractFileDir(Application.ExeName) + '\AutorizadorD7.ini';

  if (DirectoryExists(dirLogs) = False) then
  begin
    try
      ForceDirectories(dirLogs);
    except
      on e: exception do begin
        ShowMessage('Erro ao criar diretório de Logs: '+ e.message);
        Application.Terminate;
      end;
    end;
  end;
end;

procedure TformPrincipal.FormShow(Sender: TObject);
begin
  if (flag1) then
  begin
    sleep(500);
    flag1 := false;
    RestauraConfiguracoes();
    //Cascade;
  end;
end;

procedure TformPrincipal.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  if (Application.MessageBox(MSG_SAIR,'Aviso! Encerrando Autorizador.', MB_YESNO + MB_ICONQUESTION) = IDYES) then
  begin
    Application.Terminate;
  end;
  Action := caNone;
end;

{-------------- Inicio das Opções de Menu ------------------}

// Encerrar o programa
procedure TformPrincipal.Encerrar1Click(Sender: TObject);
begin
  if (Application.MessageBox(MSG_SAIR,'Aviso! Encerrando Autorizador.', MB_YESNO + MB_ICONQUESTION) = IDYES) then
  begin
    Application.Terminate;
  end;
end;

// Salvar novas configurações
procedure TformPrincipal.Salvarnovasconfiguraes1Click(Sender: TObject);
begin
  SalvarConfiguracoes();
end;

{-------------- Final das Opções de Menu ------------------}

// Esta procedure permite acrescentar detalhes na janela de LOG do Servidor
procedure TformPrincipal.DetalhePrincipal(const nivel: integer; const detalhe: string);
var s: string;
begin
  if (formServidor = nil) then exit;
  if (formServidor.logServidor = nil) then exit;
  if (nivel > formservidor.nivelDet.Value) then exit;
  
  s := detalhe;
  Apoio_Detalhe(formServidor.logServidor, s, formServidor.ultLinhas.Value );
end;

procedure TformPrincipal.SalvarConfiguracoes;
var l: TSTrings;
begin
  l := TStringList.Create;

  // form Servidor
  with formServidor do
  begin
    l.Values['Porta_TCP']        := Servidor_PortaTCP.Text;
    l.Values['nivelDet']         := nivelDet.Text;
    l.Values['SaveLog']          := BooleanToString(saveLog.Checked);
    l.Values['ultLinhas']        := ultLinhas.Text;
    l.values['string_retorno']   := Servidor_string_retorno.Text;
  end;

  l.SaveToFile(FN_ARQUIVO_INICIALIZACAO);
  l.Free;

  DetalhePrincipal(8, 'Salvando arquivo de configurações.');
end;

procedure TformPrincipal.RestauraConfiguracoes;
var l: TStrings;
begin
  if (FileExists(FN_ARQUIVO_INICIALIZACAO) = false) then exit;

  l := TStringList.Create;
  try
    l.LoadFromFile(FN_ARQUIVO_INICIALIZACAO);
  except
    on e: exception do begin
      DetalhePrincipal(8, 'Não consegui ler arquivo de configurações: '+e.Message);
      l.Free;
      exit;
    end;
  end;

  with formServidor do
  begin
    Servidor_PortaTCP.Text := l.Values['Porta_TCP'];

    if (l.Values['SaveLog'] <> '')
    then saveLog.Checked   := StringToBoolean(l.Values['SaveLog'])
    else saveLog.Checked   := true;

    if (l.Values['nivelDet'] <> '')
    then nivelDet.Text     := l.Values['nivelDet']
    else nivelDet.Text     := '5';

    if (l.Values['ultLinhas'] <> '')
    then ultLinhas.Text    := l.Values['ultLinhas']
    else ultLinhas.Text    := '200';

    if (l.Values['string_retorno'] <> '')
    then Servidor_String_Retorno.Text    := l.Values['string_retorno']
    else Servidor_String_Retorno.Text    := '';
  end;

  l.Free;

  DetalhePrincipal(8, 'Carregando arquivo de configurações.');
end;

end.
