Configuration SetupAdminPc
{
    param(
        # Credential to domain join
        [Parameter(Mandatory=$true)]
        [PSCredential]
        $DomainCreds,

        # DomainName
        [Parameter(Mandatory=$true)]
        [String]
        $DomainName
    )
    Import-DscResource -ModuleName xComputerManagement, xDefender, xPSDesiredStateConfiguration 

	[System.Management.Automation.PSCredential]$DomainCreds = New-Object System.Management.Automation.PSCredential ("${DomainName}\$($DomainCreds.UserName)", $DomainCreds.Password)


    Node localhost
    {
        xComputer NameComputer
        {
            Name = 'AdminPC'
            DomainName = $DomainName
            Credential = $DomainCreds
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
            DependsOn = '[xMpPreference]DefenderSettings'
        }
    }
}