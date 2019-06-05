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
        [PSCredential]$AdminCred,

        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [PsCredential]$SamiraACred
    )
    Import-DscResource -ModuleName PSDesiredStateConfiguration, xDefender, ComputerManagementDsc, NetworkingDsc

    $Interface=Get-NetAdapter | Where-Object Name -Like "Ethernet*"|Select-Object -First 1
    $InterfaceAlias=$($Interface.Name)

    $SamiraASmbScriptLocation = [string]'C:\ScheduledTasks\SamiraASmbSimulation.ps1'
    [PSCredential]$SamiraADomainCred = New-Object System.Management.Automation.PSCredential ("${NetBiosName}\$($SamiraACred.UserName)", $SamiraACred.Password)
	[PSCredential]$Creds = New-Object System.Management.Automation.PSCredential ("${NetBiosName}\$($AdminCred.UserName)", $AdminCred.Password)

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

        File ScheduledTaskFile
        {
            DestinationPath = $SamiraASmbScriptLocation
            Ensure = 'Present'
            Contents = 
@'
Get-ChildItem '\\contosodc\c$'; exit(0)
'@
            Type = 'File'
        }

        ScheduledTask ScheduleTaskSamiraA
        {
            TaskName = 'SimulateDomainAdminTraffic'
            ScheduleType = 'AtStartup'
            Description = 'Simulates Domain Admin traffic from Admin workstation. Useful for SMB Session Enumeration and other items'
            Ensure = 'Present'
            Enable = $true
            TaskPath = '\AatpScheduledTasks'
            ActionExecutable   = "C:\windows\system32\WindowsPowerShell\v1.0\powershell.exe"
            ActionArguments = "-File `"$SamiraASmbScriptLocation`""
            ExecuteAsCredential = $SamiraADomainCred
            Hidden = $true
            RepeatInterval = '00:05:00'
            RepetitionDuration = 'Indefinitely'
            StartWhenAvailable = $true
            DependsOn = @('[Computer]JoinDomain','[File]ScheduledTaskFile')
        }
    }
}