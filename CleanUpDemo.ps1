# CleanUpDemo.ps1

$Process1 = start-process powershell -argument "Deployment\99a-CleanupHQ.ps1" -Passthru -NoNewWindow
$Process2 = start-process powershell -argument "Deployment\99b-CleanupWest.ps1" -Passthru -NoNewWindow
$Process3 = start-process powershell -argument "Deployment\99c-CleanupNorth.ps1" -Passthru -NoNewWindow
$Process4 = start-process powershell -argument "Deployment\99d-CleanupNW.ps1" -Passthru -NoNewWindow

while($True)
{
    Start-Sleep 60
    $State = Get-Process -Id $Process1.Id -Erroraction SilentlyContinue
    if(!$State)
    {
        $State = Get-Process -Id $Process2.Id -Erroraction SilentlyContinue
        if(!$State)
        {
            $State = Get-Process -Id $Process3.Id -Erroraction SilentlyContinue
            if(!$State)
            {
                $State = Get-Process -Id $Process4.Id -Erroraction SilentlyContinue
                if(!$State)
                {
                    Break
                }
           }
        }
    }
    "Cleanup still running"
}

