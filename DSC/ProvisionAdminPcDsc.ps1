Configuration SetupAdminPc
{
    param(
        # Credential to domain join
        [Parameter(Mandatory=$true)]
        [PSCredential]
        $DomainJoinCredential,

        # DomainName
        [Parameter(Mandatory=$true)]
        [String]
        $DomainName
    )
    Import-DscResource -ModuleName xComputerManagement, xDefender, xPSDesiredStateConfiguration 

    Node localhost
    {
        xComputer NameComputer
        {
            Name = 'AdminPC'
            DomainName = $DomainName
            Credential = $DomainJoinCredential
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