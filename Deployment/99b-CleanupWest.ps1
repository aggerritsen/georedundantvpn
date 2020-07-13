#
### Remove Deployment
### Version 1.0
#

# Get Global variables
Import-Module -name .\Deployment\00-Variables.ps1 

# Remove Resource Groups
$i=1 #West
$resourceGroupName = "GeoVPN-"+$Name[$i]+"-rg"
"Removing Resource Group - $resourceGroupName"
Remove-AzResourceGroup -Name $resourceGroupName -Force -ErrorAction SilentlyContinue

