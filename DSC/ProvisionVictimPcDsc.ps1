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

    # [PSCredential]$Creds = New-Object System.Management.Automation.PSCredential ("${NetBiosName}\$($AdminCred.UserName)", $AdminCred.Password)

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

        # Computer JoinDomain
        # {
        #     Name = 'VictimPC'
        #     DomainName = $DomainName
        #     Credential = $Creds
        #     DependsOn = "[DnsServerAddress]DnsServerAddress"
        # }

        # Group AddAdmins
        # {
        #     GroupName = 'Administrators'
        #     MembersToInclude = @("$NetBiosName\Helpdesk", "$NetBiosName\JeffL")
        #     Ensure = 'Present'
        #     DependsOn = '[Computer]JoinDomain'
        # }

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
    }
}