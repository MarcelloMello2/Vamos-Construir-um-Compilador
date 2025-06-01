// Marcello Mello 05/11/2019
// Se7e Sistemas

program SLang;

{$Apptype Console}

uses
  SysUtils,
  IOUtils,
  uCodeGen in 'uCodeGen.pas',
  uErrors in 'uErrors.pas',
  uGlobals in 'uGlobals.pas',
  uParser in 'uParser.pas',
  uScanner in 'uScanner.pas';

var
  Parser: TParser;
  Scanner: TScanner;

{ Initialize }

procedure Init;
begin
  Scanner := TScanner.Create(TFile.ReadAllText('src.txt'));
  Parser := TParser.Create(Scanner);

  ClearParams();
end;

{ Main program }

begin
  Init();
  Parser.DoMain();
  Parser.GenAsmFile('temp.asm');
end.