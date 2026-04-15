; ================================================================
; ITM Agent System Setup Script (DotNet472)
; ================================================================

[Setup]
AppName=ITM Agent System
AppVersion=0.1.2.1
AppPublisher=DevelopTeam
DefaultDirName=D:\CMP_DX\ITM Agent
DefaultGroupName=ITM Agent
OutputDir=.\Output
OutputBaseFilename=ITM_Agent_Setup_v0.1.2.1_Net472
PrivilegesRequired=admin

; -------------------------------
; Version Information (Installer EXE)
; -------------------------------
VersionInfoVersion=0.1.2.1
VersionInfoProductVersion=0.1.2.1
VersionInfoCompany=DevelopTeam
VersionInfoProductName=ITM Agent System
VersionInfoDescription=ITM Agent System Installer (Full .NET Included)
VersionInfoCopyright=Copyright © 2026 Dev@samsung.com
VersionInfoOriginalFileName=ITM_Agent_Setup_v0.1.2.1_Net472.exe

; -------------------------------
; Icons / Images
; -------------------------------
SetupIconFile=F:\Workspaces\CSharp\ITM_Agent_v2\ITM_Agent\bin\Release\Resources\Icons\icon.ico
WizardImageFile=F:\Workspaces\CSharp\ITM_Agent_v2\ITM_Agent\bin\Release\Resources\Icons\icon.png
WizardSmallImageFile=F:\Workspaces\CSharp\ITM_Agent_v2\ITM_Agent\bin\Release\Resources\Icons\icon.png
UninstallDisplayIcon={app}\ITM_Agent.exe

; ================================================================
; 데이터 폴더 구조
; ================================================================
[Dirs]
Name: "D:\ITM_Agent"; Permissions: users-modify
Name: "D:\ITM_Agent\Baseline"; Permissions: users-modify
Name: "D:\ITM_Agent\die"; Permissions: users-modify
Name: "D:\ITM_Agent\die_graph"; Permissions: users-modify
Name: "D:\ITM_Agent\die_img"; Permissions: users-modify
Name: "D:\ITM_Agent\Log"; Permissions: users-modify
Name: "D:\ITM_Agent\pdf"; Permissions: users-modify
Name: "D:\ITM_Agent\wf"; Permissions: users-modify

Name: "D:\ITM_Agent\Log\error"; Permissions: users-modify
Name: "D:\ITM_Agent\Log\event"; Permissions: users-modify
Name: "D:\ITM_Agent\Log\prealign"; Permissions: users-modify
Name: "D:\ITM_Agent\Log\secs"; Permissions: users-modify

; ================================================================
; 파일 복사
; ================================================================
[Files]
; .NET 4.7.2 오프라인 설치 파일
Source: "Prerequisite\NDP472-KB4054530-x86-x64-AllOS-ENU.exe"; \
  DestDir: "{tmp}"; Flags: deleteafterinstall

; Agent 본체 (Library 제외)
Source: "F:\Workspaces\CSharp\ITM_Agent_v2\ITM_Agent\bin\Release\*"; \
  DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs; \
  Excludes: "Settings.ini,Connection.ini,Library\*"

; 설정 파일
Source: "F:\Workspaces\CSharp\ITM_Agent_v2\ITM_Agent\bin\Release\Connection.ini"; \
  DestDir: "{app}"; Flags: onlyifdoesntexist

Source: "F:\Workspaces\CSharp\ITM_Agent_v2\ITM_Agent\bin\Release\Settings.ini"; \
  DestDir: "{app}"; Flags: onlyifdoesntexist uninsneveruninstall

; ------------------------------------------------
; 플러그인 DLL 배포
; ------------------------------------------------
Source: "F:\Workspaces\CSharp\ITM_OntoPluginLib_v2\Library\Onto_ErrorDataLib.dll"; \
  DestDir: "{app}\Library"; Flags: ignoreversion

Source: "F:\Workspaces\CSharp\ITM_OntoPluginLib_v2\Library\Onto_PrealignDataLib.dll"; \
  DestDir: "{app}\Library"; Flags: ignoreversion

Source: "F:\Workspaces\CSharp\ITM_OntoPluginLib_v2\Library\Onto_SpectrumDataLib.dll"; \
  DestDir: "{app}\Library"; Flags: ignoreversion

Source: "F:\Workspaces\CSharp\ITM_OntoPluginLib_v2\Library\Onto_WaferFlatDataLib.dll"; \
  DestDir: "{app}\Library"; Flags: ignoreversion

Source: "F:\Workspaces\CSharp\ITM_OntoPluginLib_v2\Library\Onto_WaferMapHttpLib.dll"; \
  DestDir: "{app}\Library"; Flags: ignoreversion

; ================================================================
; 시작 메뉴
; ================================================================
[Icons]
Name: "{group}\ITM Agent"; \
  Filename: "{app}\ITM_Agent.exe"; \
  IconFilename: "{app}\Resources\Icons\icon.ico"

Name: "{group}\Uninstall ITM Agent"; \
  Filename: "{uninstallexe}"

; ================================================================
; 설치 완료 후 실행
; ================================================================
[Run]
Description: "ITM Agent 실행"; Filename: "{app}\ITM_Agent.exe"; Flags: nowait postinstall skipifsilent

; ================================================================
; Pascal Script Code
; ================================================================
[Code]

var
  EqpidPage: TInputQueryWizardPage;
  ArchiveDirPage: TInputDirWizardPage;
  NetworkPage: TWizardPage;
  chkUseProxy: TNewCheckBox;
  lblProxyWarning: TLabel; 
  lblProxyIP: TNewStaticText;
  txtProxyIP: TNewEdit;

function GetDotNetRelease(): Cardinal;
var
  Release: Cardinal;
begin
  if RegQueryDWordValue(
       HKLM,
       'SOFTWARE\Microsoft\NET Framework Setup\NDP\v4\Full',
       'Release',
       Release) then
    Result := Release
  else
    Result := 0;
end;

function FindFinishedLogoImage(): TBitmapImage;
var
  i: Integer;
  C: TComponent;
begin
  Result := nil;
  for i := 0 to WizardForm.ComponentCount - 1 do
  begin
    C := WizardForm.Components[i];
    if (C is TBitmapImage) and (TBitmapImage(C).Parent = WizardForm.FinishedPage) then
    begin
      Result := TBitmapImage(C);
      Exit;
    end;
  end;
end;

procedure ApplyLogoSettings(Img: TBitmapImage);
begin
  if Img = nil then Exit;
  Img.Align := alLeft;
  Img.AutoSize := True;
  Img.Stretch := False;
  Img.Center := True;
  Img.BackColor := clWhite;
end;

procedure chkUseProxyClick(Sender: TObject);
begin
  lblProxyIP.Enabled := chkUseProxy.Checked;
  txtProxyIP.Enabled := chkUseProxy.Checked;
end;

function PrepareToInstall(var NeedsRestart: Boolean): String;
var
  ResultCode: Integer;
begin
  Result := '';
  NeedsRestart := False;

  if GetDotNetRelease() < 461808 then
  begin
    if MsgBox(
      '.NET Framework 4.7.2 이상이 필요합니다.' + #13#10 + #13#10 +
      '지금 설치하시겠습니까?',
      mbConfirmation,
      MB_YESNO
    ) = IDYES then
    begin
      if not Exec(
        ExpandConstant('{tmp}\NDP472-KB4054530-x86-x64-AllOS-ENU.exe'),
        '/passive /norestart',
        '',
        SW_SHOW,
        ewWaitUntilTerminated,
        ResultCode
      ) then
      begin
        Result := '.NET Framework 설치 프로그램 실행에 실패했습니다.';
        Exit;
      end;

      if ResultCode <> 0 then
      begin
        Result := '.NET Framework 설치에 실패했습니다. (ExitCode=' + IntToStr(ResultCode) + ')';
        Exit;
      end;

      if GetDotNetRelease() < 461808 then
      begin
        Result := '.NET Framework 4.7.2 설치가 완료되지 않았습니다. 시스템 재부팅 후 다시 설치를 시도해 주세요.';
        Exit;
      end;
    end
    else
    begin
      Result := '.NET Framework 4.7.2 이상이 필요하여 설치를 중단합니다.';
      Exit;
    end;
  end;
end;

procedure InitializeWizard;
begin
  with WizardForm.WizardSmallBitmapImage do
  begin
    Align := alNone;
    Stretch := True;
    Width := 40;
    Height := 40;
    Left := Parent.Width - Width - 15;
    Top := (Parent.Height - Height) div 2;
  end;

  ApplyLogoSettings(WizardForm.WizardBitmapImage);
  ApplyLogoSettings(FindFinishedLogoImage());

  EqpidPage := CreateInputQueryPage(
    wpSelectDir,
    '장비 ID 설정',
    '설치할 장비의 고유 ID (Eqpid)를 입력하세요.',
    '이 값은 Settings.ini의 [Eqpid] 섹션에 "Eqpid = 값" 형식으로 저장됩니다.'
  );
  EqpidPage.Add('Eqpid:', False);
  EqpidPage.Values[0] := 'TEST001';

  NetworkPage := CreateCustomPage(EqpidPage.ID, '네트워크 연결 설정', '외부망 연결 방식을 선택하세요.');

  chkUseProxy := TNewCheckBox.Create(WizardForm);
  chkUseProxy.Parent := NetworkPage.Surface;
  chkUseProxy.Top := 10;
  chkUseProxy.Left := 0;
  chkUseProxy.Width := NetworkPage.SurfaceWidth;
  chkUseProxy.Caption := '내부망(Main 장비)을 경유하여 연결 (Port Proxy 사용)';
  chkUseProxy.Checked := False; 
  chkUseProxy.OnClick := @chkUseProxyClick;

  lblProxyWarning := TLabel.Create(WizardForm);
  lblProxyWarning.Parent := NetworkPage.Surface;
  lblProxyWarning.Top := chkUseProxy.Top + 25;
  lblProxyWarning.Left := 20;
  lblProxyWarning.Width := NetworkPage.SurfaceWidth - 40;
  lblProxyWarning.Height := 35; 
  lblProxyWarning.AutoSize := False; 
  lblProxyWarning.WordWrap := True;
  lblProxyWarning.Font.Color := clRed;
  lblProxyWarning.Caption := '※ 주의: Main 장비의 내부망을 이용하여 네트워크를 연결해야 하는 환경인 경우, 필히 위 옵션을 체크하고 Main 장비의 IP를 입력해 주십시오.';

  lblProxyIP := TNewStaticText.Create(WizardForm);
  lblProxyIP.Parent := NetworkPage.Surface;
  lblProxyIP.Top := lblProxyWarning.Top + lblProxyWarning.Height + 10; 
  lblProxyIP.Left := 20;
  lblProxyIP.Caption := 'Main 장비 IP 주소 (예: 172.20.60.200):';

  txtProxyIP := TNewEdit.Create(WizardForm);
  txtProxyIP.Parent := NetworkPage.Surface;
  txtProxyIP.Top := lblProxyIP.Top + 20;
  txtProxyIP.Left := 20;
  txtProxyIP.Width := 150;
  txtProxyIP.Text := '172.20.60.200';

  chkUseProxyClick(chkUseProxy);

  ArchiveDirPage := CreateInputDirPage(
    NetworkPage.ID,
    '데이터 아카이브 경로 설정',
    'Onto 장비의 데이터 아카이브 경로를 선택하세요.',
    '이 장비의 데이터는 일반적으로 D:\ 드라이브 하위에 저장되어 있습니다.' + #13#10 + #13#10 +
    '- 보통 D:\Data\Archive 또는 D:\Data\Archieve 폴더로 구성되어 있습니다.' + #13#10 +
    '- 이미 존재하는 기존 폴더를 반드시 선택해 주세요.' + #13#10 +
    '- 새로운 폴더를 생성하거나 다른 경로를 선택하면 정상 동작하지 않을 수 있습니다.',
    False, ''
  );
  ArchiveDirPage.Add('D:\Data\Archive');
end;

procedure CurPageChanged(CurPageID: Integer);
begin
  if CurPageID = wpFinished then
    ApplyLogoSettings(FindFinishedLogoImage());
end;

function NextButtonClick(CurPageID: Integer): Boolean;
begin
  Result := True;

  if CurPageID = EqpidPage.ID then
  begin
    EqpidPage.Values[0] := Uppercase(Trim(EqpidPage.Values[0]));

    if EqpidPage.Values[0] = '' then
    begin
      MsgBox('Eqpid(장비 ID)는 필수 입력 항목입니다.', mbError, MB_OK);
      Result := False;
      Exit;
    end;
  end;

  if CurPageID = NetworkPage.ID then
  begin
    if chkUseProxy.Checked and (Trim(txtProxyIP.Text) = '') then
    begin
      MsgBox('Main 장비를 경유하려면 Main 장비의 IP 주소를 입력해야 합니다.', mbError, MB_OK);
      Result := False;
      Exit;
    end;
  end;

  if (CurPageID = ArchiveDirPage.ID) and (Trim(ArchiveDirPage.Values[0]) = '') then
  begin
    MsgBox(
      '데이터 아카이브 경로는 필수 입력 항목입니다.' + #13#10 +
      'D:\Data\Archive 또는 D:\Data\Archieve 와 같이 이미 존재하는 폴더를 선택해 주세요.',
      mbError, MB_OK
    );
    Result := False;
  end;
end;

procedure CurStepChanged(CurStep: TSetupStep);
var
  SettingsPath: string;
  Lines: TStringList;
  i, SectionIndex: Integer;
begin
  if CurStep = ssPostInstall then
  begin
    SettingsPath := ExpandConstant('{app}\Settings.ini');

    SetIniString('Eqpid', 'Eqpid', EqpidPage.Values[0], SettingsPath);

    if chkUseProxy.Checked then
    begin
      SetIniString('Network', 'UseProxy', '1', SettingsPath);
      SetIniString('Network', 'ProxyIP', Trim(txtProxyIP.Text), SettingsPath);
    end
    else
    begin
      SetIniString('Network', 'UseProxy', '0', SettingsPath);
      SetIniString('Network', 'ProxyIP', '', SettingsPath);
    end;

    Lines := TStringList.Create;
    try
      Lines.LoadFromFile(SettingsPath);

      SectionIndex := -1;
      for i := 0 to Lines.Count - 1 do
        if CompareText(Trim(Lines[i]), '[Eqpid]') = 0 then
        begin
          SectionIndex := i;
          Break;
        end;

      if SectionIndex >= 0 then
        for i := SectionIndex + 1 to Lines.Count - 1 do
        begin
          if (Length(Trim(Lines[i])) > 0) and (Trim(Lines[i])[1] = '[') then Break;
          if Pos('Eqpid', Trim(Lines[i])) = 1 then
          begin
            Lines[i] := 'Eqpid = ' + EqpidPage.Values[0];
            Break;
          end;
        end;

      SectionIndex := -1;
      for i := 0 to Lines.Count - 1 do
        if CompareText(Trim(Lines[i]), '[TargetFolders]') = 0 then
        begin
          SectionIndex := i;
          Break;
        end;

      if SectionIndex >= 0 then
        Lines.Insert(SectionIndex + 1, ArchiveDirPage.Values[0]);

      Lines.SaveToFile(SettingsPath);
    finally
      Lines.Free;
    end;
  end;
end;

function IsProcessRunning(const ProcessName: string): Boolean;
var
  ResultCode: Integer;
begin
  Result :=
    Exec(
      'cmd.exe',
      '/C tasklist | find /I "' + ProcessName + '"',
      '',
      SW_HIDE,
      ewWaitUntilTerminated,
      ResultCode
    ) and (ResultCode = 0);
end;

function InitializeUninstall(): Boolean;
begin
  if IsProcessRunning('ITM_Agent.exe') then
  begin
    MsgBox(
      'ITM Agent가 현재 실행 중입니다.' + #13#10 + #13#10 +
      '프로그램을 종료한 후 다시 언인스톨을 실행해 주세요.',
      mbInformation,
      MB_OK
    );
    Result := False;
  end
  else
    Result := True;
end;

function InitializeSetup(): Boolean;
begin
  if not DirExists('D:\') then
  begin
    MsgBox(
      '오류: 이 장비에는 D:\ 드라이브가 존재하지 않습니다.' + #13#10 +
      '설치를 중단합니다.',
      mbCriticalError, MB_OK
    );
    Result := False;
    Exit;
  end;

  Result := True;
end;
