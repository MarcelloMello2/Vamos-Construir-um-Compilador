unit uScanner;

interface

uses
  SysUtils,
  uGlobals;

type

  TScanner = class
  private
    FCurrentToken: TTokenKind;
    FCurrentValue: AnsiString;
    Look: AnsiChar;
    FSource: AnsiString;
    FStart: Integer;
    FCurrent: Integer;
    FLineNro: Integer;
    procedure GetNextChar;
    function IsAlpha(c: ansichar): boolean;
    function IsAlphanumeric(c: ansichar): boolean;
    function IsDigit(c: ansichar): boolean;
    procedure GetName;
    procedure GetNumber;
    procedure GetOperator;
//    procedure SkipComment;
  public
    constructor Create(Source: string);
    function NextToken: Boolean;
    procedure MatchString(x: ansistring);
    procedure SkipSemicolon;
    function GetString: ansistring;
    function PeekNext: AnsiChar;
    function Peek: AnsiChar;
    procedure SkipWhiteSpace;
    property CurrentToken: TTokenKind read FCurrentToken;
    procedure ScanKeyword;
    property CurrentValue: AnsiString read FCurrentValue;
    function IsAtEnd: Boolean;
  end;

{ Table lookup }
function Lookup(Table: TabPtr; s : ansistring; n : integer) : integer;

{ Locate a symbol in table
  Returns the index of the entry.  Zero if not present. }
function Locate(N : Symbol): integer;

{ Look for symbol in table }
function InTable(n : Symbol): Boolean;

{ Check to see if an identifier is in the symbol table
  Report an error if it's not. }
procedure CheckTable(N : Symbol);

{ Check the symbol table for a duplicate identifier
 Report an error if identifier is already in table. }
procedure CheckDup(N : Symbol);

{ Add a new entry to symbol table }
procedure AddEntry(N : Symbol; T : ansichar);


{ Scan the current identifier for keywords }
//procedure ScanKeyword;

{ Initialize parameter table to null }
procedure ClearParams;

{ Find the parameter number }
function ParamNumber(N : ansistring) : integer;

{ See if an identifier is a parameter }
function IsParam(N : ansistring) : boolean;

{ Add a new parameter to table }
procedure AddParam(Name : ansistring);

{ Get type of symbol }
function TypeOf(n : ansistring) : ansichar;

{ Recognize an addop }
function IsAddop(c : TTokenKind) : boolean;

{ Recognize a Boolean orop }
function IsOrop(c : TTokenKind): boolean;

{ Recognize a relop }
function IsRelop(c : TTokenKind): boolean;

{ Recognize a mulop }
function IsMulop(c : TTokenKind): boolean;

implementation

uses
 uErrors;


constructor TScanner.Create(Source: string);
begin
  FSource := AnsiString(Source);
  FStart := 1;
  Fcurrent := 1;
  FLineNro := 1;
  GetNextChar();
end;

{ Read new character from input stream }
procedure TScanner.GetNextChar;
begin
  Inc(FCurrent);
  Look := FSource[FCurrent-1];
end;

function TScanner.NextToken: Boolean;
begin
  SkipWhiteSpace();
  if IsAlpha(Look) then
    GetName()
  else if IsDigit(Look) then
    GetNumber()
  else
    GetOperator();

  Result := not IsAtEnd();
end;


{ Table lookup }
function Lookup(Table: TabPtr; s : ansistring; n : integer) : integer;
var
  i : integer;
  found : Boolean;
begin
  found := false;
  i := n;
  while (i > 0) and not found do
    if s = Table^[i] then
      found := true
    else
      dec(i);
  Lookup := i;
end;

{ Locate a symbol in table
  Returns the index of the entry.  Zero if not present. }
function Locate(N : Symbol) : integer;
begin
  Locate := Lookup(@SymbolTable, N, NEntry);
end;

{ Look for symbol in table }
function InTable(n : Symbol) : Boolean;
begin
  InTable := Lookup(@SymbolTable, n, NEntry) <> 0;
end;

{ Check to see if an identifier is in the symbol table
  Report an error if it's not. }
procedure CheckTable(N : Symbol);
begin
  if not InTable(N) then
    Undefined(N);
end;

{ Check the symbol table for a duplicate identifier
 Report an error if identifier is already in table. }
procedure CheckDup(N : Symbol);
begin
  if InTable(N) then
    Duplicate(N);
end;

{ Add a new entry to symbol table }
procedure AddEntry(N : Symbol; T : ansichar);
begin
  CheckDup(N);
  if NEntry = MaxEntry then
    Abort('Symbol Table Full');
  Inc(NEntry);
  SymbolTable[NEntry] := N;
  SymbolTableType[NEntry] := T;
end;

{ Find the parameter number }
function ParamNumber(N : ansistring) : integer;
begin
  ParamNumber := Lookup(@Params, N, NumParams);
end;

{ See if an identifier is a parameter }
function IsParam(N : ansistring) : boolean;
begin
  IsParam := ParamNumber(N) <> 0;
end;

{ Add a new parameter to table }
procedure AddParam(Name : ansistring);
begin
  if IsParam(Name) then
    Duplicate(Name);
  Inc(NumParams);
  Params[NumParams] := Name;
end;

{ Get type of symbol }
function TypeOf(n : ansistring) : ansichar;
var
  Position : integer;
begin
  if IsParam(n) then
    TypeOf := 'F'
  else
    begin
      Position := Locate(n);
      TypeOf := SymbolTableType[Position];
    end;
end;

{ Recognize an alpha character }
function TScanner.IsAlpha(c : ansichar) : boolean;
begin
  IsAlpha := UpCase(c) in ['A' .. 'Z'];
end;

{ Recognize a decimal digit }
function TScanner.IsDigit(c : ansichar) : boolean;
begin
  IsDigit := c in ['0' .. '9'];
end;

{ Recognize an alphanumeric character }
function TScanner.IsAlphanumeric(c : ansichar): boolean;
begin
  IsAlphanumeric := IsAlpha(c) or IsDigit(c);
end;

{ Recognize an addop }
function IsAddop(c : TTokenKind) : boolean;
begin
  IsAddop := c in [TK_PLUS, TK_MINUS];
end;

{ Recognize a mulop }
function IsMulop(c : TTokenKind): boolean;
begin
  IsMulop := c in [TK_STAR, TK_DIVISION];
end;

{ Recognize a Boolean orop }
function IsOrop(c : TTokenKind): boolean;
begin
  IsOrop := c in [TK_VERTICAL_BAR, TK_TILDE];
end;

{ Recognize a relop }
function IsRelop(c : TTokenKind): boolean;
begin
  IsRelop := c in [TK_EQUAL, TK_CONSTANT, TK_LESS, TK_GREATER];
end;

{ Recognize white space }
function IsWhite(c : ansichar) : boolean;
begin
  IsWhite := c in [' ', TAB, CR, LF];
end;


//{ Skip a comment field }
//procedure TScanner.SkipComment;
//begin
//  while Look <> '}' do
//    begin
//      GetNextChar();
//      if Look = '{' then
//        SkipComment;
//     end;
//  GetNextChar();
//end;


{ Skip over leading white space }
procedure TScanner.SkipWhiteSpace;
begin
  while IsWhite(Look) do
    begin
//      if Look = '{' then
//        SkipComment()
//      else
        GetNextChar();
   end;
end;

{ Match a semicolon }
procedure TScanner.SkipSemicolon;
begin
  if FCurrentToken = TK_SEMICOLON then
    NextToken();
end;

function TScanner.Peek(): AnsiChar;
begin
  if (isAtEnd()) then
    Exit(#0);

  Result := FSource[FCurrent];
end;

function TScanner.PeekNext(): AnsiChar;
begin
  if (FCurrent + 1) > Length(FSource) then
    Exit(#0);

  Result := FSource[FCurrent + 1];
end;

{ Get an identifier }
procedure TScanner.GetName;
begin
  if Not IsAlpha(Look) then
    Expected('Identifier', FCurrentValue);

  FCurrentToken := TK_IDENTIFIER;
  FCurrentValue := '';

  repeat
    FCurrentValue := FCurrentValue + UpCase(Look);
    GetNextChar();
  until not IsAlphanumeric(Look);
end;

{ Get a number }
procedure TScanner.GetNumber;
begin
   if not IsDigit(Look) then
    Expected('Number', FCurrentValue);
  FCurrentToken := TK_CONSTANT;
  FCurrentValue := '';
  repeat
    FCurrentValue := FCurrentValue + Look;
    GetNextChar();
  until not IsDigit(Look);
end;

{ Get an operator }

procedure TScanner.GetOperator;
begin
  case Look of
    '=': FCurrentToken := TK_EQUAL;
    '+': FCurrentToken := TK_PLUS;
    '-': FCurrentToken := TK_MINUS;
    '/': FCurrentToken := TK_DIVISION;
    '(': FCurrentToken := TK_BRACKET_LEFT;
    ')': FCurrentToken := TK_BRACKET_RIGHT;
    ',': FCurrentToken := TK_COMMA;
    '*': FCurrentToken := TK_STAR;
    ';': FCurrentToken := TK_SEMICOLON;
    '.': FCurrentToken := TK_DOT;
    '''': FCurrentToken := TK_QUOTED;
    '>': FCurrentToken := TK_GREATER;
    '<': FCurrentToken := TK_LESS;
    ':': FCurrentToken := TK_COLON;
    '{': FCurrentToken := TK_CHAVE_LEFT;
    '}': FCurrentToken := TK_CHAVE_DIREITA;
    #0: FCurrentToken := TK_END;
  else
    raise Exception.CreateFmt('nao foi possivel identificar o operador %s', [Look]);
  end;

  FCurrentValue := Look;
  GetNextChar();
end;

function TScanner.IsAtEnd(): Boolean;
begin
  Result := FCurrent > Length(FSource);
end;


{Get quoted string from input stream }
function TScanner.GetString : ansistring;
begin
  GetString := '';
  if FCurrentToken = TK_QUOTED then
    begin
      while Look <> '''' do
        begin
          GetString := GetString + Look;
          GetNextChar();
        end;
      GetNextChar();
      FCurrentValue := Look;
      NextToken();
    end;
end;


{ Scan the current identifier for keywords }
procedure TScanner.ScanKeyword;
begin
  if FCurrentToken = TK_IDENTIFIER then
  begin
    if FCurrentValue = 'IF' then
      FCurrentToken := TK_IF
    else if FCurrentValue = 'ELSE' then
      FCurrentToken := TK_ELSE
    else if FCurrentValue = 'ENDIF' then
      FCurrentToken := TK_ENDIF
    else if FCurrentValue = 'WHILE' then
      FCurrentToken := TK_WHILE
    else if FCurrentValue = 'ENDWHILE' then
      FCurrentToken := TK_ENDWHILE
    else if FCurrentValue = 'REPEAT' then
      FCurrentToken := TK_REPEAT
    else if FCurrentValue = 'UNTIL' then
      FCurrentToken := TK_UNTIL
    else if FCurrentValue = 'FOR' then
      FCurrentToken := TK_FOR
    else if FCurrentValue = 'ENDFOR' then
      FCurrentToken := TK_ENDFOR
    else if FCurrentValue = 'READ' then
      FCurrentToken := TK_READ
    else if FCurrentValue = 'READLN' then
      FCurrentToken := TK_READLN
    else if FCurrentValue = 'WRITE' then
      FCurrentToken := TK_WRITE
    else if FCurrentValue = 'WRITELN' then
      FCurrentToken := TK_WRITELN
    else if FCurrentValue = 'VAR' then
      FCurrentToken := TK_VAR
    else if FCurrentValue = 'END' then
      FCurrentToken := TK_END
    else if FCurrentValue = 'PROC' then
      FCurrentToken := TK_PROCEDURE
    else if FCurrentValue = 'HALT' then
      FCurrentToken := TK_HALT
    else if FCurrentValue = 'GOTOXY' then
      FCurrentToken := TK_GOTOXY
    else if FCurrentValue = 'CLS' then
      FCurrentToken := TK_CLS
    else if FCurrentValue = 'SETCOLORS' then
      FCurrentToken := TK_SETCOLORS
    else if FCurrentValue = 'KEYPRESS' then
      FCurrentToken := TK_KEYPRESS
    else if FCurrentValue = 'READKEY' then
      FCurrentToken := TK_READKEY
    else if FCurrentValue = 'SLEEP' then
      FCurrentToken := TK_SLEEP
    else if FCurrentValue = 'RANDOM' then
      FCurrentToken := TK_RANDOM
  end;
end;

{ Match a specific input string }
procedure TScanner.MatchString(x : ansistring);
begin
  if FCurrentValue <> x then
    Expected('''' + x + '''', FCurrentValue);

  NextToken();
end;

{ Initialize parameter table to null }
procedure ClearParams;
var
  i : integer;
begin
  for i := 1 to MaxParams do
    Params[i] := '';
  NumParams := 0;
end;

end.
