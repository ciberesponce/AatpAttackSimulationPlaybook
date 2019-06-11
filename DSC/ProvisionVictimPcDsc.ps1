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
    Import-DscResource -ModuleName PSDesiredStateConfiguration, xDefender, ComputerManagementDsc, NetworkingDsc, xSystemSecurity

    $Interface = Get-NetAdapter | Where-Object Name -Like "Ethernet*" | Select-Object -First 1
    $InterfaceAlias = $($Interface.Name)

    $AipMsiUri = [uri]"https://download.microsoft.com/download/4/9/1/491251F7-46BA-46EC-B2B5-099155DD3C27/AzInfoProtection_MSI_for_central_deployment.msi"
    $AipOnDisk = 'C:\LabTools\aip_installer.msi'
    $AipProductId = "48A06F18-951C-42CA-86F1-3046AF06D15E"
    [PSCredential]$Creds = New-Object System.Management.Automation.PSCredential ("${NetBiosName}\$($AdminCred.UserName)", $AdminCred.Password)

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

        xMpPreference DefenderSettings
        {
            Name = 'DefenderSettings'
            ExclusionPath = 'C:\Temp'
            DisableRealtimeMonitoring = $true
        }

        Script DownloadAipMsi
		{
			SetScript = 
            {
                if ((Test-Path -PathType Container -LiteralPath 'C:\LabTools\') -ne $true){
					New-Item -Path 'C:\LabTools\' -ItemType Directory
				}
				[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
                Invoke-WebRequest -Uri 'https://github.com/ciberesponce/AatpAttackSimulationPlaybook/blob/master/Downloads/AzureADConnect.msi' -OutFile 'C:\LabTools\aip_installer.msi'
            }
			GetScript = 
            {
				if (Test-Path $AipOnDisk){
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
				if (Test-Path $AipOnDisk){
					return $true
				}
				else {
					return $false
				}
			}
		}

		Package InstallAadConnect
		{
			Name = 'AAD Connect'
			Ensure = 'Present'
			Path = $AipOnDisk
			ProductId = $AipProductId
			Arguments = '/quiet'
			DependsOn = @("[Script]DownloadAipMsi","[xADForestProperties]ForestProps","[xWaitForADDomain]DscForestWait")
		}
    }
}