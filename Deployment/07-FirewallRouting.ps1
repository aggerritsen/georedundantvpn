#
### Fireall Routing
### Version 1.0
#

# Get Global variables
Import-Module -name .\Deployment\00-Variables.ps1 

$i=0
"Preset variables"
$resourceGroupName = "GeoVPN-"+$name[$i]+"-rg"
$vNetPrefixHub = "10."+$i+".0.0/24"
$vNetPrefixSpoke = "10."+$i+".1.0/24"
$routeTableNameHub = "HubRouteTable-"+$name[$i]+"-rt"
$routeTableNameSpoke = "SpokeRouteTable-"+$name[$i]+"-rt"
$firewallIP = "10."+$i+".0.132"

"Set Hub Firewall Routes"
$routeTableHub = Get-AzRouteTable `
    -Name $routeTableNameHub `
    -ResourceGroupName $ResourceGroupName

Add-AzRouteConfig `
    -RouteTable $routeTableHub `
    -Name "ToSpoke" `
    -AddressPrefix $vNetPrefixSpoke `
    -NextHopType "VirtualAppliance" `
    -NextHopIpAddress $FirewallIP `
    -ErrorAction SilentlyContinue

Add-AzRouteConfig `
    -RouteTable $routeTableHub `
    -Name "ToPhantom" `
    -AddressPrefix "10.3.0.0/24" `
    -NextHopType "VirtualAppliance" `
    -NextHopIpAddress $FirewallIP `
    -ErrorAction SilentlyContinue

Set-AzRouteTable -RouteTable $routeTableHub


"Set Spoke Firewall Routes"
$routeTableSpoke = Get-AzRouteTable `
    -Name $routeTableNameSpoke `
    -ResourceGroupName $ResourceGroupName

Add-AzRouteConfig `
    -RouteTable $routeTableSpoke `
    -Name "DefaultRoute" `
    -AddressPrefix "0.0.0.0/0" `
    -NextHopType "VirtualAppliance" `
    -NextHopIpAddress $FirewallIP `
    -ErrorAction SilentlyContinue

Add-AzRouteConfig `
    -RouteTable $routeTableSpoke `
    -Name "ToHub" `
    -AddressPrefix $vNetPrefixHub `
    -NextHopType "VirtualAppliance" `
    -NextHopIpAddress $FirewallIP `
    -ErrorAction SilentlyContinue

$routeTableSpoke.DisableBgpRoutePropagation
Set-AzRouteTable -RouteTable $routeTableSpoke