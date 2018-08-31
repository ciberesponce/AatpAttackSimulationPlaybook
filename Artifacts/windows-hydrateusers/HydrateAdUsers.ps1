Import-Module ADDSDeployment

# create secure strings; required for New-ADUser function
$nuckCSecurePass = ConvertTo-SecureString -String 'NinjaCat123' -AsPlainText -Force
$ronHdSecurePass = ConvertTo-SecureString -String 'FightingTiger$' -AsPlainText -Force
$jeffvSecurePass = ConvertTo-SecureString -String 'Password$fun' -AsPlainText -Force
$AATPService = ConvertTo-SecureString -String 'Password123!@#' -AsPlainText -Force


# Create NuckC, add to Domain Admins
try {
	New-ADUser -Name 'NuckC' -DisplayName "Nuck Chorris" -PasswordNeverExpires $true -AccountPassword $nuckCSecurePass -Enabled $true
	Add-ADGroupMember -Identity "Domain Admins" -Members NuckC
	Write-Output "[+] Added NuckC to AD"
}
catch {
	Write-Output "[!] Unable to add NuckC"
}

# Create RonHD, Create Helpdesk SG, Add RonHD to Helpdesk
try {
	New-ADUser -Name 'RonHD' -DisplayName "Ron Helpdesk" -PasswordNeverExpires $true -AccountPassword $ronHdSecurePass -Enabled $true
	New-ADGroup -Name Helpdesk -GroupScope Global -GroupCategory Security 
	Add-ADGroupMember -Identity "Helpdesk" -Members "RonHD" 
	Write-Output "[+] Added Helpdesk and RonHD"
}
catch {
	Write-Error "[!] Unable to add Helpdesk or RonHD"
}

# Create JeffV
try{
	New-ADUser -Name 'JeffV' -DisplayName "Jeff Victim" -PasswordNeverExpires $true -AccountPassword $jeffvSecurePass -Enabled $true
	Write-Host "[+] Added JeffV"
}
catch {
	Write-Error "[!] Unable to add JeffV"
}

# Create AATP Service (or ATA one)
try {
	New-ADUser -Name 'AatpService' -DisplayName "Azure ATP/ATA Service" -PasswordNeverExpires $true -AccountPassword $AATPService -Enabled $true
	Write-Host "[+] Added AatpService (AatpService)"
}
catch {
	Write-Error "[!] Unable to add AatpService"
}

Write-Output "Finished AD hydration script"