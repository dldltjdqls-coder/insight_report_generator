# run_daily.ps1
# This script is a wrapper to run generate_report.py daily via Windows Task Scheduler.
# It handles logging and generates an error report if execution fails.

$ErrorActionPreference = "Stop"
$Today = Get-Date -Format "yyyy-MM-dd"
$WorkDir = "c:\Users\tjdql\Desktop\insight_report_generator"

# Ensure we are in the correct working directory
Set-Location $WorkDir

# Create logs directory if it does not exist
$LogDir = Join-Path $WorkDir "reports\logs"
if (-not (Test-Path $LogDir)) {
    New-Item -ItemType Directory -Path $LogDir -Force | Out-Null
}

$LogFile = Join-Path $LogDir "${Today}_run.log"
$ErrorFile = Join-Path $WorkDir "reports\${Today}_error.md"

# Detect Anaconda python path or fallback to system python
$PythonPath = "C:\Users\tjdql\anaconda3\python.exe"
if (-not (Test-Path $PythonPath)) {
    $PythonPath = "python"
}

try {
    Write-Output "[$Today] Starting Daily Insight Report generation..." > $LogFile
    
    # Run the generator script and redirect both stdout and stderr to the daily log file
    & $PythonPath generate_report.py >> $LogFile 2>&1
    
    # Check the exit code of python
    if ($LASTEXITCODE -ne 0) {
        throw "generate_report.py failed with exit code $LASTEXITCODE. Please check the log file."
    }
    
    Write-Output "[$Today] Daily Insight Report generated successfully." >> $LogFile
} catch {
    # Extract the error message and callstack
    $ErrorMsg = $_.Exception.Message
    $ErrorDetails = $_.ScriptStackTrace
    
    # Append the last 15 lines of the log if it exists to give contextual error details
    $LogTail = ""
    if (Test-Path $LogFile) {
        $LogTail = Get-Content $LogFile -Tail 15 | Out-String
    }
    
    # Create the markdown error report
    $ErrorContent = @"
# ⚠️ Daily Report Generation Error - $Today

An error occurred during the daily automated execution of the Investment/Industry Insight Report.

## 🔴 Error Message
```
$ErrorMsg
```

## 📋 PowerShell Execution Details
```
$ErrorDetails
```

## 🔍 Log Tail (Last 15 Lines)
```
$LogTail
```

---
*Please check the full execution log for debugging at:*
*Link:* [reports/logs/${Today}_run.log](file:///$WorkDir/reports/logs/${Today}_run.log)
"@

    # Save the error report
    Set-Content -Path $ErrorFile -Value $ErrorContent -Encoding utf8
    Write-Output "[$Today] Error occurred. Saved error details to $ErrorFile" >> $LogFile
}
