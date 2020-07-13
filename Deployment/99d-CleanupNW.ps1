#
### Remove Deployment
### Version 1.0
#

"Removing Resource Group - DefaultResourceGroup-WEU"
Remove-AzResourceGroup -Name DefaultResourceGroup-WEU -Force -ErrorAction SilentlyContinue

"Removing Resource Group - DefaultResourceGroup-NEU"
Remove-AzResourceGroup -Name DefaultResourceGroup-NEU -Force -ErrorAction SilentlyContinue

"Removing Resource Group - NetworkWatcherRG"
Remove-AzResourceGroup -Name NetworkWatcherRG -Force -ErrorAction SilentlyContinue
