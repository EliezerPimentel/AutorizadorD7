unit uServerSocket;

interface

uses Windows, SysUtils, classes, Forms, scktcomp;

type
  TServerSocket = class(TObject)
  private
    { Private declarations }
    ServerSocket : TClientSocket;
    Connecting   : Boolean;
    strReceive   : string;
    On_strReceive: Boolean;

    procedure OnRead(Sender: TObject; Socket: TCustomWinSocket);
    function  wait_for_connect: Boolean;
  public
    { Public declarations }
    constructor Create(AOwner: TComponent); virtual;
    destructor  Destroy; override;

    function Connect(const IPAddress: string; portNumber: integer) : Boolean;
    function Receive(var str_Receive: string; TimeOut: integer) : Boolean;
    function Send(strToSend: string) : Boolean;
    function Close : Boolean;
  end;

implementation

constructor TServerSocket.Create(AOwner: TComponent);
begin
  ServerSocket        := TClientSocket.Create(AOwner);
  ServerSocket.OnRead := OnRead;
  Connecting          := False;
  strReceive          := '';
  On_strReceive       := False;
end;

destructor TServerSocket.Destroy;
begin
   ServerSocket.Free;
end;

procedure TServerSocket.OnRead(Sender: TObject; Socket: TCustomWinSocket);
begin
   On_strReceive := True;
   strReceive    := ServerSocket.Socket.ReceiveText;
end;

function TServerSocket.Connect(const IpAddress: string; portNumber: integer) : Boolean;
begin
  ServerSocket.Address    := IpAddress;
  ServerSocket.Port       := portNumber;
  ServerSocket.ClientType := ctNonBlocking;
  ServerSocket.Open;
  Connecting              := True;
  result                  := True;
end;

function TServerSocket.wait_for_connect: Boolean;
var i: integer;
begin
   result := ServerSocket.Active;
   if (Connecting = false) then exit;
   for i := 1 to 200 do
   begin
       if (ServerSocket.Active) = False then
       begin
           Application.ProcessMessages;
           Sleep(50);
       end
       else begin
           Connecting := False;
           result     := True;
           exit;
       end;
   end;
end;

function TServerSocket.Send(StrToSend: string) : Boolean;
begin
   Result := wait_for_connect;
   if (result = False) then exit;
   ServerSocket.Socket.SendText(StrToSend);
   Result := True;
end;

function TServerSocket.Receive(var str_receive: string; TimeOut: integer) : Boolean;
var i: integer;
begin
   Result := wait_for_connect;
   if (result = False) then exit;
   if TimeOut < 1 then TimeOut := 1;
   for i := 1 to TimeOut*20 do
   begin
       if (On_strReceive = False) then
       begin
           Application.ProcessMessages;
           Sleep(10);
       end
       else begin
           str_Receive := strReceive;
           strReceive  := '';
           On_strReceive := False;
           result := True;
           exit;
       end;
   end;
end;

function TServerSocket.Close : Boolean;
begin
   ServerSocket.Active := False;
   result              := True;
end;

end.
