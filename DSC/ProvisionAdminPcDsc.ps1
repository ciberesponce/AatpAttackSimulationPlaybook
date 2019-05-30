Configuration SetupAdminPc
{
    param(
        [Parameter(Mandatory=$true)]
        [string] $DomainName,
        
        [Parameter(Mandatory=$true)]
        [string] $NetBiosName,

        [Parameter(Mandatory=$true)]
        [string] $DnsServer,

        [Parameter(Mandatory=$true)]
        [PSCredential] $AdminCred
    )
    Import-DscResource -ModuleName PSDesiredStateConfiguration, xDefender, ComputerManagementDsc, NetworkingDsc

    $Interface=Get-NetAdapter | Where-Object Name -Like "Ethernet*"|Select-Object -First 1
	$InterfaceAlias=$($Interface.Name)

	[PSCredential]$Creds = New-Object System.Management.Automation.PSCredential ("${NetBiosName}\$($AdminCred.UserName)", $AdminCred.Pass)
	# [PSCredential]$Creds = New-Object System.Management.Automation.PSCredential ("${NetBiosName}\$User)", $Pass)

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

        # Computer JoinDomain
        # {
        #     Name = 'AdminPC'
        #     DomainName = $DomainName
        #     Credential = $Creds
        #     Server =  
        #     DependsOn = "[xDnsServerAddress]DnsServerAddress"
        # }

        # Group AddAdmins
        # {
        #     GroupName = 'Administrators'
        #     MembersToInclude = "Helpdesk"
        #     Ensure = 'Present'
        #     DependsOn = '[Computer]JoinDomain'
        # }

        xMpPreference DefenderSettings
        {
            Name = 'DefenderSettings'
            ExclusionPath = 'C:\Temp'
            DisableRealtimeMonitoring = $true
        }
    }
}