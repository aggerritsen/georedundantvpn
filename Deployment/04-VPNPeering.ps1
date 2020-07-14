#
### Deployment Hybrid Virtual Network Gateway Peering
### Version 1.0
### This scripot contains code from two sources in order te setup a Hybrid Full Mesh VPN
#

# Get Global variables
Import-Module -name .\Deployment\00-Variables.ps1 


#
### Create Virtual Network Gateway Peering
#

### Code copied from Deployment\04b-VPNPeeringIPSEC.ps1

"Get IP details of all peers"
$i=0
$gatewayPIP = @()
$gatewayBGPPeer = @()
While($i -lt 3)
{
    $resourceGroupName = "GeoVPN-"+$name[$i]+"-rg"
    $gatewayPIPName = "Gateway-"+$name[$i]+"-pip"
    $location = $region[$i]
    $resourceGroupName = "GeoVPN-"+$name[$i]+"-rg"
    $gatewayName = "Gateway-"+$name[$i]+"-vpn"

    $gatewayPIP += @(Get-AzPublicIpAddress -Name $gatewayPIPName -ResourceGroupName $ResourceGroupName)
    
    $gateway = Get-AzVirtualNetworkGateway -Name $gatewayName -ResourceGroupName $ResourceGroupName
    $gatewayBGPPeer += @($gateway.BgpSettings.BgpPeeringAddress)

    # Next
    $i++
}

#
### Preset encryption
### Required when peered VPN has specific requirements
#

"Create generic IPSEC Policy"
$PreSharedKey = "SomeSecretKey" # This should come from a KeyVault
$iPSecPolicy  = New-AzIpsecPolicy `
    -IkeEncryption AES256 -IkeIntegrity SHA256 -DhGroup DHGroup14 `
    -IpsecEncryption AES256 -IpsecIntegrity SHA256 -PfsGroup ECP384 `
    -SALifeTimeSeconds 28800 -SADataSizeKilobytes 102400000



$i=0
While($i -lt 3)
{

    $site = $name[$i]
    $location = $region[$i]
    $resourceGroupName = "GeoVPN-"+$name[$i]+"-rg"
    $gatewayName = "Gateway-"+$name[$i]+"-vpn"

    if($i -eq 0) {$a=1;$b=2}
    if($i -eq 1) {$a=0;$b=2}
    if($i -eq 2) {$a=0;$b=1}

    "Create VPN Peerings for $site"

    $gateway = Get-AzVirtualNetworkGateway `
        -Name $gatewayName `
        -ResourceGroupName $ResourceGroupName


    # Create A
    "# Create Local Network Gateway to "+$name[$a]
    $localNetworkGatewayNameA = "LocalGateway"+$name[$i]+"To"+$name[$a]+"-lng"
    $connectionNameA = "Connection"+$name[$i]+"To"+$name[$a]+"-cn"
    $gatewayIPA = $gatewayPIP[$a].IpAddress
    $asnA= $asn[$a]
    $gatewayBGPPeerA = $gatewayBGPPeer[$a]
    $addressPrefixA = $gatewayBGPPeerA+"/32"

    $localNetworkGatewayA = New-AzLocalNetworkGateway `
        -Name $localNetworkGatewayNameA `
        -ResourceGroupName $resourceGroupName `
        -Location $location `
        -GatewayIpAddress $gatewayIPA `
        -AddressPrefix $addressPrefixA `
        -Asn $asnA `
        -BgpPeeringAddress $gatewayBGPPeerA `
        -Force

    "# Create IPSEC Connection to "+$name[$a]
    $connection = New-AzVirtualNetworkGatewayConnection `
        -Name $connectionNameA `
        -ResourceGroupName $ResourceGroupName `
        -Location $Location `
        -VirtualNetworkGateway1 $gateway `
        -LocalNetworkGateway2 $localNetworkGatewayA `
        -ConnectionType IPsec `
        -SharedKey $PreSharedKey `
        -IpsecPolicies $iPSecPolicy `
        -EnableBgp $True `
        -Force

    if($i -eq 0) # Do not create the interregion Local Network Gateway
    {
        # Create B
        "# Create Local Network Gateway to "+$name[$b]
        $localNetworkGatewayNameB = "LocalGateway"+$name[$i]+"To"+$name[$b]+"-lng"
        $connectionNameB = "Connection"+$name[$i]+"To"+$name[$b]+"-cn"
        $gatewayIPB = $gatewayPIP[$b].IpAddress
        $asnB= $asn[$b]
        $gatewayBGPPeerB = $gatewayBGPPeer[$b]
        $addressPrefixB = $gatewayBGPPeerB+"/32"
                    
        $localNetworkGatewayB = New-AzLocalNetworkGateway `
            -Name $localNetworkGatewayNameB `
            -ResourceGroupName $resourceGroupName `
            -Location $location `
            -GatewayIpAddress $gatewayIPB `
            -AddressPrefix $addressPrefixB `
            -Asn $asnB `
            -BgpPeeringAddress $gatewayBGPPeerB `
            -Force

        "# Create IPSEC Connection to "+$name[$b]
        $connection = New-AzVirtualNetworkGatewayConnection `
            -Name $connectionNameB `
            -ResourceGroupName $ResourceGroupName `
            -Location $Location `
            -VirtualNetworkGateway1 $gateway `
            -LocalNetworkGateway2 $localNetworkGatewayB `
            -ConnectionType IPsec `
            -SharedKey $PreSharedKey `
            -IpsecPolicies $iPSecPolicy `
            -EnableBgp $True `
            -Force
    }

    # Next
    $i++
}


### Code copied from Deployment\04a-VPNPeeringVNet2VNet.ps1

#BGP
$BGP = $True

#Encryption
$PreSharedKey = "SomeSecretKey" # This should come from a KeyVault

#Site1 details
$resourceGroupName1 = "GeoVPN-"+$name[1]+"-rg"
$location1 = $region[1]
$gatewayName1 = "Gateway-"+$name[1]+"-vpn"

#Site2 details
$resourceGroupName2 = "GeoVPN-"+$name[2]+"-rg"
$location2 = $region[2]
$gatewayName2 = "Gateway-"+$name[2]+"-vpn"

#ConnectionNames
$connectionName12 = "VNetGateway"+$name[1]+"To"+$name[2]+"-cn"
$connectionName21 = "VNetGateway"+$name[2]+"To"+$name[1]+"-cn"

#Encryption
$PreSharedKey = "SomeSecretKey" # This should come from a KeyVault

"Get Virtual Network Gateways"
$GW1 = Get-AzVirtualNetworkGateway -Name $gatewayName1 -ResourceGroupName $resourceGroupName1
$GW2 = Get-AzVirtualNetworkGateway -Name $gatewayName2 -ResourceGroupName $resourceGroupName2
   

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

