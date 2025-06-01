unit uErrors;

interface

procedure Error(s : ansistring);
procedure Abort(s : ansistring);
procedure Expected(StrExpected, StrCurrent: AnsiString);
procedure Undefined(n : ansistring);
procedure Duplicate(n : ansistring);

implementation

uses
  uGlobals,
  SysUtils;

{ Report an error. }
procedure Error(s : ansistring);
begin
  WriteLn('Error: ', s, '.');
  ReadLn;
end;

{ Report error and halt. }
procedure Abort(s : ansistring);
begin
  Error(s);
//  CloseFile(SourceFile);
//  Closefile(AsmFile);
  Halt;
end;

{ Report what was expected. }
procedure Expected(StrExpected, StrCurrent: AnsiString);
begin
   Abort(Format('Era esperado "%s", porem foi encontrado "%s"', [StrExpected, StrCurrent]));
end;

{ Report an undefined identifier. }
procedure Undefined(n : ansistring);
begin
  Abort('Undefined Identifier ' + n);
end;

{ Report a duplicate identifier. }
procedure Duplicate(n : ansistring);
begin
  Abort('Duplicate Identifier ' + n);
end;

end.