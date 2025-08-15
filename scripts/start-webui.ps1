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
    if (-not (Initialize-Logging -ScriptName "start-webui" -LogLevel $(if ($Verbose) { "DEBUG" } else { "INFO" }))) {
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

    Write-Log "Starting Open WebUI service startup process" "INFO"
    Write-Log "Using timeout from environment: WEB_UI_STARTUP_TIMEOUT = $($env:WEB_UI_STARTUP_TIMEOUT) seconds" "INFO"
    Write-Status "Using timeout from environment: $($env:WEB_UI_STARTUP_TIMEOUT) seconds" "Cyan"

# Helper function for colored output
function Write-Status {
    param([string]$Message, [string]$Color = "White")
    Write-Host $Message -ForegroundColor $Color
}

try {
    Write-Status "Starting Open WebUI Service..." "Green"
    Write-Log "Open WebUI startup process initiated" "INFO"

    # Check if Open WebUI is already running
    Write-Log "Checking if Open WebUI is already running" "INFO"
    $existingProcesses = Get-Process | Where-Object {
        $_.ProcessName -like "*open-webui*"
    }
    
    if ($existingProcesses) {
        Write-Status "Open WebUI is already running (Count: $($existingProcesses.Count))" "Yellow"
        Write-Log "Open WebUI already running with $($existingProcesses.Count) processes" "WARN"
        
        # Check if the existing process is healthy
        $healthy = Test-ServiceHealth -Url "$($env:WEB_UI_BASE_URL)/api/version" -Timeout $env:HEALTH_CHECK_TIMEOUT
        if ($healthy) {
            Write-Status "Existing Open WebUI process is healthy" "Green"
            Write-Log "Existing Open WebUI process is healthy" "INFO"
            return $true
        } else {
            Write-Status "Existing Open WebUI process is not responding, will restart" "Yellow"
            Write-Log "Open WebUI already running with $($existingProcesses.Count) processes" "WARN"
            
            # Stop the existing processes
            foreach ($process in $existingProcesses) {
                try {
                    Stop-Process -Id $process.Id -Force -ErrorAction SilentlyContinue
                    Write-Log "Stopped existing Open WebUI process PID: $($process.Id)" "INFO"
                } catch {
                    Write-Log "Failed to stop existing Open WebUI process PID: $($process.Id): $($_.Exception.Message)" "WARN"
                }
            }
            Start-Sleep -Seconds 3
        }
    }
    
    # Validate Environment
    Write-Log "Validating environment configuration" "INFO"
    
    # Ensure data directory exists
    if (-not (Test-Path $env:DATA_DIR)) {
        try {
            New-Item -ItemType Directory -Path $env:DATA_DIR -Force | Out-Null
            Write-Log "Created data directory: $($env:DATA_DIR)" "INFO"
        } catch {
            Write-Log "Failed to create data directory: $($_.Exception.Message)" "ERROR"
            exit 1
        }
    }
    
    # Start Open WebUI Service
    Write-Log "Starting Open WebUI server process" "INFO"
    Write-Status "Starting Open WebUI server..." "Yellow"
    
    # Use PROJECT_ROOT to find the virtual environment
    $venvPath = Join-Path $env:PROJECT_ROOT ".venv"
    if (-not (Test-Path $venvPath)) {
        Write-Log "Virtual environment not found: $venvPath" "ERROR"
        Write-Status "Virtual environment not found: $venvPath" "Red"
        exit 1
    }
    
    Write-Log "Using virtual environment: $venvPath" "INFO"
    
    # Check if open-webui.exe exists in virtual environment
    $webuiExe = Join-Path $venvPath "Scripts\open-webui.exe"
    if (-not (Test-Path $webuiExe)) {
        Write-Log "Open WebUI executable not found: $webuiExe" "ERROR"
        Write-Status "Open WebUI executable not found. Please check installation." "Red"
        exit 1
    }
    
    Write-Log "Found open-webui.exe: $webuiExe" "INFO"
    
    # Set up arguments for open-webui serve command
    $arguments = @("serve", "--host", $env:WEB_UI_BIND_ADDRESS, "--port", $env:WEB_UI_PORT)
    
    Write-Log "Starting Open WebUI with: $webuiExe $($arguments -join ' ')" "DEBUG"
    
    # Start Open WebUI server in a detached process
    # Use Scripts directory as working directory (it needs source code access)
    $scriptsDir = Join-Path $venvPath "Scripts"
    $processInfo = Start-Process -FilePath $webuiExe -ArgumentList $arguments -WindowStyle Minimized -PassThru -WorkingDirectory $scriptsDir
    
    if ($processInfo) {
        Write-Log "Open WebUI server process started with PID: $($processInfo.Id)" "INFO"
        Write-Status "Open WebUI server started (PID: $($processInfo.Id))" "Green"
        Write-Status "Data directory: $($env:DATA_DIR)" "Cyan"
        Write-Status "Executable: $webuiExe" "Cyan"
        Write-Status "Working directory: $scriptsDir" "Cyan"
        
        # Wait a moment for the process to initialize
        Start-Sleep -Seconds 5
        
        # Verify the process is still running
        $verifyProcess = Get-Process -Id $processInfo.Id -ErrorAction SilentlyContinue
        if (-not $verifyProcess) {
            Write-Log "Open WebUI process verification failed - process terminated" "ERROR"
            Write-Status "Process verification failed - process terminated unexpectedly" "Red"
            exit 1
        }
        
        Write-Log "Open WebUI process verification successful" "INFO"
        Write-Status "Process running successfully" "Green"
        
        # Verify the port is active
        Write-Log "Verifying port $($env:WEB_UI_PORT) is active" "INFO"
        Write-Status "Verifying port $($env:WEB_UI_PORT) is active..." "Yellow"
        
        $portActive = Test-PortActive -Port $env:WEB_UI_PORT
        if ($portActive) {
            Write-Log "Port $($env:WEB_UI_PORT) verification successful" "INFO"
            Write-Status "Port $($env:WEB_UI_PORT) is active" "Green"
        } else {
            Write-Log "Port $($env:WEB_UI_PORT) verification failed" "WARN"
            Write-Status "Port $($env:WEB_UI_PORT) not yet active, waiting..." "Yellow"
            
            # Use the full startup timeout from environment for port verification
            $portWaitTimeout = [int]$env:WEB_UI_STARTUP_TIMEOUT  # Use the full timeout from environment
            Write-Log "Port not yet active, using full timeout from environment: $portWaitTimeout seconds" "INFO"
            Write-Status "Port not yet active, using full timeout from environment: $portWaitTimeout seconds..." "Yellow"
            
            $portWaitElapsed = 0
            while (-not $portActive -and $portWaitElapsed -lt $portWaitTimeout) {
                Start-Sleep -Seconds 5  # Check every 5 seconds
                $portWaitElapsed += 5
                if ($portWaitElapsed % 15 -eq 0) {  # Show progress every 15 seconds
                    Write-Status "Port verification in progress... ($portWaitElapsed/$portWaitTimeout seconds)" "Yellow"
                    Write-Log "Port verification in progress: $portWaitElapsed/$portWaitTimeout seconds" "INFO"
                }
                $portActive = Test-PortActive -Port $env:WEB_UI_PORT
            }
            
            if ($portActive) {
                Write-Log "Port $($env:WEB_UI_PORT) verification successful after $portWaitElapsed seconds" "INFO"
                Write-Status "Port $($env:WEB_UI_PORT) is now active after $portWaitElapsed seconds" "Green"
            } else {
                Write-Log "Port $($env:WEB_UI_PORT) verification failed after $portWaitTimeout seconds" "ERROR"
                Write-Status "Port $($env:WEB_UI_PORT) failed to become active after $portWaitTimeout seconds" "Red"
                Write-Status "Note: Process is running but service may not be fully initialized" "Cyan"
                Write-Status "You can check the WebUI manually or increase WEB_UI_STARTUP_TIMEOUT" "Cyan"
                exit 1
            }
        }
        
        Write-Status "Open WebUI started successfully!" "Green"
        return $true
    } else {
        Write-Log "Failed to start Open WebUI server process" "ERROR"
        Write-Status "Failed to start Open WebUI server" "Red"
        exit 1
    }
    
} catch {
    $errorMsg = "Error starting Open WebUI: $($_.Exception.Message)"
    Write-Log $errorMsg "ERROR"
    Write-Status $errorMsg "Red"
    exit 1
}
