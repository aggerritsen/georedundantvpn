#
### Deployment Virtual Network and Virtual Network Gateway Peering
### Version 1.0
#

# Get Global variables
Import-Module -name .\Deployment\00-Variables.ps1 


#
### Create Virtual Network Peering
#

$i=0
While($i -lt 3)
{
    $site = $name[$i]
    $resourceGroupName = "GeoVPN-"+$name[$i]+"-rg"

    $vNetNameHub = "HubNetwork-"+$name[$i]+"-vnet"
    $vNetNameSpoke = "SpokeNetwork-"+$name[$i]+"-vnet"

    $spokePeeringName = "Spoke"+$name[$i]+"ToHubPeering"
    $hubPeeringName = "HubToSpoke"+$name[$i]+"Peering"

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
        -AllowGatewayTransit

    # Peer Spoke to Hub
    Add-AzVirtualNetworkPeering `
        -Name $spokePeeringName `
        -VirtualNetwork $vNetSpoke  `
        -RemoteVirtualNetworkId $vNetHub.Id `
        -AllowForwardedTraffic `
        -UseRemoteGateways

    $i ++
}

