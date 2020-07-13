#
### Start Virtual Machines
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

    "Starting virtual machines for site $site"
    Start-AzVM `
        -ResourceGroupName $ResourceGroupName `
        -Name $VMnameHub `
        -Force

    Start-AzVM `
        -ResourceGroupName $ResourceGroupName `
        -Name $VMnameSpoke `
        -Force

    $i++
}