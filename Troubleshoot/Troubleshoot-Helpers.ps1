function Remove-Extensions {
    param(
        # ResourceGroupName
        [Parameter(Mandatory=$false)]
        [string]
        $resourceGroup='Andrew-Test'
    )
    $vmData = @(
    ('Client01', 'AipDsc'),
    ('AdminPc', 'AdminPcDsc'),
    ('ContosoDc', 'DcPromoDsc'),
    ('VictimPc', 'VictimDsc')
)
    foreach ($vmSet in $vmData){
        Remove-AzVMExtension -ResourceGroupName $resourceGroup -VMName $vmset[0] -Name $vmSet[1] -Force
    }
}