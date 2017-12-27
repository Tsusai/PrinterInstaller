program PrinterInstaller;

{$R *.dres}

uses
  Vcl.Forms,
  Main in 'Main.pas' {MainApp};

{$R *.res}

begin
	Application.Initialize;
	Application.MainFormOnTaskbar := True;
	Application.Title := 'CBJSR Printer Installer';
	Application.CreateForm(TMainApp, MainApp);
  Application.Run;
end.
