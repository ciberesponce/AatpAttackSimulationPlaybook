Configuration SetupAdminPc
{
    param(
        [Parameter(Mandatory=$true)]
        [string] $DomainName,
        
        [Parameter(Mandatory=$true)]
        [string] $NetBiosName,

        [Parameter(Mandatory=$true)]
        [PSCredential] $AdminCred
    )

    Import-DscResource -ModuleName xComputerManagement, xDefender, xPSDesiredStateConfiguration, `
    xNetworking, xStorage, xDefender, PSDesiredStateConfiguration

	# [PSCredential]$Creds = New-Object System.Management.Automation.PSCredential ("${NetBiosName}\$($RonHdCreds.UserName)", $RonHdCreds.Password)

    $User = $AdminCred.UserName
    $Pass = $AdminCred.Password

    [PSCredential]$Creds = New-Object System.Management.Automation.PSCredential ("$NetBiosName\$User", "$Pass")

    Node localhost
    {
		LocalConfigurationManager
		{
            RebootNodeIfNeeded = $true
            AllowModuleOverwrite = $true
            ActionAfterReboot = 'ContinueConfiguration'
        }

        xComputer JoinDomain
        {
            Name = 'AdminPC'
            DomainName = $DomainName
            Credential = $Creds
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