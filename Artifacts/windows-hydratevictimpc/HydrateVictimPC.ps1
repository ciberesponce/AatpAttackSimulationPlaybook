$ErrorActionPreference = "Stop"

# disable real-time AV scans
Set-MpPreference -DisableRealtimeMonitoring $true

# Do fix for Azure DevTest Lab DNS (point to ContosoDC)
# set DNS to ContosoDC IP
# get contosoDC IP
try { $contosoDcIp = (Resolve-DnsName "ContosoDC").IPAddress }
catch{ Write-Error "Unable to find ContosoDC; make sure its in network before executing this artifact" }
# get current DNS
$currentDns = (Get-DnsClientServerAddress).ServerAddresses
# add contosodc
$currentDns += $contosoDcIp

# make change to DNS with all DNS servers now
Set-DnsClientServerAddress -InterfaceAlias "Ethernet 2" -ServerAddresses $currentDns

# Turn on network discovery
Get-NetFirewallRule -DisplayGroup 'Network Discovery'|Set-NetFirewallRule -Profile 'Private, Domain' `
    -Enabled true -PassThru|select Name,DisplayName,Enabled,Profile

# Add Helpdesk to Local Admin Group
# TODO

# Hacker tools to c:\tools
$client = New-Object System.Net.WebClient
try {
	$client.DownloadFile("https://github.com/gentilkiwi/mimikatz/releases/download/2.1.1-20180616/mimikatz_trunk.zip", "c:\tools")
}
catch {
	Write-Error "Unable to download mimikatz to c:\tools"
}