; Inno Setup script: packages the Flutter Windows release bundle as a single
; installer .exe.
;
; The version, source bundle and output directory are passed on the command
; line so the CI can drive it:
;   ISCC.exe /DAppVersion=v1.2.3 /DSourceDir=... /DOutDir=... EFH.iss

#ifndef AppVersion
  #define AppVersion "v0.0.0"
#endif
#ifndef SourceDir
  #define SourceDir "..\..\build\windows\x64\runner\Release"
#endif
#ifndef OutDir
  #define OutDir "..\.."
#endif

[Setup]
AppId={{7E2C1A54-9B3D-4E6F-8A21-5C4D3B2A1908}
AppName=EFH Website Blocking Detection
AppVersion={#AppVersion}
AppPublisher=NickJi2019
AppPublisherURL=https://github.com/NickJi2019/EFH
DefaultDirName={autopf}\EFH Website Blocking Detection
DefaultGroupName=EFH Website Blocking Detection
DisableProgramGroupPage=yes
Compression=lzma2
SolidCompression=yes
WizardStyle=modern
OutputDir={#OutDir}
OutputBaseFilename=EFH-{#AppVersion}-windows-setup
SetupIconFile=..\..\windows\runner\resources\app_icon.ico
UninstallDisplayIcon={app}\efh_connectivity_test.exe
ArchitecturesAllowed=x64
ArchitecturesInstallIn64BitMode=x64

[Files]
Source: "{#SourceDir}\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked

[Icons]
Name: "{group}\EFH Website Blocking Detection"; Filename: "{app}\efh_connectivity_test.exe"
Name: "{autodesktop}\EFH Website Blocking Detection"; Filename: "{app}\efh_connectivity_test.exe"; Tasks: desktopicon

[Run]
Filename: "{app}\efh_connectivity_test.exe"; Description: "{cm:LaunchProgram,EFH Website Blocking Detection}"; Flags: nowait postinstall skipifsilent
