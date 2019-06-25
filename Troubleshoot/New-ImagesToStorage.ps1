param(
    [Parameter(Mandatory=$false)]
    [string]
    $ResourceGroupName = 'andrew-test',

    # location for image
    [Parameter(Mandatory=$false)]
    [string]
    $Location = 'East US',

    # DestingationResourceGroup
    [Parameter(Mandatory=$false)]
    [string]
    $DestinationResourceGroupName = 'andrew-images',

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

$vms = Get-AzVm -ResourceGroupName $ResourceGroupName
$location = 'East US'

Write-Host "[+] Starting to backup Images for $($vms.Count) VMs..." -ForegroundColor Yellow

foreach ($vm in $vms){
    Write-Host "`t[ ] Backing up $($vm.Name)" -ForegroundColor Cyan
    $diskId = $vm.StorageProfile.OsDisk.ManagedDisk.Id # get only the OS disk; no other drives are included

    $imageConfig = New-AzImageConfig -Location $Location 
    $imageConfig = Set-AzImageOsDisk -Image $imageConfig `
        -OsType $vm.StorageProfile.OsDisk.OsType.ToString() `
        -ManagedDiskId $diskId        

    New-AzImage -ImageName "$($vm.Name)image" -ResourceGroupName andrew-images -Image $imageConfig
    Write-Host "`t[+] $($vm.Name):`tImage Backup complete"
}
Write-Host "[+] Captured Images Job Complete."
