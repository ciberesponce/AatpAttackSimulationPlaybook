###
# Discovers all VMs. Takes snapshots of those VMs. 
# Builds disks based on those snapshots; putting them in 
# Author: aharri@microsoft.com
##

param(
    # resourceGroupName
    [Parameter(Mandatory=$false)]
    [string]
    $ResourceGroupName = 'andrew-test',

    # Destination RG; where snapshots/images will be placed
    [Parameter(Mandatory=$false)]
    [string]
    $DestinationResourceGroupName = 'andrew-images',

    # location
    [Parameter(Mandatory=$false)]
    [string]
    $Location = 'East US',

    # Force stop?
    [Parameter(Mandatory=$false)]
    [bool]
    $StopVm = $true
)
$vms = Get-AzVm -ResourceGroupName andrew-test
$date = Get-Date -Format yyyyMMdd

# stop VMs
if ($StopVm){
    Write-Host "`t[ ] Stopping VMs to prepare them to be Snapshotted" -Foreground Cyan
    $vms | Stop-AzVm -Force
    Write-Host "[+] VMs successfully stopped" -ForegroundColor Green
}
else {
    Write-Host "[ ] Continuing to build snapshots without turning off VMs; use -ForceVmStop if want them stopped first" -Foreground Cyan
}

Write-Host "[ ] Taking snapshots of $($vms.Count) VMs" -ForegroundColor Cyan
foreach ($vm in $vms){
    Write-Host "[ ] Taking snapshot of $($vm.Name)" -ForegroundColor Cyan
    $snapshotName = "$($vm.Name)$date"
    $disk = Get-AzDisk -ResourceGroupName $ResourceGroupName -DiskName $vm.StorageProfile.OsDisk.Name
    $snapshotConfig = New-AzSnapshotConfig -SourceUri $disk.Id `
        -OsType $disk.OsType `
        -CreateOption Copy `
        -Location $location `
        -AccountType Premium_LRS `
        -EncryptionSettingsEnabled $false `
        -DiskSizeGB $disk.DiskSizeGB
    $snapshot = New-AzSnapshot -Snapshot $snapshotConfig -SnapshotName $snapshotName -ResourceGroupName $DestinationResourceGroupName
    Write-Host "[+] $($vm.Name):`tSnapshot complete" -ForegroundColor Green

    Write-Host "[ ] $($vm.Name):`tConverting to disk" -ForegroundColor Cyan
    $osDisk = New-AzDisk -DiskName "${snapshotName}d" `
        -Disk (New-AzDiskConfig -Location $Location -CreateOption Copy -SourceResourceId $snapshot.Id) `
        -ResourceGroupName $DestinationResourceGroupName
    Write-Host "[+] $($vm.Name):`tSuccessfully converted @ $($osDisk.Id)" -ForegroundColor Green
}