#
### Deployment Virtual Network and Virtual Network Gateway Peering
### Version 1.0
#

# Get Global variables
Import-Module -name .\Deployment\00-Variables.ps1 

#BGP
$BGP = $True

#Encryption
$PreSharedKey = "SomeSecretKey" # This should come from a KeyVault

#Site0 details
$resourceGroupName0 = "GeoVPN-"+$name[0]+"-rg"
$location0 = $region[0]
$gatewayName0 = "Gateway-"+$name[0]+"-vpn"

#Site1 details
$resourceGroupName1 = "GeoVPN-"+$name[1]+"-rg"
$location1 = $region[1]
$gatewayName1 = "Gateway-"+$name[1]+"-vpn"

#Site2 details
$resourceGroupName2 = "GeoVPN-"+$name[2]+"-rg"
$location2 = $region[2]
$gatewayName2 = "Gateway-"+$name[2]+"-vpn"

#ConnectionNames
$connectionName01 = "VNetGateway"+$name[0]+"To"+$name[1]+"-cn"
$connectionName10 = "VNetGateway"+$name[1]+"To"+$name[0]+"-cn"
$connectionName02 = "VNetGateway"+$name[0]+"To"+$name[2]+"-cn"
$connectionName20 = "VNetGateway"+$name[2]+"To"+$name[0]+"-cn"
$connectionName12 = "VNetGateway"+$name[1]+"To"+$name[2]+"-cn"
$connectionName21 = "VNetGateway"+$name[2]+"To"+$name[1]+"-cn"

#Encryption
$PreSharedKey = "SomeSecretKey" # This should come from a KeyVault

"Get Virtual Network Gateways"
$GW0 = Get-AzVirtualNetworkGateway -Name $gatewayName0 -ResourceGroupName $resourceGroupName0
$GW1 = Get-AzVirtualNetworkGateway -Name $gatewayName1 -ResourceGroupName $resourceGroupName1
$GW2 = Get-AzVirtualNetworkGateway -Name $gatewayName2 -ResourceGroupName $resourceGroupName2


"Create $connectionName01"
New-AzVirtualNetworkGatewayConnection `
    -Name $connectionName01 `
    -ResourceGroupName $resourceGroupName0 `
    -VirtualNetworkGateway1 $GW0 `
    -VirtualNetworkGateway2 $GW1 `
    -Location $Location0 `
    -ConnectionType Vnet2Vnet `
    -EnableBGP $BGP `
    -SharedKey $PreSharedKey `
    -Force

"Create $connectionName10"
New-AzVirtualNetworkGatewayConnection `
    -Name $connectionName10 `
    -ResourceGroupName $resourceGroupName1 `
    -VirtualNetworkGateway1 $GW1 `
    -VirtualNetworkGateway2 $GW0 `
    -Location $Location1 `
    -ConnectionType Vnet2Vnet `
    -EnableBGP $BGP `
    -SharedKey $PreSharedKey `
    -Force


    "Create $connectionName02"
    New-AzVirtualNetworkGatewayConnection `
        -Name $connectionName02 `
        -ResourceGroupName $resourceGroupName0 `
        -VirtualNetworkGateway1 $GW0 `
        -VirtualNetworkGateway2 $GW2 `
        -Location $Location0 `
        -ConnectionType Vnet2Vnet `
        -EnableBGP $BGP `
        -SharedKey $PreSharedKey `
        -Force
    
    "Create $connectionName20"
    New-AzVirtualNetworkGatewayConnection `
        -Name $connectionName20 `
        -ResourceGroupName $resourceGroupName2 `
        -VirtualNetworkGateway1 $GW2 `
        -VirtualNetworkGateway2 $GW0 `
        -Location $Location2 `
        -ConnectionType Vnet2Vnet `
        -EnableBGP $BGP `
        -SharedKey $PreSharedKey `
        -Force
    

        

"Create $connectionName12"
New-AzVirtualNetworkGatewayConnection `
    -Name $connectionName12 `
    -ResourceGroupName $resourceGroupName1 `
    -VirtualNetworkGateway1 $GW1 `
    -VirtualNetworkGateway2 $GW2 `
    -Location $Location1 `
    -ConnectionType Vnet2Vnet `
    -EnableBGP $BGP `
    -SharedKey $PreSharedKey `
    -Force

"Create $connectionName21"
New-AzVirtualNetworkGatewayConnection `
    -Name $connectionName21 `
    -ResourceGroupName $resourceGroupName2 `
    -VirtualNetworkGateway1 $GW2 `
    -VirtualNetworkGateway2 $GW1 `
    -Location $Location2 `
    -ConnectionType Vnet2Vnet `
    -EnableBGP $BGP `
    -SharedKey $PreSharedKey `
    -Force


            