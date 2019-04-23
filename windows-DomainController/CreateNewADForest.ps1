Install-Module xActiveDirectory -Scope CurrentUser -Force
Install-Module xPendingReboot -Scope CurrentUser -Force
Install-Module xNetworking -Scope CurrentUser -Force

Configuration CreateNewADForest {
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
    Import-DscResource -ModuleName xActiveDirectory, xPendingReboot, xNetworking

    [System.Management.Automation.PSCredential]$DomainCreds = New-Object System.Management.Automation.PSCredential `
        ("${DomainName}\$($Admincreds.UserName)", $Admincreds.Password)

    Node localhost{
        LocalConfigurationManager{
            ActionAfterReboot = 'ContinueConfiguration'
            ConfigurationMode = 'ApplyOnly'
            RebootNodeIfNeeded = $true
        }
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

    xADDomain ContosoDC
    {
        DomainName = $DomainName
        DomainNetbiosName = $NetBiosName
        DomainAdministratorCredential = $DomainCreds
        SafemodeAdministratorPassword = $SafeModeAdminPassword
        ForestMode = 'Win2012R2'
        DatabasePath = 'C:\NTDS'
        LogPath = 'C:\NTDS'
        SysvolPath = 'C:\SYSVOL'
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
        DependsOn = '[xADDomain ContosoDC]'
    }

    xPendingReboot Reboot1
    {
        Name = 'RebootServer'
        DependsOn = '[xWaitForADDomain]DscForestWait'
    }
}