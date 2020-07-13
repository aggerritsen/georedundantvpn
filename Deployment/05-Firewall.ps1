#
### Deployment Firewall 
### Version 1.0
#

# Get Global variables
Import-Module -name .\Deployment\00-Variables.ps1 

# Only in HQ
$site = $name[0]
$location = $region[0]
$resourceGroupName = "GeoVPN-"+$name[0]+"-rg"

$vNetNameHub = "HubNetwork-"+$name[0]+"-vnet"
$firewallPIPName = "Firewall-"+$name[0]+"-pip"
$firewallNameHub = "FirewallHub-"+$name[0]+"-vm"

$vNetHub = Get-AzVirtualNetwork -ResourceGroupName $ResourceGroupName -Name $vNetNameHub
$firewallPIP = Get-AzPublicIpAddress -ResourceGroupName $ResourceGroupName -Name $firewallPIPName

$firewall = Get-AzFirewall -Name $firewallNameHub -ResourceGroupName $ResourceGroupName -ErrorAction SilentlyContinue
if(!$firewall)
{

    "Creating Firewall for site $site"
    $firewall = New-AzFirewall `
        -Name $firewallNameHub `
        -ResourceGroupName $ResourceGroupName `
        -Location $Location `
        -VirtualNetwork $vNetHub  `
        -PublicIpAddress @($firewallPIP) `
        -Zone 1 `
        -ThreatIntelMode Alert `
        -PrivateRange @("IANAPrivateRanges")
 
    "Creating Firewall Rules for site $site"
    $NetRule = New-AzFirewallNetworkRule `
        -Name "BypassAll" `
        -DestinationPort "*" `
        -Protocol "Any" `
        -SourceAddress "*" `
        -DestinationAddress "*"

    $NetRuleCollection = new-AzFirewallNetworkRuleCollection `
        -Name "BypassCollection" `
        -Priority 100 `
        -ActionType "Allow" `
        -rule $NetRule

    $firewall.AddNetworkRuleCollection($NetRuleCollection)
    Set-AzFirewall -AzureFirewall $firewall

}