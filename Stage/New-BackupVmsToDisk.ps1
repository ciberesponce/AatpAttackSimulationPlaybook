###
# Discovers all VMs. Takes snapshots of those VMs. 
# Builds disks based on those snapshots; putting them in 
# Author: aharri@microsoft.com
##

param(
    # resourceGroupName
    [Parameter(Mandatory=$false)]
    [string]
    $ResourceGroupName = 'cxe-lab-test2',

    # Destination RG; where snapshots/images will be placed
    [Parameter(Mandatory=$false)]
    [string]
    $DestinationResourceGroupName = 'cxe-lab-images',

    # location
    [Parameter(Mandatory=$false)]
    [string]
    $Location = 'East US2',

    # Force stop?
    [Parameter(Mandatory=$false)]
    [bool]
    $StopVm = $false
)
$vms = Get-AzVm -ResourceGroupName $ResourceGroupName
$date = Get-Date -Format yyyyMMdd

# stop VMs
if ($StopVm){
    Write-Host "`[ ] Stopping VMs to prepare them to be Snapshotted" -Foreground Yellow
    $vms | Stop-AzVm -Force
    Write-Host "`t[+] VMs successfully stopped" -ForegroundColor Green
}
else {
    Write-Host "[ ] Continuing to build snapshots without turning off VMs; use -ForceVmStop if want them stopped first" -Foreground Yellow
}

Write-Host "[ ] Taking snapshots of $($vms.Count) VMs" -ForegroundColor Yellow
foreach ($vm in $vms){
    Write-Host "`t[$($vm.Name)] Taking snapshot" -ForegroundColor Cyan
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
    Write-Host "`t[$($vm.Name)]` Snapshot complete" -ForegroundColor Green

    Write-Host "`t[$($vm.Name)]` Converting snapshot to disk" -ForegroundColor Cyan
    $osDisk = New-AzDisk -DiskName "${snapshotName}d" `
        -Disk (New-AzDiskConfig -Location $Location -CreateOption Copy -SourceResourceId $snapshot.Id) `
        -ResourceGroupName $DestinationResourceGroupName
    Write-Host "[+] [$($vm.Name)]`t Successfully converted @ $($osDisk.Id)" -ForegroundColor Green
}