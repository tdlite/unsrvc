unit info;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, Buttons;

type
  TfrmInfo = class(TForm)
    txtInfo: TMemo;
    btnClose: TBitBtn;
    procedure btnCloseClick(Sender: TObject);
  private
  public
  end;

var
  frmInfo: TfrmInfo;

implementation

{$R *.dfm}

procedure TfrmInfo.btnCloseClick(Sender: TObject);
begin
  Self.ModalResult := mrOk;
end;

end.
