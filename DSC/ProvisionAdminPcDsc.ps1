Configuration SetupAdminPc
{
    param(
        # Credential to domain join
        [Parameter(Mandatory=$true)]
        [System.Management.Automation.PSCredential]
        $DomainCreds,

        # DomainName
        [Parameter(Mandatory=$true)]
        [String]
        $DomainName,

        # DNS Server in case not set by vNet
        [Parameter(Mandatory=$true)]
        [string]
        $DnsServer
    )
    Import-DscResource -ModuleName xComputerManagement, xDefender, xPSDesiredStateConfiguration, xNetworking, xStorage, xDefender, `
    PSDesiredStateConfiguration

	[System.Management.Automation.PSCredential]$DomainCreds = New-Object System.Management.Automation.PSCredential ("${DomainName}\$($DomainCreds.UserName)", $DomainCreds.Password)

    $Interface=Get-NetAdapter | Where-Object Name -Like "Ethernet*"|Select-Object -First 1
	$InterfaceAlias=$($Interface.Name)

    Node localhost
    {
        xDnsServerAddress DnsSettings
        {
            Address = $DnsServer
            InterfaceAlias = $InterfaceAlias
            AddressFamily = "IPv4"
            Validate = $true
        }

        xComputer NameComputer
        {
            Name = 'AdminPC'
            DomainName = $DomainName
            Credential = $DomainCreds
            DependsOn = "[xDnsServerAddress]DnsSettings"
        }

        xMpPreference DefenderSettings
        {
            Name = 'DefenderSettings'
            ExclusionPath = 'C:\Temp'
            DisableRealtimeMonitoring = $true
        }

        xGroup AddAdmins
        {
            GroupName = 'Administrators'
            MembersToInclude = "$DomainName\RonHD"
            Ensure = 'Present'
            DependsOn = '[xComputer]NameComputer'
        }
    }
}