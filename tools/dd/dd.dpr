library dd;
{$IF CompilerVersion >= 21.0}
{$WEAKLINKRTTI ON}
{$RTTI EXPLICIT METHODS([]) PROPERTIES([]) FIELDS([])}
{$IFEND}

uses
  Vcl.Forms,
  uData in 'uData.pas' {frmDataDll},
  uCommon in 'uCommon.pas';

{$R *.res}

function GetDataFormDLL: TFormClass; stdcall;
begin
  Result := TfrmDataDll;
end;

exports GetDataFormDLL;

begin

end.
