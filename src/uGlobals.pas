unit uGlobals;

interface

{ Type declarations }
type
  Symbol = String[9]; // Increased to 9 to accommodate 'procedure'
  SymTab = array[1..1000] of Symbol;
  TabPtr = ^SymTab;

  TTokenKind = (TK_IDENTIFIER, TK_CONSTANT, TK_IF, TK_ELSE, TK_ENDIF, TK_WHILE, TK_ENDWHILE,
                TK_PLUS, TK_MINUS, TK_EQUAL, TK_GREATER, TK_LESS, TK_NOT, TK_AMPERSAND, TK_VERTICAL_BAR,
                TK_REPEAT, TK_UNTIL, TK_FOR, TK_ENDFOR, TK_READ, TK_READLN, TK_TILDE, TK_COMMA, TK_COLON,
                TK_WRITE, TK_WRITELN, TK_VAR, TK_END, TK_PROCEDURE, TK_QUOTED, TK_SEMICOLON,
                TK_HALT, TK_GOTOXY, TK_CLS, TK_SETCOLORS, TK_KEYPRESS, TK_READKEY, TK_DOT, TK_CHAVE_LEFT, TK_CHAVE_DIREITA,
                TK_SLEEP, TK_RANDOM, TK_BRACKET_LEFT, TK_BRACKET_RIGHT, TK_STAR, TK_DIVISION);


  TSymbolTableItem = record
    Name: string;
    Kind: Integer;
    InitialValue: string;
    NumParams: Integer;
  end;

  TSymbolTable = class
  private
    FSize: Integer;
  public
    constructor Create;
    property Size: Integer read FSize;
  end;

{ Constant declarations }
const
  TAB = ^I;
  CR  = ^M;
  LF  = ^J;
  MaxEntry = 1000;
  MaxParams = 50;

{ Variable declarations }

var
//  Look : ansichar;             { Lookahead character }
//  Token : TTokenKind;            { Encoded token       }
//  Value : ShortString;      { Unencoded token     }

  SymbolTable: array[1 .. MaxEntry] of Symbol;
  SymbolTableType: array[1 .. MaxEntry] of Ansichar;
  LCount : integer = 0;
  NEntry : integer = 0;

  NumParams : integer; //Number of params in current procedure
  Base : integer;
  Params : array[1 .. MaxParams] of Symbol;


implementation

{ TSymbolTable }

constructor TSymbolTable.Create;
begin
  FSize := 0;
end;

end.