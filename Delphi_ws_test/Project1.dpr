program Project1;

uses
  Vcl.Forms,
  System.SysUtils,
  MainFormpas in 'MainFormpas.pas',
  AsmTouch in 'AsmTouch.pas',
  MemStats in 'MemStats.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;

  Form1 := TForm1.Create(nil);
  try
    Form1.ShowModal;   // Åö Ç±ÇÍÇæÇØÇ≈ämé¿Ç…ï\é¶Ç≥ÇÍÇÈ
  finally
    Form1.Free;
  end;
end.

