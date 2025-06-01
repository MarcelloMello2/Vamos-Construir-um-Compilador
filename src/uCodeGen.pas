
unit uCodeGen;

interface

uses
  Classes;

type

  TCodeGen = class
  private
    FDataSection: TStringList;
    FCodeSection: TStringList;
    procedure EmitLn(s: ansistring);
  public
    function NewLabel(PreFixo: AnsiString = ''): ansistring;
    procedure PostLabel(L: ansistring);
    procedure Allocate(Name, Val: ansistring);
    procedure Jump(L: ansistring);
    procedure JumpFalse(L: ansistring);
    procedure JumpGreater(L: ansistring);
    procedure Call(ProcName: ansistring);
    procedure CleanStack(N: integer);
    procedure Clear;
    procedure ClrScr;
    procedure CompareParam(N: integer);
    procedure CompareVar(Name: ansistring);
    procedure DecParam(N: integer);
    procedure DecVar(Name: ansistring);
    procedure GoToXY;
    procedure IncParam(N: integer);
    procedure IncVar(Name: ansistring);
    procedure KeyPress;
    procedure LoadConst(n: ansistring);
    procedure LoadParam(N: integer);
    procedure LoadVar(Name: ansistring);
    procedure Negate;
    procedure NewLine;
    procedure NotIt;
    procedure Pop;
    procedure PopAdd;
    procedure PopAnd;
    procedure PopCompare;
    procedure PopDiv;
    procedure PopMul;
    procedure PopOr;
    procedure PopSub;
    procedure PopXor;
    procedure ProcEpilog(N : ansistring);
    procedure ProcProlog(N: ansistring; k: integer);
    procedure Push;
    procedure Quit;
    procedure Random(RandVar: ansistring);
    procedure ReadIt;
    procedure ReadKey; overload;
    procedure SetColors(TextColour, BackColour: ansistring);
    procedure SetEqual;
    procedure SetGreater;
    procedure SetGreaterOrEqual;
    procedure SetLess;
    procedure SetLessOrEqual;
    procedure SetNEqual;
    procedure Sleep;
    procedure StoreParam(N: integer);
    procedure StoreVar(Name: ansistring);
    procedure WriteIt;
    procedure WriteString(OutPutString: ansistring);
    procedure ReadKey(K: ansistring); overload;
    procedure GenFile(const FileName: string);
    constructor Create;
    destructor Destroy; override;
  end;

implementation

uses
  uGlobals, uScanner, SysUtils;

{ Clear the primary register. }
procedure TCodeGen.Clear;
begin
   EmitLn('XOR EAX, EAX');
end;

{ Negate the primary register. }
procedure TCodeGen.Negate;
begin
  EmitLn('NEG EAX');
end;

{ Complement the primary register. }
procedure TCodeGen.NotIt;
begin
  EmitLn('NOT EAX');
end;

{ Load a constant value to primary register. }
procedure TCodeGen.LoadConst(n : ansistring);
begin
  EmitLn('MOV EAX, ' + n);
end;

{ Load a variable to primary register. }
procedure TCodeGen.LoadVar(Name : ansistring);
begin
  EmitLn('MOV EAX, ' + Name);
end;

{ Load parameter to primary register }
procedure TCodeGen.LoadParam(N : integer);
var
  Offset : integer;
begin
  Offset := 8 + 4 * (Base - N);
  EmitLn('MOV EAX, [EBP + ' + AnsiString(IntToStr(Offset)) + ']');
end;

{ Store primary register in variable. }
procedure TCodeGen.StoreVar(Name : ansistring);
begin
  EmitLn('MOV ' + Name + ', EAX');
end;

{ Store primary register in parameter.  }
procedure TCodeGen.StoreParam(N : integer);
var
  Offset : integer;
begin
  Offset := 8 + 4 * (Base - N);
  EmitLn('MOV [EBP + ' + AnsiString(IntToStr(Offset)) + '], EAX');
end;

{ Increment variable. }
procedure TCodeGen.IncVar(Name : ansistring);
begin
  EmitLn('INC ' + Name);
end;

{ Decrement variable. }
procedure TCodeGen.DecVar(Name : ansistring);
begin
  EmitLn('DEC ' + Name);
end;

destructor TCodeGen.Destroy;
begin
  FDataSection.Free();
  FCodeSection.Free();
  inherited;
end;

{ Increment parameter. }
procedure TCodeGen.IncParam(N : integer);
begin
  Push;
  LoadParam(N);
  EmitLn('INC EAX');
  StoreParam(N);
  Pop;
end;

{ Decrement parameter. }
procedure TCodeGen.DecParam(N : integer);
begin
  Push;
  LoadParam(N);
  EmitLn('DEC EAX');
  StoreParam(N);
  Pop;
end;

{ Compare variable with primary. }
procedure TCodeGen. CompareVar(Name : ansistring);
begin
  EmitLn('CMP ' + Name + ', EAX');
end;

constructor TCodeGen.Create;
begin
  FDataSection := TStringList.Create();
  FCodeSection := TStringList.Create();
end;

{Compare a parameter with the primary register. }
procedure TCodeGen.CompareParam(N : integer);
begin
  EmitLn('PUSH EDX');
  EmitLn('MOV EDX, EAX');
  LoadParam(N);
  EmitLn('CMP EAX, EDX');
  EmitLn('MOV EAX, EDX'); //Restore EAX (flags unchanged)
  EmitLn('POP EDX'); //Restore EDX (flags unchanged)
end;

{ Push primary onto stack. }
procedure TCodeGen.Push;
begin
  EmitLn('PUSH EAX');
end;

{ Pop primary from stack. }
procedure TCodeGen.Pop;
begin
  EmitLn('POP EAX');
end;

{ Add top of stack to primary. }
procedure TCodeGen.PopAdd;
begin
  EmitLn('POP EDX');
  EmitLn('ADD EAX, EDX');
end;

{ Subtract primary from top of stack. }
procedure TCodeGen.PopSub;
begin
  EmitLn('POP EDX');
  EmitLn('SUB EAX, EDX');
  EmitLn('NEG EAX');
end;

{ Multiply top of stack by primary. }
procedure TCodeGen.PopMul;
var
  LabelOverflowError: AnsiString;
begin
  LabelOverflowError := NewLabel('OverflowError');
  EmitLn('POP EDX');
  EmitLn('IMUL EDX');
  EmitLn('JNC ' + LabelOverflowError); //Carry set if overflow into EDX
  EmitLn('print "    OVERFLOW ERROR    "');
  PostLabel(LabelOverflowError);
end;

{ Divide top of stack by primary. }
procedure TCodeGen.PopDiv;
begin
  EmitLn('MOV ECX, EAX');
  EmitLn('POP EAX');
  EmitLn('XOR EDX, EDX'); //Clear EDX
  EmitLn('IDIV ECX');
end;

{ AND top of stack with primary. }
procedure TCodeGen.PopAnd;
begin
  EmitLn('POP EDX');
  EmitLn('AND EAX, EDX');
end;

{ OR top of stack with primary. }
procedure TCodeGen.PopOr;
begin
  EmitLn('POP EDX');
  EmitLn('OR EAX, EDX');
end;

{ XOR top of stack with primary. }
procedure TCodeGen.PopXor;
begin
  EmitLn('POP EDX');
  EmitLn('XOR EAX, EDX');
end;

{ Compare top of stack with primary. }
procedure TCodeGen.PopCompare;
begin
  EmitLn('POP EDX');
  EmitLn('CMP EDX, EAX');
end;

{ Set EAX if compare was =. }
procedure TCodeGen.SetEqual;
begin
  EmitLn('CMOVE EAX, T');
  EmitLn('CMOVNE EAX, F');
end;

{ Set EAX if compare was !=. }
procedure TCodeGen.SetNEqual;
begin
  EmitLn('CMOVE EAX, F');
  EmitLn('CMOVNE EAX, T');
end;

{ Set EAX if compare was >. }
procedure TCodeGen.SetGreater;
begin
  EmitLn('CMOVG EAX, T');
  EmitLn('CMOVLE EAX, F');
end;

{ Set EAX if compare was <. }
procedure TCodeGen.SetLess;
begin
  EmitLn('CMOVL EAX, T');
  EmitLn('CMOVGE EAX, F');
end;

{ Set EAX if compare was <=. }
procedure TCodeGen.SetLessOrEqual;
begin
  EmitLn('CMOVLE EAX, T');
  EmitLn('CMOVG EAX, F');
end;

{ Set EAX if compare was >=. }
procedure TCodeGen.SetGreaterOrEqual;
begin
  EmitLn('CMOVGE EAX, T');
  EmitLn('CMOVL EAX, F');
end;

{ Branch unconditional. }
procedure TCodeGen.Jump(L : ansistring);
begin
  EmitLn('JMP ' + L);
end;

{ Branch if False. }
procedure TCodeGen.JumpFalse(L : ansistring);
begin
  EmitLn('TEST EAX, -1');
  EmitLn('JE ' + L);
end;

{ Branch if greater. }
procedure TCodeGen.JumpGreater(L : ansistring);
begin
  EmitLn('JG ' + L);
end;

{ Read variable to primary register. }
procedure TCodeGen.ReadIt;
begin
  EmitLn('MOV EAX, sval(input())');
                 //sval converts signed string to integer
end;

{ Wait for key press. }
procedure TCodeGen.ReadKey;
begin
  EmitLn('inkey');
end;

{ Write from primary register. }
procedure TCodeGen.WriteIt;
begin
  EmitLn('print str$(EAX)');
end;

{ Write a string. }
procedure TCodeGen.WriteString(OutPutString : ansistring);
begin
  EmitLn('print "' + OutPutString + '"');
end;

{ Send carriage return and line feed to console. }
procedure TCodeGen.NewLine;
begin
  EmitLn('print " ", 13, 10');
end;

{ Prefix to code section. }

{ Allocate storage for a static variable. }
procedure TCodeGen.Allocate(Name, Val : ansistring);
begin
  FDataSection.Add(Name + ' DD ' + Val);
end;

{ Call a procedure. }
procedure TCodeGen.Call(ProcName : AnsiString);
begin
  EmitLn('CALL ' + ProcName);
end;

{ Adjust the stack pointer upwards by N bytes. }
procedure TCodeGen.CleanStack(N : integer);
begin
  if N > 0 then
    EmitLn('ADD ESP, ' + AnsiString(IntToStr(N)));
end;

{ Write the prolog for a procedure. }
procedure TCodeGen.ProcProlog(N : ansistring; k : integer);
begin
  EmitLn('');
  PostLabel(N);
  EmitLn('PUSH EBP');
  EmitLn('MOV EBP, ESP');
  EmitLn('SUB ESP, ' + AnsiString(inttostr(4 * k)));
end;

{ Write the epilog for a procedure. }
procedure TCodeGen.ProcEpilog(N : ansistring);
begin
 EmitLn('MOV ESP, EBP');
 EmitLn('POP EBP');
 EmitLn('RET');
 EmitLn('');
end;

{ Position the cursor at X, Y  }
procedure TCodeGen.GenFile(const FileName: string);
var
  AsmFile: Textfile;
  i: Integer;
begin

  AssignFile(AsmFile, FileName);
  try
    Rewrite(AsmFile);

    Writeln(AsmFile, 'include \masm32\include\masm32rt.inc');
    Writeln(AsmFile, '.686'); //otherwise CMOV* opcodes not accepted

    Writeln(AsmFile, '');
    Writeln(AsmFile, '.data');
//    AddEntry('T', 'v');
    Allocate('T', '-1');
//    AddEntry('F', 'v');
    Allocate('F', '0');

    for i := 0 to FDataSection.Count -1 do
      Writeln(AsmFile, FDataSection[i]);

    Writeln(AsmFile, '');
    Writeln(AsmFile, '');

    Writeln(AsmFile, '.code');
    Writeln(AsmFile, 'START:');

    for i := 0 to FCodeSection.Count -1 do
      Writeln(AsmFile, FCodeSection[i]);

    Writeln(AsmFile, '    exit');
    Writeln(AsmFile, 'END START');
  finally
    Closefile(AsmFile);
  end;
end;

procedure TCodeGen.GoToXY; //locate is zero based
begin
  EmitLn('DEC X');
  EmitLn('DEC Y');
  EmitLn('invoke locate, X, Y');
end;

{ Clear screen }
procedure TCodeGen.ClrScr;
begin
  EmitLn('invoke locate, 0, 0');
  EmitLn('print OFFSET spaces');
  EmitLn('invoke locate, 0, 0');
end;

{ Change the  colours. }
procedure TCodeGen.SetColors(TextColour, BackColour : ansistring);
begin
  EmitLn('invoke GetStdHandle, STD_OUTPUT_HANDLE');
  EmitLn('MOV OUTHANDLE, EAX');
  EmitLn('invoke SetConsoleTextAttribute, OUTHANDLE, FOREGROUND_' + TextColour + ' OR BACKGROUND_' +  BackColour);
end;

{ Test for key press. }
procedure TCodeGen.KeyPress;
begin
  EmitLn('call crt__kbhit'); //EAX is zero if no key press
  EmitLn('Test EAX, EAX');
  EmitLn('CMOVZ EDX, F');
  EmitLn('CMOVNZ EDX, T');
  EmitLn('MOV KP, EDX');
end;

{ Read the pressed key. }
procedure TCodeGen.Readkey(K : ansistring);
begin
  EmitLn('call crt__getch');
  EmitLn('MOV ' + K + ', EAX');
end;

{ Store a random number in the variable supplied as a parameter. }
procedure TCodeGen.Random(RandVar : ansistring);
begin
  EmitLn('invoke nrandom, ' + RandVar);
  EmitLn('MOV ' + RandVar + ', EAX');
end;

{ Pause for DELAY ms. }
procedure TCodeGen.Sleep;
begin
  EmitLn('invoke Sleep, DELAY');
end;

{ End the program. }
procedure TCodeGen.Quit;
begin
  EmitLn('exit');
end;

{ Output a string with tab and CRLF }

procedure TCodeGen.EmitLn(s : ansistring);
begin
  FCodeSection.Add('    ' + s);
end;

{ Generate a unique label }
function TCodeGen.NewLabel(PreFixo: AnsiString = ''): ansistring;
var
  S : ansistring;
begin
  Str(LCount, S);

  if PreFixo = '' then
    NewLabel := '@L' + S
  else
    NewLabel := '@' + S + '_' + PreFixo;

  Inc(LCount);
end;

{ Post a label to output }
procedure TCodeGen.PostLabel(L : ansistring);
begin
  EmitLn('');
  FCodeSection.Add(L + ':');
end;

end.

