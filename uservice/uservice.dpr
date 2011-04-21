program uservice;

{$APPTYPE CONSOLE}

uses
  Windows, SysUtils, IniFiles, ActiveDS_TLB, ComObj, ActiveX, UIB;

type
  TSrvParam = record
    Server: string;
    Database: string;
    Username: string;
    Password: string;
  end;

type
  TUserInfo = record
    Username: string;
    Compname: string;
    Fullname: string;
    Firstname: string;
    Lastname: string;
    Dispname: string;
    Telephone: string;
    Location: string;
    Email: string;
    Logon: string;
    Logoff: string;
  end;

type
  TUsernameService = class(TObject)
  private
    FADSystemInfo: IADsADSystemInfo;
    FADUserInfo: IADsUser;
    function GetCurrentTime: string;
    function GetUserInfo: TUserInfo;
    function GetSrvParam: TSrvParam;
  public
    procedure Logon;
    procedure Logoff;
    procedure Debug;
    function GetCompName: string;    
  end;

function ADsGetObject(lpszPathName: WideString; const riid: TGUID;
  out ppObject: Pointer): HRESULT; stdcall; external 'activeds.dll';

const
  PARAM_FILE = 'USERVICE.INI';
  LIB_FILE = 'FBCLIENT.DLL';

function TUsernameService.GetUserInfo: TUserInfo;
begin
  try
    CoInitialize(nil);
    FADSystemInfo := CreateOleObject('ADSystemInfo') as IADsADSystemInfo;
    ADsGetObject('LDAP://' + FADSystemInfo.UserName, IADsUser, Pointer(FADUserInfo));
    Result.Username := FADUserInfo.Get('sAMAccountName');
    Result.Compname := Self.GetCompName;
    Result.Fullname := FADUserInfo.Get('name');
    Result.Firstname := FADUserInfo.Get('givenName');
    Result.Lastname := FADUserInfo.Get('sn');
    Result.Dispname := FADUserInfo.Get('displayName');
    Result.Telephone := FADUserInfo.Get('telephoneNumber');
    Result.Location := FADUserInfo.Get('l');
    Result.Email := FADUserInfo.Get('mail');
    Result.Logon := Self.GetCurrentTime;
    Result.Logoff := Self.GetCurrentTime;
  except
    Writeln('* Error (100)');
  end;
  FADUserInfo := nil;
  FADSystemInfo := nil;
end;

function TUsernameService.GetCompName: string;
var
  FCompName: array[0..255] of Char;
  FCompSize: Cardinal;
begin
  try
    FCompSize := SizeOf(FCompName);
    Windows.GetComputerName(@FCompName, FCompSize);
    Result := Trim(FCompName);
  except
    Writeln('* Error (101)');
  end;
end;

function TUsernameService.GetCurrentTime: string;
begin
  Result := FormatDateTime('yyyy-mm-dd HH:nn:ss', Now);
end;

function TUsernameService.GetSrvParam: TSrvParam;
var
  FIniFile: TIniFile;
begin
  try
    FIniFile := TIniFile.Create(ExtractFilePath(ParamStr(0)) + PARAM_FILE);
    Result.Server := FIniFile.ReadString('general', 'server', 'localhost');
    Result.Database := FIniFile.ReadString('general', 'database', 'sessions');
    Result.Username := FIniFile.ReadString('general', 'username', 'sysdba');
    Result.Password := FIniFile.ReadString('general', 'password', 'masterkey');
    FIniFile.Free;
  except
    Writeln('* Error (102)');
  end;
end;

procedure TUsernameService.Logon;
var
  FUIBDatabase: TUIBDatabase;
  FUIBTransaction: TUIBTransaction;
  FUIBQuery: TUIBQuery;
  FSrvParam: TSrvParam;
  FUserInfo: TUserInfo;
begin
  FSrvParam := GetSrvParam;
  try
    FUIBDatabase := TUIBDatabase.Create(nil);
    FUIBDatabase.LibraryName := LIB_FILE;    
    FUIBDatabase.DatabaseName := FSrvParam.Server + ':' + FSrvParam.Database;
    FUIBDatabase.UserName := FSrvParam.Username;
    FUIBDatabase.PassWord := FSrvParam.Password;
    FUIBQuery := TUIBQuery.Create(nil);
    FUIBTransaction := TUIBTransaction.Create(nil);
    FUIBTransaction.DataBase := FUIBDatabase;
    FUIBQuery.Transaction := FUIBTransaction;
    FUIBQuery.SQL.Add('UPDATE OR INSERT INTO SESSIONS (USERNAME,COMPNAME,FULLNAME,FIRSTNAME,LASTNAME,DISPNAME,TELEPHONE,LOCATION,EMAIL,LOGON,LOGOFF,ONLINE) VALUES (:username,:compname,:fullname,:firstname,:lastname,:dispname,:telephone,:location,:email,:logon,null,:online)');
    FUIBQuery.Prepare;
    FUserInfo := GetUserInfo;
    FUIBQuery.Params.ByNameAsString['username'] := FUserInfo.Username;
    FUIBQuery.Params.ByNameAsString['compname'] := FUserInfo.Compname;
    FUIBQuery.Params.ByNameAsString['fullname'] := FUserInfo.Fullname;
    FUIBQuery.Params.ByNameAsString['firstname'] := FUserInfo.Firstname;
    FUIBQuery.Params.ByNameAsString['lastname'] := FUserInfo.Lastname;
    FUIBQuery.Params.ByNameAsString['dispname'] := FUserInfo.Dispname;
    FUIBQuery.Params.ByNameAsString['telephone'] := FUserInfo.Telephone;
    FUIBQuery.Params.ByNameAsString['location'] := FUserInfo.Location;
    FUIBQuery.Params.ByNameAsString['email'] := FUserInfo.Email;
    FUIBQuery.Params.ByNameAsString['logon'] := FUserInfo.Logon;
    FUIBQuery.Params.ByNameAsSmallint['online'] := 1;
    FUIBQuery.ExecSQL;
    FUIBTransaction.Free;
    FUIBQuery.Free;
    FUIBDatabase.Free;
  except
    Writeln('* Error (103)');
  end;
end;

procedure TUsernameService.Logoff;
var
  FUIBDatabase: TUIBDatabase;
  FUIBTransaction: TUIBTransaction;
  FUIBQuery: TUIBQuery;
  FSrvParam: TSrvParam;
  FUserInfo: TUserInfo;
begin
  FSrvParam := GetSrvParam;
  try
    FUIBDatabase := TUIBDatabase.Create(nil);
    FUIBDatabase.LibraryName := LIB_FILE;
    FUIBDatabase.DatabaseName := FSrvParam.Server + ':' + FSrvParam.Database;
    FUIBDatabase.UserName := FSrvParam.Username;
    FUIBDatabase.PassWord := FSrvParam.Password;
    FUIBQuery := TUIBQuery.Create(nil);
    FUIBTransaction := TUIBTransaction.Create(nil);
    FUIBTransaction.DataBase := FUIBDatabase;
    FUIBQuery.Transaction := FUIBTransaction;
    FUIBQuery.SQL.Add('UPDATE OR INSERT INTO SESSIONS (USERNAME,COMPNAME,FULLNAME,FIRSTNAME,LASTNAME,DISPNAME,TELEPHONE,LOCATION,EMAIL,LOGOFF,ONLINE) VALUES (:username,:compname,:fullname,:firstname,:lastname,:dispname,:telephone,:location,:email,:logoff,:online)');
    FUIBQuery.Prepare;
    FUserInfo := Self.GetUserInfo;
    FUIBQuery.Params.ByNameAsString['username'] := FUserInfo.Username;
    FUIBQuery.Params.ByNameAsString['compname'] := FUserInfo.Compname;
    FUIBQuery.Params.ByNameAsString['fullname'] := FUserInfo.Fullname;
    FUIBQuery.Params.ByNameAsString['firstname'] := FUserInfo.Firstname;
    FUIBQuery.Params.ByNameAsString['lastname'] := FUserInfo.Lastname;
    FUIBQuery.Params.ByNameAsString['dispname'] := FUserInfo.Dispname;
    FUIBQuery.Params.ByNameAsString['telephone'] := FUserInfo.Telephone;
    FUIBQuery.Params.ByNameAsString['location'] := FUserInfo.Location;
    FUIBQuery.Params.ByNameAsString['email'] := FUserInfo.Email;
    FUIBQuery.Params.ByNameAsString['logoff'] := FUserInfo.Logoff;
    FUIBQuery.Params.ByNameAsSmallint['online'] := 0;
    FUIBQuery.ExecSQL;
    FUIBTransaction.Free;
    FUIBQuery.Free;
    FUIBDatabase.Free;
  except
    Writeln('* Error (104)');
  end;
end;

procedure TUsernameService.Debug;
var
  FUserInfo: TUserInfo;
begin
  try
    FUserInfo := Self.GetUserInfo;
    Writeln(Format('> Username: %s', [FUserInfo.Username]));
    Writeln(Format('> Compname: %s', [FUserInfo.Compname]));
    Writeln(Format('> Fullname: %s', [FUserInfo.Fullname]));
    Writeln(Format('> Firstname: %s', [FUserInfo.Firstname]));
    Writeln(Format('> Lastname: %s', [FUserInfo.Lastname]));
    Writeln(Format('> Dispname: %s', [FUserInfo.Dispname]));
    Writeln(Format('> Telephone: %s', [FUserInfo.Telephone]));
    Writeln(Format('> Location: %s', [FUserInfo.Location]));
    Writeln(Format('> E-mail: %s', [FUserInfo.Email]));
  except
  end;
end;

var
  ARGV: string;
  FUService: TUsernameService;

begin
  ARGV := UpperCase(ParamStr(1));
  FUService := TUsernameService.Create;
  Writeln('Username Service [Version 0.3]');
  Writeln('(c) Renaissance Insurance, 2011');
  Writeln;
  if ARGV = 'ON' then
  begin
    Writeln('* Logon...');
    // Non-Citrix
    if Pos('REN-MSKCT', UpperCase(FUService.GetCompName)) <= 0 then
    FUService.Logon;
  end
  else if ARGV = 'OFF' then
  begin
    Writeln('* Logoff...');
    // Non-Citrix
    if Pos('REN-MSKCT', UpperCase(FUService.GetCompName)) <= 0 then    
    FUService.Logoff;
  end
  else if ARGV = 'PRINT' then
  begin
    Writeln('* Print...');
    Writeln;
    FUService.Debug;
  end
  else
  begin
    Writeln(' USAGE: uservice.exe [ON|OFF|PRINT]');
    Writeln;
    Writeln(' * ON      Logon event');
    Writeln(' * OFF     Logoff event');
    Writeln(' * PRINT   Print userinfo');
  end;
  FUService.Free;
end.
