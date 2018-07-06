# create secure strings; required for New-ADUser next
$nuckCSecurePass = ConvertTo-SecureString -String 'NinjaCat123' -AsPlainText -Force
$ronHdSecurePass = ConvertTo-SecureString -String 'FightingTiger$' -AsPlainText -Force
$jeffvSecurePass = ConvertTo-SecureString -String 'Password$fun' -AsPlainText -Force
$AATPService = ConvertTo-SecureString -String 'Password123!@#' -AsPlainText -Force

try{
	# Create NuckC, add to Domain Admins
	New-ADUser -Name NuckC -DisplayName "Nuck Chorris" -PasswordNeverExpires $true -AccountPassword $nuckCSecurePass -Enabled $true
	Add-ADGroupMember -Identity "Domain Admins" -Members NuckC

	# Create RonHD, Create Helpdesk SG, Add RonHD to Helpdesk
	New-ADUser -Name RonHD -DisplayName "Ron Helpdesk" -PasswordNeverExpires $true -AccountPassword $ronHdSecurePass -Enabled $true
	New-ADGroup -Name Helpdesk -GroupScope Global -GroupCategory Security
	Add-ADGroupMember -Identity "Helpdesk" -Members "RonHD"

	# Create JeffV
	New-ADUser -Name JeffV -DisplayName "Jeff Victim" -PasswordNeverExpires $true -AccountPassword $jeffvSecurePass -Enabled $true

	# Create AATP Service (or ATA one)
	New-ADUser -Name AatpService -DisplayName "Azure ATP/ATA Service" -PasswordNeverExpires $true -AccountPassword $AATPService -Enabled $true
}
catch {
	Write-Error "Unable to hydrate AD. Check to see if users (RonHD, NuckC, JeffV) exist already. Or if the Helpdesk SG exists"
	exit -1
}