Import-Module WebAdministration
cd IIS:/AppPools
$ApplicationPools = dir
$logfilepath="C:\Logs\AppPoolLog.txt"

function WriteToLogFile ($message)
{
$message +" - "+ (Get-Date).ToString() >> $logfilepath
}


$ApplicationPoolName = '.NET v4.5' #$item.Name
$ApplicationPoolStatus = Get-WebAppPoolState $ApplicationPoolName
if((Get-WebAppPoolState -Name $applicationPoolName).Value -ne 'Started')
{     
     Write-Host $ApplicationPoolName "found stopped."
     WriteToLogFile "$ApplicationPoolName Found Stopped"
     
     Start-WebAppPool -Name $ApplicationPoolName
     
     Write-Host $ApplicationPoolName "started."
     WriteToLogFile "$ApplicationPoolName Started"
}
