unit uParser;

interface

uses
  SysUtils,
  uScanner,
  uCodeGen;

type

  TParser = class
  private
    FCodeGen: TCodeGen;
    FScanner: TScanner;
    procedure Factor;
    procedure Multiply;
    procedure Divide;
    procedure Term;
    procedure Add;
    procedure Subtract;
    procedure Expression;
    procedure CompareExpression;
    procedure NextExpression;
    procedure Equal;
    procedure LessOrEqual;
    procedure NotEqual;
    procedure Less;
    procedure Greater;
    procedure Relation;
    procedure NotFactor;
    procedure BoolTerm;
    procedure BoolOr;
    procedure BoolXor;
    procedure BoolExpression;
    procedure Assignment(Name: ansistring);
    procedure DoIf;
    procedure DoWhile;
    procedure DoRepeat;
    procedure DoFor;
    procedure DoRead;
    procedure DoReadLn;
    procedure DoWrite;
    procedure DoWriteLn;
    procedure FormalParam;
    procedure FormalList;
    procedure Param;
    function ParamList: integer;
    procedure CallProc(Name: ansistring);
    procedure LocDecl;
    function LocDecls: integer;
    procedure AssignOrProc;
    procedure Block;
    procedure Alloc;
    procedure DoProc;
    procedure GlobalDeclarations;
    procedure DoHalt;
    procedure DoGoToXY;
    procedure DoClrScr;
    procedure DoSetColors;
    procedure DoKeyPress;
    procedure DoReadKey;
    procedure DoRandom;
    procedure DoSleep;
    procedure Store(Name: ansistring);
    procedure Load(Name: ansistring);
    procedure Increment(Name: ansistring);
    procedure Decrement(Name: ansistring);
    procedure Compare(Name: ansistring);
  public
    constructor Create(Scanner: TScanner);
    procedure DoMain;
    procedure GenAsmFile(const FileName: string);
  end;


implementation

uses
  uGlobals, uErrors;

{ Store primary to parameter or variable}

procedure TParser.Store(Name : ansistring);
begin
  if IsParam(Name) then
    FCodeGen.StoreParam(ParamNumber(Name))
  else
    begin
      CheckTable(Name);
      FCodeGen.StoreVar(Name);
    end;
end;

{ Load primary from parameter or variable}
procedure TParser.Load(Name : ansistring);
begin
  if IsParam(Name) then
    FCodeGen.LoadParam(ParamNumber(Name))
  else
    begin
      CheckTable(Name);
      FCodeGen.LoadVar(Name);
    end;
end;

{ Increment parameter or variable}
procedure TParser.Increment(Name : ansistring);
begin
  if IsParam(Name) then
    FCodeGen.IncParam(ParamNumber(Name))
  else
    begin
      CheckTable(Name);
      FCodeGen.IncVar(Name);
    end;
end;

{ Increment parameter or variable}
procedure TParser.Decrement(Name : ansistring);
begin
  if IsParam(Name) then
    FCodeGen.DecParam(ParamNumber(Name))
  else
    begin
      CheckTable(Name);
      FCodeGen.DecVar(Name);
    end;
end;

{ Compare parameter or variable with primary}
procedure TParser.Compare(Name : ansistring);
begin
  if IsParam(Name) then
    FCodeGen.CompareParam(ParamNumber(Name))
  else
    begin
      CheckTable(Name);
      FCodeGen.CompareVar(Name);
    end;
end;

{ Parse and translate a math factor }
procedure TParser.Factor;
begin
  if FScanner.CurrentToken = TK_BRACKET_LEFT then
    begin
      FScanner.NextToken();
      BoolExpression;
      FScanner.MatchString(')');
    end
  else
    begin
      if FScanner.CurrentToken = TK_IDENTIFIER then
        Load(FScanner.CurrentValue)
      else if FScanner.CurrentToken = TK_CONSTANT then
        FCodeGen.LoadConst(FScanner.CurrentValue)
      else
        Expected('Math Factor', FScanner.CurrentValue);
      FScanner.NextToken();
    end;
end;

{ Recognize and translate a multiply }
procedure TParser.Multiply;
begin
  FScanner.NextToken();
  Factor;
  FCodeGen.PopMul;
end;

{ Recognize and translate a divide }
procedure TParser.Divide;
begin
  FScanner.NextToken();
  Factor;
  FCodeGen.PopDiv;
end;

{ Parse and translate a maths term }
procedure TParser.Term;
begin
  Factor;
  while IsMulop(FScanner.CurrentToken) do
    begin
      FCodeGen.Push;
      case FScanner.CurrentToken of
        TK_STAR: Multiply;
        TK_DIVISION : Divide;
      end;
  end;
end;

{ Recognize and translate an add }
procedure TParser.Add;
begin
  FScanner.NextToken();
  Term;
  FCodeGen.PopAdd;
end;

{ Recognize and translate a subtract }
procedure TParser.Subtract;
begin
  FScanner.NextToken();
  Term;
  FCodeGen.PopSub;
end;

{ Parse and translate an expression }
procedure TParser.Expression;
begin
  if IsAddop(FScanner.CurrentToken) then
    FCodeGen.Clear
  else
    Term;
  while IsAddop(FScanner.CurrentToken) do
    begin
      FCodeGen.Push;
      case FScanner.CurrentToken of
        TK_PLUS : Add;
        TK_MINUS : Subtract;
      end;
  end;
end;

{ Get another expression and compare }
procedure TParser.CompareExpression;
begin
  Expression;
  FCodeGen.PopCompare;
end;

{ Get the next expression and compare }
procedure TParser.NextExpression;
begin
  FScanner.NextToken();
  CompareExpression;
end;

{ Recognize and translate a relational "Equals" }
procedure TParser.Equal;
begin
  NextExpression;
  FCodeGen.SetEqual;
end;

{ Recognize and translate a relational "Less Than or Equal" }
procedure TParser.LessOrEqual;
begin
  NextExpression;
  FCodeGen.SetLessOrEqual;
end;

{ Recognize and translate a relational "Not Equals" }
procedure TParser.NotEqual;
begin
  NextExpression;
  FCodeGen.SetNEqual;
end;

{ Recognize and translate a relational "Less Than" }
procedure TParser.Less;
begin
  FScanner.NextToken();
  case FScanner.CurrentToken of
    TK_EQUAL : LessOrEqual;
    TK_GREATER: NotEqual;
  else
    begin
      CompareExpression;
      FCodeGen.SetLess;
    end;
  end;
end;

{ Recognize and translate a relational "Greater Than" }
procedure TParser.Greater;
begin
  FScanner.NextToken();
  if FScanner.CurrentToken = TK_EQUAL then
    begin
      NextExpression;
      FCodeGen.SetGreaterOrEqual;
    end
  else
    begin
      CompareExpression;
      FCodeGen.SetGreater;
    end;
end;

{ Parse and translate a relation }
procedure TParser.Relation;
begin
  Expression;
  if IsRelop(FScanner.CurrentToken) then
    begin
      FCodeGen.Push;
      case FScanner.CurrentToken of
        TK_EQUAL : Equal;
        TK_LESS : Less;
        TK_GREATER : Greater;
      end;
    end;
end;

{ Parse and translate a Boolean factor with leading NOT }
procedure TParser.NotFactor;
begin
  if FScanner.CurrentToken = TK_NOT then
    begin
      FScanner.NextToken();
      Relation;
      FCodeGen.NotIt;
    end
  else
    Relation;
end;

{ Parse and translate a Boolean term }
procedure TParser.BoolTerm;
begin
  NotFactor;
  while FScanner.CurrentToken = TK_AMPERSAND do
    begin
      FCodeGen.Push;
      FScanner.NextToken();
      NotFactor;
      FCodeGen.PopAnd;
    end;
end;

{ Recognize and translate a Boolean OR }
procedure TParser.BoolOr;
begin
  FScanner.NextToken();
  BoolTerm;
  FCodeGen.PopOr;
end;

{ Recognize and translate an exclusive Or }
procedure TParser.BoolXor;
begin
  FScanner.NextToken();
  BoolTerm;
  FCodeGen.PopXor;
end;

{ Parse and translate a Boolean expression }
procedure TParser.BoolExpression;
begin
  BoolTerm;
  while IsOrOp(FScanner.CurrentToken) do
    begin
      FCodeGen.Push;
      case FScanner.CurrentToken of
        TK_VERTICAL_BAR: BoolOr;
        TK_TILDE: BoolXor;
      end;
    end;
end;

{ Parse and translate an assignment statement }
procedure TParser.Assignment(Name : ansistring);
begin
  FScanner.NextToken();
  FScanner.MatchString('=');
  BoolExpression;
  Store(Name);
end;

{ Recognize and translate an IF construct }
procedure TParser.DoIf;
var
  L1, L2 : ansistring;
begin
  FScanner.NextToken();
  BoolExpression;
  L1 := FCodeGen.NewLabel;
  L2 := L1;
  FCodeGen.JumpFalse(L1);
  Block;
  if FScanner.CurrentToken = TK_ELSE then
    begin
      FScanner.NextToken();
      L2 := FCodeGen.NewLabel;
      FCodeGen.Jump(L2);
      FCodeGen.PostLabel(L1);
      Block;
    end;
  FCodeGen.PostLabel(L2);
  FScanner.MatchString('ENDIF');
end;

{ Parse and translate a WHILE statement }
procedure TParser.DoWhile;
var
  LabelEnquanto, LabelFimEnquanto: ansistring;
begin
  FScanner.NextToken();
  LabelEnquanto := FCodeGen.NewLabel('enquanto');
  LabelFimEnquanto := FCodeGen.NewLabel('fim_enquanto');
  FCodeGen.PostLabel(LabelEnquanto);
  BoolExpression();
  FCodeGen.JumpFalse(LabelFimEnquanto);
  FScanner.MatchString('{');
  FCodeGen.PostLabel(FCodeGen.NewLabel('faca'));
  Block();
  FScanner.MatchString('}');
  FCodeGen.Jump(LabelEnquanto);
  FCodeGen.PostLabel(LabelFimEnquanto);
end;

{ Parse and translate a REPEAT statement }
procedure TParser.DoRepeat;
var
  Repita: AnsiString;
begin
  FScanner.MatchString('REPEAT');
  FScanner.MatchString('{');
  Repita := FCodeGen.NewLabel('repita');
  FCodeGen.PostLabel(Repita);
  Block();
  FScanner.MatchString('}');
  FScanner.MatchString('UNTIL');
  FCodeGen.PostLabel(FCodeGen.NewLabel('ate_que'));
  BoolExpression();
  FCodeGen.JumpFalse(Repita);
end;

{ Parse and translate a FOR statement }
procedure TParser.DoFor;
var
  LabelPara, LabelFimPara: AnsiString;
  Name : ansistring;
begin
  FScanner.MatchString('FOR');
  LabelPara := FCodeGen.NewLabel('para');
  LabelFimPara := FCodeGen.NewLabel('fim_para');
  Name := FScanner.CurrentValue;
  FScanner.NextToken();
  FScanner.MatchString('=');
  Expression();
  Store(Name);
  Decrement(Name);
  FScanner.MatchString('TO');
  Expression();
  FCodeGen.Push();
  FCodeGen.PostLabel(LabelPara);
  Increment(Name);
  FCodeGen.Pop();
  Compare(Name);
  FCodeGen.JumpGreater(LabelFimPara);
  FCodeGen.Push();
  FCodeGen.PostLabel(FCodeGen.NewLabel('faca'));
  Block();
  FScanner.MatchString('ENDFOR');
  FCodeGen.Jump(LabelPara);
  FCodeGen.PostLabel(LabelFimPara);
end;

{ Process a read statement }
procedure TParser.DoRead;
begin
  FScanner.NextToken();
  FScanner.MatchString('(');
  if FScanner.Currenttoken = TK_BRACKET_RIGHT then
    FCodeGen.ReadKey()
  else
    begin
    raise Exception.Create('Error Message');
//      ReadAndStore(Value);
      while FScanner.CurrentToken = TK_COMMA do
        begin
          FScanner.NextToken();
//          ReadAndStore(Value);
        end;
    end;
//  MatchString(')');
end;

{ Same as DoRead, compatability with Pascal }
procedure TParser.DoReadLn;
begin
  DoRead();
end;

{ Process a write statement. }
procedure TParser.DoWrite;
var
  OutputString : ansistring;

  {Nested proc to write a string or a variable. }
  procedure StringOrVar;
  begin
    if OutputString <> '' then
      FCodeGen.WriteString(OutputString)
    else
      begin
        Expression();
        FCodeGen.WriteIt();
      end;
  end;

begin
  FScanner.NextToken();
  FScanner.MatchString('(');
  if FScanner.CurrentToken <> TK_BRACKET_RIGHT then
    begin
      OutputString := FScanner.GetString();
      StringOrVar();
      while FScanner.CurrentToken = TK_COMMA do
        begin
          FScanner.NextToken();
          OutputString := FScanner.GetString();
          StringOrVar();
        end;
    end;
  FScanner.MatchString(')');
end;

procedure TParser.DoWriteLn;
begin
  DoWrite();
  FCodeGen.NewLine();
end;

{ Process a formal parameter. }
procedure TParser.FormalParam;
begin
  AddParam(FScanner.CurrentValue);
  FScanner.NextToken();
end;

{ Process the formal parameter list of a procedure. }
procedure TParser.FormalList;
begin
  FScanner.NextToken();
  FScanner.MatchString('(');
  if FScanner.CurrentToken <> TK_BRACKET_RIGHT then
    begin
      FormalParam;
      while FScanner.CurrentToken = TK_COMMA do
        begin
          FScanner.NextToken();
          FormalParam;
        end;
    end;
  FScanner.MatchString(')');
  Base := NumParams;
  NumParams := NumParams + 2;

end;

{ Process an actual parameter. }
procedure TParser.Param;
begin
  Expression();
  FCodeGen.Push();
end;

{ Process the parameter list for a procedure call. }
function TParser.ParamList : integer;
var
  N : integer;
begin
  N := 0;
  FScanner.NextToken();
  FScanner.MatchString('(');
  if FScanner.CurrentToken <> TK_BRACKET_RIGHT then
    begin
      Param();
      inc(N);
      while FScanner.CurrentToken = TK_COMMA do
        begin
          FScanner.MatchString(',');
          Param();
          inc(N);
        end;
    end;
  FScanner.MatchString(')');
  ParamList := 4 * N;
end;


{ Process a procedure call. }
procedure TParser.CallProc(Name : ansistring);
var
  N : integer;
begin
  N := ParamList;
  FCodeGen.Call(Name);
  FCodeGen.CleanStack(N);
end;

{ Parse and translate a local data declaration. }
procedure TParser.LocDecl;
begin
  FScanner.NextToken();
  AddParam(FScanner.CurrentValue);
  FScanner.NextToken();
end;

{ Parse and translate local declarations. }
function TParser.LocDecls : integer;
var
  n : integer;
begin
  n := 0;
  FScanner.ScanKeyword();
  while FScanner.CurrentToken = TK_VAR do
  begin
    LocDecl();
    inc(n);
  end;

  while FScanner.CurrentToken = TK_COMMA do
  begin
    LocDecl();
    inc(n);
  end;

  Result := n;

  FScanner.ScanKeyword();

  if FScanner.CurrentToken = TK_VAR then
    Result := Result + LocDecls();
end;

procedure TParser.AssignOrProc;
begin
  case TypeOf(FScanner.CurrentValue) of
    ' ': Undefined(FScanner.CurrentValue);
    'v',
    'F': Assignment(FScanner.CurrentValue);
    'p': CallProc(FScanner.CurrentValue);
  else
    Abort('Identifier ' + FScanner.CurrentValue +
          ' cannot be used here.');
  end;
end;


{ Parse and translate a block of statements. }
procedure TParser.Block;
begin
  FScanner.ScanKeyword();
  while not (FScanner.CurrentToken in [TK_END, TK_ELSE, TK_UNTIL, TK_ENDIF, TK_ENDWHILE, TK_ENDFOR, TK_CHAVE_DIREITA]) do
  begin
    case FScanner.CurrentToken of
        TK_IF : DoIf;
        TK_WHILE : DoWhile;
        TK_REPEAT : DoRepeat;
        TK_FOR : DoFor;
        TK_READ : DoRead;
        TK_READLN : DoReadLn;
        TK_WRITE : DoWrite;
        TK_WRITELN : DoWriteLn;
        TK_HALT : DoHalt;
        TK_GOTOXY : DoGoToXY;
        TK_CLS : DoClrScr;
        TK_SETCOLORS : DoSetColors;
        TK_KEYPRESS : DoKeyPress;
        TK_READKEY : DoReadKey;
        TK_SLEEP : DoSleep;
        TK_RANDOM : DoRandom;
      else
        AssignOrProc();
    end;

    FScanner.SkipSemicolon();
    FScanner.ScanKeyword();
  end;
end;

{ Allocate storage for a variable. }
procedure TParser.Alloc;
begin
  FScanner.NextToken();

  if FScanner.CurrentToken <> TK_IDENTIFIER then
    Expected('Variable Name',FScanner.CurrentValue);

  CheckDup(FScanner.CurrentValue);
  AddEntry(FScanner.CurrentValue, 'v');
  FCodeGen.Allocate(FScanner.CurrentValue, '0');

  FScanner.NextToken();

  if FScanner.CurrentToken = TK_COMMA then
    Alloc();

end;


{ Parse and translate a procedure declaration. }
procedure TParser.DoProc;
var
  k, i  : integer;
  N : ansistring;
begin
  FScanner.NextToken();

  if FScanner.CurrentToken <> TK_IDENTIFIER then
    Expected('Procedure Name', FScanner.CurrentValue);

  CheckDup(FScanner.CurrentValue);
  AddEntry(FScanner.CurrentValue, 'p');
  N := FScanner.CurrentValue;

  FormalList();
//  FScanner.SkipSemicolon();

  FScanner.MatchString('{');

  k := LocDecls();
  FCodeGen.ProcProlog(N, k);
  for i := Base + 3 to Base + 2 + k do  //must init locals only
    begin
      FCodeGen.Clear;  //Could clear before loop
      FCodeGen.StoreParam(i);
    end;

  FScanner.SkipSemicolon();
//  FScanner.MatchString('BEGIN');
  Block;
  FScanner.MatchString('}');
  FScanner.SkipSemicolon();
  FCodeGen.ProcEpilog(N);
  ClearParams;
  FScanner.ScanKeyword();
end;

{ Parse and translate main program }
//procedure TParser.DoMain;
//begin
//  FScanner.NextToken();
//  FScanner.ScanKeyword();
//
//  if FScanner.CurrentToken <> TK_IDENTIFIER then
//    Expected('Program Name', FScanner.CurrentValue);
//
//  CheckDup(FScanner.CurrentValue);
//  //Put in symbol table to prevent identifiers with same name
//  AddEntry(FScanner.CurrentValue, 'P');
//  FScanner.SkipSemicolon();
//  FScanner.NextToken();
//  GlobalDeclarations();
//  FCodeGen.CodeProlog();
//
//  while (FScanner.CurrentToken = TK_PROCEDURE) do
//    DoProc();
//
//  FScanner.MatchString('BEGIN');
//  FCodeGen.Prolog();
//  Block();
//  FScanner.MatchString('END');
//  FCodeGen.Epilog();
//  Closefile(AsmFile);
//end;

procedure TParser.DoMain;
begin
  FScanner.NextToken();

  while not FScanner.IsAtEnd() do
  begin
    FScanner.ScanKeyword();

    case FScanner.CurrentToken of
      TK_VAR: GlobalDeclarations();
      TK_PROCEDURE: DoProc();
      TK_IF : DoIf;
      TK_WHILE : DoWhile;
      TK_REPEAT : DoRepeat;
      TK_FOR : DoFor;
      TK_READ : DoRead;
      TK_READLN : DoReadLn;
      TK_WRITE : DoWrite;
      TK_WRITELN : DoWriteLn;
      TK_HALT : DoHalt;
      TK_GOTOXY : DoGoToXY;
      TK_CLS : DoClrScr;
      TK_SETCOLORS : DoSetColors;
      TK_KEYPRESS : DoKeyPress;
      TK_READKEY : DoReadKey;
      TK_SLEEP : DoSleep;
      TK_RANDOM : DoRandom;
    else
      AssignOrProc();
    end;

    FScanner.SkipSemicolon();
  end;

end;

{ Parse and translate global declarations }
procedure TParser.GenAsmFile(const FileName: string);
begin
  FCodeGen.GenFile(FileName);
end;

procedure TParser.GlobalDeclarations;
begin
  while FScanner.CurrentToken = TK_VAR do
    Alloc();

  while FScanner.CurrentToken = TK_COMMA do
    Alloc();

  FScanner.SkipSemicolon();
end;

{ End the program. }
procedure TParser.DoHalt;
begin
  FScanner.NextToken();
  FCodeGen.Quit();
end;

{ Process a GoToXY statement. }
procedure TParser.DoGoToXY;  //CRT
begin
  FScanner.NextToken();
  FScanner.MatchString('(');
  Expression;
  Store('X');
  FScanner.MatchString(',');
  Expression;
  Store('Y');
  FScanner.MatchString(')');
  FCodeGen.GoToXY;
end;

{ Process a cls statement. }
procedure TParser.DoClrScr;
begin
  FScanner.NextToken();
  FScanner.MatchString('(');
  FScanner.MatchString(')');
  FCodeGen.ClrScr;
end;

{ Process a setColors statement. }
procedure TParser.DoSetColors;
var
  TextColour, BackColour : ansistring;
begin
  FScanner.NextToken();
  FScanner.MatchString('(');
  TextColour := FScanner.CurrentValue;
  FScanner.NextToken();
  FScanner.MatchString(',');
  BackColour := FScanner.CurrentValue;
  FScanner.NextToken();
  FScanner.MatchString(')');
  FCodeGen.SetColors(TextColour, BackColour);
end;

{ Process a key press statement. }
procedure TParser.DoKeyPress;
begin
  FScanner.NextToken();
  FScanner.MatchString('(');
  FScanner.MatchString(')');
  FCodeGen.KeyPress();
end;

{ Process a readkey statement. }
procedure TParser.DoReadKey;
var
  Key : ansistring;
begin
  FScanner.NextToken();
  FScanner.MatchString('(');
  Key := FScanner.CurrentValue;
  FScanner.NextToken();
  FScanner.MatchString(')');
  FCodeGen.ReadKey(Key);
end;

{ Process a random statement.
  Puts random value in var given as first argument
  RANDOM(Varname, Limit)
}
procedure TParser.DoRandom;
var
  Rand : ansistring;
begin
  FScanner.NextToken();
  FScanner.MatchString('(');
  Rand := FScanner.CurrentValue;
  FScanner.NextToken();
  FScanner.MatchString(',');
  Expression;
  Store(Rand);
  FCodeGen.Random(Rand);
  FScanner.MatchString(')');
end;

{ Process a sleep statement. }
procedure TParser.DoSleep;
begin
  FScanner.NextToken();
  FScanner.MatchString('(');
  Expression;
  Store('DELAY');
  FScanner.MatchString(')');
  FCodeGen.Sleep;
end;
{ TParser }

constructor TParser.Create(Scanner: TScanner);
begin
  FScanner := Scanner;
  FCodeGen := TCodeGen.Create();
end;

end.