$ErrorActionPreference = "Stop"

# disable real-time AV scans
Set-MpPreference -DisableRealtimeMonitoring $true

# Do fix for Azure DevTest Lab DNS (point to ContosoDC so we can domain join)
# set DNS to ContosoDC IP
# get contosoDC IP
$contosoDcIp = (Resolve-DnsName "ContosoDC").IPAddress
# get current DNS
$currentDns = (Get-DnsClientServerAddress).ServerAddresses
# add contosodc
$currentDns += $contosoDcIp

# make change to DNS with all DNS servers now
Set-DnsClientServerAddress -InterfaceAlias "Ethernet 2" -ServerAddresses $currentDns

# turn on network discovery
Get-NetFirewallRule -DisplayGroup 'Network Discovery'|Set-NetFirewallRule -Profile 'Private, Domain' `
    -Enabled true -PassThru|select Name,DisplayName,Enabled,Profile

# Add Helpdesk to Local Admin Group
# TODO

# Remove Domain Admins from Local Admin Group
# TODO
