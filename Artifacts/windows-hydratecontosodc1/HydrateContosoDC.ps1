$ErrorActionPreference = "Stop"

# disable real-time AV scans
Set-MpPreference -DisableRealtimeMonitoring $true

# Make Server discoverable on network
Get-NetFirewallRule -DisplayGroup 'Network Discovery'|Set-NetFirewallRule -Profile 'Private, Domain' `
    -Enabled true -PassThru|select Name,DisplayName,Enabled,Profile