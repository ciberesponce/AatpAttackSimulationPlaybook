# disable real-time AV scans
Set-MpPreference -DisableRealtimeMonitoring $true
Write-Output "[+] Disabled real time AV detections"

# Turn on network discovery
try{
	Get-NetFirewallRule -DisplayGroup 'Network Discovery' | Set-NetFirewallRule -Profile 'Private, Domain, Public' -Enabled true
	Get-NetFirewallRule -DisplayGroup 'File and Printer Sharing' | Set-NetFirewallRule -Profile 'Private, Domain, Public' -Enabled true
	Write-Output "[+] Put VictimPC in Network Discovery and File and Printer Sharing Mode"
}
catch {
	Write-Output "[!] Unable to put VictimPC in Network Discovery Mode"
}

try{
	Add-WindowsFeature RSAT-AD-AdminCenter
	Write-Output "[+] Added RSAT AD AdminCenter"
}
catch{
	Write-Output "[!] Unable to add RSAT AD Admin Center. Add it manually if needed"
}

# install AD
try {
	Install-WindowsFeature AD-Domain-Services -IncludeManagementTools # Add ADDS feature; "IncludeManagementTools gives us the PowerShell capabilities later" 
	Write-Output '[+] Installed install AD DS and Management Tools'
}
catch {
	Write-Output '[!] Unable to install AD DS--make sure this gets installed before moving on!'
}

# Configure AD
try {
	$NetBiosName = "CONTOSO"
	$DomainName = "Contoso.Azure"
	$SafeModeAdminPass = "Password123!@#"
	Import-Module ADDSDeployment # Import libraries for ADDS
	Install-ADDSForest -CreateDnsDelegation:$false -DatabasePath 'C:\Windows\NTDS' -DomainMode 'Win2012R2' -DomainName $DomainName `
		-DomainNetbiosName $NetBiosName -ForestMode “Win2012R2” -InstallDns:$true -LogPath 'C:\Windows\NTDS' -SysvolPath 'C:\Windows\SYSVOL' `
		-SafeModeAdministratorPassword (convertto-securestring $SafeModeAdminPass -asplaintext -force) -NoRebootOnCompletion:$true -Force
	Write-Output '[+] ADDS Configured.'
	Write-Output "[ ] Domain Name: $DomainName `n[ ] NetBios Name: $NetBiosName"
}
catch {
	Write-Output '[!] Unable to configure AD. Make sure this is configured before moving on!'
}


# hide Server Manager at logon and IE Secure Mode
try{
	New-ItemProperty -Path HKLM:\SOFTWARE\Microsoft\ServerManager -Name DoNotOpenServerManagerAtLogon -PropertyType DWORD -Value "0x1" -Force
	New-ItemProperty -Path HKLM:\SOFTWARE\Microsoft\ServerManager\Oobe -Name DoNotOpenInitialConfigurationTasksAtLogon -PropertyType DWORD -Value "0x1" -Force

	# remove IE Enhanced Security
	Set-ItemProperty -Path “HKLM:\SOFTWARE\Microsoft\Active Setup\Installed Components\{A509B1A7-37EF-4b3f-8CFC-4F3A74704073}” -Name isinstalled -Value 0
	Set-ItemProperty -Path “HKLM:SOFTWARE\Microsoft\Active Setup\Installed Components\{A509B1A8-37EF-4b3f-8CFC-4F3A74704073}” -Name isinstalled -Value 0
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
	Write-Output "[!] Unable to disable IE Enhanced Security or Server Manager at startup"
}

# audit remote SAM
try {
	New-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Lsa" -Name 'RestrictRemoteSamAuditOnlyMode' -PropertyType DWORD -Value "0x1" -Force
	Write-Output '[+] Put remote SAM settings in Audit mode'
}
catch {
	Write-Output '[!] Unable to change Remote SAM settings (needed for lateral movement graph)'
}

Write-Output 'Finished ContosoDC1 (system) hydration script; must reboot for changes...'