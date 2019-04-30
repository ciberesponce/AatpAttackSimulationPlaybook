Configuration CreateADForest
{
	param(
		[Parameter(Mandatory=$false)]
		[String]$DomainName='Contoso.Azure',

		[Parameter(Mandatory=$false)]
		[string]$NetBiosName='Contoso',

		[Parameter(Mandatory=$true)]
		[PSCredential] $AdminCreds,

		[Parameter(Mandatory=$true)]
		[string] $UserPrincipalName = "seccxp.ninja",

		[Int]$RetryCount=20,
		[Int]$RetryIntervalSec=30
    )
	Import-DscResource -ModuleName PSDesiredStateConfiguration, XActiveDirectory, `
		xPendingReboot, xNetworking, xStorage

	$Interface=Get-NetAdapter | Where-Object Name -Like "Ethernet*"|Select-Object -First 1
	$InterfaceAlias=$($Interface.Name)

	[System.Management.Automation.PSCredential]$DomainCreds = New-Object System.Management.Automation.PSCredential ("${DomainName}\$($AdminCreds.UserName)", $AdminCreds.Password)
		
	Node localhost
	{
		LocalConfigurationManager
		{
			RebootNodeIfNeeded = $true
		}
		
		WindowsFeature DNS
		{
			Ensure = 'Present'
			Name = 'DNS'
		}

		xDnsServerAddress DnsServerAddress 
		{ 
			Address        = '127.0.0.1' 
			InterfaceAlias = $InterfaceAlias
			AddressFamily  = 'IPv4'
			DependsOn = "[WindowsFeature]DNS"
		}

		WindowsFeature DnsTools
		{
			Ensure = "Present"
			Name = "RSAT-DNS-Server"
			DependsOn = "[WindowsFeature]DNS"
		}

		WindowsFeature ADDSInstall
		{
			Ensure = 'Present'
			Name = 'AD-Domain-Services'
		}

		WindowsFeature ADDSTools
		{
			Ensure = "Present"
			Name = "RSAT-ADDS-Tools"
			DependsOn = "[WindowsFeature]ADDSInstall"
		}

		WindowsFeature ADAdminCenter
		{
			Ensure = "Present"
			Name = "RSAT-AD-AdminCenter"
			DependsOn = "[WindowsFeature]ADDSInstall"
		}

		xADDomain ContosoDC
		{
			DomainName = $DomainName
			DomainNetbiosName = $NetBiosName
			DomainAdministratorCredential = $DomainCreds
			SafemodeAdministratorPassword = $DomainCreds
			ForestMode = 'Win2012R2'
			DatabasePath = 'C:\Windows\NTDS'
			LogPath = 'C:\Windows\NTDS'
			SysvolPath = 'C:\Windows\SYSVOL'
			DependsOn = '[WindowsFeature]ADDSInstall'
		}
	
		xADForestProperties ForestProps
		{
			ForestName = $DomainName
			UserPrincipalNameSuffixToAdd = $UserPrincipalName
			DependsOn = '[xADDomain]ContosoDC'
		}
	} #end of node
} #end of configuration

Configuration HydrateUsers
{
	param(
		[string]$DomainName
	)

	Import-DscResource -ModuleName xActiveDirectory
    
	Node localhost
	{
		LocalConfigurationManager
		{
			RebootNodeIfNeeded = $true
		}
		#region Users
		xADUser SamiraA
		{
			DomainName = $DomainName
			UserName = 'SamiraA'
			Password = ConvertTo-SecureString -String 'NinjaCat123' -AsPlainText -Force
			Ensure = 'Present'
			UserPrincipalName = $UserPrincipalName
			PasswordNeverExpires = $true
		}

		xADUser RonHD
		{
			DomainName = $DomainName
			UserName = 'RonHD'
			Password = ConvertTo-SecureString -String 'FightingTiger$' -AsPlainText -Force
			Ensure = 'Present'
			PasswordNeverExpires = $true
		}

		xADUser JeffL
		{
			DomainName = $DomainName
			UserName = 'JeffL'
			Password = ConvertTo-SecureString -String 'Password$fun' -AsPlainText -Force
			Ensure = 'Present'
			PasswordNeverExpires = $true
		}

		xADUser LisaV
		{
			DomainName = $DomainName
			UserName = 'LisaV'
			Password =  ConvertTo-SecureString -String 'HightImpactUser1' -AsPlainText -Force
			Ensure = 'Present'
			PasswordNeverExpires = $true
		}

		xADGroup DomainAdmins
		{
			GroupName = 'Domain Admins'
			Category = 'Security'
			GroupScope = 'Global'
			MembershipAttribute = 'SamAccountName'
			MembersToInclude = "$DomainName\SamiraA"
			DependsOn = '[xADUser]SamiraA'
		}

		xADGroup Helpdesk
		{
			GroupName = 'Helpdesk'
			Category = 'Security'
			GroupScope = 'Global'
			Description = 'Helpdesk for this domain'
			DisplayName = 'Helpdesk'
			MembershipAttribute = 'SamAccountName'
			MembersToInclude = "$DomainName\RonHD"
			DependsOn = '[xADUser]RonHD'
		}
	}#end of Node
} # end of configuration