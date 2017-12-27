unit Main;

interface

uses
	Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
	Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.CheckLst, Vcl.ComCtrls;

type
	TMainApp = class(TForm)
		PrinterCheckBox: TCheckListBox;
		DefaultBox: TListBox;
		InstallBtn: TButton;
		PrintersLbl: TLabel;
		DefaultLbl: TLabel;
		PresetsLbl: TLabel;
		PresetsBox: TListBox;
		procedure FormCreate(Sender: TObject);
		procedure FormDestroy(Sender: TObject);
		procedure InstallBtnClick(Sender: TObject);
		procedure PrinterCheckBoxClickCheck(Sender: TObject);
		procedure PresetsBoxClick(Sender: TObject);
	private
		{ Private declarations }
	public
		{ Public declarations }
	end;

var
	MainApp: TMainApp;

implementation
{$R *.dfm}
uses
	ShellAPI,
	System.IOUtils,
	IniFiles;

procedure RunAndWait(
	hWnd: HWND;
	filename: string;
	Parameters: string;
	AsAdmin : boolean=false
);
{
		See Step 3: Redesign for UAC Compatibility (UAC)
		http://msdn.microsoft.com/en-us/library/bb756922.aspx
}
var
		sei: TShellExecuteInfo;
		ExitCode: DWORD;
begin
	ZeroMemory(@sei, SizeOf(sei));
	sei.cbSize := SizeOf(TShellExecuteInfo);
	sei.Wnd := hwnd;
	sei.fMask := SEE_MASK_FLAG_DDEWAIT or SEE_MASK_FLAG_NO_UI or SEE_MASK_NOCLOSEPROCESS;
	if AsAdmin then sei.lpVerb := PChar('runas');
	sei.lpFile := PChar(Filename); // PAnsiChar;
	if parameters <> '' then
	sei.lpParameters := PChar(parameters); // PAnsiChar;
	sei.nShow := SW_SHOWNORMAL; //Integer;
	if ShellExecuteEx(@sei) then
	begin
		repeat
			Application.ProcessMessages;
			GetExitCodeProcess(sei.hProcess, ExitCode) ;
		until (ExitCode <> STILL_ACTIVE) or  Application.Terminated;
	end;
end;

var
	PrinterDir : string;// = '\\hal\Users\Sharenapps\IT\Drivers\Printers';
	DriverTMP : string;// = 'C:\PDRIVERS';

type
	TPrinter = class(TObject)
		Name : string;
		IP : string;
		DrvN : string;
		DrvD : string;
		InfF :string;
	end;
	TPreset = class(TObject)
		Printers : array of byte;
	end;


procedure TMainApp.InstallBtnClick(Sender: TObject);
var
	i : integer;
	CMD : string;
	APrinter : TPrinter;
begin
	for i := 0 to PrinterCheckBox.Count-1 do
	begin
		if TDirectory.Exists(DriverTMP) then TDirectory.Delete(DriverTMP, true);
		if PrinterCheckBox.Checked[i] then
		begin
			APrinter := PrinterCheckBox.Items.Objects[i] as TPrinter;
			if CreateDir(DriverTMP) then
			begin
				CMD := Format('"%s\%s" %s/I /y /D /E',[PrinterDir,APrinter.DrvD,DriverTMP]);
				RunAndWait(0,'xcopy',CMD);
				//this is basically a batch file being sent as a string, the ending " & " means new command
				CMD := Format(
					'/c cscript %%WINDIR%%\System32\Printing_Admin_Scripts\en-US\Prnmngr.vbs -d -p "%s" & '+
					'cscript %%WINDIR%%\System32\Printing_Admin_Scripts\en-US\Prnport.vbs -a -r IP_%s -h %s -o raw -n 9100 -me -i 1 -y public & '+
					'cscript %%WINDIR%%\System32\Printing_Admin_Scripts\en-US\Prndrvr.vbs -a -m "%s" -v 3 -e "Windows x64" -i %s\%s -h %s & '+
					'cscript %%WINDIR%%\System32\Printing_Admin_Scripts\en-US\Prnmngr.vbs -a -p "%s" -m "%s" -r IP_%s',
					[
						APrinter.Name,
						APrinter.IP,APrinter.IP,
						APrinter.DrvN,DriverTMP,APrinter.InfF,DriverTMP,
						APrinter.Name,APrinter.DrvN,APrinter.IP
					]
				);
				RunAndWait(0,'cmd.exe',CMD,true);
				if TDirectory.Exists(DriverTMP) then TDirectory.Delete(DriverTMP, true);
			end else ShowMessage('Failed to create temp folder.');
		end;
	end;

	CMD:= Format(
		'/c cscript %%WINDIR%%\System32\Printing_Admin_Scripts\en-US\Prnmngr.vbs -p "%s" -t',
		[Defaultbox.Items.Strings[Defaultbox.ItemIndex]]
	);
	RunAndWait(0,'cmd.exe',CMD,true);

	if TDirectory.Exists(DriverTMP) then TDirectory.Delete(DriverTMP, true);
	ShowMessage('Done');
end;

procedure TMainApp.PrinterCheckBoxClickCheck(Sender: TObject);
var
	i : integer;
begin
	Defaultbox.Clear;
	for i := 0 to PrinterCheckBox.Count-1 do
	begin
		if PrinterCheckBox.Checked[i] then
		begin
			Defaultbox.Items.Add(TPrinter(PrinterCheckBox.Items.Objects[i]).Name);
		end;
	end;
	if Defaultbox.Count>0 then Defaultbox.ItemIndex:=0;

end;

procedure TMainApp.FormCreate(Sender: TObject);
var
	Ini : TMemIniFile;
	Sections : TStringlist;
	PresetPrinters : TStringList;
	sidx, pidx, iidx : integer;
	APrinter : TPrinter;
	APreset : TPreset;
begin
	Left:=(Screen.Width-Width)  div 2;
	Top:=(Screen.Height-Height) div 2;
	Ini := TMemIniFile.Create('Printers.ini');
	Sections := TStringlist.Create;
	Ini.ReadSections(Sections);
	if Sections.Count > 0 then
	begin
		for sidx := 0 to Sections.Count-1 do
		begin
			if Sections[sidx] = 'Settings' then
			begin
				PrinterDir := Ini.ReadString('Settings','RootFolder',ExtractFilePath(ParamStr(0)));
				DriverTMP := Ini.ReadString('Settings','TempFolder','C:\PDRIVERS');
			end else
			begin
				APrinter := TPrinter.Create;
				APrinter.Name :=Ini.ReadString(Sections[sidx],'Name','');
				APrinter.IP   :=Ini.ReadString(Sections[sidx],'IP','');
				APrinter.DrvN :=Ini.ReadString(Sections[sidx],'DriverName','');
				APrinter.DrvD :=Ini.ReadString(Sections[sidx],'DriverDir','');
				APrinter.InfF :=Ini.ReadString(Sections[sidx],'INF','oemsetup.inf');
				PrinterCheckBox.Items.AddObject(Sections[sidx],APrinter);
			end;
		end;
	end;
	Ini.Free;
	Sections.Free;

	//Presets!
	Ini := TMemIniFile.Create('Presets.ini');
	Sections := TStringlist.Create;
	Ini.ReadSections(Sections);
	PresetPrinters := TStringList.Create;
	if Sections.Count > 0 then
	begin
		for sidx := 0 to Sections.Count-1 do
		begin
			PresetPrinters.Clear;
			PresetPrinters.CommaText := Ini.ReadString(Sections[sidx],'Printers','');
			if PresetPrinters.CommaText = '' then continue;
			APreset := TPreset.Create;
			for pidx := 0 to PresetPrinters.Count-1 do
			begin;
				iidx := PrinterCheckBox.Items.IndexOf(PresetPrinters[pidx]);
				if iidx = -1 then continue else
				begin
					SetLength(APreset.Printers,Length(APreset.Printers)+1);
					APreset.Printers[High(APreset.Printers)] := iidx;
				end;
			end;
			PresetsBox.AddItem(Sections[sidx],APreset);
		end;
	end;
	Ini.Free;
	PresetPrinters.Free;
	Sections.Free;

end;

procedure TMainApp.FormDestroy(Sender: TObject);
var
	i : integer;
begin
	for i := PrinterCheckBox.Items.Count-1 downto 0 do PrinterCheckBox.Items.Objects[i].Free;
	for i := PresetsBox.Items.Count-1 downto 0 do PresetsBox.Items.Objects[i].Free;
end;

procedure TMainApp.PresetsBoxClick(Sender: TObject);
var
	idx : integer;
	APreset : TPreset;
begin
	if PresetsBox.ItemIndex = -1 then exit;
	APreset := TPreset(PresetsBox.Items.Objects[PresetsBox.ItemIndex]);
	for idx := PrinterCheckBox.Count-1 downto 0 do PrinterCheckBox.Checked[idx] := false;

	for idx := Low(APreset.Printers) to High(APreset.Printers) do
		PrinterCheckBox.Checked[APreset.Printers[idx]] := true;

	PrinterCheckBox.OnClickCheck(Sender);


end;

end.
