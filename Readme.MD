# THIS PROJECT MOVED
This project moved to https://aka.ms/DefendTheFlag

These Attack Simulation Playbooks are now part of a much larger effort, across Microsoft properties, to showcase attacks and more importantly, focus on defensive capabliities and investigations as a result of these new learnings.


# About
This is used to build out the lab for C+AI Security products.

## Whats new?
**VictimPC** now includes:
Additional attack tools
* Kekeo
* TOR Browser
* Attack scripts now stagged in Downloads > VictimPC
* MDATP 'eicar' file in Downloads > Eicar.exe

# Phase 0

## v1 Status

### Documentation
| Who | What | Status | Helpful resources|
|-----|------|--------|------------------|
|Kevin|Lift and Shift AIP| Complete|  |
|Kevin|Lift and Shift MCAS| Complete| |
|Kevin/Andrew|Lift and Shift AATP| Complete| |
|Kevin|Lift and Shift ASC| Complete|  |

### Common Lab Environment (CLE)

| Who | What | Status | Helpful Resources|
|-----|------|--------|------------------|
|Andrew| AAD Connect - Connect on-premises AD with AAD | Stalled | <ul><li>[PowerShell workaround](https://mikecrowley.us/2015/10/11/azure-ad-connect-powershell-cmdlets/)<li>Stalled: AAD Connect installed but not yet used; installed for API purposes |

### AATP
| Who | What | Status | Helpful Resources |
|-----|------|--------|-------------------|
|Andrew|Mimikatz|COMPLETE|                |
|Andrew|PowerSploit|COMPLETE|             |
|Andrew|NetSess|COMPLETE|                 |
|Andrew|VictimPc Scheduled Task for RonHD Cred|COMPLETE| |
|Andrew|Add respective DC Users|COMPLETE| |
|Andrew|VictimPC Admins (RonHD, JeffL) | COMPLETE |
|Andrew|AdminPC Admins (RonHD)|COMPLETE|  |
|Andrew|AdminPC Scheduled Task-SamiraA activity| COMPLETE| |
|Andrew|VictimPC Download HackTools|COMPLETE| |
|Andrew|VictimPC Unzip HackTools|COMPLETE| |
|Andrew|Ensure VMs can ping each other| COMPLETE| Ensure Network Discovery & File Sharing is enabled |

### AIP

| Who | What | Status | Helpful Resources|
|-----|------|--------|------------------|
|Andrew| Download aip software on everything but DC; MSI| COMPLETE | [AIP Install Location](https://download.microsoft.com/download/4/9/1/491251F7-46BA-46EC-B2B5-099155DD3C27/AzInfoProtection_MSI_for_central_deployment.msi)|
|Andrew| Make directory a share (Documents) | COMPLETE | |
|Andrew| Make AipScanner service account a domain account | COMPLETE | Need AAD Connect to work else need PowerShell workaround |
|Andrew| Install SQL Express (as Aip Service Account) | COMPLETE | THIS IS MANUAL; MORE TIME NEEDED TO AUTOMATE |
|Andrew|AdminPC gets AIP scanner installed|COMPLETE| |

## Validation Testing
|Who|What|Status|Date Status Updated
|---|----|------|-------------------|
|Andrew/Gershon/Brandon|AATP|  |N/A|
|Kevin|AIP| |N/A|
|Sebastien|MCAS| |N/A|
|Kara/ChrisB|ASC| |N/A|

## Phases
|Phase|Status|Last Updated|
|-----|------|------------|
|Phase 0|COMPLETE| 7/3/2019 |
|Phase 1|COMPLETE| 7/3/2019 |
|Phase 2|Ongoing| 7/17/2019 |

## Backlog (>v1.0)

### ASC
* Need Azure Passes, then create

### Azure Sentinel
* Need Azure Passes, then create
* Create helpful analytics/queries (Partner with MSTIC)?

### AIP
* Automate SQL Express install via respective credential (possible, just need more time)
* AIP Module 3 (documentation?)
