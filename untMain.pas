unit untMain;
//ToDo - Source Move or not, Source Block Move
{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ExtCtrls, ShellCtrls,
  ComCtrls, Grids, JvRollOut, untUtils, IniFiles, LResources, LCLType, FileUtil;

type

  { TfrmMain }

  TfrmMain = class(TForm)
    pnRight: TPanel;
    roLeft: TJvRollOut;
    roRight: TJvRollOut;
    pnLeft: TPanel;
    StatusBar: TStatusBar;
    sgLeft: TStringGrid;
    sgRight: TStringGrid;
    stvLeft: TShellTreeView;
    stvRight: TShellTreeView;
    Splitter: TSplitter;
    procedure FormCloseQuery(Sender: TObject; var CanClose: boolean);
    procedure FormCreate(Sender: TObject);
    procedure FormKeyDown(Sender: TObject; var Key: word; Shift: TShiftState);
    procedure FormKeyUp(Sender: TObject; var Key: word; Shift: TShiftState);
    procedure FormResize(Sender: TObject);
    procedure sgDragDrop(Sender, Source: TObject; X, Y: integer);
    procedure sgDragOver(Sender, Source: TObject; X, Y: integer;
      State: TDragState; var Accept: boolean);
    procedure sgKeyDown(Sender: TObject; var Key: word; Shift: TShiftState);
    procedure sgEditingDone(Sender: TObject);
    procedure sgSelection(Sender: TObject; aCol, aRow: integer);
    procedure sgMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: integer);
    procedure stvClick(Sender: TObject);
    procedure kpDisplay;
    procedure MoveBlock(sg: TStringGrid; idx: integer);
    function ComposeName(path: string; idx: integer; shortDstName: string): string;
    procedure RenameAll(Sender: TObject; Limit: integer; const Reverse: boolean = False);
    procedure RenameOne(Sender: TObject; aRow: integer);
    procedure CopyOne(Sender, Source: TObject; aSrcRow, aDstRow: integer);
  private

  public

  end;

var
  frmMain:      TfrmMain;
  sDragItem:    string;
  iDragItem:    integer;
  kpState:      integer;
  mdState:      integer;
  HomeDir:      string;
  sgEditDisable: boolean;
  currLeftRow:  integer;
  currRightRow: integer;

implementation

{$R *.lfm}


{ TfrmMain }

function TfrmMain.ComposeName(path: string; idx: integer; shortDstName: string): string;
begin
  Result := IncludeTrailingPathDelimiter(path) + Format('%.6d', [idx]) +
    '_' + shortDstName + '.ini';
end;

procedure TfrmMain.RenameAll(Sender: TObject; Limit: integer;
  const Reverse: boolean = False);
var
  i: integer;
  iMax: integer;
  path: string;
  idx: integer;
  oldName, newName: string;
begin
  path := ''; //because of compiler complains
  iMax := (Sender as TStringGrid).RowCount - 1;
  if Sender = sgLeft then path := stvLeft.Path;
  if Sender = sgRight then path := stvRight.Path;
  if not Reverse then
  begin
    for i := Limit to iMax do
    begin
      idx := i + 1;
      oldName := (Sender as TStringGrid).Cells[2, i];
      newName := ComposeName(path, idx, (Sender as TStringGrid).Cells[1, i]);
      if (Trim(oldName) <> '') then
        if Trim(oldName) <> Trim(newName) then
          if not RenameFile(oldName, newName) then
            ShowMessage('Could not rename file ' + IntToStr(i) +
              ': ' + (Sender as TStringGrid).Cells[1, i]);
    end;
  end;
  if Reverse then
  begin
    for i := iMax downto Limit do
    begin
      idx := i + 1;
      oldName := (Sender as TStringGrid).Cells[2, i];
      newName := ComposeName(path, idx, (Sender as TStringGrid).Cells[1, i]);
      if (Trim(oldName) <> '') then
        if Trim(oldName) <> Trim(newName) then
          if not RenameFile(oldName, newName) then
            ShowMessage('Could not rename file ' + IntToStr(i) +
              ': ' + (Sender as TStringGrid).Cells[1, i]);
    end;
  end;
  stvClick(stvLeft);
  stvClick(stvRight);
end;

procedure TfrmMain.RenameOne(Sender: TObject; aRow: integer);
var
  path: string;
  idx: integer;
  oldName, newName: string;
begin
  path := ''; //because of compiler complains
  if Sender = sgLeft then path := stvLeft.Path;
  if Sender = sgRight then path := stvRight.Path;
  idx := aRow + 1;
  oldName := (Sender as TStringGrid).Cells[2, aRow];
  newName := ComposeName(path, idx, (Sender as TStringGrid).Cells[1, aRow]);
  if (Trim(oldName) <> '') then
    if Trim(oldName) <> Trim(newName) then
      if not RenameFile(oldName, newName) then
        ShowMessage('Could not rename file ' + IntToStr(aRow) + ': ' +
          (Sender as TStringGrid).Cells[1, aRow]);
  stvClick(stvLeft);
  stvClick(stvRight);
end;

procedure TfrmMain.CopyOne(Sender, Source: TObject; aSrcRow, aDstRow: integer);
var
  path: string;
  idx: integer;
  oldName, newName: string;
begin
  path := ''; //because of compiler complains
  if Sender = sgLeft then path := stvLeft.Path;
  if Sender = sgRight then path := stvRight.Path;
  idx := aDstRow + 1;
  oldName := (Source as TStringGrid).Cells[2, aSrcRow];
  newName := ComposeName(path, idx, (Source as TStringGrid).Cells[1, aSrcRow]);
  if (Trim(oldName) <> '') then
    if Trim(oldName) <> Trim(newName) then
      if not CopyFile(oldName, newName, True) then
        ShowMessage('Could not copy file ' + (Sender as TStringGrid).Cells[1, aDstRow]);
end;

procedure TfrmMain.stvClick(Sender: TObject);
var
  sl: TStringList;
  i: integer;
  iNr: integer;
  iTmp: integer;
  sNr: string;
begin
  sgEditDisable := True;
  sl := TStringList.Create;
  FindPERF((Sender as TShellTreeView).Path, sl);
  if Sender = stvLeft then
  begin
    sgLeft.BeginUpdate;
    sgLeft.RowCount := 0;
    iNr := sl.Count;
    for i := 0 to sl.Count - 1 do
    begin
      sNr := Copy(sl[i], 1, 6);
      iTmp := StrToIntDef(sNr, 0);
      if iTmp > iNr then iNr := iTmp;
    end;
    sgLeft.RowCount := iNr;
    for i := 0 to sl.Count - 1 do
    begin
      sNr := Copy(sl[i], 1, 6);
      iTmp := StrToIntDef(sNr, 0) - 1;
      sgLeft.Cells[1, iTmp] := copy(sl[i], 8, Length(sl[i]) - 11);
      sgLeft.Cells[2, iTmp] :=
        IncludeTrailingPathDelimiter((Sender as TShellTreeView).Path) + sl[i];
    end;
    sgLeft.EndUpdate(True);
  end;
  if Sender = stvRight then
  begin
    sgRight.BeginUpdate;
    sgRight.RowCount := 0;
    iNr := sl.Count;
    for i := 0 to sl.Count - 1 do
    begin
      sNr := Copy(sl[i], 1, 6);
      iTmp := StrToIntDef(sNr, 0);
      if iTmp > iNr then iNr := iTmp;
    end;
    sgRight.RowCount := iNr;
    for i := 0 to sl.Count - 1 do
    begin
      sNr := Copy(sl[i], 1, 6);
      iTmp := StrToIntDef(sNr, 0) - 1;
      sgRight.Cells[1, iTmp] := copy(sl[i], 8, Length(sl[i]) - 11);
      sgRight.Cells[2, iTmp] :=
        IncludeTrailingPathDelimiter((Sender as TShellTreeView).Path) + sl[i];
    end;
    sgRight.EndUpdate(True);
  end;
  StatusBar.Panels[0].Text := stvLeft.Path;
  StatusBar.Panels[3].Text := stvRight.Path;
  if currLeftRow < sgLeft.RowCount then sgLeft.Row := currLeftRow
  else
    sgLeft.Row := sgLeft.RowCount - 1;
  if currRightRow < sgRight.RowCount then sgRight.Row := currRightRow
  else
    sgRight.Row := sgRight.RowCount - 1;
  sl.Free;
end;

procedure TfrmMain.sgDragOver(Sender, Source: TObject; X, Y: integer;
  State: TDragState; var Accept: boolean);
begin
  Unused(X, Y, State);
  if ((Source = sgLeft) or (Source = sgRight)) and (iDragItem <> -1) then Accept := True
  else
    Accept := False;
end;

procedure TfrmMain.sgKeyDown(Sender: TObject; var Key: word; Shift: TShiftState);
var
  iRow: integer;
  tmpKey: word;
begin
  if (Sender as TStringGrid).EditorMode = False then
  begin
    tmpKey := Key;
    iRow := (Sender as TStringGrid).Row;

    if ssShift in Shift then
    begin
      if Key = VK_INSERT then
      begin
        MoveBlock((Sender as TStringGrid), iRow);
        (Sender as TStringGrid).Cells[1, iRow] := '';
        (Sender as TStringGrid).Cells[2, iRow] := '';
        RenameAll(Sender, 0, True);
      end;
    end
    else
    if Key = VK_INSERT then
    begin
      (Sender as TStringGrid).InsertColRow(False, iRow);
      RenameAll(Sender, 0, True);
    end;

    //delete non-empty rows (files)
    if Trim((Sender as TStringGrid).Cells[2, iRow]) <> '' then
    begin
      if ssShift in Shift then
      begin
        if Key = VK_DELETE then
        begin
          if MessageDlg('Deleting file', 'Are you sure you want to delete the file' +
            #13#10 + (Sender as TStringGrid).Cells[1, iRow],
            mtConfirmation, [mbYes, mbCancel], 0) = mrYes then
          begin
            if DeleteFile((Sender as TStringGrid).Cells[2,
              (Sender as TStringGrid).Row]) then
            begin
              (Sender as TStringGrid).DeleteRow(iRow);
              RenameAll(Sender, 0);
            end
            else
              ShowMessage('Deleting file failed!');
          end;
        end;
      end
      else
      begin
        if Key = VK_DELETE then
        begin
          if MessageDlg('Deleting file', 'Are you sure you want to delete the file' +
            #13#10 + (Sender as TStringGrid).Cells[1, iRow],
            mtConfirmation, [mbYes, mbCancel], 0) = mrYes then
          begin
            if DeleteFile((Sender as TStringGrid).Cells[2,
              (Sender as TStringGrid).Row]) then
            begin
              (Sender as TStringGrid).Cells[1, iRow] := '';
              (Sender as TStringGrid).Cells[2, iRow] := '';
            end
            else
              ShowMessage('Deleting file failed!');
          end;
        end;
      end;
    end
    else
    begin
      //delete empty rows (no files)
      if Key = VK_DELETE then
      begin
        (Sender as TStringGrid).DeleteRow(iRow);
        RenameAll(Sender, 0);
      end;
    end;
    if (tmpKey = VK_INSERT) or (tmpKey = VK_DELETE) then
      Key := VK_ESCAPE
    else
      Key := tmpKey;
    if iRow < (Sender as TStringGrid).RowCount then
      (Sender as TStringGrid).Row := iRow
    else
      (Sender as TStringGrid).Row := (Sender as TStringGrid).RowCount - 1;
  end;
end;

procedure TfrmMain.sgEditingDone(Sender: TObject);
var
  r: integer;
  idx: integer;
  shortDstName: string;
  longSrcName: string;
  path: string;
  longDstName: string;
begin
  path := ''; //because of compiler complains
  if not sgEditDisable then
  begin
    r := (Sender as TStringGrid).Row;
    idx := r + 1;
    shortDstName := (Sender as TStringGrid).Cells[1, r];
    longSrcName := (Sender as TStringGrid).Cells[2, r];
    if Sender = sgLeft then path := stvLeft.Path;
    if Sender = sgRight then path := stvRight.Path;
    longDstName := ComposeName(path, idx, shortDstName);
    RenameFile(longSrcName, longDstName);
    if Sender = sgLeft then stvClick(stvLeft)
    else
      stvClick(stvRight);
  end;
end;

procedure TfrmMain.sgSelection(Sender: TObject; aCol, aRow: integer);
begin
  Unused(aCol, aRow);
  sgEditDisable := False;
end;

procedure TfrmMain.sgMouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: integer);
var
  SourceCol: integer;
begin
  Unused(Shift);
  mdState := 0;

  if Button = mbLeft then mdState := mdState + 1;
  if Button = mbRight then mdState := mdState + 2;
  kpDisplay;

  (Sender as TStringGrid).MouseToCell(X, Y, SourceCol, iDragItem);
  if iDragItem > -1 then
  begin
    (Sender as TStringGrid).BeginDrag(False, 4);
    sDragItem := (Sender as TStringGrid).Cells[2, iDragItem];
  end;
end;

procedure TfrmMain.FormResize(Sender: TObject);
begin
  pnLeft.Width := (frmMain.Width div 2) - Splitter.Width;
  StatusBar.Panels[0].Width := pnLeft.Width - 75 + (Splitter.Width div 2);
  StatusBar.Panels[3].Width := pnRight.Width - 105 + (Splitter.Width div 2);
end;

procedure TfrmMain.sgDragDrop(Sender, Source: TObject; X, Y: integer);
var
  iDestCol, iDestRow: integer;
  sTempCell: string;
  sShortTempCell: string;
  arRow: array [0..2] of string;
  sShortDragItem: string;
  Reverse: boolean;
begin
  (Sender as TStringGrid).MouseToCell(X, Y, iDestCol, iDestRow);
  Dec(iDestRow);  //insert before the selected row
  if Sender <> Source then
  begin
    if Sender = sgLeft then
    begin
      currLeftRow := iDestRow;
      currRightRow := iDragItem;
    end;
    if Sender = sgRight then
    begin
      currLeftRow := iDragItem;
      currRightRow := iDestRow;
    end;
  end;
  if Sender = Source then
  begin
    if Sender = sgLeft then currLeftRow := iDestRow;
    if Sender = sgRight then currRightRow := iDestRow;
  end;
  if (Sender = Source) and (iDestRow = iDragItem) then Exit;
  sShortDragItem := ExtractFileName(sDragItem);
  sShortDragItem := copy(sShortDragItem, 8, Length(sShortDragItem) - 11);
  arRow[0] := '';
  arRow[1] := sShortDragItem;
  arRow[2] := sDragItem;
  Reverse := iDragItem < iDestRow;
  case kpState of

    0: begin //exchange
      sTempCell := (Sender as TStringGrid).Cells[2, iDestRow];
      (Sender as TStringGrid).Cells[2, iDestRow] := sDragItem;
      (Sender as TStringGrid).Cells[1, iDestRow] := sShortDragItem;
      RenameOne(Sender, iDestRow);
      (Source as TStringGrid).Cells[2, iDragItem] := sTempCell;
      sShortTempCell := ExtractFileName(sTempCell);
      sShortTempCell := copy(sShortTempCell, 8, Length(sShortTempCell) - 11);
      (Source as TStringGrid).Cells[1, iDragItem] := sShortTempCell;
      RenameOne(Source, iDragItem);
    end;

    1: begin //Shift - Insert

      (Sender as TStringGrid).InsertColRow(False, iDestRow);
      RenameAll(Sender, iDestRow, True);

      if mdState = 1 then //Left click - Copy
      begin
        if Sender = Source then
        begin
          if iDragItem < iDestRow then
            CopyOne(Sender, Source, iDragItem, iDestRow);
          if iDragItem > iDestRow then
            CopyOne(Sender, Source, iDragItem + 1, iDestRow);//inserted row
        end
        else
          CopyOne(Sender, Source, iDragItem, iDestRow);
        RenameAll(Sender, 0, True);
        RenameAll(Source, 0, True);
      end;

      if mdState = 2 then //Right click - Move
      begin
        if Sender = Source then
        begin
          if iDragItem < iDestRow then
          begin
            CopyOne(Sender, Source, iDragItem, iDestRow);
            DeleteFile((Source as TStringGrid).Cells[2, iDragItem]);
          end;
          if iDragItem > iDestRow then
          begin
            CopyOne(Sender, Source, iDragItem + 1, iDestRow);//inserted row
            DeleteFile((Source as TStringGrid).Cells[2, iDragItem + 1]);
          end;
        end
        else
        begin
          CopyOne(Sender, Source, iDragItem, iDestRow);
          DeleteFile((Source as TStringGrid).Cells[2, iDragItem]);
        end;
        RenameAll(Sender, 0, True);
        RenameAll(Source, 0, True);
      end;
    end;

    2: begin //Ctrl - Overwrite

      if mdState = 1 then //Left click - Copy
      begin
        if Trim((Sender as TStringGrid).Cells[2, iDestRow]) <> '' then
        begin
          if MessageDlg('Overwriting file',
            'Are you sure you want to overwrite the file' + #13#10 +
            (Sender as TStringGrid).Cells[1, iDestRow], mtConfirmation,
            [mbYes, mbCancel], 0) <> mrYes then Exit
          else
            DeleteFile((Sender as TStringGrid).Cells[2, iDestRow]);
        end;
        CopyOne(Sender, Source, iDragItem, iDestRow);
        RenameAll(Sender, 0, Reverse);
        RenameAll(Source, 0, Reverse);
      end;

      if mdState = 2 then //Right click - Move
      begin
        if Trim((Sender as TStringGrid).Cells[2, iDestRow]) <> '' then
        begin
          if MessageDlg('Overwriting file',
            'Are you sure you want to overwrite the file' + #13#10 +
            (Sender as TStringGrid).Cells[1, iDestRow], mtConfirmation,
            [mbYes, mbCancel], 0) <> mrYes then Exit
          else
            DeleteFile((Sender as TStringGrid).Cells[2, iDestRow]);
        end;
        (Sender as TStringGrid).Cells[1, iDestRow] := arRow[1];
        (Sender as TStringGrid).Cells[2, iDestRow] := arRow[2];
        RenameAll(Sender, 0, Reverse);
        RenameAll(Source, 0, Reverse);
      end;
    end;

  end;
end;

procedure TfrmMain.MoveBlock(sg: TStringGrid; idx: integer);
var
  iEmptyCell: integer;
  i: integer;
begin
  sg.BeginUpdate;
  iEmptyCell := idx;
  for i := idx to sg.RowCount - 1 do
  begin
    if trim(sg.Cells[2, i]) = '' then
    begin
      iEmptyCell := i;
      Break;
    end;
  end;
  if iEmptyCell = idx then
  begin
    sg.RowCount := sg.RowCount + 1;
    iEmptyCell := sg.RowCount - 1;
  end;
  for i := (iEmptyCell - 1) downto idx do
  begin
    sg.MoveColRow(False, i, i + 1);
  end;
  sg.EndUpdate(True);
end;

procedure TfrmMain.FormCreate(Sender: TObject);
var
  ini: TIniFile;
begin
  sDragItem := '';
  iDragItem := -1;
  frmMain.KeyPreview := True;
  kpState := 0;
  mdState := 0;
  kpDisplay;
  sgLeft.RowCount := 0;
  sgRight.RowCount := 0;
  currLeftRow := 0;
  currRightRow := 0;
  HomeDir := IncludeTrailingPathDelimiter(IncludeTrailingPathDelimiter(GetUserDir) +
    'MiniDexedCC');
  if not DirectoryExists(HomeDir) then CreateDir(HomeDir);
  try
    ini := TIniFile.Create(HomeDir + 'PerfManager.ini');
    if DirectoryExists(ini.ReadString('PanelLeft', 'LastDir', '')) then
    begin
      stvLeft.Path := ini.ReadString('PanelLeft', 'LastDir', '');
      stvClick(stvLeft);
    end;
    roLeft.Collapsed := ini.ReadBool('PanelLeft', 'RollOutCollapsed', False);
    if DirectoryExists(ini.ReadString('PanelRight', 'LastDir', '')) then
    begin
      stvRight.Path := ini.ReadString('PanelRight', 'LastDir', '');
      stvClick(stvRight);
    end;
    roRight.Collapsed := ini.ReadBool('PanelRight', 'RollOutCollapsed', False);
    frmMain.Width := ini.ReadInteger('Form', 'Width', 1100);
    frmMain.Height := ini.ReadInteger('Form', 'Height', 784);
  finally
    ini.Free;
  end;
  Screen.Cursors[1] := LoadCursorFromLazarusResource('exchange24');
  Screen.Cursors[2] := LoadCursorFromLazarusResource('insert24');
  Screen.Cursors[3] := LoadCursorFromLazarusResource('overwrite24');
  if ParamCount > 0 then
  begin
    if DirectoryExists(ParamStr(1)) then
    begin
      stvLeft.Path := ParamStr(1);
      stvClick(stvLeft);
    end;
    if ParamCount = 2 then
      if DirectoryExists(ParamStr(2)) then
      begin
        stvRight.Path := ParamStr(2);
        stvClick(stvRight);
      end;
  end;
end;

procedure TfrmMain.FormCloseQuery(Sender: TObject; var CanClose: boolean);
var
  ini: TIniFile;
begin
  try
    ini := TIniFile.Create(HomeDir + 'PerfManager.ini');
    ini.WriteString('PanelLeft', 'LastDir', stvLeft.Path);
    ini.WriteBool('PanelLeft', 'RollOutCollapsed', roLeft.Collapsed);
    ini.WriteString('PanelRight', 'LastDir', stvRight.Path);
    ini.WriteBool('PanelRight', 'RollOutCollapsed', roRight.Collapsed);
    ini.WriteInteger('Form', 'Width', frmMain.Width);
    ini.WriteInteger('Form', 'Height', frmMain.Height);
  finally
    ini.Free;
  end;
  CanClose := True;
end;

procedure TfrmMain.FormKeyDown(Sender: TObject; var Key: word; Shift: TShiftState);
begin
  Unused(Key);
  kpState := 0;
  if ssShift in Shift then kpState := kpState + 1;
  if ssCtrl in Shift then kpState := kpState + 2;
  kpDisplay;
end;

procedure TfrmMain.FormKeyUp(Sender: TObject; var Key: word; Shift: TShiftState);
begin
  Unused(Key);
  kpState := 0;
  if ssShift in Shift then kpState := kpState + 1;
  if ssCtrl in Shift then kpState := kpState + 2;
  kpDisplay;
end;

procedure TfrmMain.kpDisplay;
begin
  case mdState of
    0: begin
      StatusBar.Panels[1].Text := '';
    end;
    1: begin
      StatusBar.Panels[1].Text := 'COPY';
    end;
    2: begin
      StatusBar.Panels[1].Text := 'MOVE';
    end;
  end;
  case kpState of
    0: begin
      StatusBar.Panels[1].Text := '';
      StatusBar.Panels[2].Text := 'EXCHANGE';
      sgLeft.DragCursor := 1;
      sgRight.DragCursor := 1;
    end;
    1: begin  //Shift
      StatusBar.Panels[2].Text := 'INSERT';
      sgLeft.DragCursor := 2;
      sgRight.DragCursor := 2;
    end;
    2: begin  //Ctrl
      StatusBar.Panels[2].Text := 'OVERWRITE';
      sgLeft.DragCursor := 3;
      sgRight.DragCursor := 3;
    end;
  end;
end;

initialization
{$I cursors.lrs}

end.
