unit uProcessosThreads;

interface

uses
  Dialogs, Classes, StdCtrls, ScktComp, SysUtils, Forms, DateUtils, ExtCtrls, Variants;

type
  TProcessos = class(TThread)
  Buffer:          String;
  strRetornoAutor: String;
  Socket:          TCustomWinSocket;
  h1:              TDateTime;
  idSocket:        Integer;
  timeSend:        TDateTime;
  TCPServer1:      TServerSocket;

  private
    { Private declarations }
  protected
    procedure DetalheServidor(const nivel: integer; const detalhe: string);
    procedure Apoio_Detalhe(const M: TMemo; var detalhe: string; const MaxLinhas: Integer);
    procedure Execute; override;
    procedure ProcessaBuffer;
    procedure MandaResposta;
    procedure evTerminate(sender : TObject);
  public
    constructor Create(thBuffer: string; thSocket: TCustomWinSocket; thTCPServer: TServerSocket); reintroduce;

  end;

implementation

uses uLogs, UServidor;

{ TProcessos }

// Cria a thread com o buffer, socket e modo de captura
constructor TProcessos.Create(thBuffer: string; thSocket: TCustomWinSocket; thTCPServer: TServerSocket);
begin
  Buffer          := thBuffer;
  Socket          := thSocket;
  OnTerminate     := evTerminate;
  idSocket        := Socket.SocketHandle;
  TCPServer1      := thTCPServer;

  inherited Create(False);

  DetalheServidor(5, '(skt:' + IntToStr(idSocket) + ')(th:' + IntToStr(ThreadID) + ') Criando nova thread de processo.');
end;

procedure Tprocessos.evTerminate(sender : TObject);
var dif: Integer;
begin
  if (Socket.Connected) then
  begin
    try
      Socket.Close;
      dispose(socket.Data);
    except

    end;
  end;

  dif := MilliSecondsBetween(now, h1);
  DetalheServidor(5, '(skt:' + IntToStr(idSocket) + ')(th:' + IntToStr(ThreadID) +  ') Liberando thread de processo. Tempo de processo: ' + IntToStr(dif) + ' mili-segundos.');

end;

// Inicia a execução da Thread
procedure TProcessos.Execute;
begin
  Priority := tpNormal;
  Synchronize(ProcessaBuffer);
end;

// Rotina Responsavel pela exibição dos logs nas janelas
procedure TProcessos.Apoio_Detalhe(const M: TMemo; var detalhe: string; const MaxLinhas: Integer);
begin
  detalhe := FormatDateTime('dd/mm/yyyy hh:nn:ss', now) + ' ' + detalhe;
  if (m = nil) then exit;

  M.Lines.BeginUpdate;
  M.Lines.Insert(0, detalhe);

  if (m.Lines.Count >= MaxLinhas)
  then M.Lines.Delete(M.Lines.Count-1); // mostra apenas as últimas 200 linhas

  M.Lines.EndUpdate;
end;


procedure TProcessos.DetalheServidor(const nivel: integer; const detalhe: string);
var s1: string;
begin
  if (nivel > formServidor.nivelDet.Value) then exit;
  s1 := detalhe;
  formServidor.LogAGravar.Add(s1);
  Apoio_Detalhe(formServidor.LogServidor, s1, formServidor.ultLinhas.Value);
end;

// Processa o buffer recebido pela Thread
procedure TProcessos.ProcessaBuffer;
var strBuffer: string;
begin
   //Application.ProcessMessages;
   strBuffer := Buffer;
   h1        := now; // Apenas para contabilizar o tempo gasto
   
   {





    Processando o buffer





   }


   strRetornoAutor := formServidor.Servidor_string_retorno.Text;
   Synchronize(MandaResposta);
end;

{------------------------------------------------------------------------------}

procedure TProcessos.MandaResposta;
var
    bytesEnviados: Word;
    strToSend: String;
begin
  strToSend := strRetornoAutor;

  if (Socket = nil) then exit;

  //Socket.Lock;
  if (Socket.Connected) then
  begin
    bytesEnviados := Socket.SendText(strToSend);

    if (bytesEnviados > 0) then
    begin
      DetalheServidor(5, '(skt:' + IntToStr(Socket.SocketHandle) + ') Enviando resposta ('+IntToStr(bytesEnviados)+') bytes: '+strRetornoAutor);
    end else
    begin
      DetalheServidor(5, '(skt:' + IntToStr(Socket.SocketHandle) + ') Nao foi possivel enviar ('+IntToStr(bytesEnviados)+') bytes: '+strRetornoAutor);
    end;
  end;
  //Socket.UnLock;

  bytesEnviados                        := StrToIntDef(formServidor.Servidor_Bytes_Enviados.Caption, 0);
  bytesEnviados                        := bytesEnviados  + length(strToSend);
  formServidor.Servidor_Bytes_Enviados.Caption  := FloatToStr(bytesEnviados);

  formServidor.AtualizaListaThreads(socket.SocketHandle, 0, 1, 0, socket.RemoteAddress, 'respondendo:'+strRetornoAutor);

end;

end.
