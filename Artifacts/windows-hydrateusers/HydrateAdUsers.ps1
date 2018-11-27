Write-Output "[!] Starting AD Hydration scripts"

Import-Module ADDSDeployment

# create secure strings; required for New-ADUser function
$samiraAbbasiPass = ConvertTo-SecureString -String 'NinjaCat123' -AsPlainText -Force
$ronHdSecurePass = ConvertTo-SecureString -String 'FightingTiger$' -AsPlainText -Force
$jeffLeathermanPass = ConvertTo-SecureString -String 'Password$fun' -AsPlainText -Force
$AATPService = ConvertTo-SecureString -String 'Password123!@#' -AsPlainText -Force


# Create SamiraA, add to Domain Admins
try {
	New-ADUser -Name 'SamiraA' -DisplayName "Samira Abbasi" -PasswordNeverExpires $true -AccountPassword $samiraAbbasiPass -Enabled $true
	Add-ADGroupMember -Identity "Domain Admins" -Members SamiraA
	Write-Output "[+] Added SamiraA to AD"
}
catch {
	Write-Output "[-] Unable to add SamiraA"
}

# Create RonHD, Create Helpdesk SG, Add RonHD to Helpdesk
try {
	New-ADUser -Name 'RonHD' -DisplayName "Ron Helpdesk" -PasswordNeverExpires $true -AccountPassword $ronHdSecurePass -Enabled $true
	New-ADGroup -Name Helpdesk -GroupScope Global -GroupCategory Security 
	Add-ADGroupMember -Identity "Helpdesk" -Members "RonHD" 
	Write-Output "[+] Added Helpdesk and RonHD"
}
catch {
	Write-Output "[-] Unable to add Helpdesk or RonHD" -ErrorAction SilentlyContinue
}

# Create JeffL
try{
	New-ADUser -Name 'JeffL' -DisplayName "Jeff Leatherman" -PasswordNeverExpires $true -AccountPassword $jeffLeathermanPass -Enabled $true
	Write-Host "[+] Added JeffL"
}
catch {
	Write-Output "[-] Unable to add JeffL" -ErrorAction SilentlyContinue
}

# Create AATP Service (or ATA one)
try {
	New-ADUser -Name 'AatpService' -DisplayName "Azure ATP/ATA Service" -PasswordNeverExpires $true -AccountPassword $AATPService -Enabled $true
	Write-Host "[+] Added AatpService (AatpService)"
}
catch {
	Write-Output "[-] Unable to add AatpService" -ErrorAction SilentlyContinue
}

Write-Output "[+++] Finished AD hydration script"