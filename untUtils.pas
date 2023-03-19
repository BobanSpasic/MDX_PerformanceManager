{
 *****************************************************************************
  See the file COPYING.modifiedLGPL.txt, included in this distribution,
  for details about the license.
 *****************************************************************************

 Author: Boban Spasic

 Unit description:
 A couple of functions and procedures for general use in other units
}

unit untUtils;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, LazFileUtils, SysUtils;

function FileIsPerf(aFileName: string): Boolean;
procedure FindSYX(Directory: string; var sl: TStringList);
procedure FindPERF(Directory: string; var sl: TStringList);
procedure Unused(const A1);
procedure Unused(const A1, A2);
procedure Unused(const A1, A2, A3);
function SameArrays(var a1, a2: array of byte): boolean;

implementation

function FileIsPerf(aFileName: string): Boolean;
var
  sName: string;
  sNumber: string;
  iNumber: Integer;
begin
  Result := True;
  sName := ExtractFileName(aFileName);
  sNumber := copy(sName, 0, 6);
  iNumber := StrToIntDef(sNumber, -1);
  if iNumber = -1 then Result := False;
  iNumber := Pos('_', sName);
  if iNumber <> 7 then Result := False;
  if LowerCase(ExtractFileExt(sName)) <> '.ini' then Result := False;
end;

procedure FindSYX(Directory: string; var sl: TStringList);
var
  sr: TSearchRec;
begin
  if FindFirst(Directory + '*.syx', faAnyFile, sr) = 0 then
    repeat
      sl.Add(ExtractFileName(sr.Name));
    until FindNext(sr) <> 0;
  FindClose(sr);
end;

procedure FindPERF(Directory: string; var sl: TStringList);
var
  sr: TSearchRec;
begin
  if FindFirst(Directory + '*.ini', faAnyFile, sr) = 0 then
    repeat
      if FileIsPerf(sr.Name) then
        sl.Add(ExtractFileName(sr.Name));
    until FindNext(sr) <> 0;
  FindClose(sr);
end;

{$PUSH}{$HINTS OFF}
procedure Unused(const A1);
begin
end;

procedure Unused(const A1, A2);
begin
end;

procedure Unused(const A1, A2, A3);
begin
end;

{$POP}

function SameArrays(var a1, a2: array of byte): boolean;
var
  i: integer;
begin
  i := Low(a1);
  while (i <= High(a1)) and (a1[i] = a2[i]) do
    Inc(i);
  Result := i >= High(a1);
end;

end.
