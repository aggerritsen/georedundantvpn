#
### Peering and Routing
### Version 1.0
#

# Get Global variables
Import-Module -name .\Deployment\00-Variables.ps1 


$i=0 # HQ
$i=1 # West
$i=2 # North
$resourceGroupName = "GeoVPN-"+$name[$i]+"-rg"
$gatewayName = "Gateway-"+$name[$i]+"-vpn"
$gateway = Get-AzVirtualNetworkGateway -Name $gatewayName -ResourceGroupName $ResourceGroupName
$gatewayBGPPeer = $gateway.BgpSettings.BgpPeeringAddress

Get-AzVirtualNetworkGatewayBGPPeerStatus -VirtualNetworkGatewayName $gatewayName -ResourceGroupName $resourceGroupName -ErrorAction SilentlyContinue
Get-AzVirtualNetworkGatewayLearnedRoute -VirtualNetworkGatewayName $gatewayName -ResourceGroupName $resourceGroupName -ErrorAction SilentlyContinue
#Get-AzVirtualNetworkGatewayAdvertisedRoute -VirtualNetworkGatewayName $gatewayName -ResourceGroupName $resourceGroupName -Peer $gatewayBGPPeer
