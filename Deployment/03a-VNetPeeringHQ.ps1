#
### Deployment Virtual Network Peering for HQ (no gateways)
### Version 1.0
#

# Get Global variables
Import-Module -name .\Deployment\00-Variables.ps1 


#
### Create Virtual Network Peering
#



$site = $name[0]
$resourceGroupName = "GeoVPN-"+$name[0]+"-rg"

$vNetNameHub = "HubNetwork-"+$name[0]+"-vnet"
$vNetNameSpoke = "SpokeNetwork-"+$name[0]+"-vnet"

$spokePeeringName = "Spoke"+$name[0]+"ToHubPeering"
$hubPeeringName = "HubToSpoke"+$name[0]+"Peering"

"Create Virtual Network Peering for $site"

$vNetHub = Get-AzVirtualNetwork `
    -Name $vNetNameHub `
    -ResourceGroupName $ResourceGroupName

$vNetSpoke = Get-AzVirtualNetwork `
    -Name $vNetNameSpoke `
    -ResourceGroupName $ResourceGroupName

# Peer Hub to Spoke
Add-AzVirtualNetworkPeering `
    -Name $hubPeeringName `
    -VirtualNetwork $vNetHub `
    -RemoteVirtualNetworkId $vNetSpoke.Id   `
    -AllowGatewayTransit `
    -AllowForwardedTraffic

# Peer Spoke to Hub
Add-AzVirtualNetworkPeering `
    -Name $spokePeeringName `
    -VirtualNetwork $vNetSpoke  `
    -RemoteVirtualNetworkId $vNetHub.Id `
    -AllowGatewayTransit `
    -AllowForwardedTraffic


