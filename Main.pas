unit Main;

interface

uses
	Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
	Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.CheckLst, Vcl.ComCtrls,
  Vcl.ExtCtrls;

type
	TMainApp = class(TForm)
		PrinterCheckBox: TCheckListBox;
		DefaultBox: TListBox;
		InstallBtn: TButton;
		PrintersLbl: TLabel;
		DefaultLbl: TLabel;
		PresetsLbl: TLabel;
		PresetsBox: TListBox;
		DuplexRadio: TRadioGroup;
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
	if AsAdmin then sei.lpVerb := PChar('runas'); //Triggers UAC Elevation
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
	PrinterDir : string;// = '\\server\path\path\path\Printers';
	DriverTMP : string;// = 'C:\PDRIVERS';
	PausePhase : boolean;
	TestMode : boolean;

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

//Application Startup
procedure TMainApp.FormCreate(Sender: TObject);
var
	Ini : TMemIniFile;
	Sections : TStringlist;
	PresetPrinters : TStringList;
	sidx, pidx, iidx : integer;
	APrinter : TPrinter;
	APreset : TPreset;
begin
	//Set to the center of the screen on startup
	Left:=(Screen.Width-Width)  div 2;
	Top:=(Screen.Height-Height) div 2;

	(*Load Settings
	[Settings]
	RootFolder=\\server\path\path\path\Printers
	TempFolder=C:\PDRIVERS
	Pause=True
	TestMode=False
	*)
	Ini := TMemIniFile.Create('Settings.ini');
	PrinterDir := Ini.ReadString('Settings','RootFolder',ExtractFilePath(ParamStr(0)));
	DriverTMP := Ini.ReadString('Settings','TempFolder','C:\PDRIVERS');
	PausePhase := Ini.ReadBool('Settings','Pause',true);
	TestMode := Ini.ReadBool('Settings','TestMode',false);
	Ini.Free;

	(*Load Printers
	[Boss Workroom]                                  (Name of the Printer in the GUI)
	Name=Workroom (Color)                            (Installed Name of the Printer)
	IP=192.168.1.16                                  (IP Address of Printer)
	DriverName=Kyocera Classic Universaldriver PCL6  (Driver Name in INI File)
	DriverDir=Kx630909_UPD_en\64bit\XP and newer     (Path to Driver)
	INF=OEMSETUP.INF                                 (Optional, already assumes OEMSETUP.INF)
	*)
	Ini := TMemIniFile.Create('Printers.ini');
	Sections := TStringlist.Create;
	Ini.ReadSections(Sections);
	if Sections.Count > 0 then
	begin
		//Loop through INI Sections
		for sidx := 0 to Sections.Count-1 do
		begin
		//Grab Printer Info, Store in TObject to store into CheckListBox
		//Box "owns" object, freed on Application Destruction
			APrinter := TPrinter.Create;
			APrinter.Name :=Ini.ReadString(Sections[sidx],'Name','');
			APrinter.IP   :=Ini.ReadString(Sections[sidx],'IP','');
			APrinter.DrvN :=Ini.ReadString(Sections[sidx],'DriverName','');
			APrinter.DrvD :=Ini.ReadString(Sections[sidx],'DriverDir','');
			APrinter.InfF :=Ini.ReadString(Sections[sidx],'INF','oemsetup.inf');
			PrinterCheckBox.Items.AddObject(Sections[sidx],APrinter);
		end;
	end;
	//Free Data
	Ini.Free;
	Sections.Free;

	(*Load Presets!
	[Group Name ]                              (Name of the Group/Preset)
	Printers="Printer A","Printer B"           (Use the names of [Printers] from Printers.ini)
	*)
	Ini := TMemIniFile.Create('Presets.ini');
	Sections := TStringlist.Create;
	Ini.ReadSections(Sections);
	PresetPrinters := TStringList.Create;
	if Sections.Count > 0 then
	begin
		for sidx := 0 to Sections.Count-1 do
		begin
			PresetPrinters.Clear;
			//Loading the Printerlist into a TStringList
			PresetPrinters.CommaText := Ini.ReadString(Sections[sidx],'Printers','');
			if PresetPrinters.CommaText = '' then continue;
			APreset := TPreset.Create;
			for pidx := 0 to PresetPrinters.Count-1 do
			begin;
				//Matching Preset Printer list to Actual Printers
				iidx := PrinterCheckBox.Items.IndexOf(PresetPrinters[pidx]);
				if iidx = -1 then continue else
				begin
					//Got one, expand array and store the printer index number
					SetLength(APreset.Printers,Length(APreset.Printers)+1);
					APreset.Printers[High(APreset.Printers)] := iidx;
				end;
			end;
			PresetsBox.AddItem(Sections[sidx],APreset);
		end;
	end;
	//Free Data
	Ini.Free;
	PresetPrinters.Free;
	Sections.Free;
end;

//Application Shutdown
procedure TMainApp.FormDestroy(Sender: TObject);
var
	ini : TMemIniFile;
	idx : integer;
begin
	Ini := TMemIniFile.Create('Settings.ini');
	Ini.WriteString('Settings','RootFolder',PrinterDir);
	Ini.WriteString('Settings','TempFolder',DriverTMP);
	Ini.WriteBool('Settings','Pause',PausePhase);
	Ini.WriteBool('Settings','TestMode',TestMode);
	Ini.UpdateFile;
	Ini.Free;

	for idx := PrinterCheckBox.Items.Count-1 downto 0 do PrinterCheckBox.Items.Objects[idx].Free;
	for idx := PresetsBox.Items.Count-1 downto 0 do PresetsBox.Items.Objects[idx].Free;
end;

//Preset Logic.
procedure TMainApp.PresetsBoxClick(Sender: TObject);
var
	idx : integer;
	APreset : TPreset;
begin
	if PresetsBox.ItemIndex = -1 then exit;
	//Grab our Preset Object with all our indexes
	APreset := TPreset(PresetsBox.Items.Objects[PresetsBox.ItemIndex]);
	//Clear Checks
	for idx := PrinterCheckBox.Count-1 downto 0 do PrinterCheckBox.Checked[idx] := false;
	//Run through Printer Index array and Check Printer
	for idx := Low(APreset.Printers) to High(APreset.Printers) do
		PrinterCheckBox.Checked[APreset.Printers[idx]] := true;
	//Refresh Defaults Box as if we manually did a checkbox click
	PrinterCheckBox.OnClickCheck(Sender);
end;

//Load current selection of Printers into Default Printers column
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

//Main Execution
procedure TMainApp.InstallBtnClick(Sender: TObject);
var
	pidx : integer;
	CMD : string;
	APrinter : TPrinter;
	Phase1, Phase2, Phase3 : TStringList;
	TestDump : TStringList;
	AFolder : string;
begin
	InstallBtn.Enabled := false;
	Phase1 := TStringList.Create;
	Phase2 := TStringList.Create;
	Phase3 := TStringList.Create;
	TestDump := TStringList.Create;
	try
		TestDump.Clear;

		Phase1.Clear;
		Phase2.Clear;
		Phase3.Clear;

		//Phase 1, Copy files, remove old printer userlevel
		//Phase 2, remove printer admin level, install driver admin level
		//Phase 3, userlevel cleanup and tweaks
		for pidx := 0 to PrinterCheckBox.Count-1 do
		begin
			AFolder := DriverTMP+'\'+IntToStr(pidx)+'\';
			if TDirectory.Exists(AFolder) then TDirectory.Delete(AFolder, true);
			if PrinterCheckBox.Checked[pidx] then
			begin
				APrinter := PrinterCheckBox.Items.Objects[pidx] as TPrinter;
				TDirectory.CreateDirectory(AFolder);
				//Copy Files User Level
				Phase1.Add(
					Format('xcopy "%s\%s" %s /I /y /D /E',[PrinterDir,APrinter.DrvD,AFolder])
				);
				//Remove Printer User Level
				Phase1.Add(
					Format('cscript %%WINDIR%%\System32\Printing_Admin_Scripts\en-US\Prnmngr.vbs -d -p "%s"',[APrinter.Name])
				);
				//Add Printer Port
				Phase1.Add(
					Format('cscript %%WINDIR%%\System32\Printing_Admin_Scripts\en-US\Prnport.vbs -a -r IP_%s -h %s -o raw -n 9100 -me -i 1 -y public',[APrinter.IP,APrinter.IP])
				);
				//Remove Printer Admin Level
				Phase2.Add(
					Format('cscript %%WINDIR%%\System32\Printing_Admin_Scripts\en-US\Prnmngr.vbs -d -p "%s"',[APrinter.Name])
				);
				//Add Printer Driver Admin Level
				Phase2.Add(
					Format('cscript %%WINDIR%%\System32\Printing_Admin_Scripts\en-US\Prndrvr.vbs -a -m "%s" -v 3 -e "Windows x64" -i %s\%s -h %s',[APrinter.DrvN,AFolder,APrinter.InfF,AFolder])
				);
				//Add Printer User Level
				Phase3.Add(
					Format('cscript %%WINDIR%%\System32\Printing_Admin_Scripts\en-US\Prnmngr.vbs -a -p "%s" -m "%s" -r IP_%s',[APrinter.Name,APrinter.DrvN,APrinter.IP])
				);
			end;
		end;

		if Phase1.Count > 0 then
		begin
			//Prepare CMD string to run Phase 1
			CMD := '/c ';
			for pidx := 0 to Phase1.Count-1 do
			begin
				CMD := CMD + Phase1.Strings[pidx];
				if pidx <> (Phase1.Count-1) then CMD := CMD + ' & ';
			end;
			if PausePhase then CMD := CMD+ ' & pause';
			if Not TestMode then RunAndWait(Self.Handle,'cmd',CMD) else TestDump.Add('Phase 1: ' + CMD);
			//End of Phase1

			//Phase 2
			//Clear all Print Jobs, add to top of list
			Phase2.Insert(0,'cscript %WINDIR%\System32\Printing_Admin_Scripts\en-US\prnqctl.vbs -x');
			CMD := '/c ';
			for pidx := 0 to Phase2.Count-1 do
			begin
				CMD := CMD + Phase2.Strings[pidx];
				if pidx <> (Phase2.Count-1) then CMD := CMD + ' & ';
			end;
			if PausePhase then CMD := CMD+ ' & pause';
			if Not TestMode then RunAndWait(Self.Handle,'cmd',CMD) else TestDump.Add('Phase 2: ' + CMD);
			//End of Phase 2

			//Phase 3
			CMD := '/c ';
			for pidx := 0 to Phase3.Count-1 do
			begin
				CMD := CMD + Phase3.Strings[pidx];
				if pidx <> (Phase3.Count-1) then CMD := CMD + ' & ';
			end;
			//Disable Duplex?
			if FileExists(GetCurrentDir+'\Tools\setprinter.exe') then
			begin
				case DuplexRadio.ItemIndex of
				0: CMD := CMD + ' & ' + GetCurrentDir+'\Tools\setprinter.exe "" 8 "pDevMode=dmDuplex=1"'; //8 = All Users
				1: CMD := CMD + ' & ' + GetCurrentDir+'\Tools\setprinter.exe "" 2 "pDevMode=dmDuplex=1"'; //2 = Current User
				end;
			end;
			//Set Default Printer
			if Defaultbox.ItemIndex <> -1 then
			begin
				CMD := CMD + ' & ' +
					Format(
						'cscript %%WINDIR%%\System32\Printing_Admin_Scripts\en-US\Prnmngr.vbs -p "%s" -t',
						[Defaultbox.Items.Strings[Defaultbox.ItemIndex]]
					);
			end;
			if PausePhase then CMD := CMD+ ' & pause';
			if Not TestMode then RunAndWait(Self.Handle,'cmd',CMD) else TestDump.Add('Phase 3: ' + CMD);
			//End of Phase 3

			if TestMode then TestDump.SaveToFile('Test Mode Dump.txt');
			if Assigned(TestDump) then TestDump.Free;
		end;
	finally
		if TDirectory.Exists(DriverTMP) then TDirectory.Delete(DriverTMP, true);
		ShowMessage('Done');
		Phase1.Free;
		Phase2.Free;
		Phase3.Free;
		InstallBtn.Enabled := true;
	end;
end;

end.
