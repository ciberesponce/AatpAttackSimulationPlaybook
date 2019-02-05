Write-Output "[!] Starting hydration process for VictimPC"
# THIS SHOULD NOT BE EXECUTED ON PRODUCTION RESOURCES!!!

# disable real-time AV scans
# THIS SHOULD NOT BE EXECUTED ON PRODUCTION RESOURCES!!!
try {
	Set-MpPreference -DisableRealtimeMonitoring $true
	New-ItemProperty -Path “HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender” -Name DisableAntiSpyware -Value 1 -PropertyType DWORD -Force -ErrorAction SilentlyContinue
	# added incase AV comes back on; whitelist our folder of hack tools
	Add-MpPreference -ExclusionPath "C:\Tools"
	Write-Output "[+] Successfully turned off Windows Defender on VictimPC; this is purely for purposes to focus on AATP and not Windows Defender or Windows Defender ATP (WDATP)/Azure Security Center (ASC)"
}
catch {
	Write-Output "[-] Unable to turn off Windows Defender. Make sure this is disabled as this lab purposefully doesn't show how to evade AV nor does it focus on client-side Enterprise Detection and Response (EDR)."
}


# Do fix for Azure DevTest Lab DNS (point to ContosoDC)
# set DNS to ContosoDC IP
# get contosoDC IP
try{
	$contosoDcIp = (Resolve-DnsName "ContosoDC1").IPAddress 

	# get current DNS
	$currentDns = (Get-DnsClientServerAddress).ServerAddresses
	# add contosodc
	$currentDns += $contosoDcIp
	# make change to DNS with all DNS servers 
	Set-DnsClientServerAddress -InterfaceAlias "Ethernet 2" -ServerAddresses $currentDns
	Clear-DnsClientCache
	Write-Output "[+] Added ContosoDC1 to DNS"
}
catch {
	Write-Output "[-] Unable to add ContosoDC1 to DNS" -ErrorAction Continue
}

# Turn on network discovery
try{
	Get-NetFirewallRule -DisplayGroup 'Network Discovery' | Set-NetFirewallRule -Profile 'Private, Domain, Public' -Enabled true
	Get-NetFirewallRule -DisplayGroup 'File and Printer Sharing' | Set-NetFirewallRule -Profile 'Private, Domain, Public' -Enabled true
	Write-Output "[+] Put VictimPC in Network Discovery and File and Printer Sharing Mode"
}
catch {
	Write-Output "[-] Unable to put VictimPC in Network Discovery Mode" -ErrorAction Continue
}


# Domain join computer
try {
	$domain = "contoso.azure"
	$user = "contoso\SamiraA"
	$SamiraAPass = "NinjaCat123" | ConvertTo-SecureString -AsPlainText -Force
	$cred = New-Object System.Management.Automation.PSCredential($user, $SamiraAPass)

	Add-Computer -DomainName $domain -Credential $cred
	Write-Output "[+] VictimPC added to Contoso"
}
catch {
	Write-Output "[-] Unable to add VictimPC to Contoso domain" -ErrorAction Continue
}

# Add JeffL and Helpdesk to Local Admin Group
try {
	Add-LocalGroupMember -Group "Administrators" -Member "Contoso\JeffL"
	Add-LocalGroupMember -Group "Administrators" -Member "Contoso\Helpdesk"

	Remove-LocalGroupMember -Group "Administrators" -Member "Domain Admins"
	Write-Output "[+] Added JeffL and Helpdesk to Admins Group. Removed Domain Admins :)"
}
catch {
	Write-Output "[-] Unable to add JeffL and Helpdesk to Admin Group" -ErrorAction Continue
}

# disable UAC/LUA (User Access Control/Limited User Account)
try{
	Set-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" -Name "ConsentPromptBehaviorAdmin" -Value "0x0" -Force
	Set-ItemProperty "HKLM:\Software\Microsoft\Windows\CurrentVersion\Policies\System" -Name EnableLUA -Value 0 -Force
	Set-ItemProperty "HKLM:\Software\Microsoft\Windows\CurrentVersion\Policies\System" -Name "ConsentPromptBehaviorAdmin" -Value 0
	Write-Output "[+] Disabled User Access Control/Limited User Account"
}
catch {
	Write-Output "[-] Unable to disable UAC" -ErrorAction Continue
}

# hide Server Manager at logon
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
	Write-Output "[+] Disabled Server Manager and IE Enhanced Security"
}
catch {
	Write-Output "[-] Unable to disable IE Enhanced Security or Server Manager at startup" -ErrorAction Continue
}

# audit remote SAM
try {
	New-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Lsa" -Name 'RestrictRemoteSamAuditOnlyMode' -PropertyType DWORD -Value "0x1" -Force
	Write-Output "[+] Put remote SAM settings in Audit mode"
}
catch {
	Write-Output "[-] Unable to change Remote SAM settings (needed for lateral movement graph)" -ErrorAction Continue
}

# add scheduled task for RonHD cmd.exe (expose creds--simulate logon/scheduled task/etc)
try {
	$action = New-ScheduledTaskAction -Execute 'cmd.exe'
	$trigger = New-ScheduledTaskTrigger -AtLogOn
	$runAs = 'Contoso\RonHD'
	$ronHHDPass = 'FightingTiger$'
	Register-ScheduledTask -TaskName "RonHD Cmd.exe - AATP SA Playbook" -Trigger $trigger -User $runAs -Password $ronHHDPass -Action $action

	Write-Output "[+] Created ScheduledTask on VictimPC to run cmd.exe as RonHD (simulate ScheduledTask/logon)"

}
catch {
	Write-Output "[-] Unable to create Scheduled Task on VictimPC! Need to simulate RonHD exposing creds to machine." -ErrorAction Continue
}

#TODO
# add an exposed SMB Share
try{
	
}
catch {
	Write-Output "[-] Unable to modify C$ SMB ACLs. Make sure you add JeffL manually to this to the ACL and the SMB Share itself (need both)" -ErrorAction Continue
}

# add firewall rule to allow ftp (useful for other stuff)
New-NetFirewallRule -Enabled True -Name "FTP TCP" -Direction Inbound -Action Allow -Program "%SystemRoot%\System32\ftp.exe" -Protocol tcp -DisplayName "FTP TCP Allow"
New-NetFirewallRule -Enabled True -Name "FTP UDP" -Direction Inbound -Action Allow -Program "%SystemRoot%\System32\ftp.exe" -Protocol udp -DisplayName "FTP UDP Allow"
Write-Output "[+++] Finished hydrating VictimPC"