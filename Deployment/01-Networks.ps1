#
### Deployment Networks
### Version 1.0
#

# Get Global variables
Import-Module -name .\Deployment\00-Variables.ps1 

$i=0
While($i -lt 3)
{
    "Preset variables"
    $site = $name[$i]
    $location = $region[$i]
    $resourceGroupName = "GeoVPN-"+$name[$i]+"-rg"

    $routeTableNameHub = "HubRouteTable-"+$name[$i]+"-rt"
    $vNetNameHub = "HubNetwork-"+$name[$i]+"-vnet"
    $vNetPrefixHub = "10."+$i+".0.0/24"
    $defaultPrefixHub = "10."+$i+".0.0/26"
    $gatewayPrefixHub = "10."+$i+".0.64/26"
    $firewallPrefixHub = "10."+$i+".0.128/26"

    $routeTableNameSpoke = "SpokeRouteTable-"+$name[$i]+"-rt"
    $vNetNameSpoke = "SpokeNetwork-"+$name[$i]+"-vnet"
    $vNetPrefixSpoke = "10."+$i+".1.0/24"
    $defaultPrefixSpoke = "10."+$i+".1.0/26"

    $gatewayPIPName = "Gateway-"+$name[$i]+"-pip"
    $firewallPIPName = "Firewall-"+$name[$i]+"-pip"
    $jumphostHubPIPName = "JumpHostHub-"+$name[$i]+"-pip"
    $jumphostSpokePIPName = "JumpHostSpoke-"+$name[$i]+"-pip"

    #
    ### Create Resource Group
    #

    "Create Resource Group - $site"
    New-AzResourceGroup `
        -name $ResourceGroupName `
        -location $Location `
        -Force `
        -WarningAction silentlyContinue


    #
    ### Create Hub
    #

    "Create RouteTable for Hub - $site"
    $routeTableHub = New-AzRouteTable `
        -Name $routeTableNameHub `
        -ResourceGroupName $ResourceGroupName `
        -location $Location `
        -Force `
        -WarningAction silentlyContinue

    "Create Subnets Configuration for Hub - $site"
    $defaultSubnetHub = New-AzVirtualNetworkSubnetConfig `
        -Name "DefaultSubnet" `
        -AddressPrefix $defaultPrefixHub `
        -RouteTable $routeTableHub  `
        -WarningAction silentlyContinue

    $gatewaySubnetHub = New-AzVirtualNetworkSubnetConfig `
        -Name "GatewaySubnet" `
        -AddressPrefix $gatewayPrefixHub `
        -RouteTable $routeTableHub `
        -WarningAction silentlyContinue

        "Create Virtual Network for Hub - $site"
        if($i -eq 0)
        {
            $firewallSubnetHub = New-AzVirtualNetworkSubnetConfig `
                -Name "AzureFirewallSubnet" `
                -AddressPrefix $firewallPrefixHub `
                -ServiceEndpoint "Microsoft.Servicebus", "Microsoft.Storage" `
                -WarningAction silentlyContinue
    
            New-AzVirtualNetwork `
                -Name $vNetNameHub `
                -ResourceGroupName $ResourceGroupName `
                -Location $Location `
                -AddressPrefix $vNetPrefixHub `
                -Subnet $defaultSubnetHub, $gatewaySubnetHub, $firewallSubnetHub `
                -Force
        }
        else 
        {
            "Create Virtual Network for Hub - $site"
            New-AzVirtualNetwork `
                -Name $vNetNameHub `
                -ResourceGroupName $ResourceGroupName `
                -Location $Location `
                -AddressPrefix $vNetPrefixHub `
                -Subnet $defaultSubnetHub, $gatewaySubnetHub `
                -Force
        }

    #    
    ### Create Spoke
    #

    "Create RouteTable for Spoke - $site"
    $routeTableSpoke = New-AzRouteTable `
        -Name $routeTableNameSpoke `
        -ResourceGroupName $ResourceGroupName `
        -location $Location `
        -Force `
        -WarningAction silentlyContinue

    "Create Subnets Configuration for Spoke - $site"
    $defaultSubnetSpoke = New-AzVirtualNetworkSubnetConfig `
        -Name "DefaultSubnet" `
        -AddressPrefix $defaultPrefixSpoke `
        -RouteTable $routeTableSpoke  `
        -WarningAction silentlyContinue


    "Create Virtual Network for Spoke - $site"
    New-AzVirtualNetwork `
        -Name $vNetNameSpoke `
        -ResourceGroupName $ResourceGroupName `
        -Location $Location `
        -AddressPrefix $vNetPrefixSpoke `
        -Subnet $defaultSubnetSpoke `
        -Force 

        
    #
    ### Create Public IP Addresses
    #

    "Create Public IP Addresses - $site"
    New-AzPublicIpAddress `
        -Name $gatewayPIPName `
        -ResourceGroupName $ResourceGroupName `
        -Location $Location `
        -AllocationMethod Static `
        -Sku Standard `
        -IdleTimeoutInMinutes 30 `
        -WarningAction silentlyContinue `
        -Force

    New-AzPublicIpAddress `
        -Name $firewallPIPName `
        -ResourceGroupName $ResourceGroupName `
        -Location $Location `
        -AllocationMethod Static `
        -Sku Standard `
        -IdleTimeoutInMinutes 30 `
        -WarningAction silentlyContinue `
        -Force

    New-AzPublicIpAddress `
        -Name $jumphostHubPIPName `
        -ResourceGroupName $ResourceGroupName `
        -Location $Location `
        -AllocationMethod Static `
        -Sku Standard `
        -IdleTimeoutInMinutes 30 `
        -WarningAction silentlyContinue `
        -Force

    New-AzPublicIpAddress `
        -Name $jumphostSpokePIPName `
        -ResourceGroupName $ResourceGroupName `
        -Location $Location `
        -AllocationMethod Static `
        -Sku Standard `
        -IdleTimeoutInMinutes 30 `
        -WarningAction silentlyContinue `
        -Force

    # Next
    $i++
}
