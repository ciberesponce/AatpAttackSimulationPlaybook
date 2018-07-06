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

# turn on network discovery
Get-NetFirewallRule -DisplayGroup 'Network Discovery'|Set-NetFirewallRule -Profile 'Private, Domain' -Enabled true


# Add Helpdesk to local admin group
try{
	Add-LocalGroupMember -Group "Administrators" -Member "Contoso\Helpdesk"
}
catch{
	Write-Error "Unable to add Helpdesk to the Local Admin Group"
}

# Remove Domain Admins from local admin group
try{
	Remove-LocalGroupMember -Group "Administrators" -Member "Domain Admins"
}
catch{
	Write-Error "Unable to remove Domain Admins from Local Admin Group"
}

# hide Server Manager at logon
New-ItemProperty -Path HKLM:\SOFTWARE\Microsoft\ServerManager -Name DoNotOpenServerManagerAtLogon -PropertyType DWORD -Value "0x1" -Force
New-ItemProperty -Path HKLM:\SOFTWARE\Microsoft\ServerManager\Oobe -Name DoNotOpenInitialConfigurationTasksAtLogon -PropertyType DWORD -Value "0x1" -Force

# audit remote SAM
New-ItemProperty -Path HKLM:\SYSTEM\CurrentControlSet\Control\Lsa -Name RestrictRemoteSamAuditOnlyMode -PropertyType DWORD -Value "0x1" -Force