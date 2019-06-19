$rg = 'andrew-test'
$Ips = Get-AzNetworkInterface -ResourceGroupName $rg
$vmDetails = New-Object "System.Collections.Generic.List[psobject]"
foreach ($instance in $Ips){
    $Vm = ($instance.VirtualMachine).Id.Split('/') | select -Last 1
    $PrivateIp = $instance.IpConfigurations.PrivateIpAddress
    $PublicIp = (Get-AzPublicIpAddress -ResourceGroupName $rg -Name ($instance.IpConfigurations.publicIpAddress.Id.Split('/') | select -Last 1)).IpAddress
    $obj = New-Object psobject -Property @{
        ResourceGroupName = $rg
        VmName = $vm
        PrivateIp = $PrivateIp
        PublicIp = $PublicIp
    }
    $vmDetails.Add($obj)
}
Write-Output $vmDetails