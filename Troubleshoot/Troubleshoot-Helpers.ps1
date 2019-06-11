param(
    # ResourceGroupName
    [Parameter(Mandatory = $false)]
    [string]
    $resourceGroup = 'Andrew-Test'
)
#array showing VMName, DSC name
$vmData = @(
    ('ContosoDc', 'DcPromoDsc'),
    ('AdminPc', 'AdminPcDsc'),
    ('VictimPc', 'VictimDsc'),
    ('Client01', 'AipDsc')
)
foreach ($vmSet in $vmData) {
    Remove-AzVMExtension -ResourceGroupName $resourceGroup -VMName $vmset[0] -Name $vmSet[1] -Force
}