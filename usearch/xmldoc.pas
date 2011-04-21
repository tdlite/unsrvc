unit xmldoc;

interface

uses SysUtils, MSXML2_TLB;

type
  TXMLDoc = class(TObject)
    private
      FXMLFile: string;
      FXMLDoc: DOMDocument;
      FRoot: IXMLDOMElement;
      function FIsExist(AName: string): boolean;
    public
      constructor Create(AFilename: string);
      destructor Destroy; override;
      function ReadString(ASection, AName, ADefault: string): string;
      function ReadInteger(ASection, AName: string; ADefault: integer): integer;
      function ReadItem(ASection, AName: string; AIndex, ADefault: integer): integer;
      procedure WriteString(ASection, AName, AValue: string);
      procedure WriteInteger(ASection, AName: string; AValue: integer);
      procedure WriteItem(ASection, AName: string; AIndex, AValue: integer);
      function GetItems(ASection, AName: string): IXMLDOMNodeList;
  end;

const
  XML_ROOT = '<?xml version="1.0" encoding="utf-8"?><configuration></configuration>';

implementation

{ TXMLDoc }

constructor TXMLDoc.Create(AFilename: string);
begin
  FXMLFile := AFilename;
  FXMLDoc := CoDOMDocument.Create;
  if FileExists(FXMLFile) then
  begin
    FXMLDoc.Load(FXMLFile);
    if FXMLDoc.ParseError.ErrorCode <> 0 then
    FXMLDoc.LoadXML(XML_ROOT);
  end
  else
  FXMLDoc.LoadXML(XML_ROOT);
  FRoot := FXMLDoc.DocumentElement;
end;

destructor TXMLDoc.Destroy;
begin
  FXMLDoc.Save(FXMLFile);
  FRoot := nil;
  FXMLDoc := nil;
  inherited Destroy;
end;

function TXMLDoc.FIsExist(AName: string): boolean;
begin
  if FRoot.GetElementsByTagName(AName).Length > 0 then
  Result := True else Result := False;
end;

function TXMLDoc.ReadString(ASection, AName, ADefault: string): string;
begin
  if FIsExist(ASection + '/' + AName) then
  Result := FRoot.SelectSingleNode(ASection + '/' + AName).Text
  else Result := ADefault;
end;

function TXMLDoc.ReadInteger(ASection, AName: string; ADefault: integer): integer;
begin
  if FIsExist(ASection + '/' + AName) then
  try
    Result := StrToInt(FRoot.SelectSingleNode(ASection + '/' + AName).Text);
  except
    Result := ADefault;
  end
  else Result := ADefault;
end;

function TXMLDoc.ReadItem(ASection, AName: string; AIndex,
  ADefault: integer): integer;
var
  FXPath: string;
begin
  FXPath := ASection + '/' + AName + '[@index="' + IntToStr(AIndex) + '"]';
  if FIsExist(FXPath) then
  try
    Result := StrToInt(FRoot.SelectSingleNode(FXPath).Text);
  except
    Result := ADefault;
  end
  else Result := ADefault;
end;

procedure TXMLDoc.WriteString(ASection, AName, AValue: string);
var
  FNode: IXMLDOMNode;
begin
  if not FIsExist(ASection) then
  FRoot.AppendChild(FXMLDoc.CreateElement(ASection));
  if not FIsExist(ASection + '/' + AName) then
  begin
    FNode := FXMLDoc.CreateElement(AName);
    FRoot.SelectSingleNode(ASection).AppendChild(FNode);
  end;
  FRoot.SelectSingleNode(ASection + '/' + AName).Text := AValue;
end;

procedure TXMLDoc.WriteInteger(ASection, AName: string; AValue: integer);
var
  FNode: IXMLDOMNode;
begin
  if not FIsExist(ASection) then
  FRoot.AppendChild(FXMLDoc.CreateElement(ASection));
  if not FIsExist(ASection + '/' + AName) then
  begin
    FNode := FXMLDoc.CreateElement(AName);
    FRoot.SelectSingleNode(ASection).AppendChild(FNode);
  end;
  FRoot.SelectSingleNode(ASection + '/' + AName).Text := IntToStr(AValue);
end;

procedure TXMLDoc.WriteItem(ASection, AName: string; AIndex, AValue: integer);
var
  FXPath: string;
  FNode: IXMLDOMNode;
  FAttribute: IXMLDOMAttribute;
begin
  FXPath := ASection + '/' + AName + '[@index="' + IntToStr(AIndex) + '"]';
  if not FIsExist(ASection) then
  FRoot.AppendChild(FXMLDoc.CreateElement(ASection));
  if not FIsExist(FXPath) then
  begin
    FNode := FXMLDoc.CreateElement(AName);
    FRoot.SelectSingleNode(ASection).AppendChild(FNode);
    FAttribute := FXMLDoc.CreateAttribute('index');
    FAttribute.Value := IntToStr(AIndex);
    FNode.Attributes.SetNamedItem(FAttribute);
  end;
  FRoot.SelectSingleNode(FXPath).Text := IntToStr(AValue);
end;

function TXMLDoc.GetItems(ASection, AName: string): IXMLDOMNodeList;
begin
  if FIsExist(ASection + '/' + AName) then
  Result := FRoot.SelectSingleNode(ASection).SelectNodes(AName)
  else Result := nil;
end;

end.
