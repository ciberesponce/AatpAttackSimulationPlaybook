param(
    # resourceGroupName
    [Parameter(Mandatory=$false)]
    [string]
    $ResourceGroupName = 'andrew-test',

    # location
    [Parameter(Mandatory=$false)]
    [string]
    $Location = 'East US'
)
$vms = Get-AzVm -ResourceGroupName andrew-test
$date = Get-Date -Format yyyyMMdd

# stop VMs
Write-Host "`t[ ] Stopping VMs to prepare them to be Snapshotted" -Foreground Cyan
$vms | Stop-AzVm -Force
Write-Host "[+] VMs successfully stopped" -ForegroundColor Green

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
    $snapshot = New-AzSnapshot -Snapshot $snapshotConfig -SnapshotName $snapshotName -ResourceGroupName 'andrew-images'
    Write-Host "[+] $($vm.Name):`tSnapshot complete" -ForegroundColor Green

    Write-Host "[ ] $($vm.Name):`tConverting to disk" -ForegroundColor Cyan
    $osDisk = New-AzDisk -DiskName "${snapshotName}d" `
        -Disk (New-AzDiskConfig -Location $Location -CreateOption Copy -SourceResourceId $snapshot.Id) `
        -ResourceGroupName 'andrew-images'
    Write-Host "[+] $($vm.Name):`tSuccessfully converted @ $($osDisk.Id)" -ForegroundColor Green
}