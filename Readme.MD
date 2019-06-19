# About
This is used to build out the lab for C+AI Security products.  These products are the following:

|AOR|Product|Primary|Secondary|
|---|-------|-------|---------|
|EMS TP|AATP|Gershon|Brandon|
|EMS TP|MCAS|Banu|Sebastien|
|AIP| AIP| Kevin| Nir |
|Azure Sec| ASC | Chris B| Yuri|
|Azure Sec | Azure Sentinel|Kara|Andrew|

The above chart also shows the Primary owner of the respective lab, as well as the secondary/backup.

## ToDo
### Documentation
| Who | What | Status | Helpful resources|
|-----|------|--------|------------------|
|Kevin|Lift and Shift AIP|Exploring|  |
|Kevin|Lift and Shift MCAS| Exploring| |
|Kevin/Andrew|Lift and Shift AATP|Exploring| |
|Kevin|Lift and Shift ASC|Exploring| |

### Common Lab Environment (CLE)

| Who | What | Status | Helpful Resources|
|-----|------|--------|------------------|
|Andrew| AAD Connect - Connect on-premises AD with AAD | Exploring | - [PowerShell workaround](https://mikecrowley.us/2015/10/11/azure-ad-connect-powershell-cmdlets/) |

### AATP
| Who | What | Status | Helpful Resources |
|-----|------|--------|-------------------|
|Andrew|Mimikatz|Exploring|               |
|Andrew|PowerSploit|Exploring|            |
|Andrew|NetSess|Exploring|                |
|Andrew|VictimPc Scheduled Task for RonHD Cred|Exploring| |
|Andrew|DC Users|COMPLETE| |
|Andrew|VictimPC Admins (RonHD, JeffL) | COMPLETE |
|Andrew|AdminPC Admins (RonHD)|COMPLETE| |
|Andrew|AdminPC Scheduled Task-SamiraA activity| COMPLETE| |

### AIP

| Who | What | Status | Helpful Resources|
|-----|------|--------|------------------|
|Andrew| Download aip software on everything but DC; MSI| COMPLETE | (https://download.microsoft.com/download/4/9/1/491251F7-46BA-46EC-B2B5-099155DD3C27/AzInfoProtection_MSI_for_central_deployment.msi)|
|Andrew| Make directory a share | Need more info | |
|Andrew| Make AipScanner service account a domain account | COMPLETE | Need AAD Connect to work else need PowerShell workaround |
|Andrew| Install SQL Express (as Aip Service Account) | Need more info | |
|Andrew|AdminPC gets AIP scanner installed|COMPLETE| |

## Validation Testing
|Who|What|Status|Date Status Updated
|---|----|------|-------------------|
|Andrew/Gershon/Brandon|AATP|  |N/A|
|Kevin|AIP| |N/A|
|Sebastien|MCAS| |N/A|
|Kara/ChrisB|ASC| |N/A|