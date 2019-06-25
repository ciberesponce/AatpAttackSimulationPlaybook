param(
    [Parameter(Mandatory=$false)]
    [string]
    $ResourceGroupName = 'andrew-test',

    # location for image
    [Parameter(Mandatory=$false)]
    [string]
    $Location = 'East US'
)
$vms = Get-AzVm -ResourceGroupName $ResourceGroupName
$location = 'East US'

Write-Host "[+] Starting to backup Images for $($vms.Count) VMs..." -ForegroundColor Yellow

foreach ($vm in $vms){
    Write-Host "`t[ ] Backing up $($vm.Name)" -ForegroundColor Cyan
    $diskId = $vm.StorageProfile.OsDisk.ManagedDisk.Id

    $imageConfig = New-AzImageConfig -Location $Location
    $imageConfig = Set-AzImageOsDisk -Image $imageConfig `
        -OsType $vm.StorageProfile.OsDisk.OsType.ToString() `
        -ManagedDiskId $diskId

    New-AzImage -ImageName "$($vm.Name)image" -ResourceGroupName andrew-images -Image $imageConfig
    Write-Host "`t[+] $($vm.Name):`tImage Backup complete"
}
Write-Host "[+] Complete."