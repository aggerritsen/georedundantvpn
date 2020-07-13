#
### BGP Monitoting
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


Function AddBGPMonitor 
{

    $Prefix = $args[0]
    $Name = $args[1]
    $SourceID = $args[2]
    $DestinationIP = $args[3]
    $WorkSpaceID = $args[4]
    $RTT = $args[5]
    $NetworkWatcher = $args[6].Name 
    $ResourceGroupName = $args[6].ResourceGroupName 
    $Location = $args[7]

    $EndPointName = $Name+"-endp"
    $TestConfiguratieName = $Name+"-tcfg"
    $TestGroupName = $Name+"-tgrp"
    $ConnectionMonitorName = $Name+"-cmon"

    $DestinationEndPoint = New-AzNetworkWatcherConnectionMonitorEndpointObject `
        -Name $EndPointName `
        -Address $DestinationIP

    $SourceEndPoint = New-AzNetworkWatcherConnectionMonitorEndpointObject `
        -ResourceID $SourceID

    $ProtocolConfiguration = New-AzNetworkWatcherConnectionMonitorProtocolConfigurationObject `
        -TcpProtocol `
        -Port 179

    $TestConfiguration = New-AzNetworkWatcherConnectionMonitorTestConfigurationObject `
        -Name $TestConfiguratieName `
        -TestFrequencySec 30 `
        -ProtocolConfiguration $ProtocolConfiguration `
        -SuccessThresholdChecksFailedPercent 50 `
        -SuccessThresholdRoundTripTimeMs $RTT

    $TestGroup = New-AzNetworkWatcherConnectionMonitorTestGroupObject `
        -Name $TestGroupName `
        -TestConfiguration $TestConfiguration `
        -Source $SourceEndPoint `
        -Destination $DestinationEndpoint

    $Output = New-AzNetworkWatcherConnectionMonitorOutputObject `
        -OutputType Workspace `
        -WorkspaceResourceId $WorkSpaceID


    # Create or overwrite connection monitor

    $Monitor = New-AzNetworkWatcherConnectionMonitor `
        -NetworkWatcherName $NetworkWatcher `
        -ResourceGroupName $ResourceGroupName `
        -Name $ConnectionMonitorName `
        -TestGroup $TestGroup `
        -Output $Output `
        -Force

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
        -Severity 2 `
        -DisableRule

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
        -Severity 1


    Return $Alert

}


# Monitoring Variables
$workspaceName = "GeoVPN"
$resourceGroupName = "GeoVPN-$Site0-rg"
$location = "westeurope"

$networkWatcherNameWE = "NetworkWatcherWE"
$networkWatcherNameNE = "NetworkWatcherNE"
$ActionGroupName = "BGPMonitoring-agrp"
$ShortName = "GeoVPN"

$failThreshold = 50 # Percentage
$pingThreshold = 30 # Milliseconds


"Get or Create Log Analytics Workspace"
$workspace = (Get-AzOperationalInsightsWorkspace -ResourceGroupName $resourceGroupName `
    -ErrorAction SilentlyContinue) `
    | Where-Object {$_.Name -match $workspaceName}

if($workspace)
{
  $workspaceID=$workspace.ResourceId
}
else 
{
    $workspaceName = "GeoVPN-"+(Get-Random -Minimum 100000 -Maximum 999999)+"-law"

    $workspace = New-AzOperationalInsightsWorkspace `
        -ResourceGroupName $resourceGroupName `
        -Location $location `
        -Name $workspaceName `
        -Sku pergb2018

    $workspaceID=$workspace.ResourceId
}


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



"Creating Monitoring for - $Site0 [0]"
$site = $name[0]
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


"Create Monitor for BGP Peer $Site0-$Site1"
$monitorName = "V2-$Site0-$Site1-cmon"
$destinationIP = "10.1.0.126"

$connectionMonitor = AddBGPMonitor `
    $site `
    $monitorName `
    $sourceID `
    $destinationIP `
    $workspaceID `
    $pingThreshold `
    $networkWatcherWE `
    $location

$connectionMonitor

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
$monitorName = "V2-$Site0-$Site2-cmon"
$destinationIP = "10.2.0.126"

$connectionMonitor = AddBGPMonitor `
    $site `
    $monitorName `
    $sourceID `
    $destinationIP `
    $workspaceID `
    $pingThreshold `
    $networkWatcherWE `
    $location

$connectionMonitor

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



"Creating Monitoring for - $Site1 [1]"
$site = $name[1]
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
$monitorName = "V2-$Site1-$Site0-cmon"
$destinationIP = "10.0.0.126"

$connectionMonitor = AddBGPMonitor `
    $site `
    $monitorName `
    $sourceID `
    $destinationIP `
    $workspaceID `
    $pingThreshold `
    $networkWatcherWE `
    $location

$connectionMonitor

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
$monitorName = "V2-$Site1-$Site2-cmon"
$destinationIP = "10.2.0.126"

$connectionMonitor = AddBGPMonitor `
    $site `
    $monitorName `
    $sourceID `
    $destinationIP `
    $workspaceID `
    $pingThreshold `
    $networkWatcherWE `
    $location

$connectionMonitor

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



"Creating Monitoring for - $Site2 [2]"
$site = $name[2]
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


"Create Monitor for BGP Peer $Site2-$Site0"
$monitorName = "V2-$Site2-$Site0-cmon"
$destinationIP = "10.0.0.126"

$connectionMonitor = AddBGPMonitor `
    $site `
    $monitorName `
    $sourceID `
    $destinationIP `
    $workspaceID `
    $pingThreshold `
    $networkWatcherNE `
    $location

$connectionMonitor

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


"Create Monitor for BGP Peer $Site2-$Site1"
$monitorName = "V2-$Site2-$Site1-cmon"
$destinationIP = "10.1.0.126"

$connectionMonitor = AddBGPMonitor `
    $site `
    $monitorName `
    $sourceID `
    $destinationIP `
    $workspaceID `
    $pingThreshold `
    $networkWatcherNE `
    $location

$connectionMonitor

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