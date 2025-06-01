program TINY_IDE;

{$mode objfpc}{$H+}

uses
 {$IFDEF UseCThreads}
  cthreads,
 {$ENDIF}
  Interfaces, Forms, uEdit;

begin
  Application.Initialize;
  Application.CreateForm(TfrmEdit, frmEdit);
  Application.Run;
end.