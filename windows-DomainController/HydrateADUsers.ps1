Configuration HydrateUsers{
    param(
        [Parameter(Mandatory=$false)]
        [string] $DomainName = "Contoso.Azure",

        [Parameter(Mandatory=$true)]
        [System.Management.Automation.PSCredential] $AdminCreds
    )

    Import-DscResource -ModuleName xActiveDirectory

    [System.Management.Automation.PSCredential]$DomainCreds = New-Object System.Management.Automation.PSCredential `
        ("${DomainName}\$($Admincreds.UserName)", $Admincreds.Password)

    Node localhost{
        LocalConfigurationManager{
            ActionAfterReboot = 'ContinueConfiguration'
            ConfigurationMode = 'ApplyOnly'
            RebootNodeIfNeeded = $true
        }
    }

    xADUser SamiraA
    {
        DomainName = $DomainName
        DomainAdministratorCredential = $DomainCreds
        UserName = 'SamiraA'
        Password = 'NinjaCat123'
        Ensure = 'Present'
        UserPrincipalName = $UserPrincipalName
        PasswordNeverExpires = $true
    }

    xADUser RonHD
    {
        DomainName = $DomainName
        DomainAdministratorCredential = $DomainCreds
        UserName = 'RonHD'
        Password = 'FightingTiger$'
        Ensure = 'Present'
        PasswordNeverExpires = $true
    }

    xADUser JeffL
    {
        DomainName = $DomainName
        DomainAdministratorCredential = $DomainCreds
        UserName = 'JeffL'
        Password = 'Password$fun'
        Ensure = 'Present'
        PasswordNeverExpires = $true
    }

    xADUser LisaV
    {
        DomainName = $DomainName
        DomainAdministratorCredential = $DomainCreds
        UserName = 'LisaV'
        Password = 'HightImpactUser1'
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
}