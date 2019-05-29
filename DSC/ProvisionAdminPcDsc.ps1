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

    [string]$User = "RonHD"
    $Pass = ConvertTo-SecureString "FightingTiger$" -AsPlainText -Force 

    # $User = $AdminCred.UserName
    # $Pass = $AdminCred.Password

    Import-DscResource -ModuleName PSDesiredStateConfiguration, xDefender, ComputerManagementDsc

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

        Computer JoinDomain
        {
            Name = 'AdminPC'
            DomainName = $DomainName
            Credential = $Creds            
        }

        Group AddAdmins
        {
            GroupName = 'Administrators'
            MembersToInclude = "Helpdesk"
            Ensure = 'Present'
            DependsOn = '[xComputer]JoinDomain'
        }

        xMpPreference DefenderSettings
        {
            Name = 'DefenderSettings'
            ExclusionPath = 'C:\Temp'
            DisableRealtimeMonitoring = $true
        }
    }
}