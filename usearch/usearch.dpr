program usearch;

uses
  Forms,
  main in 'main.pas' {frmUSearch},
  info in 'info.pas' {frmInfo};

{$R *.res}

begin
  Application.Initialize;
  Application.Title := 'USearch';
  Application.CreateForm(TfrmUSearch, frmUSearch);
  Application.CreateForm(TfrmInfo, frmInfo);
  Application.Run;
end.
