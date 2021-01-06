#requires -version 2

<# Checks if the script is being ran as administrator. Having administrator rights would be useful in the log collection #>

Write-Host "Checking for elevated permissions..."
if (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Warning -Message "Running as non-admin. To facilitate proper log collection, please open the PowerShell console as an administrator and run this script again." -Debug
    Break
}
else {
    Write-Host "Code is running as administrator — go on executing the script..." -ForegroundColor Green
}

# List of computer names obtained from the domain controller
$Global:computerList = (Get-ADComputer -Filter *).Name

ForEach ($computer in $computerList){ 
    <# Global Variables #>
    $Global:ipaddress = (Get-ADComputer $computer -Properties *).IPv4Address
    $Global:outputDirectory = ".\" + $computer + "_" + $ipaddress + "\"
    $Global:outputFileName = $outputDirectory +"\" + $computer + "_" + $ipaddress + ".csv"
    $Global:hivelist = "HKCU", "HKLM", "HKCR", "HKU", "HKCC", "HKPD"  
    
    #Testing if a directory exists for the individual system exists. If not, create a directory.
    if(!(Test-Path -Path $outputDirectory)){
        New-Item -ItemType Directory -Force -Path $outputDirectory
    }

    <# The following function will extract all registry keys and export out to <hive root>.csv. #>
    Write-Host ("Starting registry extraction... - " + $computer ) -ForegroundColor Green
    ForEach($hive in $hivelist){
        if($computer -match $env:COMPUTERNAME){
            Get-ChildItem -recurse ($hive + ":\") -ErrorAction SilentlyContinue | export-csv ($outputDirectory + $hive + ".csv") -NoTypeInformation
        }
        else{
            try{
                Invoke-Command -ComputerName $computer -ScriptBlock {Get-ChildItem -recurse ($hive + ":\")} | export-csv ($outputDirectory + $hive + ".csv") -NoTypeInformation
            }
            catch [System.Security.SecurityException] {
                Write-Host ($_) -ForegroundColor Red
                Write-Host ("Please ensure that you are logged into an Administrator Account") -ForegroundColor Red
            }
        }
    }
    Write-Host ("Registry extraction for " + $computer + " has been completed.") -ForegroundColor Green

    # Stores all the log names into a variable "logNames"
    try{
        Write-Host ("Writing for: " + $computer) -ForegroundColor Green
        $logNames = Get-WinEvent -ListLog * -ComputerName $computer -ErrorVariable err -ea 0
    }
    catch [System.Diagnostics.Eventing.Reader.EventLogException]{ 
        Write-Host ($_) -ForegroundColor Red
        Write-Host ("Please ensure that the RPC service is up and running from your client or your firewall settings allow connections from the Domain Controller " + $computer) -ForegroundColor Red
    }
    catch [System.UnauthorizedAccessException]{
        Write-Host ($_) -ForegroundColor Red
        Write-Host ("Please ensure that you are logged into an Administrator Account") -ForegroundColor Red
    }

    # Used as an indicator for progress bar for tracking.
    $Count = $logNames.count
        
    
    $logs = $logNames | 
    ForEach-Object -Process{
        Write-Output "Starting log extraction..." -ForegroundColor Green
        # Creates a variable to get a log name from the list $logNames iteratively through "ForEach-Object" loop.
        $LogName = $_.logname

        # Line 72 - 75 is meant to create a "dashboard" for progress tracking.
        $Index = [array]::IndexOf($logNames,$_)
        $Percentage = $Index / $Count
        $Message = "Retrieving logs ($Index of $Count)"
        Write-Progress -Activity $Message -PercentComplete ($Percentage * 100) -CurrentOperation $LogName -Status 'Processing '
        
        #Hashtable is used to filter for the time range using StartTime and EndTime.
        Get-WinEvent -FilterHashtable @{
            LogName   = $LogName
            #StartTime can be modified accordingly through the Get-Date method. (AddDays/AddMonths/AddYears)
            StartTime = (Get-Date).AddDays(-1)
            EndTime = Get-Date
        } -ea 0
    }

    if($logs)
    {
        $Global:sortedLogs = $logs  |
        Sort-Object -Property timecreated |
        Select-Object -Property timecreated, id, logname, leveldisplayname, message

        Write-Progress -Activity 'Exporting' -PercentComplete 100 -CurrentOperation '...' -Completed -Status 'Done'
        $sortedLogs | Export-csv ($outputFileName)  -NoTypeInformation -Verbose
    }
}
