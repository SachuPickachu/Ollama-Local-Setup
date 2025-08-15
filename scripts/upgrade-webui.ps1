param(
    [switch]$SkipBackup,
    [switch]$SkipVerification
)

# Load environment variables
. .\config\env.ps1

# Setup logging
$logFile = Join-Path $env:DATA_ROOT "logs\upgrade-webui-$(Get-Date -Format 'yyyyMMdd-HHmmss').log"
$logDir = Split-Path $logFile -Parent
if (-not (Test-Path $logDir)) {
    New-Item -ItemType Directory -Path $logDir -Force | Out-Null
}

function Write-Log {
    param([string]$Message, [string]$Level = "INFO")
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "[$timestamp] [$Level] $Message"
    Write-Host $logEntry
    Add-Content -Path $logFile -Value $logEntry
}

Write-Log "Starting Open WebUI upgrade process..." "INFO"
Write-Host "Open WebUI Upgrade Process" -ForegroundColor Cyan
Write-Host "=========================" -ForegroundColor Cyan

try {
    # Step 1: Stop all services
    Write-Log "Step 1: Stopping all services..." "INFO"
    Write-Host "`n1. Stopping all services..." -ForegroundColor Yellow
    
    . .\scripts\stop-all.ps1
    if ($LASTEXITCODE -ne 0) {
        Write-Log "Warning: Some services may still be running" "WARNING"
        Write-Host "Warning: Some services may still be running" -ForegroundColor Yellow
    }
    
    # Wait for cleanup
    Start-Sleep -Seconds 3
    
    # Step 2: Create backup (unless skipped)
    if (-not $SkipBackup) {
        Write-Log "Step 2: Creating backup..." "INFO"
        Write-Host "`n2. Creating backup..." -ForegroundColor Yellow
        Write-Host "   (Excluding models and cache files to save space)" -ForegroundColor Gray
        
        $timestamp = Get-Date -Format "yyyy-MM-dd-HHmmss"
        $backupDir = "E:\OLLAMA\backups\$timestamp"
        
        try {
            New-Item -ItemType Directory -Path $backupDir -Force | Out-Null
            
            # Only backup essential WebUI data (exclude models which are huge)
            # Backup webui folder but exclude any model-related subdirectories
            $webuiSource = "E:\OLLAMA\webui"
            $webuiDest = "$backupDir\webui"
            
            # Create destination directory
            New-Item -ItemType Directory -Path $webuiDest -Force | Out-Null
            
            # Copy WebUI data selectively (exclude models, cache, etc.)
            Get-ChildItem -Path $webuiSource -Recurse | ForEach-Object {
                $relativePath = $_.FullName.Substring($webuiSource.Length + 1)
                $destination = Join-Path $webuiDest $relativePath
                
                # Skip model files and large cache directories
                if ($relativePath -notlike "*models*" -and 
                    $relativePath -notlike "*cache*" -and 
                    $relativePath -notlike "*.bin" -and
                    $relativePath -notlike "*.gguf" -and
                    $relativePath -notlike "*.safetensors") {
                    
                    if ($_.PSIsContainer) {
                        New-Item -ItemType Directory -Path $destination -Force | Out-Null
                    } else {
                        Copy-Item $_.FullName -Destination $destination -Force
                    }
                }
            }
            
            Write-Log "Backup created successfully at: $backupDir (models excluded)" "SUCCESS"
            Write-Host "Backup created at: $backupDir (models excluded)" -ForegroundColor Green
        } catch {
            Write-Log "Backup failed: $($_.Exception.Message)" "ERROR"
            Write-Host "Backup failed: $($_.Exception.Message)" -ForegroundColor Red
            throw "Backup creation failed"
        }
    } else {
        Write-Log "Step 2: Backup skipped by user request" "INFO"
        Write-Host "`n2. Backup skipped by user request" -ForegroundColor Yellow
    }
    
    # Step 3: Check current version
    Write-Log "Step 3: Checking current version..." "INFO"
    Write-Host "`n3. Checking current version..." -ForegroundColor Yellow
    
    try {
        . .\.venv\Scripts\Activate.ps1
        $currentVersion = pip show open-webui | Select-String "Version:" | ForEach-Object { $_.ToString().Split(":")[1].Trim() }
        Write-Log "Current Open WebUI version: $currentVersion" "INFO"
        Write-Host "Current version: $currentVersion" -ForegroundColor Cyan
    } catch {
        Write-Log "Failed to check current version: $($_.Exception.Message)" "WARNING"
        Write-Host "Warning: Could not determine current version" -ForegroundColor Yellow
    }
    
    # Step 4: Upgrade Open WebUI
    Write-Log "Step 4: Upgrading Open WebUI..." "INFO"
    Write-Host "`n4. Upgrading Open WebUI..." -ForegroundColor Yellow
    
    try {
        # Upgrade pip first
        Write-Log "Upgrading pip..." "INFO"
        pip install --upgrade pip
        
        # Upgrade Open WebUI
        Write-Log "Installing latest Open WebUI..." "INFO"
        pip install --upgrade open-webui
        
        # Check new version
        $newVersion = pip show open-webui | Select-String "Version:" | ForEach-Object { $_.ToString().Split(":")[1].Trim() }
        Write-Log "New Open WebUI version: $newVersion" "SUCCESS"
        Write-Host "Upgrade completed! New version: $newVersion" -ForegroundColor Green
        
        if ($currentVersion -and $newVersion -ne $currentVersion) {
            Write-Host "Version changed from $currentVersion to $newVersion" -ForegroundColor Cyan
        }
    } catch {
        Write-Log "Upgrade failed: $($_.Exception.Message)" "ERROR"
        Write-Host "Upgrade failed: $($_.Exception.Message)" -ForegroundColor Red
        throw "Open WebUI upgrade failed"
    }
    
    # Step 5: Test the upgrade
    Write-Log "Step 5: Testing the upgrade..." "INFO"
    Write-Host "`n5. Testing the upgrade..." -ForegroundColor Yellow
    
    try {
        # Start Ollama
        Write-Log "Starting Ollama server..." "INFO"
        . .\scripts\start-ollama.ps1
        
        # Wait for Ollama to start
        Start-Sleep -Seconds 5
        
        # Test Ollama
        Write-Log "Testing Ollama connection..." "INFO"
        $ollamaTest = curl -s http://127.0.0.1:11434/api/tags 2>$null
        if ($ollamaTest) {
            Write-Log "Ollama is responding" "SUCCESS"
            Write-Host "Ollama is responding" -ForegroundColor Green
        } else {
            Write-Log "Ollama test failed" "WARNING"
            Write-Host "Warning: Ollama test failed" -ForegroundColor Yellow
        }
        
        # Test WebUI startup
        Write-Log "Testing WebUI startup..." "INFO"
        $webuiProcess = Start-Process -FilePath "python" -ArgumentList "-m", "open_webui" -PassThru -WindowStyle Minimized
        
        # Wait a bit for WebUI to start
        Start-Sleep -Seconds 10
        
        # Check if WebUI is running
        $webuiRunning = Get-Process -Id $webuiProcess.Id -ErrorAction SilentlyContinue
        if ($webuiRunning) {
            Write-Log "WebUI started successfully" "SUCCESS"
            Write-Host "WebUI started successfully" -ForegroundColor Green
            
            # Stop WebUI for now (user can start it manually later)
            Stop-Process -Id $webuiProcess.Id -Force
            Write-Log "WebUI stopped (user can start manually)" "INFO"
        } else {
            Write-Log "WebUI startup test failed" "WARNING"
            Write-Host "Warning: WebUI startup test failed" -ForegroundColor Yellow
        }
        
    } catch {
        Write-Log "Testing failed: $($_.Exception.Message)" "ERROR"
        Write-Host "Testing failed: $($_.Exception.Message)" -ForegroundColor Red
    }
    
    # Final status
    Write-Log "Open WebUI upgrade process completed" "SUCCESS"
    Write-Host "`nUpgrade completed successfully!" -ForegroundColor Green
    Write-Host "Log file: $logFile" -ForegroundColor Cyan
    
    if (-not $SkipVerification) {
        Write-Host "`nNext steps:" -ForegroundColor Cyan
        Write-Host "1. Start Ollama: .\scripts\start-ollama.ps1" -ForegroundColor White
        Write-Host "2. Start WebUI: . .\.venv\Scripts\Activate.ps1 && python -m open_webui" -ForegroundColor White
        Write-Host "3. Test at: http://127.0.0.1:8080" -ForegroundColor White
    }
    
    exit 0
    
} catch {
    Write-Log "Critical error in upgrade script: $($_.Exception.Message)" "ERROR"
    Write-Host "Error in upgrade script: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "Log file: $logFile" -ForegroundColor Cyan
    
    Write-Host "`nIf the upgrade failed, you can:" -ForegroundColor Yellow
    Write-Host "1. Check the log file for details" -ForegroundColor White
    Write-Host "2. Restore from backup if needed" -ForegroundColor White
    Write-Host "3. Try the upgrade again" -ForegroundColor White
    
    exit 1
}
