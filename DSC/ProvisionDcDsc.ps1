Configuration Main
{
	param(
		[Parameter(Mandatory=$false)]
		[String]$DomainName='Contoso.Azure',

		[Parameter(Mandatory=$false)]
		[string]$NetBiosName='Contoso',

		[Parameter(Mandatory=$true)]
		[System.Management.Automation.PSCredential] $AdminCreds,

		[Parameter(Mandatory=$true)]
		[System.Management.Automation.PSCredential] $SafeModeAdminPassword,

		[Parameter(Mandatory=$true)]
		[string] $UserPrincipalName = "seccxp.ninja",

		[Int]$RetryCount=20,
		[Int]$RetryIntervalSec=30
    )
	Import-DscResource -ModuleName PSDesiredStateConfiguration, XActiveDirectory, xPendingReboot

	[System.Management.Automation.PSCredential]$DomainCreds = New-Object System.Management.Automation.PSCredential `
        ("${DomainName}\$($Admincreds.UserName)", $Admincreds.Password)

	Node localhost
	{
		  LocalConfigurationManager{
				ActionAfterReboot = 'ContinueConfiguration'
				ConfigurationMode = 'ApplyOnly'
				RebootNodeIfNeeded = $true
			}
		   WindowsFeature DNS
			{
				Ensure = 'Present'
				Name = 'DNS'
			}

			WindowsFeature RSAT{
				Ensure = 'Present'
				Name = 'RSAT'
			}

			WindowsFeature ADDSInstall
			{
				Ensure = 'Present'
				Name = 'AD-Domain-Services'
			}

			WindowsFeature RSAT_ADDS
			{
				Ensure = 'Present'
				Name = 'RSAT-ADDS'
			}

			WindowsFeature RSAT_AD_Tools
			{
				Ensure = 'Present'
				Name = 'RSAT-AD-Tools'
			}

			WindowsFeature RSAT_Role_Tools
			{
				Ensure = 'Present'
				Name = 'RSAT-Role-Tools'
			}

			xADDomain ContosoDC
			{
				DomainName = $DomainName
				DomainNetbiosName = $NetBiosName
				DomainAdministratorCredential = $DomainCreds
				SafemodeAdministratorPassword = $SafeModeAdminPassword
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

			xWaitForADDomain DscForestWait
			{
				DomainName = $DomainName
				DomainUserCredential = $DomainCreds
				RetryCount = $RetryCount
				RetryIntervalSec = $RetryIntervalSec
				DependsOn = '[xADDomain]ContosoDC'
			}

			xPendingReboot Reboot
			{
				Name = 'RebootServer'
				DependsOn = '[xWaitForADDomain]DscForestWait'
			}
	}
}

#Configuration HydrateUsers{
#    param(
#        [Parameter(Mandatory=$false)]
#        [string] $DomainName = "Contoso.Azure",

#        [Parameter(Mandatory=$true)]
#        [System.Management.Automation.PSCredential] $AdminCreds
#    )

#    Import-DscResource -ModuleName xActiveDirectory

#    [System.Management.Automation.PSCredential]$DomainCreds = New-Object System.Management.Automation.PSCredential `
#        ("${DomainName}\$($Admincreds.UserName)", $Admincreds.Password)

#    Node localhost{
#        LocalConfigurationManager{
#            ActionAfterReboot = 'ContinueConfiguration'
#            ConfigurationMode = 'ApplyOnly'
#            RebootNodeIfNeeded = $true
#        }
#    }

#    xADUser SamiraA
#    {
#        DomainName = $DomainName
#        DomainAdministratorCredential = $DomainCreds
#        UserName = 'SamiraA'
#        Password = 'NinjaCat123'
#        Ensure = 'Present'
#        UserPrincipalName = $UserPrincipalName
#        PasswordNeverExpires = $true
#    }

#    xADUser RonHD
#    {
#        DomainName = $DomainName
#        DomainAdministratorCredential = $DomainCreds
#        UserName = 'RonHD'
#        Password = 'FightingTiger$'
#        Ensure = 'Present'
#        PasswordNeverExpires = $true
#    }

#    xADUser JeffL
#    {
#        DomainName = $DomainName
#        DomainAdministratorCredential = $DomainCreds
#        UserName = 'JeffL'
#        Password = 'Password$fun'
#        Ensure = 'Present'
#        PasswordNeverExpires = $true
#    }

#    xADUser LisaV
#    {
#        DomainName = $DomainName
#        DomainAdministratorCredential = $DomainCreds
#        UserName = 'LisaV'
#        Password = 'HightImpactUser1'
#        Ensure = 'Present'
#        PasswordNeverExpires = $true
#    }

#    xADGroup DomainAdmins
#    {
#        GroupName = 'Domain Admins'
#        Category = 'Security'
#        GroupScope = 'Global'
#        MembershipAttribute = 'SamAccountName'
#        MembersToInclude = "$DomainName\SamiraA"
#        DependsOn = '[xADUser]SamiraA'
#    }

#    xADGroup Helpdesk
#    {
#        GroupName = 'Helpdesk'
#        Category = 'Security'
#        GroupScope = 'Global'
#        Description = 'Helpdesk for this domain'
#        DisplayName = 'Helpdesk'
#        MembershipAttribute = 'SamAccountName'
#        MembersToInclude = "$DomainName\RonHD"
#        DependsOn = '[xADUser]RonHD'
#    }
#  }
#}