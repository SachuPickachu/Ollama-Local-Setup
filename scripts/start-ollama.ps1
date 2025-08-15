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
    if (-not (Initialize-Logging -ScriptName "start-ollama" -LogLevel $(if ($Verbose) { "DEBUG" } else { "INFO" }))) {
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

Write-Log "Starting Ollama service startup process" "INFO"

# Helper function for colored output
function Write-Status {
    param([string]$Message, [string]$Color = "White")
    Write-Host $Message -ForegroundColor $Color
}

try {
    Write-Status "Starting Ollama Service..." "Green"
    Write-Log "Ollama startup process initiated" "INFO"

    # Check if Ollama is already running
    Write-Log "Checking if Ollama is already running" "INFO"
    $existingProcess = Get-ProcessInfo -ProcessName "ollama"
    
    if ($existingProcess) {
        Write-Status "Ollama is already running (PID: $($existingProcess.Id))" "Yellow"
        Write-Log "Ollama already running with PID: $($existingProcess.Id)" "WARN"
        
        # Check if the existing process is healthy
        $healthy = Test-ServiceHealth -Url "$($env:OLLAMA_BASE_URL)/api/tags" -Timeout $env:HEALTH_CHECK_TIMEOUT
        if ($healthy) {
            Write-Status "Existing Ollama process is healthy" "Green"
            Write-Log "Existing Ollama process is healthy" "INFO"
            return $true
        } else {
            Write-Status "Existing Ollama process is not responding, will restart" "Yellow"
            Write-Log "Existing Ollama process is not responding, will restart" "WARN"
            
            # Stop the existing process
            try {
                Stop-Process -Id $existingProcess.Id -Force -ErrorAction SilentlyContinue
                Start-Sleep -Seconds 2
                Write-Log "Stopped existing unhealthy Ollama process" "INFO"
            } catch {
                Write-Log "Failed to stop existing Ollama process: $($_.Exception.Message)" "WARN"
            }
        }
    }
    
    # Locate Ollama Executable
    Write-Log "Locating Ollama executable" "INFO"
    $ollamaCmd = $null
    
    # Try to locate ollama executable
    $cmd = Get-Command ollama -ErrorAction SilentlyContinue
    if ($cmd -and $cmd.Source) {
        $ollamaCmd = $cmd.Source
        Write-Log "Found Ollama in PATH: $ollamaCmd" "INFO"
    }
    
    if (-not $ollamaCmd -and (Test-Path 'C:\Program Files\Ollama\ollama.exe')) {
        $ollamaCmd = 'C:\Program Files\Ollama\ollama.exe'
        Write-Log "Found Ollama in Program Files: $ollamaCmd" "INFO"
    }
    
    if (-not $ollamaCmd -and $env:LOCALAPPDATA) {
        $candidate = Join-Path $env:LOCALAPPDATA 'Programs\Ollama\ollama.exe'
        if (Test-Path $candidate) { 
            $ollamaCmd = $candidate
            Write-Log "Found Ollama in LocalAppData: $ollamaCmd" "INFO"
        }
    }
    
    if (-not $ollamaCmd -and $env:ProgramFiles) {
        $candidate = Join-Path $env:ProgramFiles 'Ollama\ollama.exe'
        if (Test-Path $candidate) { 
            $ollamaCmd = $candidate
            Write-Log "Found Ollama in ProgramFiles: $ollamaCmd" "INFO"
        }
    }
    
    if (-not $ollamaCmd) {
        $errorMsg = "Could not find ollama executable on PATH or in standard locations"
        Write-Log $errorMsg "ERROR"
        Write-Error $errorMsg
        exit 1
    }
    
    Write-Status "Using Ollama executable: $ollamaCmd" "Cyan"
    
    # Validate Environment
    Write-Log "Validating environment configuration" "INFO"
    
    # Ensure models directory exists
    if (-not (Test-Path $env:OLLAMA_MODELS)) {
        try {
            New-Item -ItemType Directory -Path $env:OLLAMA_MODELS -Force | Out-Null
            Write-Log "Created models directory: $($env:OLLAMA_MODELS)" "INFO"
        } catch {
            Write-Log "Failed to create models directory: $($_.Exception.Message)" "ERROR"
            exit 1
        }
    }
    
    # Start Ollama Service
    Write-Log "Starting Ollama server process" "INFO"
    Write-Status "Starting Ollama server..." "Yellow"
    
    # Set environment variable for models directory
    $env:OLLAMA_MODELS = $env:OLLAMA_MODELS
    
    Write-Log "Starting Ollama with models directory: $($env:OLLAMA_MODELS)" "DEBUG"
    
    # Start Ollama server in a detached process with environment variables
    # Use the current session's environment variables by setting them before Start-Process
    $env:OLLAMA_HOST = "$($env:OLLAMA_BIND_ADDRESS):$($env:OLLAMA_PORT)"
    $env:OLLAMA_PORT = $env:OLLAMA_PORT
    
    Write-Log "Environment variables set for Ollama process:" "DEBUG"
    Write-Log "  OLLAMA_MODELS: $($env:OLLAMA_MODELS)" "DEBUG"
    Write-Log "  OLLAMA_HOST: $($env:OLLAMA_HOST)" "DEBUG"
    Write-Log "  OLLAMA_PORT: $($env:OLLAMA_PORT)" "DEBUG"
    
    $processInfo = Start-Process -FilePath $ollamaCmd -ArgumentList "serve" -WindowStyle Minimized -PassThru
    
    if ($processInfo) {
        Write-Log "Ollama server process started with PID: $($processInfo.Id)" "INFO"
        Write-Status "Ollama server started (PID: $($processInfo.Id))" "Green"
        Write-Status "Models directory: $($env:OLLAMA_MODELS)" "Cyan"
        
        # Wait a moment for the process to initialize
        Start-Sleep -Seconds 2
        
        # Verify the process is still running
        $verifyProcess = Get-Process -Id $processInfo.Id -ErrorAction SilentlyContinue
        if ($verifyProcess) {
            Write-Log "Ollama process verification successful" "INFO"
            Write-Status "Ollama started successfully!" "Green"
            return $true
        } else {
            Write-Log "Ollama process verification failed - process terminated" "ERROR"
            Write-Status "Ollama process terminated unexpectedly" "Red"
            return $false
        }
    } else {
        Write-Log "Failed to start Ollama server process" "ERROR"
        Write-Status "Failed to start Ollama server" "Red"
        exit 1
    }
    
} catch {
    $errorMsg = "Error starting Ollama: $($_.Exception.Message)"
    Write-Log $errorMsg "ERROR"
    Write-Status $errorMsg "Red"
    exit 1
}
