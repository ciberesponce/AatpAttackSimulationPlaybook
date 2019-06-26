param(
    # resourceGroupName
    [Parameter(Mandatory=$false)]
    [string]
    $ResourceGroupName = 'andrew-images',

    # StorageAccount
    [Parameter(Mandatory=$false)]
    [string]
    $StorageAccount = 'caiseclabdev',

    # Container to save Images in storage account
    [Parameter(Mandatory=$false)]
    [string]
    $AssetsContainer = 'assets',

    # StorageAccount Key
    [Parameter(Mandatory=$false)]
    [string]
    $StorageAccessKey = 'MHCknrQZRBfqzv1mB+UgN7s1pinKp+buIDVmeZM2BLDTbwtrxMxh/85MjggBpEi+FHwTb3kmQR9Sd4dBjVheow=='
)

Write-Host "[+] Moving to proper Storage Account/containers"
$disks = Get-AzDisk -ResourceGroupName $ResourceGroupName
$destStorageContext = New-AzStorageContext -StorageAccountName $StorageAccount -StorageAccountKey $StorageAccessKey

foreach ($disk in $disks){
    $name = ($disk.Id).Split('/') | Select-Object -last 1

    Write-Host "[ ] Moving $name disk to Storage Account..." -ForegroundColor Cyan
    $sas = Grant-AzDiskAccess -ResourceGroupName $ResourceGroupName `
        -DiskName $disk.Name `
        -DurationInSecond 3600 -Access Read

    Start-AzStorageBlobCopy -AbsoluteUri $sas.AccessSAS `
        -DestContainer $AssetsContainer `
        -DestContext $destStorageContext `
        -DestBlob "$name.vhd"
    Write-Host "`t[+] Successfully copied $name disk to Storage Account..." -ForegroundColor Green
}