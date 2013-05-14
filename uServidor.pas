unit uServidor;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms, WinSock,
  Dialogs, StdCtrls, ComCtrls, Buttons, ExtCtrls, Spin, Sockets, ScktComp, ImgList, DateUtils, Math;

function getIPs: Tstrings;

type
  TformServidor = class(TForm)
    PageControl1: TPageControl;
    tabRede: TTabSheet;
    tabLog: TTabSheet;
    GroupBox1: TGroupBox;
    GroupBox3: TGroupBox;
    Panel1: TPanel;
    logServidor: TMemo;
    Label1: TLabel;
    Servidor_PortaTCP: TEdit;
    Panel2: TPanel;
    StopServidor: TBitBtn;
    PlayServidor: TBitBtn;
    Panel3: TPanel;
    GroupBox2: TGroupBox;
    TreeView1: TTreeView;
    Timer1: TTimer;
    Shape9: TShape;
    Label11: TLabel;
    Servidor_Status: TLabel;
    Button1: TButton;
    Button2: TButton;
    Timer2: TTimer;
    TCPServer1: TServerSocket;
    Label13: TLabel;
    nivelDet: TSpinEdit;
    saveLog: TCheckBox;
    Label12: TLabel;
    ultLinhas: TSpinEdit;
    Label14: TLabel;
    GroupBox4: TGroupBox;
    Label2: TLabel;
    lblDias: TLabel;
    Servidor_Tempo_Conex: TLabel;
    Shape1: TShape;
    Label15: TLabel;
    Servidor_Clientes_Conect: TLabel;
    Shape11: TShape;
    Shape12: TShape;
    Label3: TLabel;
    Label16: TLabel;
    Shape13: TShape;
    Label6: TLabel;
    Shape14: TShape;
    Label17: TLabel;
    Shape15: TShape;
    Label18: TLabel;
    Shape16: TShape;
    Label19: TLabel;
    Shape17: TShape;
    Label20: TLabel;
    Servidor_Bytes_Recebidos: TLabel;
    Servidor_Bytes_Enviados: TLabel;
    Servidor_Nome_Maquina: TLabel;
    Servidor_Endereco_IP: TLabel;
    Servidor_Executado_Em: TLabel;
    Servidor_Ativado_Em: TLabel;
    Servidor_Parado_Em: TLabel;
    tabThreads: TTabSheet;
    GroupBox5: TGroupBox;
    ImageList1: TImageList;
    Panel4: TPanel;
    Shape2: TShape;
    Button3: TButton;
    Panel5: TPanel;
    listaThreads: TListView;
    GroupBox6: TGroupBox;
    Label4: TLabel;
    Servidor_string_retorno: TEdit;
    btnOpcoes: TButton;
    Servidor_Arquivo_Log: TLabel;
    procedure FormCreate(Sender: TObject);
    procedure PlayServidorClick(Sender: TObject);
    procedure Timer1Timer(Sender: TObject);
    procedure TreeView1Click(Sender: TObject);
    procedure StopServidorClick(Sender: TObject);
    procedure Button1Click(Sender: TObject);
    procedure Button2Click(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure Timer2Timer(Sender: TObject);
    procedure TCPServer1ClientError(Sender: TObject;
      Socket: TCustomWinSocket; ErrorEvent: TErrorEvent;
      var ErrorCode: Integer);
    procedure TCPServer1ClientRead(Sender: TObject;
      Socket: TCustomWinSocket);
    procedure TCPServer1ClientConnect(Sender: TObject;
      Socket: TCustomWinSocket);
    procedure TCPServer1ClientDisconnect(Sender: TObject;
      Socket: TCustomWinSocket);
    procedure Button3Click(Sender: TObject);
    procedure listaThreadsColumnClick(Sender: TObject;
      Column: TListColumn);
    procedure btnOpcoesClick(Sender: TObject);
  private
    { Private declarations }
    Hoje: TDate;
    procedure ProcessaBuffer(const Buffer: string; const Socket: TCustomWinSocket);
    procedure Detalhe(const nivel: integer; const detalhe: string);
  public
    { Public declarations }
    LogAGravar: TStrings;
    procedure MandaResposta(const Socket: TCustomWinSocket; const resposta: string);
    procedure AtualizaListaThreads(const SocketID: integer; const ThreadId: integer; const ImageID: integer; const Tempo: integer; const origem: string; const status: string);
  end;

var
  formServidor: TformServidor;
  hora, minuto, segundo: word;
  dia: integer;

  
implementation

uses uLogs, uProcessosThreads;

{$R *.dfm}

// Escreve as ocorrências no LOG
procedure TformServidor.Detalhe(const nivel: integer; const detalhe: string);
var s1: string;
begin
  if (nivel > nivelDet.Value) then exit;
  s1 := detalhe;
  Apoio_Detalhe(logServidor, s1, ultLinhas.Value);
  LogAGravar.Add(s1);
end;

procedure TformServidor.FormCreate(Sender: TObject);
var i: integer;
begin
  Hoje           := Date();
  LogAGravar     := TStringList.Create;

  with PageControl1 do
  begin
    for i := 0 to PageCount -1 do
    begin
      Pages[i].TabVisible := False;
    end;
    ActivePage            := tabThreads;
  end;
  TreeView1.Items.Item[0].SelectedIndex := 2;

  Servidor_Parado_Em.Caption      := 'Ainda não foi parado.';
  Servidor_Executado_Em.Caption   := FormatDateTime('dd/mm/yyyy hh:nn:ss', now);
  hora := 0; segundo := 0; minuto := 0; dia  := 0;

  Detalhe(1,'Servidor Iniciado em: ' + FormatDateTime('dd/mm/yyyy hh:nn:ss', now));
  Servidor_Arquivo_Log.Caption    := ExtractFileDir(Application.ExeName) + '\Logs\logServidor_'+FormatDateTime('yyyymmdd', now) + '.txt';

  lblDias.Caption := '';
  Panel1.Height   := 75;

  PlayServidor.Click;
end;

// Botão Parar Servidor
procedure TformServidor.StopServidorClick(Sender: TObject);
begin
  Servidor_Status.Caption    := 'Parado';
  Servidor_Status.Font.Color := clRed;
  TCPServer1.Active          := False;
  Timer1.Enabled             := False;
  stopServidor.Enabled       := False;
  playServidor.Enabled       := True;
  GroupBox1.Enabled          := True;
  Servidor_Parado_Em.Caption := FormatDateTime('dd/mm/yyyy hh:nn:ss', now);

  Detalhe(1,'Servidor Parado em: ' + FormatDateTime('dd/mm/yyyy hh:nn:ss', now));
end;

// Botão Ativar Servidor
procedure TformServidor.PlayServidorClick(Sender: TObject);
var lstIPs: TStrings;
begin
  try
    TCPServer1.Port   := StrToIntDef(Servidor_PortaTCP.Text, 16500);
    TCPServer1.Active := True;
  except
    on e: exception do begin
      Detalhe(1, 'Erro ao iniciar servidor de conexões: ' + e.Message);
      exit;
    end;
  end;

  Timer1.Enabled                  := True;
  stopServidor.Enabled            := True;
  playServidor.Enabled            := False;
  GroupBox1.Enabled               := False;
  Servidor_Nome_Maquina.Caption   := TCPServer1.Socket.LocalHost;

  lstIPs := TStringList.Create;
  lstIPs := getIPs;

  if (lstIPs.Count > 0) then
  Servidor_Endereco_IP.Caption    := lstIps.Strings[0]
  else
  Servidor_Endereco_IP.Caption    := TCPServer1.Socket.LocalAddress;

  lstIPs.Free;
  
  Servidor_Ativado_Em.Caption     := FormatDateTime('dd/mm/yyyy hh:nn:ss', now);
  Servidor_Status.Caption         := 'Ativado';
  Servidor_Status.Font.Color      := clNavy;

  Detalhe(1, 'Servidor Ativado em: ' + FormatDateTime('dd/mm/yyyy hh:nn:ss', now));
end;

// Mostra quanto tempo tem de duração a conexão (não conta as paradas)
procedure TformServidor.Timer1Timer(Sender: TObject);
var tempo: TTime;
begin
  inc(segundo);
  if (segundo = 60) then
  begin
    segundo := 0;
    inc(minuto);
  end;

  if (minuto = 60) then
  begin
    inc(hora);
    minuto := 0; segundo := 0;
  end;

  if (hora = 24) then
  begin
    inc(dia);
    hora := 0; minuto := 0; segundo := 0;

    if (dia = 1)
    then lblDias.Caption := '1 dia e'
    else lblDias.Caption := IntToStr(dia) + ' dias e ';
  end;

  try
    tempo                        := EncodeTime(hora, minuto, segundo, 0);
    Servidor_Tempo_Conex.Caption := TimeToStr(tempo);
  except
    on e: exception do begin
      Detalhe(10,'Erro ao mostrar tempo: hora=' + IntToStr(hora) + ', minuto=' + IntToStr(minuto) + ', segundo=' + IntToStr(segundo));
      Detalhe(10,'Erro ao mostrar tempo, parando timer: ' + e.Message);
      timer1.Enabled := false;
    end;
  end;
end;

procedure TformServidor.TreeView1Click(Sender: TObject);
begin
  if (TreeView1.Selected.Index < 0) then exit;
  PageControl1.ActivePageIndex := TreeView1.Selected.Index;
end;

// Limpar a tela de Logs
procedure TformServidor.Button1Click(Sender: TObject);
begin
  LimpaTelaDeLogs(logServidor);
end;

//Abrir log no bloco de notas
procedure TformServidor.Button2Click(Sender: TObject);
var fnTemp: string;
begin
  fnTemp := ExtractFileDir(Application.ExeName) + '\Logs\logServidorTEMP_'+FormatDateTime('yyyymmdd', now) + '.txt';
  AbreLogNoBlocoNotas(logServidor, fnTemp);
end;

procedure TformServidor.FormDestroy(Sender: TObject);
begin
  Detalhe(1,'Encerrando o Autorizador com solicitação de usuário!');

  if (SaveLog.Checked) then Grava_Log(LogAGravar, Servidor_Arquivo_Log.Caption);

  if (LogAGravar <> nil) then
  begin
    LogAGravar.Free;
    LogAGravar := nil;
  end;
end;

// Para gravar o Log em segundo plano para melhor performance
procedure TformServidor.Timer2Timer(Sender: TObject);
begin
  if (Hoje <> Date()) then
  begin
    Servidor_Arquivo_Log.Caption    := ExtractFileDir(Application.ExeName) + '\Logs\logServidor_'+FormatDateTime('yyyymmdd', now) + '.txt';
    Hoje := Date();
  end;
  if (LogAGravar.Count = 0) then exit;
  if (SaveLog.Checked) then Grava_Log(LogAGravar, Servidor_Arquivo_Log.Caption);
end;

// Cria a Thread de Processo para processar o buffer recebido
procedure TformServidor.ProcessaBuffer(const Buffer: string; const Socket: TCustomWinSocket);
var
  thProcessos: TProcessos;
begin
  thProcessos                 := TProcessos.Create(Buffer, socket, TCPServer1);

  AtualizaListaThreads(socket.SocketHandle, thProcessos.ThreadID, 1, 0, socket.RemoteAddress, 'criando thread');

  thProcessos.FreeOnTerminate := True;
  thProcessos.Resume;
end;

procedure TformServidor.TCPServer1ClientError(Sender: TObject; Socket: TCustomWinSocket; ErrorEvent: TErrorEvent; var ErrorCode: Integer);
begin
  AtualizaListaThreads(socket.SocketHandle, 0, 2, 0, socket.RemoteAddress, 'erro de socket: ' + IntToStr(ErrorCode));

  Detalhe(1,'(skt:' + IntToStr(Socket.SocketHandle) + ') Erro de conexão : ' + Socket.RemoteAddress + ',' + IntToStr(ErrorCode));

  try
    Socket.Close;
  except

  end;

  ErrorCode := 0;
end;

//Recebendo buffer enviado pelo client
procedure TformServidor.TCPServer1ClientRead(Sender: TObject; Socket: TCustomWinSocket);
var bytesRecebidos: Word;
    strBuffer, strCommand: string;
begin
  AtualizaListaThreads(socket.SocketHandle, 0, 4, 0, socket.RemoteAddress, 'recebendo...');

  Servidor_Endereco_IP.Caption := Socket.LocalAddress;

  bytesRecebidos := StrToIntDef(Servidor_Bytes_Recebidos.Caption, 0);
  strBuffer      := Socket.ReceiveText;

  strCommand                       := trim(strBuffer);
  bytesRecebidos                   := bytesRecebidos + length(strCommand);
  Servidor_Bytes_Recebidos.Caption := FloatToStr(bytesRecebidos);

  Detalhe(5,'(skt:' + IntToStr(Socket.SocketHandle) + ') Recebendo buffer com : ' + IntToStr(length(strCommand)) + ' bytes.');
  Detalhe(8,'(skt:' + IntToStr(Socket.SocketHandle) + ') Buffer Recebido : ' + strCommand);

  processaBuffer(strBuffer, Socket);
end;

//Cliente conectou via sockt
procedure TformServidor.TCPServer1ClientConnect(Sender: TObject; Socket: TCustomWinSocket);
begin
  AtualizaListaThreads(socket.SocketHandle, 0, 0, 0, socket.RemoteAddress, 'conectado.');

  Servidor_Clientes_Conect.Caption := IntToStr(StrToIntDef(Servidor_Clientes_Conect.Caption, 0) +1);
  Servidor_Clientes_Conect.Refresh;
  Detalhe(5,'(skt:' + IntToStr(Socket.SocketHandle) + ') Conectado por : ' + Socket.RemoteAddress);
end;

procedure TformServidor.TCPServer1ClientDisconnect(Sender: TObject; Socket: TCustomWinSocket);
begin
  AtualizaListaThreads(socket.SocketHandle, 0, 3, 0, socket.RemoteAddress, 'desconectado');

  if (Servidor_Clientes_Conect.Caption <> '0')
  then Servidor_Clientes_Conect.Caption := IntToStr(StrToIntDef(Servidor_Clientes_Conect.Caption, 1) -1);
  Servidor_Clientes_Conect.Refresh;

  Detalhe(5, '(skt:' + IntToStr(Socket.SocketHandle) + ') Desconectado por : ' + Socket.RemoteAddress);
end;

procedure TformServidor.MandaResposta(const Socket: TCustomWinSocket; const resposta: string);
var
    bytesEnviados: Word;
    strToSend: String;
begin
  strToSend := resposta;

  if (Socket = nil) then exit;

  if (Socket.Connected) then
  begin
    bytesEnviados := Socket.SendText(strToSend);

    if (bytesEnviados = 0) then
    begin
      sleep(100);
      bytesEnviados := Socket.SendText(strToSend);
    end;

    if (bytesEnviados > 0) then
    begin
      Detalhe(5, '(skt:' + IntToStr(Socket.SocketHandle) + ') Enviando resposta ('+IntToStr(bytesEnviados)+') bytes: '+resposta);
    end else
    begin
      Detalhe(5, '(skt:' + IntToStr(Socket.SocketHandle) + ') Nao foi possivel enviar ('+IntToStr(bytesEnviados)+') bytes: '+resposta);
    end;
  end;
  socket.Close;

  bytesEnviados                        := StrToIntDef(Servidor_Bytes_Enviados.Caption, 0);
  bytesEnviados                        := bytesEnviados  + length(strToSend);
  Servidor_Bytes_Enviados.Caption  := FloatToStr(bytesEnviados);

  AtualizaListaThreads(socket.SocketHandle, 0, 1, 0, socket.RemoteAddress, 'respondendo:'+resposta);
end;

procedure TformServidor.AtualizaListaThreads(const SocketID: integer; const ThreadId: integer; const ImageID: integer; const Tempo: integer; const origem: string; const status: string);
var item: TListItem;
    dif: integer;
begin
  listaThreads.Canvas.Lock;

  if (ImageID = 0) then // cria nova conexao
  begin
    listaThreads.Items.BeginUpdate;
    item            := listaThreads.Items.Insert(0);
    item.Caption    := IntToStr(SocketID);
    item.ImageIndex := 4;
    item.SubItems.Add(IntToStr(ThreadID));
    item.SubItems.Add(formatDateTime('dd/mm/yyyy hh:nn:ss:zz', now));
    item.SubItems.Add(origem);
    item.SubItems.Add(' ');
    item.SubItems.Add('Conectado...');
    item.SubItems.Add(' ');

    if (listaThreads.Items.Count > 200) then listaThreads.Items.Delete(200);
    listaThreads.Items.EndUpdate;
    listaThreads.Canvas.UnLock;
    exit;
  end;

  item := listaThreADS.FindCaption(0, IntToStr(SocketID), false, true, false); // encontra socket existente

  if (item = nil) then exit; // nao achou, entao vaza...

  listaThreads.Items.BeginUpdate;

  item.ImageIndex  := ImageID;
  if (Tempo <> 0)
  then item.SubItems.Strings[3] := IntToStr(Tempo);

  if (ThreadID <> 0)
  then item.SubItems.Strings[0] := IntToStr(ThreadID);

  item.SubItems.Strings[4]      := Status;

  if (status = 'desconectado') then
  begin
    dif := MilliSecondsBetween(now, StrToDateTime(item.SubItems.Strings[1]));
    item.SubItems.Strings[3] := IntToStr(dif);//+'ms';
  end;

  if (imageId = 2) then item.SubItems.Strings[5] := status;

  listaThreads.Items.EndUpdate;
  listaThreads.Canvas.UnLock;

end;

procedure TformServidor.Button3Click(Sender: TObject);
begin
  listaThreads.Items.BeginUpdate;
  listaThreads.Items.Clear;
  listaThreads.Items.EndUpdate;
end;

function SortByColumn(PItem1, PItem2: TListItem; PData: integer):integer; stdcall;
var
  Ascending: Boolean;
  f1, f2: double;
  s1, s2: String;
begin
  // Check out the Ascending or Descending property, this is embedded in the sign of PData
  Ascending := Sign(PData) = 1;

  // Get away the ascending or descending property
  PData := abs(PData);

  // Get the strings to compare
  if PData = 1 then
    begin
      s1 := PItem1.Caption;
      s2 := PItem2.Caption;
    end
  else
    begin
      s1 := PItem1.SubItems[PData-2];
      s2 := PItem2.SubItems[PData-2];
    end;

  try
    // Check out if the column contains numerical data
    f1 := StrToFloat(s1);
    f2 := StrToFloat(s2);

    // if code execution get's to this point, we have to deal with numerical values, and return -1, 0, 1 according to
    if f1 > f2 then
      result := 1
    else if f1 < f2 then
      result := -1
    else
      result := 0;
  except
    // Else the result is based upon string comparison
    Result := AnsiCompareText(s1, s2)
  end;

  if not Ascending then Result := -Result;
end;

procedure TformServidor.listaThreadsColumnClick(Sender: TObject; Column: TListColumn);
var i: integer;
begin
  for i := 0 to TListView(Sender).Columns.Count -1 do
    TListView(Sender).Columns.Items[i].ImageIndex := -1;

  // Check out if this is the first time the column is sorted
  if Column.Tag = 0 then
    // Default = Ascending
    Column.Tag        := 1
  else
    Column.Tag        := -Column.Tag;

  if (Column.tag = -1)
  then Column.ImageIndex := 5
  else Column.ImageIndex := 0;


  // Perform the sort 
  // the second parameter has a part for the ascending property, the sign of the parameter and the 
  // column index is increased by one, else the first column (index=0) is always sorted Descending 
  // In the SortByCloumn function this assumption is taken into account 
  TListView(Sender).CustomSort(@SortByColumn, Column.Tag * (Column.Index + 1));

end;

procedure TformServidor.btnOpcoesClick(Sender: TObject);
begin
  if (btnOpcoes.Tag = 0) then
  begin
    btnOpcoes.Caption := '<< Menos opções';
    btnOpcoes.Tag     := 1;
    Panel1.Height     := 130;
  end else
  begin
    btnOpcoes.Caption := 'Mais opções >>';
    btnOpcoes.Tag     := 0;
    Panel1.Height     := 75;
  end;
end;

function getIPs: Tstrings;
type
  TaPInAddr = array[0..10] of PInAddr;
  PaPInAddr = ^TaPInAddr;
var
  phe: PHostEnt;
  pptr: PaPInAddr;
  Buffer: array[0..63] of Char;
  I: Integer;
  GInitData: TWSAData;
begin
  WSAStartup($101, GInitData);
  Result := TstringList.Create;
  Result.Clear;
  GetHostName(Buffer, SizeOf(Buffer));
  phe := GetHostByName(buffer);
  if phe = nil then Exit;
  pPtr := PaPInAddr(phe^.h_addr_list);
  I    := 0;
  while pPtr^[I] <> nil do
  begin
    Result.Add(inet_ntoa(pptr^[I]^));
    Inc(I);
  end;
  WSACleanup;
end;


end.
