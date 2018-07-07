# THIS SHOULD NOT BE EXECUTED ON PRODUCTION RESOURCES!!!

# disable real-time AV scans
# THIS SHOULD NOT BE EXECUTED ON PRODUCTION RESOURCES!!!
Set-MpPreference -DisableRealtimeMonitoring $true

# Do fix for Azure DevTest Lab DNS (point to ContosoDC)
# set DNS to ContosoDC IP
# get contosoDC IP
$contosoDcIp = (Resolve-DnsName "ContosoDC").IPAddress 

# get current DNS
$currentDns = (Get-DnsClientServerAddress).ServerAddresses
# add contosodc
$currentDns += $contosoDcIp

# make change to DNS with all DNS servers now
Set-DnsClientServerAddress -InterfaceAlias "Ethernet 2" -ServerAddresses $currentDns

# Turn on network discovery
Get-NetFirewallRule -DisplayGroup 'Network Discovery'|Set-NetFirewallRule -Profile 'Private, Domain' -Enabled true

# Domain join computer
$domain = "contoso.azure"
$user = "contoso\nuckc"
$nuckCPass = "NinjaCat123" | ConvertTo-SecureString -AsPlainText -Force
$cred = New-Object System.Management.Automation.PSCredential($user, $nuckCPass)

Add-Computer -DomainName $domain -Credential $cred

# Add JeffV and Helpdesk to Local Admin Group
Add-LocalGroupMember -Group "Administrators" -Member "Contoso\JeffV"
Add-LocalGroupMember -Group "Administrators" -Member "Contoso\Helpdesk"

Remove-LocalGroupMember -Group "Administrators" -Member "Domain Admins"

# disable UAC
Set-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" -Name "ConsentPromptBehaviorAdmin" -Value "0x0" -Force

# hide Server Manager at logon
New-ItemProperty -Path HKLM:\SOFTWARE\Microsoft\ServerManager -Name DoNotOpenServerManagerAtLogon -PropertyType DWORD -Value "0x1" -Force
New-ItemProperty -Path HKLM:\SOFTWARE\Microsoft\ServerManager\Oobe -Name DoNotOpenInitialConfigurationTasksAtLogon -PropertyType DWORD -Value "0x1" -Force

# remove IE Enhanced Security
Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Active Setup\Installed Components\{A509B1A7-37EF-4b3f-8CFC-4F3A74704073}" -Name "IsInstalled" -Value 0 -Force
Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Active Setup\Installed Components\{A509B1A8-37EF-4b3f-8CFC-4F3A74704073}" -Name "IsInstalled" -Value 0 -Force
Stop-Process -Name Explorer

# audit remote SAM
New-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Lsa" -Name 'RestrictRemoteSamAuditOnlyMode' -PropertyType DWORD -Value "0x1" -Force

# restart machine due to UAC change
Restart-Computer -Force