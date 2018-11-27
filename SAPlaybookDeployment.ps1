Write-Host "[!] Setting up environment" -ForegroundColor Yellow
try {
    Import-Module AzureRM -Force
}
catch {
    Write-Host "[-] Unable to load AzureRM. Ensure AzureRM is properly installed as a modeul (Install-Module AzureRM)" -ForegroundColor Red -ErrorAction Stop
}
Import-Module .\ArmDeployment\Deployment.psm1 -Force

# Modidify this!
$RESOURCEGROUPNAME = 'test-aatp-deployment'

# these should not change...
$VictimPCVmName = "VictimPC" # as identified in template.json
$AdminPCVmName = "AdminPC" # as identified in template.json
$ContosoDcVmName = "ContosoDC1" # as identified in template.json
#$deploymentName = ""
Write-Host "[+] Environment setup" -ForegroundColor Green


# logon to your Azure Subscription
try {
    Write-Host "[!] Connecting to your Azure Account" -ForegroundColor Yellow
    Connect-AzureRmAccount
    Write-Host "[+] Successfully logged in to Azure" -ForegroundColor Green
}
catch {
    Write-Host "[-] Unable to connect to AzureRmAccount. Make sure PowerShell has proper libraries" -ForegroundColor Red 
    Write-Host "[-] Make sure AzureRM module is installed (Install-Module -Name AzureRM)" -ErrorAction Stop -ForegroundColor Red
}

try {
    Write-Host "[!] Enumerating all Azure Subscriptions you have access to" -ForegroundColor Yellow
    Get-AzureRmSubscription | Select-Object 'Name','State','TenantId','SubscriptionId' | Format-Table
    Write-Host "[!] From the subscriptions above, which SubscriptionId would you like to install this in?" -ForegroundColor Yellow
    [guid]$subscriptionId = Read-Host -Prompt 'Copy SubscriptionId GUID here'
    Write-Host "[+] Successfully selected subscription: $subscriptionId" -ForegroundColor Green
}
catch {
    Write-Error "[-] Try again.  Make sure the SubscriptionId is a GUID value; without quotes" -ErrorAction Stop
}


# deploy VMs/VNet to ResourceGroupName
Test-AzureRmResourceGroupDeployment -ResourceGroupName $RESOURCEGROUPNAME -TemplateFile ".\ArmDeployment\template.json"
Deploy-SuspiciousActivityPlaybookResourceGroup -subscriptionId $subscriptionId -resourceGroupName $RESOURCEGROUPNAME 

###################
###########
###############
############
# MAKE SURE REFERENCES TO CONTOSODC are SAME (CONTOSODC1?)


#region ContosoDC1 (Forest/Domain Controller)
# Hydrate DC (include installing ADDS and Configuring the forest)
Invoke-AzureRmVMRunCommand -ResourceGroupName $RESOURCEGROUPNAME -Name $ContosoDcVmName -CommandId 'RunPowerShellScript' `
    -ScriptPath ".\Artifacts\windows-hydratecontosodc\HydrateContosoDC.ps1"

Write-Host "[*] Restarting ContosoDC1 now that it has ADDS feature installed" -ForegroundColor Cyan
$DcRestartJob = Restart-AzureRmVM -resourceGroupName $RESOURCEGROUPNAME -Name $ContosoDcVmName -AsJob
Write-Host "[+] ContosoDC1 restarted" -ForegroundColor Green
Write-Host "[*] Hydrading DC with users now" -ForegroundColor Cyan
Write-Host "[+] DC Hydration Complete" -ForegroundColor Green
#endregion

#region VictimPC
Invoke-AzureRmVMRunCommand -ResourceGroupName $RESOURCEGROUPNAME -Name $VictimPCVmName -CommandId 'RunPowerShellScript' `
    -ScriptPath ".\Artifacts\windows-hydratevictimpc\HydrateVictimPC.ps1"
Write-Host "[!] Restarting VictimPC"
$VictimPcJob = Restart-AzureRmVM -ResourceGroupName $RESOURCEGROUPNAME -Name $VictimPCVmName -AsJob
#endregion

#region AdminPC
Invoke-AzureRmVMRunCommand -ResourceGroupName $RESOURCEGROUPNAME -Name -CommandId 'RunPowerShellScript' `
    -ScriptPath ".\Artifacts\windows-hydrateadminpc\HydrateAdminPC.ps1"
Write-Host "[!] Restarting AdminPC"
$AdminPcJob = Restart-AzureRmVM -ResourceGroupName $RESOURCEGROUPNAME -Name $VictimPCVmName -AsJob
#endregion