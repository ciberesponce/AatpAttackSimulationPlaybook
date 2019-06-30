Configuration SetupVictimPc
{
    param(
        # COE
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$DomainName = "Contoso.Azure",
            
        # COE
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$NetBiosName = "Contoso",

        # COE
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$DnsServer,

        # COE
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [PSCredential]$AdminCred,

        # AATP: Used to expose RonHD cred to machine
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [PSCredential]$RonHdCred
    )
    #region COE
    Import-DscResource -ModuleName PSDesiredStateConfiguration, xDefender, ComputerManagementDsc, NetworkingDsc, xSystemSecurity, cChoco

    $Interface = Get-NetAdapter | Where-Object Name -Like "Ethernet*" | Select-Object -First 1
    $InterfaceAlias = $($Interface.Name)
    [PSCredential]$Creds = New-Object System.Management.Automation.PSCredential ("${NetBiosName}\$($AdminCred.UserName)", $AdminCred.Password)
    #endregion

    #region AATP stuff
    [PSCredential]$RonHdDomainCred = New-Object System.Management.Automation.PSCredential ("${NetBiosName}\$($RonHdCred.UserName)", $RonHdCred.Password)
    #endregion

    #region AIP stuff
    $AipProductId = "48A06F18-951C-42CA-86F1-3046AF06D15E"
    #endregion

    Node localhost
    {
        LocalConfigurationManager
        {
            ConfigurationMode = 'ApplyOnly'
            RebootNodeIfNeeded = $true
            AllowModuleOverwrite = $true
            ActionAfterReboot = 'ContinueConfiguration'
        }

        #region COE
        Service DisableWindowsUpdate
        {
            Name = 'wuauserv'
            State = 'Stopped'
            StartupType = 'Disabled'
        }

        DnsServerAddress DnsServerAddress 
        {
            Address        = $DnsServer
            InterfaceAlias = $InterfaceAlias
            AddressFamily  = 'IPv4'
            Validate = $true
        }

        xIEEsc DisableAdminIeEsc
        {
            UserRole = 'Administrators'
            IsEnabled = $false
        }

        xIEEsc DisableUserIeEsc
        {
            UserRole = 'Users'
            IsEnabled = $false
        }
        

        xUAC DisableUac
        {
            Setting = "NeverNotifyAndDisableAll"
        }

        Computer JoinDomain
        {
            Name = 'VictimPC'
            DomainName = $DomainName
            Credential = $Creds
            DependsOn = "[DnsServerAddress]DnsServerAddress"
        }

        Group AddAdmins
        {
            GroupName = 'Administrators'
            MembersToInclude = @("$NetBiosName\Helpdesk", "$NetBiosName\JeffL")
            Ensure = 'Present'
            DependsOn = '[Computer]JoinDomain'
        }

        Registry HideServerManager
        {
            Key = 'HKLM:\SOFTWARE\Microsoft\ServerManager'
            ValueName = 'DoNotOpenServerManagerAtLogon'
            ValueType = 'Dword'
            ValueData = '1'
            Force = $true
            Ensure = 'Present'
            DependsOn = '[Computer]JoinDomain'
        }

        Registry HideInitialServerManager
        {
            Key = 'HKLM:\SOFTWARE\Microsoft\ServerManager\Oobe'
            ValueName = 'DoNotOpenInitialConfigurationTasksAtLogon'
            ValueType = 'Dword'
            ValueData = '1'
            Force = $true
            Ensure = 'Present'
            DependsOn = '[Computer]JoinDomain'
        }
        #endregion

        #region AATP
        # every 10 minutes open up a new CMD.exe as RonHD
        ScheduledTask RonHd
        {
            TaskName = 'SimulateRonHdProcess'
            ScheduleType = 'Once'
            Description = 'Simulates RonHD exposing his account via an interactive or scheduled task manner.  In this case, we use scheduled task. This mimics the machine being managed.'
            Ensure = 'Present'
            Enable = $true
            TaskPath = '\AatpScheduledTasks'
            ExecuteAsCredential = $RonHdDomainCred
            ActionExecutable = 'cmd.exe'
            Priority = 9
            DisallowHardTerminate = $false
            RepeatInterval = '00:10:00'
            RepetitionDuration = 'Indefinitely'
            StartWhenAvailable = $true
            DependsOn = '[Computer]JoinDomain'
        }

        Registry AuditModeSamr
        {
            Key = 'HKLM:\SYSTEM\CurrentControlSet\Control\Lsa'
            ValueName = 'RestrictRemoteSamAuditOnlyMode'
            ValueType = 'Dword'
            ValueData = '1'
            Force = $true
            Ensure = 'Present'
            DependsOn = '[Computer]JoinDomain'
        }

        #region Choco
        cChocoInstaller InstallChoco
        {
            InstallDir = "C:\choco"
            DependsOn = '[Computer]JoinDomain'
        }

        cChocoPackageInstaller InstallSysInternals
        {
            Name = 'sysinternals'
            Ensure = 'Present'
            AutoUpgrade = $false
            DependsOn = '[cChocoInstaller]InstallChoco'
        }

        Script DownloadBginfo
        {
            SetScript =
            {
                if ((Test-Path -PathType Container -LiteralPath 'C:\BgInfo\') -ne $true){
					New-Item -Path 'C:\BgInfo\' -ItemType Directory
				}
                [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
                $ProgressPreference = 'SilentlyContinue' # used to speed this up from 30s to 100ms
                Invoke-WebRequest -Uri 'https://github.com/ciberesponce/AatpAttackSimulationPlaybook/blob/master/Downloads/BgInfo/adminpc.bgi?raw=true' -Outfile 'C:\BgInfo\BgInfo.bgi'
            }
            GetScript =
            {
                if (Test-Path -LiteralPath 'C:\BgInfo\BgInfo.bgi' -PathType Leaf){
                    return @{
                        result = $true
                    }
                }
                else {
                    return @{
                        result = $false
                    }
                }
            }
            TestScript = 
            {
                if (Test-Path -LiteralPath 'C:\BgInfo\BgInfo.bgi' -PathType Leaf){
                    return $true
                }
                else {
                    return $false
                }
            }
            DependsOn = @('[cChocoPackageInstaller]InstallSysInternals')

        }

        ScheduledTask BgInfo
        {
            TaskName = 'BgInfo'
            ScheduleType = 'AtLogOn'
            LogonType = 'Interactive'
			Description = 'Always show BgInfo at login'
            Ensure = 'Present'
            Enable = $true
            TaskPath = '\CoeScheduledTask'
            ActionExecutable = 'c:\choco\bin\bginfo64.exe'
            ActionArguments = '"c:\bginfo\bginfo.bgi" /nolicprompt /timer:0'
            Priority = 9
            StartWhenAvailable = $true
            RunLevel = 'Highest'
            DependsOn = @('[script]DownloadBginfo','[cChocoPackageInstaller]InstallSysInternals')
        }

        #endregion

        Script TurnOnNetworkDiscovery
        {
            SetScript = 
            {
                Get-NetFirewallRule -DisplayGroup 'Network Discovery' | Set-NetFirewallRule -Profile 'Domain, Private' -Enabled true
            }
            GetScript = 
            {
                $fwRules = Get-NetFirewallRule -DisplayGroup 'Network Discovery'
                $result = $true
                foreach ($rule in $fwRules){
                    if ($rule.Enabled -eq 'False'){
                        $result = $false
                        break
                    }
                }
                return @{
                    result = $result
                }
            }
            TestScript = 
            {
                $fwRules = Get-NetFirewallRule -DisplayGroup 'Network Discovery'
                $result = $true
                foreach ($rule in $fwRules){
                    if ($rule.Enabled -eq 'False'){
                        $result = $false
                        break
                    }
                }
                return $result
            }
            DependsOn = '[Computer]JoinDomain'
        }
        
        Script TurnOnFileSharing
        {
            SetScript = 
            {
                Get-NetFirewallRule -DisplayGroup 'File and Printer Sharing' | Set-NetFirewallRule -Profile 'Domain, Private' -Enabled true
            }
            GetScript = 
            {
                $fwRules = Get-NetFirewallRule -DisplayGroup 'File and Printer Sharing'
                $result = $true
                foreach ($rule in $fwRules){
                    if ($rule.Enabled -eq 'False'){
                        $result = $false
                        break
                    }
                }
                return @{
                    result = $result
                }
            }
            TestScript = 
            {
                $fwRules = Get-NetFirewallRule -DisplayGroup 'File and Printer Sharing'
                $result = $true
                foreach ($rule in $fwRules){
                    if ($rule.Enabled -eq 'False'){
                        $result = $false
                        break
                    }
                }
                return $result
            }
            DependsOn = '[Computer]JoinDomain'
        }

        Script EnsureTempFolder
        {
            SetScript = 
            {
                New-Item -Path 'C:\Temp\' -ItemType Directory
            }
            GetScript = 
            {
                if (Test-Path -PathType Container -LiteralPath 'C:\Temp'){
					return @{
						result = $true
					}
				}
				else {
					return @{
						result = $false
					}
				}
            }
            TestScript = {
                if(Test-Path -PathType Container -LiteralPath 'C:\Temp'){
                    return $true
                }
                else {
                    return $false
                }
            }
        }

        Registry DisableSmartScreen
        {
            Key = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer'
            ValueName = 'SmartScreenEnable'
            ValueType = 'String'
            ValueData = 'Off'
            Ensure = 'Present'
            DependsOn = '[Computer]JoinDomain'
        }

        #region Modify IE Zone 3 Settings
        # needed to download files via IE from GitHub and other sources
        # can't just modify regkeys, need to export/import reg
        # ref: https://support.microsoft.com/en-us/help/182569/internet-explorer-security-zones-registry-entries-for-advanced-users
        Script DownloadRegkeyZone3Workaround
        {
            SetScript = 
            {
                if ((Test-Path -PathType Container -LiteralPath 'C:\LabTools\') -ne $true){
					New-Item -Path 'C:\LabTools\' -ItemType Directory
				}
                [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
                $ProgressPreference = 'SilentlyContinue' # used to speed this up from 30s to 100ms
                Invoke-WebRequest -Uri 'https://raw.githubusercontent.com/ciberesponce/AatpAttackSimulationPlaybook/master/Downloads/Zone3.reg' -Outfile 'C:\LabTools\RegkeyZone3.reg'
            }
			GetScript = 
            {
				if (Test-Path 'C:\LabTools\RegkeyZone3.reg'){
					return @{
						result = $true
					}
				}
				else {
					return @{
						result = $false
					}
				}
            }
            TestScript = 
            {
				if (Test-Path 'C:\LabTools\RegkeyZone3.reg'){
					return $true
				}
				else {
					return $false
				}
            }
            DependsOn = '[Registry]DisableSmartScreen'
        }
        Script ExecuteZone3Override
        {
            SetScript = 
            {
                & 'reg import "C:\LabTools\RegkeyZone3.reg"'
            }
			GetScript = 
            {
				return $false
            }
            TestScript = 
            {
				return $true
            }
            DependsOn = '[Script]DownloadRegkeyZone3Workaround'
        }
        #endregion

        xMpPreference DefenderSettings
        {
            Name = 'DefenderSettings'
            ExclusionPath = 'C:\Tools'
            DisableRealtimeMonitoring = $true
            DisableArchiveScanning = $true
        }
        #endregion

        Script DownloadAipMsi
		{
			SetScript = 
            {
                if ((Test-Path -PathType Container -LiteralPath 'C:\LabTools\') -ne $true){
					New-Item -Path 'C:\LabTools\' -ItemType Directory
				}
                [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
                $ProgressPreference = 'SilentlyContinue' # used to speed this up from 30s to 100ms
                Invoke-WebRequest -Uri 'https://github.com/ciberesponce/AatpAttackSimulationPlaybook/blob/master/Downloads/AzInfoProtection_MSI_for_central_deployment.msi?raw=true' -Outfile 'C:\LabTools\aip_installer.msi'
            }
			GetScript = 
            {
				if (Test-Path 'C:\LabTools\aip_installer.msi'){
					return @{
						result = $true
					}
				}
				else {
					return @{
						result = $false
					}
				}
            }
            TestScript = 
            {
				if (Test-Path 'C:\LabTools\aip_installer.msi'){
					return $true
				}
				else {
					return $false
				}
            }
            DependsOn = '[Registry]DisableSmartScreen'
		}

		Package InstallAipClient
		{
			Name = 'Microsoft Azure Information Protection'
			Ensure = 'Present'
			Path = 'C:\LabTools\aip_installer.msi'
			ProductId = $AipProductId
			Arguments = '/quiet'
			DependsOn = @('[Script]DownloadAipMsi','[Computer]JoinDomain')
        }
        
        #region HackTools
        Script DownloadHackTools
        {
            SetScript = 
            {
                if ((Test-Path -PathType Container -LiteralPath 'C:\Tools') -ne $true){
                    New-Item -Path 'C:\Tools\' -ItemType Directory | Out-Null
                }
                [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
                $ProgressPreference = 'SilentlyContinue' # used to speed this up from 30s to 100ms
                $tools = @(
                    ('https://github.com/gentilkiwi/mimikatz/releases/download/2.2.0-20190512/mimikatz_trunk.zip', 'C:\Tools\Mimikatz.zip'),
                    ('https://github.com/PowerShellMafia/PowerSploit/archive/master.zip', 'C:\Tools\PowerSploit.zip'),
                    ('https://github.com/ciberesponce/AatpAttackSimulationPlaybook/blob/master/Downloads/NetSess.zip?raw=true', 'C:\Tools\NetSess.zip')
                )
                foreach ($tool in $tools){
                    Invoke-WebRequest -Uri $tool[0] -OutFile $tool[1]
                }
            }    
            GetScript = 
            {
                if ((Test-Path 'C:\Tools\NetSess.zip') -and (Test-Path 'C:\Tools\PowerSploit.zip') -and (Test-Path 'C:\Tools\Mimikatz.zip') -and (Test-Path 'C:\Tools\SysInternalsSuite.zip')){
                    return @{
                        result = $true
                    }
                }
                else {
                    return @{
                        result = $false
                    }
                }
            }
            TestScript = 
            {
                if ((Test-Path 'C:\Tools\NetSess.zip') -and (Test-Path 'C:\Tools\PowerSploit.zip') -and (Test-Path 'C:\Tools\Mimikatz.zip') -and (Test-Path 'C:\Tools\SysInternalsSuite.zip')){
                    return $true
                }
                else {
                    return $false
                }
            }
            DependsOn = @('[xMpPreference]DefenderSettings', '[Registry]DisableSmartScreen', '[Script]ExecuteZone3Override')
        }
        Archive UnzipMimikatz
        {
            Path = 'C:\Tools\Mimikatz.zip'
            Destination = 'C:\Tools\Mimikatz'
            Ensure = 'Present'
            DependsOn = '[Script]DownloadHackTools'
        }
        Archive UnzipPowerSploit
        {
            Path = 'C:\Tools\PowerSploit.zip'
            Destination = 'C:\Tools\PowerSploit'
            Ensure = 'Present'
            DependsOn = '[Script]DownloadHackTools'
        }
        Archive UnzipNetSess
        {
            Path = 'C:\Tools\NetSess.zip'
            Destination = 'C:\Tools\NetSess'
            Ensure = 'Present'
            DependsOn = '[Script]DownloadHackTools'
        }
        #endregion
    }
}