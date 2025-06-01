unit uEdit;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, StrUtils, FileUtil, Forms, Controls, Graphics, Dialogs, ExtCtrls,
  Buttons, Menus, ComCtrls, StdCtrls, SynEdit, SynHighlighterAny, Process;

type
  TfrmEdit = class(TForm)
    ImageList1 : TImageList;
    Memo1: TMemo;
    OpenDialog1 : TOpenDialog;
    SaveDialog1 : TSaveDialog;
    SynAnySyn1 : TSynAnySyn;
    SynEdit1 : TSynEdit;
    ToolBar1 : TToolBar;
    tbtnOpen : TToolButton;
    tbtnSave : TToolButton;
    tbtnExecute : TToolButton;
    procedure Execute(Sender: TObject);
    procedure FormChangeBounds(Sender: TObject);
    procedure Open(Sender: TObject);
    procedure Save(Sender: TObject);
    procedure FormCreate(Sender: TObject);
  end;
var
  frmEdit: TfrmEdit;

implementation

{$R *.lfm}
const
  COMPILER_PATHNAME = '/home/pi/TINY/TINY14PI';

var
  SourcePathname, BinPathname, AssemblerPathname : string;

procedure TfrmEdit.Open(Sender: TObject);
begin
  with opendialog1 do
    if Execute then
      begin
        Memo1.Lines.Clear;
        InitialDir := '';  //current folder
        SourcePathname := Filename;
        AssemblerPathname := ChangeFileExt(Filename, '.s');
        BinPathname := ChangeFileExt(Filename, '');
        Synedit1.Lines.LoadFromFile(Filename);
        frmEdit.Caption := ExtractFileName(SourcePathname) + ' in TINY IDE';
      end;
end;

procedure TfrmEdit.Save(Sender: TObject);
begin
  with savedialog1 do
    if Execute then
      begin
        InitialDir := '';  //current folder
        SourcePathname := Filename;
        AssemblerPathname := ChangeFileExt(Filename, '.s');
        BinPathname := ChangeFileExt(Filename, '');
        Synedit1.Lines.SaveToFile(Filename);
        frmEdit.Caption := ExtractFileName(SourcePathname) + ' in TINY IDE';
      end;
end;

procedure TfrmEdit.Execute(Sender: TObject);
var
  ProcessCompile, ProcessAssemble, ProcessRun : TProcess;
  ErrorLineNo : integer;
  ErrorLine : string;
  NumMarker : integer; //to be subtracted from the string length to
                       //give the number of digits in the number
begin
  Synedit1.Lines.SaveToFile(SourcePathname);
  ProcessCompile:= TProcess.Create(nil);
  Memo1.Lines.Clear;
  Memo1.Lines[0] := '';
  try
    ProcessCompile.CommandLine := COMPILER_PATHNAME + ' ' + SourcePathname;
    ProcessCompile.Options := [poUsePipes, poWaitOnExit];
    ProcessCompile.Execute;
    Memo1.Lines.LoadFromStream(ProcessCompile.Output);
  finally
    ProcessCompile.Free;
  end;
  if Memo1.Lines[0] = '' then
    begin
      ProcessAssemble := TProcess.Create(nil);
      try
        ProcessAssemble.CommandLine := '/usr/bin/gcc -o ' + BinPathname + ' ' + AssemblerPathname;
        ProcessAssemble.Options := ProcessAssemble.Options + [poWaitOnExit];
        ProcessAssemble.Execute;
      finally
        ProcessAssemble.free;
      end;

      ProcessRun := TProcess.Create(nil);
      try
        ProcessRun.CommandLine := '/usr/bin/x-terminal-emulator -T ''' +
                                  BinPathname + ''' -e ' + BinPathname;
        ProcessRun.Options := ProcessRun.Options + [poWaitOnExit];
        ProcessRun.Execute;
      finally
        ProcessRun.free;
      end;
    end
  else
    begin
      ErrorLine := Memo1.lines[0];
      NumMarker := pos('line', ErrorLine) + 4;
      try
        ErrorLineNo := strtoint(rightStr(ErrorLine, length(ErrorLine) - NumMarker));
        //Couldn't find simple GoToLine so insert nothing and position cursor after it!
        synEdit1.TextBetweenPointsEx[Point(1, ErrorLineNo), Point(1, ErrorLineNo), ScamEnd] := '';
      except
        Memo1.lines.Add('The cursor has not been moved.');
      end;
    end;
end;

//Resize Memo and SynEdit when user resizes form.
procedure TfrmEdit.FormChangeBounds(Sender: TObject);
begin
  SynEdit1.Width:= frmEdit.Width - 20;
  SynEdit1.Height:= frmEdit.Height - 80;
  Memo1.Width:= frmEdit.Width - 20;
  Memo1.Top:= SynEdit1.Top + SynEdit1.Height + 5;
end;

procedure TfrmEdit.FormCreate(Sender: TObject);
begin
  SourcePathname := ParamStr(1);
  AssemblerPathname := ChangeFileExt(SourcePathname, '.s');
  BinPathname := ChangeFileExt(SourcePathname, '');
  Synedit1.Lines.LoadFromFile(SourcePathname);
  frmEdit.Caption := ExtractFileName(SourcePathname) + ' in TINY IDE';
end;

end.