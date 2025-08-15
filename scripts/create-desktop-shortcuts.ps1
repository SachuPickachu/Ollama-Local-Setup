# Create Desktop Shortcuts for Local LLM Stack (Fixed Version)
# This script creates Windows desktop shortcuts for start-all and stop-all scripts
# with better error handling and working directory setup

param(
    [switch]$Verbose,
    [switch]$Force
)

# Get the script directory and project root
$scriptPath = Split-Path $MyInvocation.MyCommand.Path -Parent
$projectRoot = Split-Path $scriptPath -Parent

# Get desktop path
$desktopPath = [Environment]::GetFolderPath("Desktop")

Write-Host "Creating Desktop Shortcuts for Local LLM Stack (Fixed Version)" -ForegroundColor Green
Write-Host "=============================================================" -ForegroundColor Green
Write-Host "Desktop Path: $desktopPath" -ForegroundColor Cyan
Write-Host "Project Root: $projectRoot" -ForegroundColor Cyan
Write-Host ""

# Function to create shortcut
function Create-Shortcut {
    param(
        [string]$Name,
        [string]$TargetScript,
        [string]$Description
    )
    
    $shortcutPath = Join-Path $desktopPath "$Name.lnk"
    
    if ((Test-Path $shortcutPath) -and (-not $Force)) {
        Write-Host "Shortcut '$Name' already exists. Use -Force to overwrite." -ForegroundColor Yellow
        return $false
    }
    
    try {
        # Create WScript.Shell object
        $WshShell = New-Object -ComObject WScript.Shell
        
        # Create shortcut object
        $Shortcut = $WshShell.CreateShortcut($shortcutPath)
        
        # Set target (PowerShell with the script)
        $Shortcut.TargetPath = "powershell.exe"
        
        # Use a more robust command that sets working directory and loads environment
        $Shortcut.Arguments = "-ExecutionPolicy Bypass -NoProfile -Command `"Set-Location '$projectRoot'; . '$projectRoot\config\env.ps1'; & '$TargetScript'`""
        
        # Set working directory
        $Shortcut.WorkingDirectory = $projectRoot
        
        # Set description
        $Shortcut.Description = $Description
        
        # Save shortcut
        $Shortcut.Save()
        
        Write-Host "SUCCESS: Created shortcut: $Name" -ForegroundColor Green
        Write-Host "  Target: $TargetScript" -ForegroundColor Gray
        Write-Host "  Working Directory: $projectRoot" -ForegroundColor Gray
        return $true
        
    } catch {
        Write-Host "ERROR: Failed to create shortcut '$Name': $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}

# Create start-all shortcut
Write-Host "Creating Start All shortcut..." -ForegroundColor Yellow
$startScriptPath = Join-Path $projectRoot "scripts\start-all.ps1"
$startSuccess = Create-Shortcut -Name "Start Local LLM" -TargetScript $startScriptPath -Description "Start Ollama and Open WebUI services"

# Create stop-all shortcut
Write-Host "Creating Stop All shortcut..." -ForegroundColor Yellow
$stopScriptPath = Join-Path $projectRoot "scripts\stop-all.ps1"
$stopSuccess = Create-Shortcut -Name "Stop Local LLM" -TargetScript $stopScriptPath -Description "Stop Ollama and Open WebUI services"

# Summary
Write-Host ""
Write-Host "Summary:" -ForegroundColor Cyan
Write-Host "=======" -ForegroundColor Cyan

if ($startSuccess) {
    Write-Host "SUCCESS: Start Local LLM shortcut created" -ForegroundColor Green
} else {
    Write-Host "FAILED: Start Local LLM shortcut creation" -ForegroundColor Red
}

if ($stopSuccess) {
    Write-Host "SUCCESS: Stop Local LLM shortcut created" -ForegroundColor Green
} else {
    Write-Host "FAILED: Stop Local LLM shortcut creation" -ForegroundColor Red
}

Write-Host ""
Write-Host "Shortcuts created on desktop:" -ForegroundColor Cyan
Write-Host "- Start Local LLM: Double-click to start all services" -ForegroundColor White
Write-Host "- Stop Local LLM: Double-click to stop all services" -ForegroundColor White
Write-Host ""
Write-Host "IMPORTANT NOTES:" -ForegroundColor Yellow
Write-Host "- These shortcuts now use improved command execution" -ForegroundColor White
Write-Host "- Working directory is properly set to project root" -ForegroundColor White
Write-Host "- Environment variables should load correctly" -ForegroundColor White
Write-Host "- You may need to right-click and 'Run as Administrator' if you encounter permission issues" -ForegroundColor Yellow
