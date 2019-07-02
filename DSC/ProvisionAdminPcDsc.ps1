# ADMIN PC has to have SQL Express installed.  Hard to stage SQL as its 700+ MB and we
# can only stage files up to 100MB on GitHub


Configuration SetupAdminPc
{
    param(
        # COE: Domain's name
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]$DomainName,
        
        # COE: Domain's NetBios
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]$NetBiosName,

        # COE: ensures DNS properly set by OS before domain join
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]$DnsServer,

        # COE: used to domain join
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [PSCredential]$AdminCred,

        # AATP: used to do Scheduled Task
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [PsCredential]$SamiraACred,

        # AIP: used to install SqlServer in context of AIP Admin
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [PsCredential]$AipServiceCred

    )
    #region COE
    Import-DscResource -ModuleName PSDesiredStateConfiguration, xDefender, ComputerManagementDsc, NetworkingDsc, `
        xSystemSecurity, SqlServerDsc, cChoco, DSCR_Shortcut

    $Interface=Get-NetAdapter | Where-Object Name -Like "Ethernet*"|Select-Object -First 1
    $InterfaceAlias=$($Interface.Name)

    [PSCredential]$Creds = New-Object System.Management.Automation.PSCredential ("${NetBiosName}\$($AdminCred.UserName)", $AdminCred.Password)
    
    #region ScheduledTask-AATP
    $SamiraASmbScriptLocation = [string]'C:\ScheduledTasks\SamiraASmbSimulation.ps1'
    [PSCredential]$SamiraADomainCred = New-Object System.Management.Automation.PSCredential ("${NetBiosName}\$($SamiraACred.UserName)", $SamiraACred.Password)
    #endregion
    #endregion

    #region AIP stuff
    $AipProductId = "48A06F18-951C-42CA-86F1-3046AF06D15E"
    [PSCredential]$AipDomainAccount = New-Object System.Management.Automation.PSCredential ("${NetBiosName}\$($AipServiceCred.UserName)", $AipServiceCred.Password)

    #end region

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

        Computer JoinDomain
        {
            Name = 'AdminPC'
            DomainName = $DomainName
            Credential = $Creds
            DependsOn = "[DnsServerAddress]DnsServerAddress"
        }

        xIEEsc DisableAdminIeEsc
        {
            UserRole = 'Administrators'
            IsEnabled = $false
            DependsOn = "[Computer]JoinDomain"
        }

        xIEEsc DisableUserIeEsc
        {
            UserRole = 'Users'
            IsEnabled = $false
            DependsOn = "[Computer]JoinDomain"

        }

        xUAC DisableUac
        {
            Setting = "NeverNotifyAndDisableAll"
            DependsOn = "[Computer]JoinDomain"
        }

        Group AddAdmins
        {
            GroupName = 'Administrators'
            MembersToInclude = @("$NetBiosName\Helpdesk", "$NetBiosName\$($AipServiceCred.UserName)")
            Ensure = 'Present'
            DependsOn = '[Computer]JoinDomain'
        }

        Group AddRemoteDesktopUsers
        {
            GroupName = 'Remote Desktop Users'
            MembersToInclude = @("$NetBiosName\SamiraA", "$NetBiosName\Helpdesk")
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

        Script MSSqlFirewall
        {
            SetScript = 
            {
                New-NetFirewallRule -DisplayName 'MSSQL ENGINE TCP' -Direction Inbound -LocalPort 1433 -Protocol TCP -Action Allow
            }
            GetScript = 
            {
                $firewallStuff = Get-NetFirewallRule -DisplayName "MSSQL ENGINE TCP" -ErrorAction SilentlyContinue
                # if null, no rule exists with the Display Name
                if ($firewallStuff -ne $null){
                    return @{ result = $true}
                }
                else {
                    return @{ result = $false }
                }
            }
            TestScript = 
            {
                $firewallStuff = Get-NetFirewallRule -DisplayName "MSSQL ENGINE TCP" -ErrorAction SilentlyContinue
                # if null, no rule exists with the Display Name
                if ($firewallStuff -ne $null){
                    return $true
                }
                else {
                    return $false
                }
            }
        }

        #endregion

        #region AATP
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

        # Stage AIP data
        Script DownloadAipData
        {
            SetScript = 
            {
                if ((Test-Path -PathType Container -LiteralPath 'C:\PII\') -ne $true){
					New-Item -Path 'C:\PII\' -ItemType Directory
                }
                [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
                $ProgressPreference = 'SilentlyContinue' # used to speed this up from 30s to 100ms
                Invoke-WebRequest -Uri 'https://github.com/ciberesponce/AatpAttackSimulationPlaybook/blob/master/Downloads/AIP/docs.zip?raw=true' -Outfile 'C:\PII\data.zip'
            }
            TestScript =
            {
                if (Test-Path -PathType Leaf -LiteralPath 'C:\PII\data.zip'){
                    return @{ result = $true }
                } 
                else { 
                    return @{ result = $false }
                }
            }
            
            GetScript = 
            {
                if (Test-Path -PathType Leaf -LiteralPath 'C:\PII\data.zip'){
                    return = $true 
                }
                else { 
                    return $false 
                }
                
            }
            DependsOn = '[Computer]JoinDomain'
        }

        Archive AipDataToPii
        {
            Path = 'C:\PII\data.zip'
            Destination = 'C:\PII'
            Ensure = 'Present'
            DependsOn = '[Script]DownloadAipData'
        }

        Archive AipDataToPublicDocuments
        {
            Path = 'C:\Users\Public\Documents'
            Destination = 'C:\PII'
            Ensure = 'Present'
            DependsOn = '[Script]DownloadAipData'
        }

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
                Invoke-WebRequest -Uri 'https://github.com/ciberesponce/AatpAttackSimulationPlaybook/blob/master/Downloads/BgInfo/adminpc.bgi?raw=true' -Outfile 'C:\BgInfo\BgInfoConfig.bgi'
			}
            GetScript =
            {
                if (Test-Path -LiteralPath 'C:\BgInfo\BgInfoConfig.bgi' -PathType Leaf){
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
                if (Test-Path -LiteralPath 'C:\BgInfo\BgInfoConfig.bgi' -PathType Leaf){
                    return $true
                }
                else {
                    return $false
                }
			}
            DependsOn = '[cChocoPackageInstaller]InstallSysInternals'
        }
        cShortcut BgInfo
		{
			Path = 'C:\ProgramData\Microsoft\Windows\Start Menu\Programs\StartUp\BgInfo.lnk'
			Target = 'bginfo64.exe'
			Arguments = 'c:\BgInfo\BgInfoConfig.bgi /accepteula /timer:0'
            Description = 'Ensure BgInfo starts at every logon, in context of the user signing in (only way for stable use!)'
            DependsOn = @('[Script]DownloadBginfo','[cChocoPackageInstaller]InstallSysInternals')
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

        xMpPreference DefenderSettings
        {
            Name = 'DefenderSettings'
            ExclusionPath = 'C:\Tools'
            DisableRealtimeMonitoring = $true
        }

        File ScheduledTaskFile
        {
            DestinationPath = $SamiraASmbScriptLocation
            Ensure = 'Present'
            Contents = 
@'
Get-ChildItem '\\contosodc\c$'; exit(0)
'@
            Type = 'File'
        }

        ScheduledTask ScheduleTaskSamiraA
        {
            TaskName = 'SimulateDomainAdminTraffic'
            ScheduleType = 'Once'
            Description = 'Simulates Domain Admin traffic from Admin workstation. Useful for SMB Session Enumeration and other items'
            Ensure = 'Present'
            Enable = $true
            TaskPath = '\M365Security\Aatp'
            ActionExecutable   = "C:\windows\system32\WindowsPowerShell\v1.0\powershell.exe"
            ActionArguments = "-File `"$SamiraASmbScriptLocation`""
            ExecuteAsCredential = $SamiraADomainCred
            Hidden = $true
            Priority = 6
            RepeatInterval = '00:05:00'
            RepetitionDuration = 'Indefinitely'
            StartWhenAvailable = $true
            DependsOn = @('[Computer]JoinDomain','[File]ScheduledTaskFile')
        }
        #endregion

        #region AIP
        Script DownloadAipStuff
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
		}

		Package InstallAipClient
		{
			Name = 'Microsoft Azure Information Protection'
			Ensure = 'Present'
			Path = 'C:\LabTools\aip_installer.msi'
			ProductId = $AipProductId
			Arguments = '/quiet'
			DependsOn = @('[Script]DownloadAipStuff','[Computer]JoinDomain')
        }
        #endregion
    }
}