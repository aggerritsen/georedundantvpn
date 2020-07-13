#
### Deployment Virtual Network Gateways
### Version 1.0
#

# Get Global variables
Import-Module -name .\Deployment\00-Variables.ps1 

$i=1 # West

$site = $name[$i]
$location = $region[$i]
$resourceGroupName = "GeoVPN-"+$name[$i]+"-rg"

$vNetNameHub = "HubNetwork-"+$name[$i]+"-vnet"
$gatewayPIPName = "Gateway-"+$name[$i]+"-pip"
$gatewayIPConfigName = "Config-"+$name[$i]+"-ip"
$gatewayName = "Gateway-"+$name[$i]+"-vpn"
$gatewayASN = $asn[$i]

"Creating Virtual Gateway - $site"

$gateway = Get-AzVirtualNetworkGateway `
    -Name $gatewayName `
    -ResourceGroupName $ResourceGroupName `
    -ErrorAction SilentlyContinue

if(!$gateway) # Do not overwrite existing VPN, in order to save time
{
    $gatewayPIP = Get-AzPublicIpAddress -Name $gatewayPIPName -ResourceGroupName $ResourceGroupName
    $vNet = Get-AzVirtualNetwork -ResourceGroupName $ResourceGroupName -Name $vNetNameHub
    $subNet = Get-AzVirtualNetworkSubnetConfig -Name "GatewaySubnet" -VirtualNetwork $vNet
    $iPConfig = New-AzVirtualNetworkGatewayIpConfig -Name $gatewayIPConfigName -Subnet $subNet -PublicIpAddress $gatewayPIP

    New-AzVirtualNetworkGateway `
        -Name $gatewayName `
        -ResourceGroupName $ResourceGroupName `
        -Location $Location `
        -IpConfigurations $iPConfig `
        -GatewayType "vpn" `
        -VpnType "RouteBased" `
        -GatewaySku "VpnGw1" `
        -Asn $gatewayASN `
        -EnableBgp $True
}