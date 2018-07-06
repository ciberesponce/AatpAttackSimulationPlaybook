# disable real-time AV scans
Set-MpPreference -DisableRealtimeMonitoring $true

# Make Server discoverable on network
Get-NetFirewallRule -DisplayGroup 'Network Discovery'|Set-NetFirewallRule -Profile 'Private, Domain' -Enabled true

try {
	Add-WindowsFeature RSAT-AD-AdminCenter
}
catch {
	Write-Error "Unable to add RSAT-AD-AdminCenter Feature"
	exit -1
}

# hide Server Manager at logon
New-ItemProperty -Path HKLM:\SOFTWARE\Microsoft\ServerManager -Name DoNotOpenServerManagerAtLogon -PropertyType DWORD -Value "0x1" -Force
New-ItemProperty -Path HKLM:\SOFTWARE\Microsoft\ServerManager\Oobe -Name DoNotOpenInitialConfigurationTasksAtLogon -PropertyType DWORD -Value "0x1" -Force

# audit remote SAM
New-ItemProperty -Path HKLM:\SYSTEM\CurrentControlSet\Control\Lsa -Name RestrictRemoteSamAuditOnlyMode -PropertyType DWORD -Value "0x1" -Force