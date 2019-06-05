Configuration SetupAdminPc
{
    param(
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]$DomainName,
        
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]$NetBiosName,

        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]$DnsServer,

        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [PSCredential]$AdminCred
    )
    Import-DscResource -ModuleName PSDesiredStateConfiguration, xDefender, ComputerManagementDsc, NetworkingDsc

    $Interface=Get-NetAdapter | Where-Object Name -Like "Ethernet*"|Select-Object -First 1
    $InterfaceAlias=$($Interface.Name)

	[PSCredential]$Creds = New-Object System.Management.Automation.PSCredential ("${NetBiosName}\$($AdminCred.UserName)", $AdminCred.Password)
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

        Computer JoinDomain
        {
            Name = 'AdminPC'
            DomainName = $DomainName
            Credential = $Creds
            DependsOn = "[DnsServerAddress]DnsServerAddress"
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

        xMpPreference DefenderSettings
        {
            Name = 'DefenderSettings'
            ExclusionPath = 'C:\Temp'
            DisableRealtimeMonitoring = $true
        }
    }
}