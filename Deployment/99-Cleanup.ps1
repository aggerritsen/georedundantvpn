#
### Remove Deployment
### Version 1.0
#

# Get Global variables
Import-Module -name .\Deployment\00-Variables.ps1 

# Remove Resource Groups
$i=0
While($i -lt 3)
{

    $resourceGroupName = "GeoVPN-"+$Name[$i]+"-rg"

    "Removing Resource Group - $resourceGroupName"
    Remove-AzResourceGroup -Name $resourceGroupName -Force -ErrorAction SilentlyContinue

    # Next
    $i++
}

"Removing Resource Group - DefaultResourceGroup-WEU"
Remove-AzResourceGroup -Name DefaultResourceGroup-WEU -Force -ErrorAction SilentlyContinue

"Removing Resource Group - DefaultResourceGroup-NEU"
Remove-AzResourceGroup -Name DefaultResourceGroup-NEU -Force -ErrorAction SilentlyContinue

"Removing Resource Group - NetworkWatcherRG"
Remove-AzResourceGroup -Name NetworkWatcherRG -Force -ErrorAction SilentlyContinue
