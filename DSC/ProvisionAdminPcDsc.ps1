Configuration SetupAdminPc
{
    param(
		# [Parameter(Mandatory=$true)]
        # [PSCredential]$RonHdCreds,
        
        [Parameter(Mandatory=$true)]
        [string]$NetBiosName,

        [Parameter(Mandatory=$true)]
        [string]$DomainName
    )
    
    Import-DscResource -ModuleName xComputerManagement, xDefender, xPSDesiredStateConfiguration, `
    xNetworking, xStorage, xDefender, xPSDesiredStateConfiguration

	# [PSCredential]$Creds = New-Object System.Management.Automation.PSCredential ("${NetBiosName}\$($RonHdCreds.UserName)", $RonHdCreds.Password)

    [PSCredential]$Creds = New-Object System.Management.Automation.PSCredential ("$NetBiosName\RonHD", "FightingTiger$")

    $Interface=Get-NetAdapter | Where-Object Name -Like "Ethernet*"|Select-Object -First 1
	$InterfaceAlias=$($Interface.Name)

    Node localhost
    {
        # xDnsServerAddress DnsSettings
        # {
        #     Address = $DnsServer
        #     InterfaceAlias = $InterfaceAlias
        #     AddressFamily = "IPv4"
        #     Validate = $true
        # }

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