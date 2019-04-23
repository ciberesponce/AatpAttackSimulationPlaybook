param(
	[string]
	$UPN_NAME="seccxp.ninja"
)
#region ContosoDC
Write-Output "[!] Starting hydration process for ContosoDC1"

# disable real-time AV scans
try {
	Set-MpPreference -DisableRealtimeMonitoring $true
	New-ItemProperty -Path “HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender” -Name DisableAntiSpyware -Value 1 -PropertyType DWORD -Force -ErrorAction SilentlyContinue

	Write-Output "[+] Successfully turned off Windows Defender on VictimPC; this is purely for purposes to focus on AATP and not Windows Defender or Windows Defender ATP (WDATP)/Azure Security Center (ASC)"
}
catch {
	Write-Output "[-] Unable to turn off Windows Defender. Make sure this is disabled as this lab purposefully doesn't show how to evade AV nor does it focus on client-side Enterprise Detection and Response (EDR)."
}

# Turn on network discovery
try{
	Get-NetFirewallRule -DisplayGroup 'Network Discovery' | Set-NetFirewallRule -Profile 'Private, Domain, Public' -Enabled true
	Get-NetFirewallRule -DisplayGroup 'File and Printer Sharing' | Set-NetFirewallRule -Profile 'Private, Domain, Public' -Enabled true
	Write-Output "[+] Put ContosoDC1 in Network Discovery and File and Printer Sharing Mode"
}
catch {
	Write-Output "[-] Unable to put ContosoDC1 in Network Discovery Mode"
}

try{
	Add-WindowsFeature RSAT-AD-AdminCenter
	Write-Output "[+] Added RSAT AD AdminCenter"
}
catch{
	Write-Output "[-] Unable to add RSAT AD Admin Center. Add it manually if needed"
}

# install AD
try {
	Install-WindowsFeature AD-Domain-Services -IncludeManagementTools # Add ADDS feature; "IncludeManagementTools gives us the PowerShell capabilities later" 
	Write-Output '[+] Installed install AD DS and Management Tools'
}
catch {
	Write-Output '[-] Unable to install AD DS--make sure this gets installed before moving on!'
}

# Configure AD
try {
	$NetBiosName = "CONTOSO"
	$DomainName = "Contoso.Azure"
	$SafeModeAdminPass = "Password123!@#"
	Import-Module ADDSDeployment # Import libraries for ADDS
	Install-ADDSForest -CreateDnsDelegation:$false -DatabasePath 'C:\Windows\NTDS' -DomainMode 'Win2012R2' -DomainName $DomainName `
		-DomainNetbiosName $NetBiosName -ForestMode “Win2012R2” -InstallDns:$true -LogPath 'C:\Windows\NTDS' -SysvolPath 'C:\Windows\SYSVOL' `
		-SafeModeAdministratorPassword (convertto-securestring $SafeModeAdminPass -asplaintext -force) -NoRebootOnCompletion:$false -Force

	Write-Output '[+] ADDS Configured.'
	Write-Output "[ ] Domain Name: $DomainName `n[ ] NetBios Name: $NetBiosName"
}
catch {
	Write-Output '[-] Unable to configure AD. Make sure this is configured before moving on!'
}


# hide Server Manager at logon and IE Secure Mode
try{
	New-ItemProperty -Path HKLM:\SOFTWARE\Microsoft\ServerManager -Name DoNotOpenServerManagerAtLogon -PropertyType DWORD -Value "0x1" -Force
	New-ItemProperty -Path HKLM:\SOFTWARE\Microsoft\ServerManager\Oobe -Name DoNotOpenInitialConfigurationTasksAtLogon -PropertyType DWORD -Value "0x1" -Force

	# remove IE Enhanced Security
	Set-ItemProperty -Path “HKLM:\SOFTWARE\Microsoft\Active Setup\Installed Components\{A509B1A7-37EF-4b3f-8CFC-4F3A74704073}” -Name isinstalled -Value 0
	Rundll32 iesetup.dll, IEHardenLMSettings,1,True
	Rundll32 iesetup.dll, IEHardenUser,1,True
	Rundll32 iesetup.dll, IEHardenAdmin,1,True
	If (Test-Path “HKCU:\SOFTWARE\Microsoft\Active Setup\Installed Components\{A509B1A7-37EF-4b3f-8CFC-4F3A74704073}”) {
		Remove-Item -Path “HKCU:\SOFTWARE\Microsoft\Active Setup\Installed Components\{A509B1A7-37EF-4b3f-8CFC-4F3A74704073}”
	}
	If (Test-Path “HKCU:\SOFTWARE\Microsoft\Active Setup\Installed Components\{A509B1A8-37EF-4b3f-8CFC-4F3A74704073}”) {
		Remove-Item -Path “HKCU:\SOFTWARE\Microsoft\Active Setup\Installed Components\{A509B1A8-37EF-4b3f-8CFC-4F3A74704073}”
	}
	Write-Output '[+] Disabled Server Manager and IE Enhanced Security'
}
catch {
	Write-Output "[-] Unable to disable IE Enhanced Security or Server Manager at startup"
}

# audit remote SAM
try {
	New-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Lsa" -Name 'RestrictRemoteSamAuditOnlyMode' -PropertyType DWORD -Value "0x1" -Force
	Write-Output '[+] Put remote SAM settings in Audit mode'
}
catch {
	Write-Output '[-] Unable to change Remote SAM settings (needed for lateral movement graph)'
}

Write-Output '[+++] Finished ContosoDC1 (system) hydration script; must reboot for changes...'
Write-Output '[ ] If you want to show Hybrid use-cases, Install AAD Connect'
Write-Output '[ ] For more information: https://docs.microsoft.com/en-us/azure/active-directory/hybrid/tutorial-password-hash-sync#download-and-install-azure-ad-connect'
# endregion


#region Populate Users
Write-Output "[!] Starting AD Hydration scripts"

Import-Module ADDSDeployment

# create secure strings; required for New-ADUser function
$samiraAbbasiPass = ConvertTo-SecureString -String 'NinjaCat123' -AsPlainText -Force
$ronHdSecurePass = ConvertTo-SecureString -String 'FightingTiger$' -AsPlainText -Force
$jeffLeathermanPass = ConvertTo-SecureString -String 'Password$fun' -AsPlainText -Force
$lisaVPass = ConvertTo-SecureString -String 'HightImpactUser1' -AsPlainText -Force
$AATPService = ConvertTo-SecureString -String 'Password123!@#' -AsPlainText -Force

# Create SamiraA, add to Domain Admins
try {
	New-ADUser -Name 'SamiraA' -DisplayName "Samira Abbasi" -PasswordNeverExpires $true -AccountPassword $samiraAbbasiPass -Enabled $true -AccountExpirationDate 0
	Set-ADUser -Identity 'SamiraA' -UserPrincipalName "samiraa@$UPN_NAME"
	Add-ADGroupMember -Identity "Domain Admins" -Members SamiraA
	Write-Output "[+] Added SamiraA to AD"
}
catch {
	Write-Output "[-] Unable to add SamiraA"
}

# Create LisaV
try {
	New-ADUser -Name 'LisaV' -DisplayName "Lisa Valentine" -PasswordNeverExpires $true -AccountPassword $lisaVPass -Enabled $true -AccountExpirationDate 0
	Set-ADUser -Identity 'LisaV' -UserPrincipalName "lisav@$UPN_NAME"
	Write-Output "[+] Added LisaV to AD"
}
catch {
	Write-Output "[-] Unable to add LisaV"
}

# Create RonHD, Create Helpdesk SG, Add RonHD to Helpdesk
try {
	New-ADUser -Name 'RonHD' -DisplayName "Ron Helpdesk" -PasswordNeverExpires $true -AccountPassword $ronHdSecurePass -Enabled $true -AccountExpirationDate 0
	Set-ADUser -Identity 'RonHD' -UserPrincipalName "ronhd@$UPN_NAME"
	New-ADGroup -Name Helpdesk -GroupScope Global -GroupCategory Security 
	Add-ADGroupMember -Identity "Helpdesk" -Members "RonHD" 
	Write-Output "[+] Added Helpdesk and RonHD"
}
catch {
	Write-Output "[-] Unable to add Helpdesk or RonHD" -ErrorAction SilentlyContinue
}

# Create JeffL
try{
	New-ADUser -Name 'JeffL' -DisplayName "Jeff Leatherman" -PasswordNeverExpires $true -AccountPassword $jeffLeathermanPass -Enabled $true -AccountExpirationDate 0
	Set-ADUser -Identity 'jeffl' -UserPrincipalName "jeffl@$UPN_NAME"
	Write-Host "[+] Added JeffL"
}
catch {
	Write-Output "[-] Unable to add JeffL" -ErrorAction SilentlyContinue
}

# Create AATP Service (or ATA one)
try {
	New-ADUser -Name 'AatpService' -DisplayName "Azure ATP/ATA Service" -PasswordNeverExpires $true -AccountPassword $AATPService -Enabled $true -AccountExpirationDate 0
	# no need to set UPN; it shouldn't replicate up to AAD anyways
	Write-Host "[+] Added AatpService (AatpService)"
}
catch {
	Write-Output "[-] Unable to add AatpService" -ErrorAction SilentlyContinue
}

Write-Output "[+++] Finished AD hydration script"
#endregion