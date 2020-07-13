#
### Deployment Virtual Network and Virtual Network Gateway Peering
### Version 1.0
#

# Get Global variables
Import-Module -name .\Deployment\00-Variables.ps1 


#
### Create Virtual Network Gateway Peering
#

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
    if($i -eq 1) {$a=2;$b=0}
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


    # Next
    $i++
}