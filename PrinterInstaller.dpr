(*
2019-2020 "Tsusai": Printer Installer: Uses windows scripts to deploy multiple printers.
*)
program PrinterInstaller;

{$R *.dres}

uses
  Vcl.Forms,
  Main in 'Main.pas' {MainApp};

{$R *.res}

begin
	Application.Initialize;
	Application.MainFormOnTaskbar := True;
	Application.Title := 'Printer Installer';
	Application.CreateForm(TMainApp, MainApp);
  Application.Run;
end.
