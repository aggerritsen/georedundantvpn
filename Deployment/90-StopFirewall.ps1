#
### Stop Firewall 
### Version 1.0
#

# Get Global variables
Import-Module -name .\Deployment\00-Variables.ps1 

# Only in HQ
$site = $name[0]
$resourceGroupName = "GeoVPN-"+$name[0]+"-rg"
$firewallNameHub = "FirewallHub-"+$name[0]+"-vm"

$firewall = Get-AzFirewall -Name $firewallNameHub -ResourceGroupName $ResourceGroupName -ErrorAction SilentlyContinue
if($firewall)
{

    "Stopping Firewall for site $site"
    $firewall.Deallocate()
    Set-AzFirewall -AzureFirewall $firewall

}
else
{
    "Firewall $firewallNameHub not found"
}