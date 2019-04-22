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