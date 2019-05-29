Configuration SetupAdminPc
{
    # param(
    #     [Parameter(Mandatory=$true)]
    #     [string] $DomainName,
        
    #     [Parameter(Mandatory=$true)]
    #     [string] $NetBiosName,

    #     [Parameter(Mandatory=$true)]
    #     [PSCredential] $AdminCred
    # )
    [string]$DomainName = "Contoso.Azure"
    [string]$NetBiosName = "Contoso"
    [string]$DnsServer = "10.0.24.4"

    [string]$User = "RonHD"
    $Pass = ConvertTo-SecureString "FightingTiger$" -AsPlainText -Force 

    Import-DscResource -ModuleName PSDesiredStateConfiguration, xDefender, ComputerManagementDsc, xNetworking

    $Interface=Get-NetAdapter | Where-Object Name -Like "Ethernet*"|Select-Object -First 1
	$InterfaceAlias=$($Interface.Name)

    # $User = $AdminCred.UserName
    # $Pass = $AdminCred.Password

	# [PSCredential]$Creds = New-Object System.Management.Automation.PSCredential ("${NetBiosName}\$($RonHdCreds.UserName)", $RonHdCreds.Password)
	[PSCredential]$Creds = New-Object System.Management.Automation.PSCredential ("${NetBiosName}\$User)", $Pass)

    Node localhost
    {
		LocalConfigurationManager
		{
            ConfigurationMode = 'ApplyOnly'
            RebootNodeIfNeeded = $true
            AllowModuleOverwrite = $true
            ActionAfterReboot = 'ContinueConfiguration'
        }

		xDnsServerAddress DnsServerAddress 
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
            DependsOn = "[xDnsServerAddress]DnsServerAddress"
        }

        Group AddAdmins
        {
            GroupName = 'Administrators'
            MembersToInclude = "Helpdesk"
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