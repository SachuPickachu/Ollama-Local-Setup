# =============================================================================
# Local LLM Stack - Stop All Services Script
# =============================================================================
# This script stops both Ollama and Open WebUI services in the correct order
# with proper cleanup and verification.

param(
    [switch]$Verbose,
    [switch]$Force,
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
    if (-not (Initialize-Logging -ScriptName "stop-all" -LogLevel $(if ($Verbose) { "DEBUG" } else { "INFO" }))) {
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

Write-Log "Starting Local LLM Stack shutdown process" "INFO"

# Helper function for colored output
function Write-Status {
    param([string]$Message, [string]$Color = "White")
    Write-Host $Message -ForegroundColor $Color
}

try {
    Write-Status "Stopping Local LLM Stack..." "Red"
    Write-Status "=================================" "Red"
    Write-Log "Shutdown process initiated" "INFO"

    # =============================================================================
    # 1. Stop Open WebUI First (it depends on Ollama)
    # =============================================================================
    Write-Log "Step 1: Stopping Open WebUI" "INFO"
    Write-Status "`n1. Stopping Open WebUI..." "Yellow"
    
    $stopWebuiScript = Get-ProjectPath "scripts\stop-webui.ps1"
    if (Test-Path $stopWebuiScript) {
        try {
            $webuiResult = Invoke-WithErrorHandling -ScriptBlock { 
                & $stopWebuiScript 
            } -ErrorMessage "Failed to stop Open WebUI"
            
            if ($webuiResult) {
                Write-Log "Open WebUI stopped successfully via script" "INFO"
                Write-Status "Open WebUI stop completed" "Green"
            } else {
                Write-Log "Open WebUI script returned false" "WARN"
                throw "Script execution failed"
            }
        } catch {
            Write-Log "Open WebUI script failed: $($_.Exception.Message)" "ERROR"
            Write-Status "Warning: Open WebUI stop script failed, using fallback process termination..." "Yellow"
            
            # Fallback: Force terminate Open WebUI processes
            try {
                $webuiProcesses = Get-Process | Where-Object {
                    $_.ProcessName -like "*python*" -and 
                    $_.ProcessName -ne "pythonw"
                }
                
                if ($webuiProcesses) {
                    Write-Log "Found $($webuiProcesses.Count) WebUI processes for fallback termination" "INFO"
                    $webuiProcesses | ForEach-Object {
                        Write-Log "Force terminating process: $($_.ProcessName) (PID: $($_.Id))" "WARN"
                        Stop-Process -Id $_.Id -Force -ErrorAction SilentlyContinue
                    }
                    Write-Log "Fallback WebUI process termination completed" "INFO"
                } else {
                    Write-Log "No WebUI processes found for fallback termination" "INFO"
                }
            } catch {
                Write-Log "Fallback WebUI termination also failed: $($_.Exception.Message)" "ERROR"
            }
        }
    } else {
        Write-Log "Stop WebUI script not found, using fallback termination" "WARN"
        # Fallback termination logic here
    }
    
    # =============================================================================
    # 2. Wait for Cleanup
    # =============================================================================
    Write-Log "Waiting for cleanup..." "INFO"
    Write-Status "Waiting 3 seconds for cleanup..." "Cyan"
    Start-Sleep -Seconds 3
    
    # =============================================================================
    # 3. Stop Ollama
    # =============================================================================
    Write-Log "Step 2: Stopping Ollama" "INFO"
    Write-Status "`n2. Stopping Ollama..." "Yellow"
    
    $stopOllamaScript = Get-ProjectPath "scripts\stop-ollama.ps1"
    if (Test-Path $stopOllamaScript) {
        try {
            $ollamaResult = Invoke-WithErrorHandling -ScriptBlock { 
                & $stopOllamaScript 
            } -ErrorMessage "Failed to stop Ollama"
            
            if ($ollamaResult) {
                Write-Log "Ollama stopped successfully via script" "INFO"
                Write-Status "Ollama stop completed" "Green"
            } else {
                Write-Log "Ollama script returned false" "WARN"
                throw "Script execution failed"
            }
        } catch {
            Write-Log "Ollama script failed: $($_.Exception.Message)" "ERROR"
            Write-Status "Warning: Ollama stop script failed, using fallback process termination..." "Yellow"
            
            # Fallback: Force terminate Ollama processes
            try {
                $ollamaProcesses = Get-Process -Name "ollama" -ErrorAction SilentlyContinue
                $ollamaAppProcesses = Get-Process -Name "ollama-app" -ErrorAction SilentlyContinue
                
                if ($ollamaProcesses -or $ollamaAppProcesses) {
                    Write-Log "Found $($ollamaProcesses.Count) Ollama processes and $($ollamaAppProcesses.Count) ollama-app processes for fallback termination" "INFO"
                    
                    # First kill ollama-app processes to prevent auto-restart
                    if ($ollamaAppProcesses) {
                        $ollamaAppProcesses | ForEach-Object {
                            Write-Log "Force terminating ollama-app process: PID $($_.Id)" "WARN"
                            Stop-Process -Id $_.Id -Force -ErrorAction SilentlyContinue
                        }
                        Start-Sleep -Seconds 2  # Give time for cleanup
                    }
                    
                    # Then kill ollama processes
                    if ($ollamaProcesses) {
                        $ollamaProcesses | ForEach-Object {
                            Write-Log "Force terminating process: $($_.ProcessName) (PID: $($_.Id))" "WARN"
                            Stop-Process -Id $_.Id -Force -ErrorAction SilentlyContinue
                        }
                    }
                    
                    Write-Log "Fallback Ollama and ollama-app process termination completed" "INFO"
                } else {
                    Write-Log "No Ollama or ollama-app processes found for fallback termination" "INFO"
                }
            } catch {
                Write-Log "Fallback Ollama termination also failed: $($_.Exception.Message)" "ERROR"
            }
        }
    } else {
        Write-Log "Stop Ollama script not found, using fallback termination" "WARN"
        # Fallback termination logic here
    }
    
    # =============================================================================
    # 4. Final Verification
    # =============================================================================
    Write-Log "Step 3: Performing final verification" "INFO"
    Write-Status "`n3. Final verification..." "Yellow"
    
    $ollamaRunning = Get-ProcessInfo -ProcessName "ollama"
    $webuiRunning = Get-Process | Where-Object {
        $_.ProcessName -like "*python*" -and 
        $_.ProcessName -ne "pythonw"
    }
    
    $port11434 = Test-PortActive -Port $env:OLLAMA_PORT
    $port8080 = Test-PortActive -Port $env:WEBUI_PORT
    
    Write-Log "Verification results - Ollama: $($(if ($ollamaRunning) { 'Running' } else { 'Stopped' })), WebUI: $($(if ($webuiRunning) { 'Running' } else { 'Stopped' })), Port $($env:OLLAMA_PORT): $($(if ($port11434) { 'In use' } else { 'Free' })), Port $($env:WEBUI_PORT): $($(if ($port8080) { 'In use' } else { 'Free' }))" "INFO"
    
    Write-Status "`nFinal Status:" "Cyan"
    Write-Status "   Ollama Process: $($(if ($ollamaRunning) { 'Still Running' } else { 'Stopped' }))" $(if ($ollamaRunning) { 'Red' } else { 'Green' })
    Write-Status "   WebUI Process:  $($(if ($webuiRunning) { 'Still Running' } else { 'Stopped' }))" $(if ($webuiRunning) { 'Red' } else { 'Green' })
    Write-Status "   Port $($env:OLLAMA_PORT):     $($(if ($port11434) { 'Still in use' } else { 'Free' }))" $(if ($port11434) { 'Red' } else { 'Green' })
    Write-Status "   Port $($env:WEBUI_PORT):      $($(if ($port8080) { 'Still in use' } else { 'Free' }))" $(if ($port8080) { 'Red' } else { 'Green' })
    
    # =============================================================================
    # 5. Success/Failure Determination
    # =============================================================================
    if (-not $ollamaRunning -and -not $webuiRunning -and -not $port11434 -and -not $port8080) {
        Write-Log "All services stopped successfully!" "INFO"
        Write-Status "`nAll services stopped successfully!" "Green"
        
        if (-not $NoLogging) {
            Write-Status "Log file: $script:LogFile" "Cyan"
        }
        
        exit 0
    } else {
        Write-Log "Some services may still be running. Final status check failed." "WARN"
        Write-Status "`nSome services may still be running. Check the status above." "Yellow"
        
        if (-not $NoLogging) {
            Write-Status "Log file: $script:LogFile" "Cyan"
        }
        
        exit 1
    }
    
} catch {
    $errorMsg = "Critical error in stop-all script: $($_.Exception.Message)"
    Write-Log $errorMsg "ERROR"
    Write-Status $errorMsg "Red"
    
    if (-not $NoLogging) {
        Write-Status "Log file: $script:LogFile" "Cyan"
    }
    
    exit 1
}
