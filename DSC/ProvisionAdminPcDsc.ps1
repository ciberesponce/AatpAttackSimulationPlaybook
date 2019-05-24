Configuration SetupAdminPc
{
    param(
		[Parameter(Mandatory=$true)]
        [PSCredential]$DomainCreds,
        
        [Parameter(Mandatory=$true)]
        [string]$DomainName,

        [Parameter(Mandatory=$true)]
        [string]$DnsServer
	)
    Import-DscResource -ModuleName xComputerManagement, xDefender, xPSDesiredStateConfiguration, xNetworking, xStorage, xDefender, `
    PSDesiredStateConfiguration

	[System.Management.Automation.PSCredential]$Creds = New-Object System.Management.Automation.PSCredential ("${DomainName}\$($DomainCreds.UserName)", $DomainCreds.Password)

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

        xComputer JoinDomain
        {
            Name = 'AdminPC'
            DomainName = $DomainName
            Credential = $Creds
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
            MembersToInclude = "Helpdesk"
            Ensure = 'Present'
            DependsOn = '[xComputer]JoinDomain'
        }
    }
}