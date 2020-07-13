#
### Deployment Virtual Machines
### Version 1.0
#

# Get Global variables
Import-Module -name .\Deployment\00-Variables.ps1 


# This should come from a Key Vault
$securePasswordString = ConvertTo-SecureString "AzurePassword1234" -AsPlainText -Force
$userCredential = New-Object System.Management.Automation.PSCredential ("AzureUser", $securePasswordString)

$i=0
While($i -lt 3)
{
    
    $site = $name[$i]
    $location = $region[$i]
    $resourceGroupName = "GeoVPN-"+$name[$i]+"-rg"

    $vNetNameHub = "HubNetwork-"+$name[$i]+"-vnet"
    $vmNameHub = "JumphostHub-"+$name[$i]+"-vm"
    $defaultPrefixHub = "10."+$i+".0.0/26"

    $jumphostHubPIPName = "JumpHostHub-"+$name[$i]+"-pip"


    $vm = Get-AzVM -Name $vmNameHub -ResourceGroupName $ResourceGroupName -ErrorAction SilentlyContinue
    if(!$vm) {

        "Create Virtual Machine in Hub for $site"
        New-AzVM `
            -ResourceGroupName $ResourceGroupName `
            -Location $Location `
            -Name $VMnameHub `
            -Credential $userCredential `
            -Image "RHEL" `
            -Size Standard_B1ms `
            -VirtualNetworkName $vNetNameHub `
            -SubnetName "DefaultSubnet" `
            -SubnetAddressPrefix $defaultPrefixHub `
            -PublicIpAddressName $jumphostHubPIPName
        
    }
    
    "Set Network Security Group"
    Get-AzNetworkSecurityGroup `
        -Name $VMnameHub `
        -ResourceGroupName $ResourceGroupName | 
        Add-AzNetworkSecurityRuleConfig `
        -Name AllowAllOutbound `
        -Description "Enabled for monitoring" `
        -Access Allow `
        -Protocol Tcp `
        -Direction outbound `
        -Priority 1000 `
        -SourceAddressPrefix * `
        -SourcePortRange * `
        -DestinationAddressPrefix * `
        -DestinationPortRange * | `
        Set-AzNetworkSecurityGroup
    

    "Get or Install NetworkWatcherAgent"
    $extention = Get-AzVMExtension `
        -ResourceGroupName $ResourceGroupName `
        -VMName $VMnameHub `
        -Name "NetworkWatcherAgent" `
        -ErrorAction SilentlyContinue

    if(!$extention)
    {
        Set-AzVMExtension `
            -ResourceGroupName $ResourceGroupName `
            -Location $Location `
            -VMName $VMnameHub `
            -Name "NetworkWatcherAgent" `
            -Publisher "Microsoft.Azure.NetworkWatcher" `
            -Type "NetworkWatcherAgentLinux" `
            -TypeHandlerVersion "1.4"
    }


    $vNetNameSpoke = "SpokeNetwork-"+$name[$i]+"-vnet"
    $vmNameSpoke = "JumphostSpoke-"+$name[$i]+"-vm"
    $defaultPrefixSpoke = "10."+$i+".1.0/26"
    $jumphostSpokePIPName = "JumpHostSpoke-"+$name[$i]+"-pip"

    $vm = Get-AzVM -Name $vmNameSpoke -ResourceGroupName $ResourceGroupName -ErrorAction SilentlyContinue
    if(!$vm) {

        "Create Virtual Machine in Spoke for $site"

        New-AzVM `
            -ResourceGroupName $ResourceGroupName `
            -Location $Location `
            -Name $VMnameSpoke `
            -Credential $userCredential `
            -Image "RHEL" `
            -Size Standard_B1ms `
            -VirtualNetworkName $vNetNameSpoke `
            -SubnetName "DefaultSubnet" `
            -SubnetAddressPrefix $defaultPrefixSpoke  `
            -PublicIpAddressName $jumphostSpokePIPName
    
    }


    # Next
    $i++
}