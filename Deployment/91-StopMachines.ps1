#
### Stop Virtual Machines
### Version 1.0
#

# Get Global variables
Import-Module -name .\Deployment\00-Variables.ps1 

$i=0
While($i -lt 3)
{
    
    $site = $name[$i]
    $location = $region[$i]
    $resourceGroupName = "GeoVPN-"+$name[$i]+"-rg"

    $vmNameHub = "JumphostHub-"+$name[$i]+"-vm"
    $vmNameSpoke = "JumphostSpoke-"+$name[$i]+"-vm"

    "Stopping virtual machines for site $site"
    Stop-AzVM `
        -ResourceGroupName $ResourceGroupName `
        -Name $VMnameHub `
        -Force

    Stop-AzVM `
        -ResourceGroupName $ResourceGroupName `
        -Name $VMnameSpoke `
        -Force

    $i++
}