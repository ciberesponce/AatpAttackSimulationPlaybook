$items = Get-ChildItem ".\DSC\*.ps1" -Exclude "PublishPs1.ps1","HydrateAdminPC.ps1","HydrateVictimPC.ps1"
foreach ($item in $items){
    $filename = $item.Name
    $basefile = $filename.Split('.')[0]
    Publish-AzVMDscConfiguration -ConfigurationPath ".\DSC\$filename" -OutputArchivePath ".\DSC\$basefile.zip" -Force
}