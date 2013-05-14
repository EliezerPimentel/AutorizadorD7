program AutorizadorD7;

uses
  Forms,
  uPrincipal in 'uPrincipal.pas' {formPrincipal},
  UServidor in 'uServidor.pas' {formServidor},
  uLogs in 'uLogs.pas',
  uProcessosThreads in 'uProcessosThreads.pas',
  uServerSocket in 'uServerSocket.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.Title := 'AutorizadorD7';
  Application.CreateForm(TformPrincipal, formPrincipal);
  Application.CreateForm(TformServidor, formServidor);
  Application.Run;
end.
