#
### BGP Monitoring
### Version 1.0
#

#
### Deployment Virtual Network Gateways
### Version 1.0
#

# Get Global variables
Import-Module -name .\Deployment\00-Variables.ps1 
$Site0 = $name[0]
$Site1 = $name[1]
$Site2 = $name[2]

Function AddBGPMonitorV1 
{

    $NetworkWatcher = $args[0]
    $Name = $args[1]
    $SourceID = $args[2]
    $DestinationIP = $args[3]


    $Monitor = Get-AzNetworkWatcherConnectionMonitor `
        -NetworkWatcher $networkWatcher `
        -Name $Name `
        -ErrorAction SilentlyContinue

    if($Monitor)
    {
        Stop-AzNetworkWatcherConnectionMonitor `
            -NetworkWatcher $networkWatcher `
            -Name $Name
    }

    $Monitor = New-AzNetworkWatcherConnectionMonitor `
        -NetworkWatcher $networkWatcher `
        -Name $Name `
        -SourceResourceId $sourceID `
        -MonitoringIntervalInSeconds 30 `
        -DestinationPort 179 `
        -DestinationAddress $DestinationIP `
        -Force

    Start-AzNetworkWatcherConnectionMonitor `
        -NetworkWatcher $networkWatcher `
        -Name $Name

    Return $Monitor
}


Function AddRTTAlert
{
        
    $ActionGroupName = $args[0]
    $ResourceGroupName = $args[1]
    $ShortName = $args[2]
    $Threshold = $args[3]
    $MonitorName = $args[4]
    $Monitor = $args[5]

    $RuleDescription = "RTT for "+$MonitorName+" exceeds "+$Threshold+" ms."

    # Create or Update ActionGroup

    $Email1 = New-AzActionGroupReceiver `
        -Name "Cloud Operations Mail" `
        -EmailReceiver `
        -EmailAddress "joedoe@contoso.com"

    $SMS1 = New-AzActionGroupReceiver `
        -Name "Cloud Operations SMS" `
        -SmsReceiver `
        -CountryCode "31" `
        -PhoneNumber "0123456789"

    $Action = Set-AzActionGroup -Name $ActionGroupName -ResourceGroup $ResourceGroupName -ShortName $ShortName -Receiver $Email1, $SMS1

    # Create or Update Action Rules

    $ActionGroup = New-AzActionGroup -ActionGroupId $Action.id
    $AlertRuleName = $MonitorName+"-rule"
    $TargetResourceId = $Monitor.Id

    $Criteria = New-AzMetricAlertRuleV2Criteria `
        -MetricName "RoundTripTimeMs" `
        -MetricNameSpace "Microsoft.Network/networkWatchers/connectionMonitors" `
        -TimeAggregation Average `
        -Operator GreaterThan `
        -Threshold $Threshold

    $Alert = Add-AzMetricAlertRuleV2 `
        -Name $AlertRuleName `
        -ResourceGroupName $ResourceGroupName `
        -WindowSize 00:05:00 `
        -Frequency 00:01:00 `
        -TargetResourceId $TargetResourceId `
        -Condition $Criteria `
        -ActionGroup $ActionGroup `
        -Description $RuleDescription `
        -Severity 2

    Return $Alert
}


Function AddFailAlert
{
        
    $ActionGroupName = $args[0]
    $ResourceGroupName = $args[1]
    $ShortName = $args[2]
    $Threshold = $args[3]
    $MonitorName = $args[4]
    $Monitor = $args[5]

    $RuleDescription = "Check on "+$MonitorName+" failed for more than "+$Threshold+" percent."

    # Create or Update ActionGroup

    $Email1 = New-AzActionGroupReceiver `
        -Name "Cloud Operations Mail" `
        -EmailReceiver `
        -EmailAddress "joedoe@contoso.com"

    $SMS1 = New-AzActionGroupReceiver `
        -Name "Cloud Operations SMS" `
        -SmsReceiver `
        -CountryCode "31" `
        -PhoneNumber "0123456789"

    $Action = Set-AzActionGroup -Name $ActionGroupName -ResourceGroup $ResourceGroupName -ShortName $ShortName -Receiver $Email1, $SMS1

    # Create or Update Action Rules

    $ActionGroup = New-AzActionGroup -ActionGroupId $Action.id
    $AlertRuleName = $MonitorName+"Fail-rule"
    $TargetResourceId = $Monitor.Id

    $Criteria = New-AzMetricAlertRuleV2Criteria `
        -MetricName "ChecksFailedPercent" `
        -MetricNameSpace "Microsoft.Network/networkWatchers/connectionMonitors" `
        -TimeAggregation Average `
        -Operator GreaterThan `
        -Threshold $Threshold

    $Alert = Add-AzMetricAlertRuleV2 `
        -Name $AlertRuleName `
        -ResourceGroupName $ResourceGroupName `
        -WindowSize 00:05:00 `
        -Frequency 00:01:00 `
        -TargetResourceId $TargetResourceId `
        -Condition $Criteria `
        -ActionGroup $ActionGroup `
        -Description $RuleDescription `
        -Severity 1 `
        -DisableRule

    Return $Alert
}

# Monitoring Variables
$Site0 = $name[0]
$Site1 = $name[1]
$Site2 = $name[2]

$workspaceName = "GeoVPN"
$resourceGroupName = "GeoVPN-$Name[0]-rg"
$location = "westeurope"

$networkWatcherNameWE = "NetworkWatcherWE"
$networkWatcherNameNE = "NetworkWatcherNE"
$ActionGroupName = "BGPMonitoring-agrp"
$ShortName = "GeoVPN"

$failThreshold = 50 # Percentage
$pingThreshold = 30 # Milliseconds


"Get or Create the Network Watchers"
$NetworkWatcherWE = Get-AzNetworkWatcher -Location westeurope -Erroraction SilentlyContinue
if (!$NetworkWatcherWE)
{
    $NetworkWatcherWE = New-AzNetworkWatcher `
        -Name $NetworkWatcherNameWE `
        -ResourceGroupName $ResourceGroupName `
        -Location westeurope
}


$NetworkWatcherNE = Get-AzNetworkWatcher -Location northeurope -Erroraction SilentlyContinue
if (!$NetworkWatcherNE)
{
    $NetworkWatcherNE = New-AzNetworkWatcher `
        -Name $NetworkWatcherNameNE `
        -ResourceGroupName $ResourceGroupName `
        -Location northeurope

}

"Creating V1 Monitoring for - $Name[0]"
$location = $region[0]
$resourceGroupName = "GeoVPN-"+$name[0]+"-rg"
$vmNameHub = "JumphostHub-"+$name[0]+"-vm"

"Get Virtual Machine Dependencies"
$VM = Get-AzVM `
    -ResourceGroupName $resourceGroupName `
    -Name $vmNameHub

$sourceID = $VM.Id

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

"Create V1 Monitor for BGP Peer $Site0-$Site1"
$monitorName = "V1-$Site0-$Site1-cmon"
$destinationIP = "10.1.0.126"

$connectionMonitor = AddBGPMonitorV1 `
    $networkWatcherWE `
    $monitorName `
    $sourceID `
    $destinationIP

$alertRule = AddRTTAlert `
    $actionGroupName `
    $resourceGroupName `
    $shortName `
    $pingThreshold `
    $monitorName `
    $connectionMonitor

$alertRule

$alertRule = AddFailAlert `
    $ActionGroupName `
    $resourceGroupName `
    $shortName `
    $failThreshold `
    $monitorName `
    $connectionMonitor

$alertRule

"Create Monitor for BGP Peer $Site0-$Site2"
$monitorName = "V1-$Site0-$Site2-cmon"
$destinationIP = "10.2.0.126"

$connectionMonitor = AddBGPMonitorV1 `
    $networkWatcherWE `
    $monitorName `
    $sourceID `
    $destinationIP


$alertRule = AddRTTAlert `
    $actionGroupName `
    $resourceGroupName `
    $shortName `
    $pingThreshold `
    $monitorName `
    $connectionMonitor

$alertRule

$alertRule = AddFailAlert `
    $ActionGroupName `
    $resourceGroupName `
    $shortName `
    $failThreshold `
    $monitorName `
    $connectionMonitor

$alertRule



"Creating V1 Monitoring for - $Site1"
$location = $region[1]
$resourceGroupName = "GeoVPN-"+$name[1]+"-rg"
$vmNameHub = "JumphostHub-"+$name[1]+"-vm"

"Get Virtual Machine Dependencies"
$VM = Get-AzVM `
    -ResourceGroupName $resourceGroupName `
    -Name $vmNameHub

$sourceID = $VM.Id

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

"Create Monitor for BGP Peer $Site1-$Site0"
$monitorName = "V1-$Site1-$Site0-cmon"
$destinationIP = "10.0.0.126"

$connectionMonitor = AddBGPMonitorV1 `
    $networkWatcherWE `
    $monitorName `
    $sourceID `
    $destinationIP

$alertRule = AddRTTAlert `
    $actionGroupName `
    $resourceGroupName `
    $shortName `
    $pingThreshold `
    $monitorName `
    $connectionMonitor

$alertRule

$alertRule = AddFailAlert `
    $ActionGroupName `
    $resourceGroupName `
    $shortName `
    $failThreshold `
    $monitorName `
    $connectionMonitor

$alertRule

"Create Monitor for BGP Peer $Site1-$Site2"
$monitorName = "V1-$Site1-$Site2-cmon"
$destinationIP = "10.2.0.126"

$connectionMonitor = AddBGPMonitorV1 `
    $networkWatcherWE `
    $monitorName `
    $sourceID `
    $destinationIP

$alertRule = AddRTTAlert `
    $actionGroupName `
    $resourceGroupName `
    $shortName `
    $pingThreshold `
    $monitorName `
    $connectionMonitor

$alertRule

$alertRule = AddFailAlert `
    $ActionGroupName `
    $resourceGroupName `
    $shortName `
    $failThreshold `
    $monitorName `
    $connectionMonitor

$alertRule



"Creating V1 Monitoring for - $Site2"
$location = $region[2]
$resourceGroupName = "GeoVPN-"+$name[2]+"-rg"
$vmNameHub = "JumphostHub-"+$name[2]+"-vm"

"Get Virtual Machine Dependencies"
$VM = Get-AzVM `
    -ResourceGroupName $resourceGroupName `
    -Name $vmNameHub

$sourceID = $VM.Id

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


"Create Monitor for BGP Peer $Site2-$Site1"
$monitorName = "V1-$Site2-$Site1-cmon"
$destinationIP = "10.1.0.126"

$connectionMonitor = AddBGPMonitorV1 `
    $networkWatcherNE `
    $monitorName `
    $sourceID `
    $destinationIP

$alertRule = AddRTTAlert `
    $actionGroupName `
    $resourceGroupName `
    $shortName `
    $pingThreshold `
    $monitorName `
    $connectionMonitor

$alertRule

$alertRule = AddFailAlert `
    $ActionGroupName `
    $resourceGroupName `
    $shortName `
    $failThreshold `
    $monitorName `
    $connectionMonitor

$alertRule

"Create Monitor for BGP Peer $Site2-$Site0"
$monitorName = "V1-$Site2-$Site0-cmon"
$destinationIP = "10.0.0.126"

$connectionMonitor = AddBGPMonitorV1 `
    $networkWatcherNE `
    $monitorName `
    $sourceID `
    $destinationIP


$alertRule = AddRTTAlert `
    $actionGroupName `
    $resourceGroupName `
    $shortName `
    $pingThreshold `
    $monitorName `
    $connectionMonitor

$alertRule

$alertRule = AddFailAlert `
    $ActionGroupName `
    $resourceGroupName `
    $shortName `
    $failThreshold `
    $monitorName `
    $connectionMonitor

$alertRule