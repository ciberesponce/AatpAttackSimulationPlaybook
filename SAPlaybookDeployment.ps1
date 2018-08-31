Import-Module AzureRM
Import-Module .\ArmDeployment\Deployment.psm1 -Force

# Modidify this!
$RESOURCEGROUPNAME = '<myResourceGroupName>'

# these should not change...
$VictimPCVmName = "VictimPC" # as identified in template.json
$AdminPCVmName = "AdminPC" # as identified in template.json
$ContosoDcVmName = "ContosoDC" # as identified in template.json

$deploymentName = ""


# logon to your Azure Subscription
try {
    Write-Host "[*] Connecting to your Azure Account" -ForegroundColor Yellow
    Connect-AzureRmAccount
    Write-Host "[+] Successfully logged in to Azure" -ForegroundColor Green
}
catch {
    Write-Error "[-] Unable to connect to AzureRmAccount. Make sure PowerShell has proper libraries"
    Write-Error "[-] Make sure AzureRM module is installed (Install-Module -Name AzureRM)" -ErrorAction Stop
}
try {
    Write-Host "Enumerating all Azure Subscriptions you have access to" -ForegroundColor Yellow
    Get-AzureRmSubscription | Select-Object 'Name','State','TenantId','SubscriptionId' | Format-Table
    Write-Host "[!] From the subscriptions above, which SubscriptionId would you like to install this in?" -ForegroundColor Yellow
    [guid]$subscriptionId = Read-Host -Prompt 'Copy SubscriptionId GUID here'
    Write-Host "Successfully selected subscription: $subscriptionId" -ForegroundColor Green
}
catch {
    Write-Error "[-] Try again.  Make sure the SubscriptionId is a GUID value" -ErrorAction Stop
}

# deploy VMs to ResourceGroupName
Test-AzureRm -ResourceGroupName $RESOURCEGROUPNAME -TemplateFile ".\ArmDeployment\template.json"

Deploy-SuspiciousActivityPlaybookResourceGroup -subscriptionId $subscriptionId -resourceGroupName $RESOURCEGROUPNAME 


#region ContosoDC (Forest/Domain Controller)
# Hydrate DC (include installing ADDS and Configuring the forest)
Invoke-AzureRmVMRunCommand -ResourceGroupName $RESOURCEGROUPNAME -Name $ContosoDcVmName -CommandId 'RunPowerShellScript' `
    -ScriptPath ".\Artifacts\windows-hydratecontosodc\HydrateContosoDC.ps1"

Write-Host "[*] Restarting ContosoDC now that it has ADDS feature installed" -ForegroundColor Cyan
Restart-AzureRmVM -resourceGroupName $RESOURCEGROUPNAME -Name $ContosoDcVmName
Write-Host "[+] ContosoDC restarted" -ForegroundColor Green
Write-Host "[*] Hydrading DC with users now" -ForegroundColor Cyan
Write-Host "[+] DC Hydration Complete" -ForegroundColor Green
#endregion