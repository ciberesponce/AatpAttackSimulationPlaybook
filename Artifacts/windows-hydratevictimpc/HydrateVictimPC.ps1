# THIS SHOULD NOT BE EXECUTED ON PRODUCTION RESOURCES!!!

# disable real-time AV scans
# THIS SHOULD NOT BE EXECUTED ON PRODUCTION RESOURCES!!!
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
Get-NetFirewallRule -DisplayGroup 'Network Discovery'|Set-NetFirewallRule -Profile 'Private, Domain' -Enabled true

# Domain join computer
try{
	$domain = "contoso.azure"
	$user = "contoso\nuckc"
	$nuckCPass = "NinjaCat123" | ConvertTo-SecureString -AsPlainText -Force
	$cred = New-Object System.Management.Automation.PSCredential($user, $nuckCPass)

	Add-Computer -DomainName $domain -Credential $cred
}
catch{
	Write-Error "Unable to add JeffV to Local Admin Group"
}

# Add JeffV and Helpdesk to local admin group
try{
	Add-LocalGroupMember -Group "Administrators" -Member "Contoso\JeffV"
	Add-LocalGroupMember -Group "Administrators" -Member "Contoso\Helpdesk"
}
catch{
	Write-Error "Unable to add JeffV to Local Admin Group"
}

# Remove Domain Admins from local admin group
try{
	Remove-LocalGroupMember -Group "Administrators" -Member "Domain Admins"
}
catch{
	Write-Error "Unable to remove Domain Admins from Local Admin Group"
}