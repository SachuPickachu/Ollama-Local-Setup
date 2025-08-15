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
    if (-not (Initialize-Logging -ScriptName "stop-ollama" -LogLevel $(if ($Verbose) { "DEBUG" } else { "INFO" }))) {
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

Write-Log "Starting Ollama service shutdown process" "INFO"

# Helper function for colored output
function Write-Status {
    param([string]$Message, [string]$Color = "White")
    Write-Host $Message -ForegroundColor $Color
}

try {
    Write-Status "Stopping Ollama Service..." "Yellow"
    Write-Log "Ollama shutdown process initiated" "INFO"

    # Check if Ollama is running
    Write-Log "Searching for Ollama processes" "INFO"
    $ollamaProcess = Get-Process -Name "ollama" -ErrorAction SilentlyContinue
    
    if ($ollamaProcess) {
        Write-Status "Found Ollama process (PID: $($ollamaProcess.Id))" "Green"
        Write-Log "Found Ollama process (PID: $($ollamaProcess.Id))" "INFO"
        
        # Try graceful shutdown first
        Write-Status "Attempting graceful shutdown..." "Yellow"
        Write-Log "Attempting graceful shutdown for PID $($ollamaProcess.Id)" "INFO"
        
        try {
            # Send graceful shutdown signal
            $ollamaProcess.CloseMainWindow() | Out-Null
            
            # Wait for graceful shutdown with much longer timeout
            $gracefulTimeout = [int]$env:OLLAMA_STARTUP_TIMEOUT  # Use the same timeout as startup
            $elapsed = 0
            Write-Log "Waiting up to $gracefulTimeout seconds for graceful shutdown" "INFO"
            
            while ($ollamaProcess.HasExited -eq $false -and $elapsed -lt $gracefulTimeout) {
                Start-Sleep -Seconds 2  # Check every 2 seconds instead of every 1 second
                $elapsed += 2
                if ($elapsed % 10 -eq 0) {  # Show progress every 10 seconds
                    Write-Status "Waiting for graceful shutdown... ($elapsed/$gracefulTimeout seconds)" "Yellow"
                    Write-Log "Graceful shutdown in progress: $elapsed/$gracefulTimeout seconds" "INFO"
                }
            }
            
            # Check if process exited gracefully
            if ($ollamaProcess.HasExited) {
                Write-Status "Ollama stopped gracefully after $elapsed seconds" "Green"
                Write-Log "Ollama stopped gracefully after $elapsed seconds" "INFO"
            } else {
                            # Force kill if still running after timeout
            Write-Status "Graceful shutdown timeout after $gracefulTimeout seconds, force stopping..." "Red"
            Write-Log "Graceful shutdown timeout, force stopping PID $($ollamaProcess.Id)" "WARN"
            
            # First kill ollama-app processes to prevent auto-restart
            $ollamaAppProcesses = Get-Process -Name "ollama-app" -ErrorAction SilentlyContinue
            if ($ollamaAppProcesses) {
                Write-Status "Force stopping ollama-app processes to prevent auto-restart..." "Yellow"
                Write-Log "Found $($ollamaAppProcesses.Count) ollama-app processes, force stopping them" "WARN"
                $ollamaAppProcesses | ForEach-Object {
                    Write-Log "Force stopping ollama-app process: PID $($_.Id)" "WARN"
                    Stop-Process -Id $_.Id -Force -ErrorAction SilentlyContinue
                }
                Start-Sleep -Seconds 2  # Give time for cleanup
            }
            
            # Then kill the ollama process
            Stop-Process -Id $ollamaProcess.Id -Force
            Start-Sleep -Seconds 3  # Give it time to fully terminate
            }
            
        } catch {
            Write-Log "Error during graceful shutdown of Ollama: $($_.Exception.Message)" "ERROR"
            Write-Status "Error stopping Ollama: $($_.Exception.Message)" "Red"
            
            # Try force kill as fallback
            try {
                Write-Log "Attempting force kill as fallback for PID $($ollamaProcess.Id)" "WARN"
                
                # First kill ollama-app processes to prevent auto-restart
                $ollamaAppProcesses = Get-Process -Name "ollama-app" -ErrorAction SilentlyContinue
                if ($ollamaAppProcesses) {
                    Write-Log "Force stopping ollama-app processes as fallback" "WARN"
                    $ollamaAppProcesses | ForEach-Object {
                        Write-Log "Force stopping ollama-app process: PID $($_.Id)" "WARN"
                        Stop-Process -Id $_.Id -Force -ErrorAction SilentlyContinue
                    }
                    Start-Sleep -Seconds 2
                }
                
                # Then kill the ollama process
                Stop-Process -Id $ollamaProcess.Id -Force -ErrorAction SilentlyContinue
                Start-Sleep -Seconds 2
            } catch {
                Write-Log "Failed to force kill Ollama process: $($_.Exception.Message)" "ERROR"
                Write-Status "Failed to force kill Ollama process" "Red"
            }
        }
        
        # Verify stopped
        Write-Log "Verifying Ollama process is stopped" "INFO"
        Start-Sleep -Seconds 5  # Give extra time for cleanup
        
        $checkProcess = Get-Process -Name "ollama" -ErrorAction SilentlyContinue
        if (-not $checkProcess) {
            Write-Status "Ollama stopped successfully" "Green"
            Write-Log "Ollama stopped successfully" "INFO"
        } else {
            Write-Status "Failed to stop Ollama process" "Red"
            Write-Log "Ollama process still running after shutdown attempt" "ERROR"
            exit 1
        }
    } else {
        Write-Status "Ollama is not running" "Cyan"
        Write-Log "No Ollama processes found to stop" "INFO"
    }
    
    # Check if port is still in use
    Write-Log "Checking if port $($env:OLLAMA_PORT) is still in use" "INFO"
    $portActive = Test-PortActive -Port $env:OLLAMA_PORT
    
    if ($portActive) {
        Write-Status "Port $($env:OLLAMA_PORT) still in use. Checking for other processes..." "Yellow"
        Write-Log "Port $($env:OLLAMA_PORT) still active after shutdown" "WARN"
        
        $portProcesses = Get-PortProcess -Port $env:OLLAMA_PORT
        if ($portProcesses) {
            foreach ($portProcess in $portProcesses) {
                Write-Status "Process $($portProcess.ProcessName) (PID: $($portProcess.Id)) still using port $($env:OLLAMA_PORT)" "Red"
                Write-Log "Port $($env:OLLAMA_PORT) still used by: $($portProcess.ProcessName) (PID: $($portProcess.Id))" "WARN"
            }
        }
    } else {
        Write-Status "Port $($env:OLLAMA_PORT) is free" "Green"
        Write-Log "Port $($env:OLLAMA_PORT) is free after shutdown" "INFO"
    }
    
    Write-Status "Ollama shutdown process completed" "Green"
    Write-Log "Ollama shutdown process completed successfully" "INFO"
    
} catch {
    $errorMsg = "Error stopping Ollama: $($_.Exception.Message)"
    Write-Log $errorMsg "ERROR"
    Write-Status $errorMsg "Red"
    exit 1
}
