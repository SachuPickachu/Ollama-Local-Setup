param(
    [switch]$Verbose,
    [switch]$NoLogging
)

# Load common functions and environment
$scriptPath = Split-Path $MyInvocation.MyCommand.Path -Parent
$projectRoot = Split-Path $scriptPath -Parent
$functionsPath = Join-Path $projectRoot "config\functions.ps1"

if (Test-Path $functionsPath) {
    . $functionsPath
} else {
    Write-Error "Functions library not found at: $functionsPath"
    exit 1
}

# Initialize logging (unless disabled)
if (-not $NoLogging) {
    if (-not (Initialize-Logging -ScriptName "stop-webui" -LogLevel $(if ($Verbose) { "DEBUG" } else { "INFO" }))) {
        Write-Error "Failed to initialize logging"
        exit 1
    }
}

# Load and validate environment
if (-not (Load-Environment)) {
    Write-Log "Failed to load environment configuration" "ERROR"
    exit 1
}

if (-not (Test-Environment)) {
    Write-Log "Environment validation failed" "ERROR"
    exit 1
}

Write-Log "Starting Open WebUI service shutdown process" "INFO"

# Helper function for colored output
function Write-Status {
    param([string]$Message, [string]$Color = "White")
    Write-Host $Message -ForegroundColor $Color
}

try {
    Write-Status "Stopping Open WebUI Service..." "Yellow"
    Write-Log "Open WebUI shutdown process initiated" "INFO"

    # Find Open WebUI processes (look for actual open-webui processes, not Python)
    Write-Log "Searching for Open WebUI processes" "INFO"
    $webuiProcesses = Get-Process | Where-Object {
        $_.ProcessName -like "*open-webui*"
    }
    
    if (-not $webuiProcesses) {
        Write-Log "No open-webui processes found, checking for Python processes as fallback" "WARN"
        # Fallback: check for Python processes that might be Open WebUI
        $webuiProcesses = Get-Process | Where-Object {
            $_.ProcessName -like "*python*" -and 
            $_.ProcessName -ne "pythonw"
        }
    }
    
    if ($webuiProcesses) {
        Write-Status "Found $($webuiProcesses.Count) Open WebUI process(es)" "Green"
        Write-Log "Found $($webuiProcesses.Count) Open WebUI processes to stop" "INFO"
        
        foreach ($process in $webuiProcesses) {
            Write-Status "Process: $($process.ProcessName) (PID: $($process.Id))" "Cyan"
            Write-Log "Stopping process: $($process.ProcessName) (PID: $($process.Id))" "INFO"
            
            # Try graceful shutdown first
            Write-Status "Attempting graceful shutdown for PID $($process.Id)..." "Yellow"
            Write-Log "Attempting graceful shutdown for PID $($process.Id)" "INFO"
            
            try {
                # Send graceful shutdown signal
                $process.CloseMainWindow() | Out-Null
                
                # Wait for graceful shutdown with much longer timeout
                $gracefulTimeout = [int]$env:WEB_UI_STARTUP_TIMEOUT  # Use the same timeout as startup
                $elapsed = 0
                Write-Log "Waiting up to $gracefulTimeout seconds for graceful shutdown" "INFO"
                
                while ($process.HasExited -eq $false -and $elapsed -lt $gracefulTimeout) {
                    Start-Sleep -Seconds 2  # Check every 2 seconds instead of every 1 second
                    $elapsed += 2
                    if ($elapsed % 10 -eq 0) {  # Show progress every 10 seconds
                        Write-Status "Waiting for graceful shutdown... ($elapsed/$gracefulTimeout seconds)" "Yellow"
                        Write-Log "Graceful shutdown in progress: $elapsed/$gracefulTimeout seconds" "INFO"
                    }
                }
                
                # Check if process exited gracefully
                if ($process.HasExited) {
                    Write-Status "Process $($process.Id) stopped gracefully after $elapsed seconds" "Green"
                    Write-Log "Process $($process.Id) stopped gracefully after $elapsed seconds" "INFO"
                } else {
                    # Force kill if still running after timeout
                    Write-Status "Graceful shutdown timeout after $gracefulTimeout seconds, force stopping PID $($process.Id)..." "Red"
                    Write-Log "Graceful shutdown timeout, force stopping PID $($process.Id)" "WARN"
                    Stop-Process -Id $process.Id -Force
                    Start-Sleep -Seconds 3  # Give it time to fully terminate
                }
                
            } catch {
                Write-Log "Error during graceful shutdown of process $($process.Id): $($_.Exception.Message)" "ERROR"
                Write-Status "Error stopping process $($process.Id): $($_.Exception.Message)" "Red"
                
                # Try force kill as fallback
                try {
                    Write-Log "Attempting force kill as fallback for PID $($process.Id)" "WARN"
                    Stop-Process -Id $process.Id -Force -ErrorAction SilentlyContinue
                    Start-Sleep -Seconds 2
                } catch {
                    Write-Log "Failed to force kill process $($process.Id): $($_.Exception.Message)" "ERROR"
                    Write-Status "Failed to force kill process $($process.Id)" "Red"
                }
            }
        }
        
        # Verify all processes are stopped
        Write-Log "Verifying all processes are stopped" "INFO"
        Start-Sleep -Seconds 5  # Give extra time for cleanup
        
        $checkProcesses = Get-Process | Where-Object {
            $_.ProcessName -like "*open-webui*" -or 
            ($_.ProcessName -like "*python*" -and $_.ProcessName -ne "pythonw")
        }
        
        if (-not $checkProcesses) {
            Write-Status "All Open WebUI processes stopped successfully" "Green"
            Write-Log "All Open WebUI processes stopped successfully" "INFO"
        } else {
            Write-Status "Some processes still running. Checking details..." "Yellow"
            Write-Log "Some processes still running after shutdown attempt" "WARN"
            $checkProcesses | ForEach-Object {
                Write-Status "Still running: $($_.ProcessName) (PID: $($_.Id))" "Red"
                Write-Log "Process still running: $($_.ProcessName) (PID: $($_.Id))" "WARN"
            }
        }
    } else {
        Write-Status "No Open WebUI processes found" "Cyan"
        Write-Log "No Open WebUI processes found to stop" "INFO"
    }
    
    # Check if port is still in use
    Write-Log "Checking if port $($env:WEB_UI_PORT) is still in use" "INFO"
    $portActive = Test-PortActive -Port $env:WEB_UI_PORT
    
    if ($portActive) {
        Write-Status "Port $($env:WEB_UI_PORT) still in use. Checking for other processes..." "Yellow"
        Write-Log "Port $($env:WEB_UI_PORT) still active after shutdown" "WARN"
        
        $portProcesses = Get-PortProcess -Port $env:WEB_UI_PORT
        if ($portProcesses) {
            foreach ($portProcess in $portProcesses) {
                Write-Status "Process $($portProcess.ProcessName) (PID: $($portProcess.Id)) still using port $($env:WEB_UI_PORT)" "Red"
                Write-Log "Port $($env:WEB_UI_PORT) still used by: $($portProcess.ProcessName) (PID: $($portProcess.Id))" "WARN"
            }
        }
    } else {
        Write-Status "Port $($env:WEB_UI_PORT) is free" "Green"
        Write-Log "Port $($env:WEB_UI_PORT) is free after shutdown" "INFO"
    }
    
    Write-Status "Open WebUI shutdown process completed" "Green"
    Write-Log "Open WebUI shutdown process completed successfully" "INFO"
    
} catch {
    $errorMsg = "Error stopping Open WebUI: $($_.Exception.Message)"
    Write-Log $errorMsg "ERROR"
    Write-Status $errorMsg "Red"
    exit 1
}
