# =============================================================================
# Local LLM Stack Status Check Script
# =============================================================================
# This script provides comprehensive status information about the Local LLM Stack
# including Ollama, Open WebUI, disk space, and models.

param(
    [switch]$Verbose,
    [switch]$NoColor
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

# Load and validate environment first
if (-not (Load-Environment)) {
    Write-Error "Failed to load environment configuration"
    exit 1
}

if (-not (Test-Environment)) {
    Write-Error "Environment validation failed"
    exit 1
}

# Initialize logging after environment is loaded
if (-not (Initialize-Logging -ScriptName "status" -LogLevel $(if ($Verbose) { "DEBUG" } else { "INFO" }))) {
    Write-Error "Failed to initialize logging"
    exit 1
}

Write-Log "Starting Local LLM Stack Status Check" "INFO"

# Helper function for colored output
function Write-Status {
    param([string]$Message, [string]$Color = "White")
    if ($NoColor) {
        Write-Host $Message
    } else {
        Write-Host $Message -ForegroundColor $Color
    }
}

try {
    Write-Status "Local LLM Stack Status Check" "Cyan"
    Write-Status "===============================" "Cyan"
    Write-Log "Status check started" "INFO"

    # =============================================================================
    # 1. Ollama Service Status
    # =============================================================================
    Write-Log "Checking Ollama service status" "INFO"
    Write-Status "`n1. Ollama Service:" "Yellow"
    
    $ollamaProcess = Get-ProcessInfo -ProcessName "ollama"
    
    if ($ollamaProcess) {
        Write-Status "   Process Running (PID: $($ollamaProcess.Id))" "Green"
        Write-Status "   Memory: $($ollamaProcess.MemoryMB) MB" "Cyan"
        Write-Status "   Uptime: $($ollamaProcess.UptimeMinutes) minutes" "Cyan"
        Write-Log "Ollama process found: PID $($ollamaProcess.Id), Memory: $($ollamaProcess.MemoryMB) MB" "INFO"
    } else {
        Write-Status "   Process Not Running" "Red"
        Write-Log "Ollama process not found" "WARN"
    }
    
    # Check Ollama port
    $ollamaPortActive = Test-PortActive -Port $env:OLLAMA_PORT
    if ($ollamaPortActive) {
        Write-Status "   Port $($env:OLLAMA_PORT) Active" "Green"
        Write-Log "Ollama port $($env:OLLAMA_PORT) is active" "INFO"
    } else {
        Write-Status "   Port $($env:OLLAMA_PORT) Not Active" "Red"
        Write-Log "Ollama port $($env:OLLAMA_PORT) is not active" "WARN"
    }
    
    # =============================================================================
    # 2. Open WebUI Service Status
    # =============================================================================
    Write-Log "Checking Open WebUI service status" "INFO"
    Write-Status "`n2. Open WebUI Service:" "Yellow"
    
    $webuiProcesses = Get-Process | Where-Object {
        $_.ProcessName -like "*python*" -and 
        $_.ProcessName -ne "pythonw"
    }
    
    if ($webuiProcesses) {
        Write-Status "   Process Running (Count: $($webuiProcesses.Count))" "Green"
        Write-Log "Found $($webuiProcesses.Count) WebUI processes" "INFO"
        foreach ($process in $webuiProcesses) {
            $memoryMB = [math]::Round($process.WorkingSet / (1024*1024), 2)
            Write-Status "      PID: $($process.Id), Memory: $memoryMB MB" "Cyan"
            Write-Log "WebUI process: PID $($process.Id), Memory: $memoryMB MB" "DEBUG"
        }
    } else {
        Write-Status "   Process Not Running" "Red"
        Write-Log "No WebUI processes found" "WARN"
    }
    
    # Check WebUI port
    $webuiPortActive = Test-PortActive -Port $env:WEB_UI_PORT
    if ($webuiPortActive) {
        Write-Status "   Port $($env:WEB_UI_PORT) Active" "Green"
        Write-Log "WebUI port $($env:WEB_UI_PORT) is active" "INFO"
    } else {
        Write-Status "   Port $($env:WEB_UI_PORT) Not Active" "Red"
        Write-Log "WebUI port $($env:WEB_UI_PORT) is not active" "WARN"
    }
    
    # =============================================================================
    # 3. Disk Space Status
    # =============================================================================
    Write-Log "Checking disk space" "INFO"
    Write-Status "`n3. Disk Space:" "Yellow"
    
    $dataDrive = Split-Path $env:DATA_ROOT -Qualifier
    $dataDriveInfo = Get-WmiObject -Class Win32_LogicalDisk | Where-Object { $_.DeviceID -eq $dataDrive }
    
    if ($dataDriveInfo) {
        $freeGB = [math]::Round($dataDriveInfo.FreeSpace / 1GB, 2)
        $totalGB = [math]::Round($dataDriveInfo.Size / 1GB, 2)
        $usedGB = $totalGB - $freeGB
        $usagePercent = [math]::Round(($usedGB / $totalGB) * 100, 1)
        
        Write-Status "   $dataDrive Drive:" "Cyan"
        Write-Status "      Total: $totalGB GB" "Cyan"
        Write-Status "      Used:  $usedGB GB" "Cyan"
        Write-Status "      Free:  $freeGB GB" "Cyan"
        
        $usageColor = if ($usagePercent -gt 90) { 'Red' } elseif ($usagePercent -gt 80) { 'Yellow' } else { 'Green' }
        Write-Status "      Usage: $usagePercent%" $usageColor
        
        Write-Log "Data drive $dataDrive - Total $totalGB GB, Used $usedGB GB, Free $freeGB GB, Usage $usagePercent%" "INFO"
    }
    
    # Check C: drive space (for build tools)
    $cDriveInfo = Get-WmiObject -Class Win32_LogicalDisk | Where-Object { $_.DeviceID -eq "C:" }
    if ($cDriveInfo) {
        $cFreeGB = [math]::Round($cDriveInfo.FreeSpace / 1GB, 2)
        $cColor = if ($cFreeGB -lt 10) { 'Red' } elseif ($cFreeGB -lt 20) { 'Yellow' } else { 'Green' }
        Write-Status "   C: Drive (Build Tools): $cFreeGB GB free" $cColor
        Write-Log "C: drive: $cFreeGB GB free" "INFO"
    }
    
    # =============================================================================
    # 4. Models Status
    # =============================================================================
    Write-Log "Checking models status" "INFO"
    Write-Status "`n4. Models:" "Yellow"
    
    $modelsPath = $env:OLLAMA_MODELS
    if (Test-Path $modelsPath) {
        # Get actual model information by calling the models script logic
        $manifestPath = Join-Path $modelsPath "manifests\registry.ollama.ai\library"
        if (Test-Path $manifestPath) {
            $modelFamilies = Get-ChildItem -Path $manifestPath -Directory -ErrorAction SilentlyContinue
            if ($modelFamilies) {
                $allModels = @()
                
                foreach ($family in $modelFamilies) {
                    $modelVersions = Get-ChildItem -Path $family.FullName -File -ErrorAction SilentlyContinue
                    if ($modelVersions) {
                        foreach ($version in $modelVersions) {
                            $allModels += @{
                                Family = $family.Name
                                Version = $version.Name
                                FullName = "$($family.Name):$($version.Name)"
                            }
                        }
                    } else {
                        $allModels += @{
                            Family = $family.Name
                            Version = "latest"
                            FullName = $family.Name
                        }
                    }
                }
                
                if ($allModels.Count -gt 0) {
                    Write-Status "   Found $($allModels.Count) model(s):" "Green"
                    Write-Log "Found $($allModels.Count) models" "INFO"
                    
                    # Group models by family for better display
                    $modelsByFamily = $allModels | Group-Object -Property Family | Sort-Object Name
                    
                    foreach ($familyGroup in $modelsByFamily) {
                        Write-Status "      $($familyGroup.Name):" "Yellow"
                        foreach ($model in $familyGroup.Group) {
                            $versionInfo = if ($model.Version -eq "latest") { "" } else { ":$($model.Version)" }
                            Write-Status "        - $($model.Family)$versionInfo" "Cyan"
                            Write-Log "Model: $($model.FullName)" "DEBUG"
                        }
                    }
                } else {
                    Write-Status "   No models found" "Yellow"
                    Write-Log "No models found in manifests" "WARN"
                }
            } else {
                Write-Status "   No model families found" "Yellow"
                Write-Log "No model families found in manifests directory" "WARN"
            }
        } else {
            Write-Status "   Manifests directory not found" "Yellow"
            Write-Log "Manifests directory not found: $manifestPath" "WARN"
        }
        
    } else {
        Write-Status "   Models directory not found" "Red"
        Write-Status "   Expected location: $modelsPath" "Cyan"
        Write-Log "Models directory not found: $modelsPath" "ERROR"
    }
    
    # =============================================================================
    # 5. Service Health Check
    # =============================================================================
    Write-Log "Performing service health checks" "INFO"
    Write-Status "`n5. Service Health:" "Yellow"
    
    # Test Ollama API
    $ollamaHealthy = Test-ServiceHealth -Url "$($env:OLLAMA_BASE_URL)/api/tags" -Timeout $env:HEALTH_CHECK_TIMEOUT
    if ($ollamaHealthy) {
        Write-Status "   Ollama API: Healthy" "Green"
        Write-Log "Ollama API health check passed" "INFO"
    } else {
        Write-Status "   Ollama API: Unhealthy" "Red"
        Write-Log "Ollama API health check failed" "WARN"
    }
    
    # Test WebUI API
    $webuiHealthy = Test-ServiceHealth -Url "$($env:WEB_UI_BASE_URL)/api/version" -Timeout $env:HEALTH_CHECK_TIMEOUT
    if ($webuiHealthy) {
        Write-Status "   WebUI API: Healthy" "Green"
        Write-Log "WebUI API health check passed" "INFO"
    } else {
        Write-Status "   WebUI API: Unhealthy" "Red"
        Write-Log "WebUI API health check failed" "WARN"
    }
    
    # =============================================================================
    # Overall Status Summary
    # =============================================================================
    Write-Status "`nOverall Status:" "Cyan"
    
    $ollamaOk = $ollamaProcess -and $ollamaPortActive -and $ollamaHealthy
    $webuiOk = $webuiProcesses -and $webuiPortActive -and $webuiHealthy
    
    if ($ollamaOk -and $webuiOk) {
        Write-Status "   All services running normally!" "Green"
        Write-Log "All services are healthy" "INFO"
        exit 0
    } elseif ($ollamaOk -or $webuiOk) {
        Write-Status "   Partial service availability" "Yellow"
        Write-Log "Partial service availability detected" "WARN"
        exit 1
    } else {
        Write-Status "   No services running" "Red"
        Write-Log "No services are running" "ERROR"
        exit 1
    }
    
} catch {
    $errorMsg = "Error checking status: $($_.Exception.Message)"
    Write-Log $errorMsg "ERROR"
    Write-Status $errorMsg "Red"
    exit 1
}
