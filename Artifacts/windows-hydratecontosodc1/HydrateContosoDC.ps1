$ErrorActionPreference = "Stop"

# disable real-time AV scans
Set-MpPreference -DisableRealtimeMonitoring $true

# Make Server discoverable on network
Get-NetFirewallRule -DisplayGroup 'Network Discovery'|Set-NetFirewallRule -Profile 'Private, Domain' `
    -Enabled true -PassThru|select Name,DisplayName,Enabled,Profile

try {
	Add-WindowsFeature RSAT-AD-AdminCenter
}
catch {
	Write-Error "Unable to add RSAT-AD-AdminCenter Feature"
	exit -1
}