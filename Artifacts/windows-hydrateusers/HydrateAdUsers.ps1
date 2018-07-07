# create secure strings; required for New-ADUser function
$nuckCSecurePass = ConvertTo-SecureString -String 'NinjaCat123' -AsPlainText -Force
$ronHdSecurePass = ConvertTo-SecureString -String 'FightingTiger$' -AsPlainText -Force
$jeffvSecurePass = ConvertTo-SecureString -String 'Password$fun' -AsPlainText -Force
$AATPService = ConvertTo-SecureString -String 'Password123!@#' -AsPlainText -Force


# Create NuckC, add to Domain Admins
try {
New-ADUser -Name NuckC -DisplayName "Nuck Chorris" -PasswordNeverExpires $true -AccountPassword $nuckCSecurePass -Enabled $true
Add-ADGroupMember -Identity "Domain Admins" -Members NuckC
	Write-Host "Added NuckC"
	}
	catch {
		Write-Error "Unable to add NuckC" -ErrorAction Continue
	}

# Create RonHD, Create Helpdesk SG, Add RonHD to Helpdesk
try {
New-ADUser -Name RonHD -DisplayName "Ron Helpdesk" -PasswordNeverExpires $true -AccountPassword $ronHdSecurePass -Enabled $true
New-ADGroup -Name Helpdesk -GroupScope Global -GroupCategory Security
Add-ADGroupMember -Identity "Helpdesk" -Members "RonHD"
	Write-Host "Added Helpdesk and RonHD"
	}
	catch {
		Write-Error "Unable to add Helpdesk or RonHD" -ErrorAction Continue
	}

# Create JeffV
try{
New-ADUser -Name JeffV -DisplayName "Jeff Victim" -PasswordNeverExpires $true -AccountPassword $jeffvSecurePass -Enabled $true
	Write-Host "Added JeffV"
	}
	catch {
		Write-Error "Unable to add JeffV" -ErrorAction Continue
	}

# Create AATP Service (or ATA one)
try {
New-ADUser -Name AatpService -DisplayName "Azure ATP/ATA Service" -PasswordNeverExpires $true -AccountPassword $AATPService -Enabled $true
	Write-Host "Added AatpService"
	}
	catch {
		Write-Error "Unable to add AatpService" -ErrorAction Continue
	}
# this account is used for LDAP purposes; will need to use this password when setting up Azure ATP/ATA