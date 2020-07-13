#
### Start Firewall 
### Version 1.0
#

# Get Global variables
Import-Module -name .\Deployment\00-Variables.ps1 

# Only in HQ
$site = $name[0]
$resourceGroupName = "GeoVPN-"+$name[0]+"-rg"

$vNetNameHub = "HubNetwork-"+$name[0]+"-vnet"
$firewallPIPName = "Firewall-"+$name[0]+"-pip"
$firewallNameHub = "FirewallHub-"+$name[0]+"-vm"

$vNetHub = Get-AzVirtualNetwork -ResourceGroupName $ResourceGroupName -Name $vNetNameHub
$firewallPIP = Get-AzPublicIpAddress -ResourceGroupName $ResourceGroupName -Name $firewallPIPName

$firewall = Get-AzFirewall -Name $firewallNameHub -ResourceGroupName $ResourceGroupName -ErrorAction SilentlyContinue

if($firewall)
{

    "Starting Firewall for site $site"
    $firewall.Allocate($vNetHub,$firewallPIP)
    Set-AzFirewall -AzureFirewall $firewall

}