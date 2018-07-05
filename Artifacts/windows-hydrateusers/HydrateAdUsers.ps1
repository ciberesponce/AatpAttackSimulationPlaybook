# create secure strings; required for New-ADUser next
$nuckCSecurePass = ConvertTo-SecureString -String 'NinjaCat123' -AsPlainText -Force
$ronHdSecurePass = ConvertTo-SecureString -String 'FightingTiger$' -AsPlainText -Force
$jeffvSecurePass = ConvertTo-SecureString -String 'Password$fun' -AsPlainText -Force

// Create NuckC, add to Domain Admins
New-ADUser -Name NuckC -DisplayName "Nuck Chorris" -PasswordNeverExpires $true -AccountPassword $nuckCSecurePass
Add-ADGroupMember -Identity "Domain Admins" -Members NuckC

// Create RonHD, Create Helpdesk SG, Add RonHD to Helpdesk
New-ADUser -Name RonHD -DisplayName "Ron Helpdesk" -PasswordNeverExpires $true -AccountPassword $ronHdSecurePass
New-ADGroup -Name Helpdesk -GroupScope Global -GroupCategory Security
Add-ADGroupMember -Identity "Helpdesk" -Members "RonHD"

// Create JeffV
New-ADUser -Name JeffV -DisplayName "Jeff Victim" -PasswordNeverExpires $true -AccountPassword $jeffvSecurePass