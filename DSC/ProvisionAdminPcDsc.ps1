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
    Import-DscResource -ModuleName PSDesiredStateConfiguration, xDefender, ComputerManagementDsc, NetworkingDsc, xSystemSecurity, SqlServerDsc

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
            MembersToInclude = "$NetBiosName\Helpdesk"
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
        #endregion

        #region AATP
        Script TurnOnNetworkDiscovery
        {
            SetScript = 
            {
                Get-NetFirewallRule -DisplayGroup 'Network Discovery' | Set-NetFirewallRule -Profile 'Domain' -Enabled true
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

        Script TurnOnFileSharing
        {
            SetScript = 
            {
                Get-NetFirewallRule -DisplayGroup 'File and Printer Sharing' | Set-NetFirewallRule -Profile 'Domain' -Enabled true
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
            TaskPath = '\AatpScheduledTasks'
            ActionExecutable   = "C:\windows\system32\WindowsPowerShell\v1.0\powershell.exe"
            ActionArguments = "-File `"$SamiraASmbScriptLocation`""
            ExecuteAsCredential = $SamiraADomainCred
            Hidden = $true
            Priority = 9
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