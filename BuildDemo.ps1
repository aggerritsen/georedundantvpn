# BuildDemo.ps1

. Deployment\01-Networks.ps1

#. Deployment\02-Gateways.ps1
$Process1 = start-process powershell -argument "Deployment\02a-GatewayHQ.ps1" -Passthru -NoNewWindow
$Process2 = start-process powershell -argument "Deployment\02b-GatewayWest.ps1" -Passthru -NoNewWindow
$Process3 = start-process powershell -argument "Deployment\02c-GatewayNorth.ps1" -Passthru -NoNewWindow

while($True)
{
    Start-Sleep 60
    $State = Get-Process -Id $Process1.Id -Erroraction SilentlyContinue
    if(!$State)
    {
        "Gateway Deployment HQ Ended"
        $State = Get-Process -Id $Process2.Id -Erroraction SilentlyContinue
        if(!$State)
        {
            "Gateway Deployment West Ended"
            $State = Get-Process -Id $Process3.Id -Erroraction SilentlyContinue
            if(!$State)
            {
                "Gateway Deployment North Ended"
                Break
           }
        }
    }
    "Gateway Deployment still running"
}

. Deployment\03-VNetPeering.ps1
. Deployment\04-VPNPeering.ps1
. Deployment\05-Machines.ps1
. Deployment\06-Firewall.ps1
. Deployment\07-FirewallRouting.ps1
. Deployment\08-MonitoringV1.ps1
. Deployment\09-MonitoringV2.ps1