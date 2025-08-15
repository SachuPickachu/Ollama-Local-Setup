# =============================================================================
# Local LLM Stack - Start All Services Script
# =============================================================================
# This script starts both Ollama and Open WebUI services in the correct order
# with proper health checks and error handling.

param(
    [switch]$Verbose,
    [switch]$Force,
    [switch]$SkipHealthCheck
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

# Initialize logging
if (-not (Initialize-Logging -ScriptName "start-all" -LogLevel $(if ($Verbose) { "DEBUG" } else { "INFO" }))) {
    Write-Error "Failed to initialize logging"
    exit 1
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

Write-Log "Starting Local LLM Stack startup process" "INFO"

# Helper function for colored output
function Write-Status {
    param([string]$Message, [string]$Color = "White")
    Write-Host $Message -ForegroundColor $Color
}

try {
    Write-Status "Starting Local LLM Stack..." "Green"
    Write-Status "===============================" "Green"
    Write-Log "Startup process initiated" "INFO"

    # =============================================================================
    # 1. Pre-Startup Checks
    # =============================================================================
    Write-Log "Performing pre-startup checks" "INFO"
    Write-Status "`nChecking current status..." "Yellow"
    
    $ollamaRunning = Get-ProcessInfo -ProcessName "ollama"
    $webuiRunning = Get-Process | Where-Object {
        $_.ProcessName -like "*python*" -and 
        $_.ProcessName -ne "pythonw"
    }
    
    if ($ollamaRunning) {
        Write-Status "Warning: Ollama is already running (PID: $($ollamaRunning.Id))" "Yellow"
        Write-Log "Ollama already running with PID: $($ollamaRunning.Id)" "WARN"
    }
    
    if ($webuiRunning) {
        Write-Status "Warning: Open WebUI is already running (Count: $($webuiRunning.Count))" "Yellow"
        Write-Log "WebUI already running with $($webuiRunning.Count) processes" "WARN"
    }
    
    if (($ollamaRunning -or $webuiRunning) -and -not $Force) {
        $response = Read-Host "`nSome services are already running. Continue anyway? (y/N)"
        if ($response -notmatch "^[Yy]") {
            Write-Log "Startup cancelled by user" "INFO"
            Write-Status "Startup cancelled by user" "Red"
            exit 0
        }
    }
    
    # =============================================================================
    # 2. Start Ollama Service
    # =============================================================================
    Write-Log "Starting Ollama service" "INFO"
    Write-Status "`n1. Starting Ollama..." "Yellow"
    
    $startOllamaScript = Get-ProjectPath "scripts\start-ollama.ps1"
    if (-not (Test-Path $startOllamaScript)) {
        throw "Start Ollama script not found: $startOllamaScript"
    }
    
    $ollamaResult = Invoke-WithErrorHandling -ScriptBlock { 
        & $startOllamaScript 
    } -ErrorMessage "Failed to start Ollama"
    
    if (-not $ollamaResult) {
        Write-Log "Ollama startup failed" "ERROR"
        Write-Status "Failed to start Ollama. Check the error above." "Red"
        exit 1
    }
    
    Write-Log "Ollama startup script completed successfully" "INFO"
    
    # =============================================================================
    # 3. Wait for Ollama to be Ready
    # =============================================================================
    if (-not $SkipHealthCheck) {
        Write-Log "Waiting for Ollama to become ready" "INFO"
        $ollamaReady = Wait-ForService -Url "$($env:OLLAMA_BASE_URL)/api/tags" -Timeout $env:OLLAMA_STARTUP_TIMEOUT -ServiceName "Ollama"
        
        if (-not $ollamaReady) {
            Write-Log "Ollama failed to become ready within timeout" "ERROR"
            Write-Status "Ollama failed to start within $($env:OLLAMA_STARTUP_TIMEOUT) seconds" "Red"
            exit 1
        }
    } else {
        Write-Log "Skipping Ollama health check as requested" "WARN"
        Start-Sleep -Seconds 10  # Give some time for startup
    }
    
    # =============================================================================
    # 4. Start Open WebUI Service
    # =============================================================================
    Write-Log "Starting Open WebUI service" "INFO"
    Write-Status "`n2. Starting Open WebUI..." "Yellow"
    
    $startWebuiScript = Get-ProjectPath "scripts\start-webui.ps1"
    if (-not (Test-Path $startWebuiScript)) {
        throw "Start WebUI script not found: $startWebuiScript"
    }
    
    $webuiResult = Invoke-WithErrorHandling -ScriptBlock { 
        & $startWebuiScript 
    } -ErrorMessage "Failed to start Open WebUI"
    
    if (-not $webuiResult) {
        Write-Log "WebUI startup failed" "ERROR"
        Write-Status "Failed to start Open WebUI. Check the error above." "Red"
        Write-Status "Note: Ollama is still running. You can start WebUI manually later." "Cyan"
        exit 1
    }
    
    Write-Log "WebUI startup script completed successfully" "INFO"
    
    # =============================================================================
    # 5. Wait for Open WebUI to be Ready
    # =============================================================================
    if (-not $SkipHealthCheck) {
        Write-Log "Waiting for Open WebUI to become ready" "INFO"
        $webuiReady = Wait-ForService -Url "$($env:WEB_UI_BASE_URL)/api/version" -Timeout $env:WEB_UI_STARTUP_TIMEOUT -ServiceName "Open WebUI"
        
        if (-not $webuiReady) {
            Write-Log "WebUI failed to become ready within timeout" "ERROR"
            Write-Status "Open WebUI failed to start within $($env:WEB_UI_STARTUP_TIMEOUT) seconds" "Red"
            Write-Status "Note: Ollama is running. Check WebUI logs for errors." "Cyan"
            exit 1
        }
    } else {
        Write-Log "Skipping WebUI health check as requested" "WARN"
        Start-Sleep -Seconds 15  # Give some time for startup
    }
    
    # =============================================================================
    # 6. Final Verification
    # =============================================================================
    Write-Log "Performing final verification" "INFO"
    Write-Status "`n3. Final verification..." "Yellow"
    Start-Sleep -Seconds 2
    
    $ollamaProcess = Get-ProcessInfo -ProcessName "ollama"
    $webuiProcesses = Get-Process | Where-Object {
        $_.ProcessName -like "*python*" -and 
        $_.ProcessName -ne "pythonw"
    }
    
    $ollamaPort = Test-PortActive -Port $env:OLLAMA_PORT
    $webuiPort = Test-PortActive -Port $env:WEB_UI_PORT
    
    Write-Log "Final verification results - Ollama: $($(if ($ollamaProcess) { 'Running' } else { 'Not Running' })), WebUI: $($(if ($webuiProcesses) { 'Running' } else { 'Not Running' })), Port $($env:OLLAMA_PORT): $($(if ($ollamaPort) { 'Active' } else { 'Not Active' })), Port $($env:WEB_UI_PORT): $($(if ($webuiPort) { 'Active' } else { 'Not Active' }))" "INFO"
    
    Write-Status "`nFinal Status:" "Cyan"
    Write-Status "   Ollama Process: $($(if ($ollamaProcess) { 'Running (PID: ' + $ollamaProcess.Id + ')' } else { 'Not Running' }))" $(if ($ollamaProcess) { 'Green' } else { 'Red' })
    Write-Status "   WebUI Process:  $($(if ($webuiProcesses) { 'Running (Count: ' + $webuiProcesses.Count + ')' } else { 'Not Running' }))" $(if ($webuiProcesses) { 'Green' } else { 'Red' })
    Write-Status "   Port $($env:OLLAMA_PORT):     $($(if ($ollamaPort) { 'Active' } else { 'Not Active' }))" $(if ($ollamaPort) { 'Green' } else { 'Red' })
    Write-Status "   Port $($env:WEB_UI_PORT):      $($(if ($webuiPort) { 'Active' } else { 'Not Active' }))" $(if ($webuiPort) { 'Green' } else { 'Red' })
    
    # =============================================================================
    # 7. Success Summary
    # =============================================================================
    if ($ollamaProcess -and $webuiProcesses -and $ollamaPort -and $webuiPort) {
        Write-Log "All services started successfully" "INFO"
        Write-Status "`nAll services started successfully!" "Green"
        Write-Status "`nAccess Points:" "Cyan"
        Write-Status "   Open WebUI: $($env:WEB_UI_BASE_URL)" "Green"
        Write-Status "   Ollama API: $($env:OLLAMA_BASE_URL)" "Green"
        
        # Get LAN IP for intranet access
        try {
            $lanIP = (Get-NetIPAddress -AddressFamily IPv4 | Where-Object { $_.IPAddress -notmatch "^169\.254\.|^127\.|^10\.|^172\.|^192\.168\." } | Select-Object -First 1).IPAddress
            if ($lanIP) {
                Write-Status "   Intranet:  http://${lanIP}:$($env:WEB_UI_PORT)" "Green"
                Write-Log "LAN IP detected: $lanIP" "INFO"
            }
        } catch {
            Write-Status "   Intranet:  Check your LAN IP manually" "Yellow"
            Write-Log "Failed to detect LAN IP: $($_.Exception.Message)" "WARN"
        }
        
        Write-Status "`nNote: Use .\scripts\status.ps1 to check service health" "Cyan"
        Write-Status "Note: Use .\scripts\stop-all.ps1 to stop all services" "Cyan"
        
        exit 0
    } else {
        Write-Log "Some services may not be running properly" "WARN"
        Write-Status "`nWarning: Some services may not be running properly. Check the status above." "Yellow"
        exit 1
    }
    
} catch {
    $errorMsg = "Error in start-all script: $($_.Exception.Message)"
    Write-Log $errorMsg "ERROR"
    Write-Status $errorMsg "Red"
    exit 1
}
