Configuration CreateADForest
{
	param(
		[Parameter(Mandatory=$true)]
		[ValidateNotNullOrEmpty()]
		[string]$DomainName='Contoso.Azure',

		[Parameter(Mandatory=$true)]
		[ValidateNotNullOrEmpty()]
		[string]$NetBiosName='Contoso',

		[Parameter(Mandatory=$true)]
		[ValidateNotNullOrEmpty()]
		[PSCredential]$AdminCreds,

		[Parameter(Mandatory=$true)]
		[ValidateNotNullOrEmpty()]
		[string]$UserPrincipalName = "seccxp.ninja",

		[Parameter(Mandatory=$true)]
		[ValidateNotNullOrEmpty()]
		[PSCredential]$JeffLCreds,

		[Parameter(Mandatory=$true)]
		[ValidateNotNullOrEmpty()]
		[PSCredential]$SamiraACreds,

		[Parameter(Mandatory=$true)]
		[ValidateNotNullOrEmpty()]
		[PSCredential]$RonHdCreds,

		[Parameter(Mandatory=$true)]
		[ValidateNotNullOrEmpty()]
		[PSCredential]$LisaVCreds,

		[Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [PsCredential]$AipServiceCreds,

		[int]$RetryCount=20,
		[int]$RetryIntervalSec=30
	)

	Import-DscResource -ModuleName PSDesiredStateConfiguration, xActiveDirectory, xPendingReboot, `
		NetworkingDsc, xStorage, xDefender

	$Interface=Get-NetAdapter | Where-Object Name -Like "Ethernet*"|Select-Object -First 1
	$InterfaceAlias=$($Interface.Name)

	[PSCredential]$DomainCreds = New-Object System.Management.Automation.PSCredential ("${NetBiosName}\$($AdminCreds.UserName)", $AdminCreds.Password)
	
	[string]$AadConnectProductId = '6069C45A-B2D7-488C-AEC6-9364D11D4314'

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
		
		DnsServerAddress DnsServerAddress 
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

		xWaitForADDomain DscForestWait
		{
				DomainName = $DomainName
				DomainUserCredential = $DomainCreds
				RetryCount = $RetryCount
				RetryIntervalSec = $RetryIntervalSec
				DependsOn = "[xADDomain]ContosoDC"
		}

		Registry HideServerManager
        {
            Key = 'HKLM:\SOFTWARE\Microsoft\ServerManager'
            ValueName = 'DoNotOpenServerManagerAtLogon'
            ValueType = 'Dword'
            ValueData = '1'
            Force = $true
            Ensure = 'Present'
			DependsOn = @("[xADForestProperties]ForestProps", "[xWaitForADDomain]DscForestWait")
		}
		        #region enable Network Discovery for Domain Firewall profile
        # had to use Get-NetFirewallRule to get real name of predefined rules, not just displayname
        
        #LLMNR-UDP-In
        Firewall EnableNetworkDiscoveryLLMNR
        {
            Name = '{29B0772A-CEFB-49AD-BCF8-3CD60E4ED26C}'
            Enabled = 'True'
            Ensure = 'Present'
            Profile = 'Domain'
        }
        #NB-Datagram-In
        Firewall EnableNetworkDiscoveryNBDatagram
        {
            Name = '{24644562-E54C-4E3C-8790-AB6196E89C40}'
            Enabled = 'True'
            Ensure = 'Present'
            Profile = 'Domain'
        }
        #NB-Name-In
        Firewall EnableNetworkDiscoveryNBName
        {
            Name = '{BB81B632-81A5-4CE1-810C-A8D7ADF1AEE3}'
            Enabled = 'True'
            Ensure = 'Present'
            Profile = 'Domain'
        }
        #WSD EventSecure-In
        Firewall EnableNetworkDiscoveryWSDEventSecure
        {
            Name = '{B90C5364-961F-4D25-A940-57FC33EE7C84}'
            Enabled = 'True'
            Ensure = 'Present'
            Profile = 'Domain'
        }
        #Pub-WSD-In
        Firewall EnableNetworkDiscoveryPubWSD
        {
            Name = '{02E25160-C1B7-4D3A-926B-080E70646752}'
            Enabled = 'True'
            Ensure = 'Present'
            Profile = 'Domain'
        }
        #WSD-In
        Firewall EnableNetworkDiscoveryWSD
        {
            Name = '{39D4888F-3936-4F03-970C-AA2D8F5B8F2C}'
            Enabled = 'True'
            Ensure = 'Present'
            Profile = 'Domain'
        }
        #SSDP-In
        Firewall EnableNetworkDiscoverySSDP
        {
            Name = '{6B9347C6-E7F7-466B-960B-975119FED771}'
            Enabled = 'True'
            Ensure = 'Present'
            Profile = 'Domain'
        }
        #UPnP-In
        Firewall EnableNetworkDiscoveryUPnP
        {
            Name = '{DC81C2E8-B535-4234-9D12-2655D03D5930}'
            Enabled = 'True'
            Ensure = 'Present'
            Profile = 'Domain'
        }
        #WSD Events-In
        Firewall EnableNetworkDiscoveryWSDEvents
        {
            Name = '{AFAC157E-7F7A-4091-AE1A-1F70C4A51FCB}'
            Enabled = 'True'
            Ensure = 'Present'
            Profile = 'Domain'
        }
        #endregion


        Registry HideInitialServerManager
        {
            Key = 'HKLM:\SOFTWARE\Microsoft\ServerManager\Oobe'
            ValueName = 'DoNotOpenInitialConfigurationTasksAtLogon'
            ValueType = 'Dword'
            ValueData = '1'
            Force = $true
            Ensure = 'Present'
			DependsOn = @("[xADForestProperties]ForestProps", "[xWaitForADDomain]DscForestWait")
		}

		Script DownloadAadMsi
		{
			SetScript = 
            {
				if ((Test-Path -PathType Container -LiteralPath 'C:\LabTools\') -ne $true){
					New-Item -Path 'C:\LabTools\' -ItemType Directory
				}
				[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
                Start-BitsTransfer -Source 'https://github.com/ciberesponce/AatpAttackSimulationPlaybook/blob/master/Downloads/AzureADConnect.msi?raw=true' -Destination 'C:\LabTools\aadconnect.msi'
            }
			GetScript = 
            {
				if (Test-Path -LiteralPath 'C:\LabTools\aadconnect.msi'){
					return @{
						result = $true
					}
				}
				else {
					return @{
						result = $false
					}
				}
            }
            TestScript = 
            {
				if (Test-Path -LiteralPath 'C:\LabTools\aadconnect.msi'){
					return $true
				}
				else {
					return $false
				}
			}
		}

		Package InstallAadConnect
		{
			Name = 'Microsoft Azure AD Connect'
			ProductId = $AadConnectProductId
			Ensure = 'Present'
			Path = 'C:\LabTools\aadconnect.msi'
			Arguments = '/quiet'
			DependsOn = @("[Script]DownloadAadMsi","[xADForestProperties]ForestProps","[xWaitForADDomain]DscForestWait")
		}

		xADUser SamiraA
		{
			DomainName = $DomainName
			UserName = 'SamiraA'
			Password = $SamiraACreds
			Ensure = 'Present'
			GivenName = 'Samira'
			Surname = 'A'
			PasswordNeverExpires = $true
			DependsOn = @("[xADForestProperties]ForestProps", "[xWaitForADDomain]DscForestWait")
		}

		xADUser AipService
		{
			DomainName = $DomainName
			UserName = $AipServiceCreds.UserName
			Password = $AipServiceCreds
			Ensure = 'Present'
			GivenName = 'AipService'
			Surname = 'Account'
			PasswordNeverExpires = $true
			DependsOn = @("[xADForestProperties]ForestProps", "[xWaitForADDomain]DscForestWait")
		}

		xADUser RonHD
		{
			DomainName = $DomainName
			UserName = 'RonHD'
			Password = $RonHdCreds
			Ensure = 'Present'
			GivenName = 'Ron'
			Surname = 'HD'
			PasswordNeverExpires = $true
			DisplayName = 'RonHD'
			DependsOn = @("[xADForestProperties]ForestProps", "[xWaitForADDomain]DscForestWait")
		}

		xADUser JeffL
		{
			DomainName = $DomainName
			UserName = 'JeffL'
			GivenName = 'Jeff'
			Surname = 'Leatherman'
			Password = $JeffLCreds
			Ensure = 'Present'
			PasswordNeverExpires = $true
			DisplayName = 'JeffL'
			DependsOn = @("[xADForestProperties]ForestProps", "[xWaitForADDomain]DscForestWait")
		}

		xADUser LisaV
		{
			DomainName = $DomainName
			UserName = 'LisaV'
			GivenName = 'Lisa'
			Surname = 'Valentine'
			Password =  $LisaVCreds
			Ensure = 'Present'
			PasswordNeverExpires = $true
			DependsOn = @("[xADForestProperties]ForestProps", "[xWaitForADDomain]DscForestWait")
		}

		xADGroup DomainAdmins
		{
			GroupName = 'Domain Admins'
			Category = 'Security'
			GroupScope = 'Global'
			MembershipAttribute = 'SamAccountName'
			MembersToInclude = "SamiraA"
			Ensure = 'Present'
			DependsOn = @("[xADUser]SamiraA", "[xWaitForADDomain]DscForestWait")
		}

		xADGroup Helpdesk
		{
			GroupName = 'Helpdesk'
			Category = 'Security'
			GroupScope = 'Global'
			Description = 'Tier-2 (desktop) Helpdesk for this domain'
			DisplayName = 'Helpdesk'
			MembershipAttribute = 'SamAccountName'
			MembersToInclude = "RonHD"
			Ensure = 'Present'
			DependsOn = @("[xADUser]RonHD","[xWaitForADDomain]DscForestWait")
		}

		xMpPreference DefenderSettings
		{
			Name = 'DefenderProperties'
			DisableRealtimeMonitoring = $true
			ExclusionPath = 'c:\Temp'
		}
	} #end of node
} #end of configuration