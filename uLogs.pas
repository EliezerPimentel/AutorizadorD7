unit uLogs;

interface
uses
   Classes, StdCtrls, Windows, SysUtils, Controls;

const
  MaxFileLogs = 40;

procedure Apoio_Detalhe(const M: TMemo; var detalhe: string; const MaxLinhas: integer);
procedure Grava_Log(const LogAGravar: TStrings; const fn: string);
procedure LimpaTelaDeLogs(const M: TMemo);
procedure AbreLogNoBlocoNotas(const M: TMemo; const fnTemp: string);

implementation

// Exibe logs
procedure Apoio_Detalhe(const M: TMemo; var detalhe: string; const MaxLinhas: Integer);
begin
  detalhe := FormatDateTime('dd/mm/yyyy hh:nn:ss,zzz ', now) + detalhe;
  if (m = nil) then exit;
  
  M.Lines.BeginUpdate;
  M.Lines.Insert(0, detalhe);

  if (m.Lines.Count >= MaxLinhas)
  then M.Lines.Delete(M.Lines.Count-1); // mostra apenas as últimas 200 linhas

  M.Lines.EndUpdate;
end;

procedure Grava_Log(const LogAGravar: TStrings; const fn: string);
var f: TextFile;
    s: string;
begin
   if (LogAGravar = nil) then exit;
   if (LogAGravar.Count < 1) then exit;

   if (DirectoryExists(ExtractFileDir(fn))=  false) then ForceDirectories(ExtractFileDir(fn));

   AssignFile(f, fn);

   if (FileExists(fn) = true)
   then Append(f)
   else Rewrite(f);

   while LogAGravar.Count >= 1 do
   begin
       s := LogAGravar[0];
       LogAGravar.Delete(0);
       try
           Writeln(f, s);
       except
           // se ocorrer algum erro, ignorar...
       end;
   end;
   CloseFile(f);
end;

procedure LimpaTelaDeLogs(const M: TMemo);
begin
  with M.Lines do
  begin
    BeginUpdate;
    Clear;
    EndUpdate;
  end;
end;

procedure AbreLogNoBlocoNotas(const M: TMemo; const fnTemp: string);
var comando: string;
begin
  if (m.Lines.Count = 0) then exit;
  try
    M.Lines.SaveToFile(fnTemp);
  except
    exit;
  end;

  try
    comando := 'notepad.exe ' + fnTemp;
    WinExec(pchar(comando), sw_Show);
  except
    exit;
  end;
end;


end.
