Configuration SetupVictimPc
{
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$DomainName = "Contoso.Azure",
            
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$NetBiosName = "Contoso",

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$DnsServer,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [PSCredential]$AdminCred
    )
    #region COE
    Import-DscResource -ModuleName PSDesiredStateConfiguration, xDefender, ComputerManagementDsc, NetworkingDsc, xSystemSecurity

    $Interface = Get-NetAdapter | Where-Object Name -Like "Ethernet*" | Select-Object -First 1
    $InterfaceAlias = $($Interface.Name)
    [PSCredential]$Creds = New-Object System.Management.Automation.PSCredential ("${NetBiosName}\$($AdminCred.UserName)", $AdminCred.Password)
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
            ExclusionPath = 'C:\Temp'
            DisableRealtimeMonitoring = $true
            DisableArchiveScanning = $true
        }

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
                    ('https://github.com/gentilkiwi/mimikatz/releases/download/2.2.0-20190512/mimikatz_trunk.zip', 'C:\Tools\Mimikatz_20190512.zip'),
                    ('https://github.com/PowerShellMafia/PowerSploit/archive/master.zip', 'C:\Tools\PowerSploit.zip'),
                    ('https://github.com/ciberesponce/AatpAttackSimulationPlaybook/blob/master/Downloads/NetSess.zip?raw=true', 'C:\Tools\NetSess.zip')
                )
                foreach ($tool in $tools){
                    Invoke-WebRequest -Uri $tool[0] -OutFile $tool[1]
                }
            }    
            GetScript = 
            {
                if ((Test-Path 'C:\Tools\NetSess.zip') -and (Test-Path 'C:\Tools\PowerSploit.zip') -and (Test-Path 'C:\Tools\Mimikatz_20190512.zip')){
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
                if ((Test-Path 'C:\Tools\NetSess.zip') -and (Test-Path 'C:\Tools\PowerSploit.zip') -and (Test-Path 'C:\Tools\Mimikatz_20190512.zip')){
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
            Path = 'C:\Tools\Mimikatz_20190512.zip'
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