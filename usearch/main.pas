unit main;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, XPMan, ComCtrls, ExtCtrls, StdCtrls, Buttons, KControls, KGrids,
  Menus, XMLDoc, MSXML2_TLB, UIB, Info;

type
  TSrvParam = record
    Server: string;
    Database: string;
    Username: string;
    Password: string;
  end;

type
  TfrmUSearch = class(TForm)
    icoTray: TTrayIcon;
    ftrStatus: TStatusBar;
    txtSearch: TEdit;
    btnSearch: TBitBtn;
    tblUsers: TKGrid;
    mnuUser: TPopupMenu;
    mnuMain: TPopupMenu;
    mVisible: TMenuItem;
    mSeparator: TMenuItem;
    mExit: TMenuItem;
    procedure FormCreate(Sender: TObject);
    procedure mExitClick(Sender: TObject);
    procedure mVisibleClick(Sender: TObject);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
    procedure FormDestroy(Sender: TObject);
    procedure btnSearchClick(Sender: TObject);
    procedure icoTrayClick(Sender: TObject);
    procedure tblUsersMouseDblClickCell(Sender: TObject; ACol, ARow: Integer);
    procedure mInformationClick(Sender: TObject);
    procedure tblUsersMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
  private
    procedure FSetHeaders;
    function FGetSrvParam: TSrvParam;
    procedure FConnect;
    procedure FDisconnect;    
    procedure FSeek(AQuery: string);
    procedure FView;
    procedure FLoadMain;
    procedure FSaveMain;
    procedure FAddInfo;
    procedure FShowInfo(ARecord: integer);
    procedure FAddCmd(AName, ACommand: string);
    procedure FExecute(Sender: TObject);
    function FReplace(ACommand: string): string;
    procedure FShowError(AMessage: string);
  public
  end;

var
  frmUSearch: TfrmUSearch;
  FUIBDatabase: TUIBDatabase;
  FUIBTransaction: TUIBTransaction;
  FUIBQuery: TUIBQuery;
  FCmdList: TStringList;

const
  PARAM_FILE = 'usearch.xml';
  LIB_FILE = 'fbclient.dll';
  LOG_FILE = 'error.log';

implementation

{$R *.dfm}

procedure TfrmUSearch.FormCreate(Sender: TObject);
begin
  FCmdList := TStringList.Create;
  Self.FSetHeaders;
  Self.FLoadMain;
  Self.FConnect;
end;

procedure TfrmUSearch.FormDestroy(Sender: TObject);
begin
  FreeAndNil(FCmdList);
  Self.FDisconnect;
  Self.FSaveMain;
end;

procedure TfrmUSearch.btnSearchClick(Sender: TObject);
begin
  Self.FSeek(txtSearch.Text);
  Self.FView;
end;

procedure TfrmUSearch.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
begin
  CanClose := False;
  mVisible.OnClick(Self);
end;

procedure TfrmUSearch.icoTrayClick(Sender: TObject);
begin
  mVisible.OnClick(Self);
end;

procedure TfrmUSearch.mExitClick(Sender: TObject);
begin
  Application.Terminate;
end;

procedure TfrmUSearch.mVisibleClick(Sender: TObject);
begin
  if Self.Visible then
  begin
    Self.Hide;
    mVisible.Caption := 'Показать';
  end
  else
  begin
    Self.Show;
    mVisible.Caption := 'Скрыть';
  end;
end;

procedure TfrmUSearch.mInformationClick(Sender: TObject);
begin
  FShowInfo(tblUsers.Selection.Row1);
end;

procedure TfrmUSearch.tblUsersMouseDblClickCell(Sender: TObject; ACol,
  ARow: Integer);
begin
  FShowInfo(ARow);
end;

procedure TfrmUSearch.tblUsersMouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
var
  FRow: integer;
  FCol: integer;
  FPoint: TPoint;
begin
  if Button = mbRight then
  begin
    tblUsers.MouseToCell(X, Y, FCol, FRow);
    if (FRow > 0) and (FRow < tblUsers.RowCount) then
    begin
      tblUsers.SetFocus;
      tblUsers.Selection := GridRect(1, FRow, 1, FRow);
      FPoint := tblUsers.ClientToScreen(Point(X,Y));
      tblUsers.PopupMenu.Popup(FPoint.X, FPoint.Y);
    end;
  end;
end;

procedure TfrmUSearch.FSetHeaders;
begin
  tblUsers.Cells[0,0] := 'Имя пользователя';
  tblUsers.Cells[1,0] := 'E-mail';
  tblUsers.Cells[2,0] := 'Телефон';
  tblUsers.Cells[3,0] := 'Город';
  tblUsers.Cells[4,0] := 'Компьютер';
end;

function TfrmUSearch.FGetSrvParam: TSrvParam;
var
  FXMLFile: TXMLDoc;
begin
  try
    FXMLFile := TXMLDoc.Create(ExtractFilePath(ParamStr(0)) + PARAM_FILE);
    Result.Server := FXMLFile.ReadString('network', 'server', 'localhost');
    Result.Database := FXMLFile.ReadString('network', 'database', 'sessions');
    Result.Username := FXMLFile.ReadString('network', 'username', 'sysdba');
    Result.Password := FXMLFile.ReadString('network', 'password', 'masterkey');
  except
    // ERROR
    on E: Exception do
    FShowError(E.Message);
  end;
  FreeAndNil(FXMLFile);
end;

procedure TfrmUSearch.FConnect;
var
  FSrvParam: TSrvParam;
begin
  try
    FSrvParam := Self.FGetSrvParam;
    FUIBDatabase := TUIBDatabase.Create(nil);
    FUIBTransaction := TUIBTransaction.Create(nil);
    FUIBQuery := TUIBQuery.Create(nil);
    FUIBTransaction.DataBase := FUIBDatabase;
    FUIBQuery.Transaction := FUIBTransaction;
    FUIBDatabase.LibraryName := LIB_FILE;
    FUIBDatabase.DatabaseName := FSrvParam.Server + ':' + FSrvParam.Database;
    FUIBDatabase.UserName := FSrvParam.Username;
    FUIBDatabase.PassWord := FSrvParam.Password;
  except
    // ERROR
    on E: Exception do
    FShowError(E.Message);
  end;
end;

procedure TfrmUSearch.FDisconnect;
begin
  try
    FUIBQuery.Close(etmCommit);
  except
    // ERROR
    on E: Exception do
    FShowError(E.Message);
  end;
end;

procedure TfrmUSearch.FSeek(AQuery: string);
begin
  AQuery := UpperCase(AQuery);
  try
    FUIBQuery.Close(etmCommit);
    FUIBQuery.Params.Clear;
    FUIBQuery.SQL.Clear;
    FUIBQuery.SQL.Add('SELECT * FROM SESSIONS WHERE ');
    FUIBQuery.SQL.Add('(UPPER(USERNAME) = :username) OR ');
    FUIBQuery.SQL.Add('(UPPER(FULLNAME) LIKE :fullname) OR ');
    FUIBQuery.SQL.Add('(UPPER(FIRSTNAME) LIKE :firstname) OR ');
    FUIBQuery.SQL.Add('(UPPER(LASTNAME) LIKE :lastname) OR ');
    FUIBQuery.SQL.Add('(UPPER(DISPNAME) LIKE :dispname) OR ');
    FUIBQuery.SQL.Add('(UPPER(TELEPHONE) = :telephone) OR ');
    FUIBQuery.SQL.Add('(UPPER(EMAIL) = :email)');
    FUIBQuery.Params.ByNameAsString['username'] := AQuery;
    FUIBQuery.Params.ByNameAsString['fullname'] := '%' + AQuery + '%';
    FUIBQuery.Params.ByNameAsString['firstname'] := '%' + AQuery + '%';
    FUIBQuery.Params.ByNameAsString['lastname'] := '%' + AQuery + '%';
    FUIBQuery.Params.ByNameAsString['dispname'] := '%' + AQuery + '%';
    FUIBQuery.Params.ByNameAsString['telephone'] := AQuery;
    FUIBQuery.Params.ByNameAsString['email'] := AQuery;
    FUIBQuery.Execute;
    FUIBQuery.FetchAll;
  except
    // ERROR
    on E: Exception do
    FShowError(E.Message);
  end;
end;

procedure TfrmUSearch.FView;
var
  FIndex: integer;
begin
  try
    for FIndex := 1 to tblUsers.RowCount do
    tblUsers.ClearRow(FIndex);
    if FUIBQuery.Fields.RecordCount < 1 then
    tblUsers.RowCount := 2 else
    tblUsers.RowCount := FUIBQuery.Fields.RecordCount + 1;
    ftrStatus.Panels[0].Text := 'Записей: ' + IntToStr(FUIBQuery.Fields.RecordCount);
    FUIBQuery.First;
    FIndex := 1;
    while not FUIBQuery.EOF do
    begin
      tblUsers.Cells[0, FIndex] := FUIBQuery.Fields.ByNameAsString['fullname'];
      tblUsers.Cells[1, FIndex] := FUIBQuery.Fields.ByNameAsString['email'];
      tblUsers.Cells[2, FIndex] := FUIBQuery.Fields.ByNameAsString['telephone'];
      tblUsers.Cells[3, FIndex] := FUIBQuery.Fields.ByNameAsString['location'];
      tblUsers.Cells[4, FIndex] := FUIBQuery.Fields.ByNameAsString['compname'];
      FUIBQuery.Next;
      Inc(FIndex);
    end;
  except
    // ERROR
    on E: Exception do
    FShowError(E.Message);
  end;
end;

procedure TfrmUSearch.FLoadMain;
var
  FXMLDoc: TXMLDoc;
  FNode: IXMLDOMNodeList;
  FIndex: integer;
  FDefault: integer;
begin
  try
    FDefault := tblUsers.Width div tblUsers.ColCount;
    FXMLDoc := TXMLDoc.Create(ExtractFilePath(ParamStr(0)) + PARAM_FILE);
    Self.Height := FXMLDoc.ReadInteger('window', 'height', Self.Height);
    Self.Width := FXMLDoc.ReadInteger('window', 'width', Self.Width);
    for FIndex := 0 to tblUsers.ColCount - 1 do
    tblUsers.ColWidths[FIndex] := FXMLDoc.ReadItem('columns', 'column', FIndex, FDefault);
    FNode := FXMLDoc.GetItems('commands', 'command');
    if FNode <> nil then
    begin
      for FIndex := 0 to FNode.Length - 1 do
      if FNode[FIndex].Attributes.GetNamedItem('execute') <> nil then
      FAddCmd(FNode[FIndex].Text, FNode[FIndex].Attributes.GetNamedItem('execute').Text);
    end;
    FAddInfo;
  except
    // ERROR
    on E: Exception do
    FShowError(E.Message);
  end;
  FreeAndNil(FXMLDoc);
end;

procedure TfrmUSearch.FSaveMain;
var
  FXMLDoc: TXMLDoc;
  FIndex: integer;
begin
  try
    FXMLDoc := TXMLDoc.Create(ExtractFilePath(ParamStr(0)) + PARAM_FILE);
    FXMLDoc.WriteInteger('window', 'height', Self.Height);
    FXMLDoc.WriteInteger('window', 'width', Self.Width);
    for FIndex := 0 to tblUsers.ColCount - 1 do
    FXMLDoc.WriteItem('columns', 'column', FIndex, tblUsers.ColWidths[FIndex]);
  except
    // ERROR
    on E: Exception do
    FShowError(E.Message);
  end;
  FreeAndNil(FXMLDoc);
end;

procedure TfrmUSearch.FAddInfo;
var
  mnuItem: TMenuItem;
begin
  mnuItem := TMenuItem.Create(nil);
  mnuItem.Caption := '-';
  tblUsers.PopupMenu.Items.Add(mnuItem);
  mnuItem := TMenuItem.Create(nil);
  mnuItem.Caption := 'Информация';
  mnuItem.Default := True;
  mnuItem.OnClick := Self.mInformationClick;
  tblUsers.PopupMenu.Items.Add(mnuItem);  
end;

procedure TfrmUSearch.FShowInfo(ARecord: integer);
var
  FRecord: integer;
begin
  FRecord := ARecord - 1;
  try
    if (FUIBDatabase.Connected) and
    (FUIBQuery.Fields.RecordCount >= FRecord) and
    (ARecord > 0) then
    begin
      FUIBQuery.Fields.GetRecord(FRecord);
      frmInfo.txtInfo.Lines.Clear;      
      frmInfo.txtInfo.Lines.Add(Format('Запись: %s', [FUIBQuery.Fields.ByNameAsString['fullname']]));
      frmInfo.txtInfo.Lines.Add(Format('Полное имя: %s', [FUIBQuery.Fields.ByNameAsString['dispname']]));
      frmInfo.txtInfo.Lines.Add(Format('Имя: %s', [FUIBQuery.Fields.ByNameAsString['firstname']]));
      frmInfo.txtInfo.Lines.Add(Format('Фамилия: %s', [FUIBQuery.Fields.ByNameAsString['lastname']]));
      frmInfo.txtInfo.Lines.Add(Format('Город: %s', [FUIBQuery.Fields.ByNameAsString['location']]));
      frmInfo.txtInfo.Lines.Add(Format('E-mail: %s', [FUIBQuery.Fields.ByNameAsString['email']]));
      frmInfo.txtInfo.Lines.Add(Format('Телефон: %s', [FUIBQuery.Fields.ByNameAsString['telephone']]));
      frmInfo.txtInfo.Lines.Add(Format('Логин: %s', [FUIBQuery.Fields.ByNameAsString['username']]));
      frmInfo.txtInfo.Lines.Add(Format('Компьютер: %s', [FUIBQuery.Fields.ByNameAsString['compname']]));
      if FUIBQuery.Fields.ByNameIsNull['logoff'] then
      frmInfo.txtInfo.Lines.Add(Format('Вошел: %s', ['n/a']))
      else frmInfo.txtInfo.Lines.Add(Format('Вошел: %s', [FUIBQuery.Fields.ByNameAsString['logon']]));
      if FUIBQuery.Fields.ByNameIsNull['logoff'] then
      frmInfo.txtInfo.Lines.Add(Format('Вышел: %s', ['n/a']))
      else frmInfo.txtInfo.Lines.Add(Format('Вышел: %s', [FUIBQuery.Fields.ByNameAsString['logoff']]));
      if FUIBQuery.Fields.ByNameAsSmallint['online'] = 0 then
      frmInfo.txtInfo.Lines.Add(Format('В сети: %s', ['нет']))
      else frmInfo.txtInfo.Lines.Add(Format('В сети: %s', ['да']));
      frmInfo.ShowModal;
    end;
  except
    // ERROR
    on E: Exception do
    FShowError(E.Message);
  end;
end;

procedure TfrmUSearch.FAddCmd(AName, ACommand: string);
var
  mnuItem: TMenuItem;
begin
  mnuItem := TMenuItem.Create(nil);
  mnuItem.Caption := AName;
  mnuItem.OnClick := FExecute;
  tblUsers.PopupMenu.Items.Add(mnuItem);
  FCmdList.Add(ACommand);
end;

procedure TfrmUSearch.FExecute(Sender: TObject);
var
  FIndex: integer;
  FCommand: string;
begin
  FIndex := tblUsers.PopupMenu.Items.IndexOf(TMenuItem(Sender));
  FCommand := FReplace(FCmdList[FIndex]);
  try
    WinExec(PChar(FCommand), 1);
  except
    // ERROR
    on E: Exception do
    FShowError(E.Message);
  end;
end;

function TfrmUSearch.FReplace(ACommand: string): string;
var
  FRecord: integer;
  FIndex: integer;
begin
  FRecord := tblUsers.Selection.Row1 - 1;
  Result := ACommand;
  try
    if (FUIBDatabase.Connected) and
    (FUIBQuery.Fields.RecordCount >= FRecord) and
    (FRecord >= 0) then
    begin
      FUIBQuery.Fields.GetRecord(FRecord);
      for FIndex := 0 to FUIBQuery.Fields.FieldCount - 1 do
      Result := StringReplace(Result, '%' + LowerCase(FUIBQuery.Fields.AliasName[FIndex]) + '%', FUIBQuery.Fields.AsString[FIndex], [rfReplaceAll]);
    end
    else Result := '';
  except
    // ERROR
    on E: Exception do
    FShowError(E.Message);
  end;
end;

procedure TfrmUSearch.FShowError(AMessage: string);
var
  FLogFile: TextFile;
  FLogName: string;
begin
  FLogName := ExtractFilePath(ParamStr(0)) + LOG_FILE;
  AssignFile(FLogFile, FLogName);
  if not FileExists(FLogName) then
  ReWrite(FLogFile) else Append(FLogFile);
  WriteLn(FLogFile, FormatDateTime('[dd.mm.yyyy HH:nn:ss]'#13#10, Now) + AMessage + #13#10);
  CloseFile(FLogFile);
  MessageBox(0, PChar('Во время выполнения произошла ошибка.'#13#10 + AMessage), 'Ошибка', 48);
end;

end.
