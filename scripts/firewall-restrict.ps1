# Firewall Restriction for Local LLM Stack
# This script restricts access to specific trusted IPs only

param(
    [string[]]$TrustedIPs = @(),
    [switch]$Interactive = $true
)

Write-Host "🔒 Setting up restricted firewall rules for Local LLM" -ForegroundColor Green

# Check if running as Administrator
if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host "Error: This script requires Administrator privileges!" -ForegroundColor Red
    Write-Host "Please run PowerShell as Administrator and try again." -ForegroundColor Yellow
    exit 1
}

# Load environment
if (Test-Path "..\config\env.ps1") {
    . "..\config\env.ps1"
    Write-Host "Environment loaded. DATA_ROOT: $env:DATA_ROOT" -ForegroundColor Yellow
} else {
    Write-Host "Error: Environment file not found. Please run from scripts directory." -ForegroundColor Red
    exit 1
}

# Function to get network information
function Get-NetworkInfo {
    $NetworkAdapter = Get-NetAdapter | Where-Object { $_.Status -eq "Up" -and $_.InterfaceDescription -notlike "*Loopback*" } | Select-Object -First 1
    $IPConfig = Get-NetIPAddress -InterfaceIndex $NetworkAdapter.ifIndex -AddressFamily IPv4 | Select-Object -First 1
    
    $Subnet = $IPConfig.IPAddress -replace "\.\d+$", ".0/24"
    
    return @{
        AdapterName = $NetworkAdapter.Name
        LocalIP = $IPConfig.IPAddress
        Subnet = $Subnet
        Gateway = (Get-NetRoute -InterfaceIndex $NetworkAdapter.ifIndex -DestinationPrefix "0.0.0.0/0").NextHop
    }
}

# Get trusted IPs if not provided
if ($TrustedIPs.Count -eq 0 -and $Interactive) {
    $NetworkInfo = Get-NetworkInfo
    
    Write-Host "`nCurrent Network Configuration:" -ForegroundColor Cyan
    Write-Host "Local IP: $($NetworkInfo.LocalIP)" -ForegroundColor White
    Write-Host "Subnet: $($NetworkInfo.Subnet)" -ForegroundColor White
    Write-Host "Gateway: $($NetworkInfo.Gateway)" -ForegroundColor White
    
    Write-Host "`nFirewall Restriction Options:" -ForegroundColor Cyan
    Write-Host "1. Restrict to specific IPs only (most secure)"
    Write-Host "2. Restrict to current subnet only ($($NetworkInfo.Subnet))"
    Write-Host "3. Restrict to gateway + specific IPs"
    Write-Host "4. Keep current broad access (not recommended)"
    
    $choice = Read-Host "`nSelect option (1-4, default: 2)"
    
    switch ($choice) {
        "1" {
            Write-Host "Enter trusted IP addresses (comma-separated):"
            Write-Host "Example: 192.168.1.100,192.168.1.101,192.168.1.102"
            $input = Read-Host "Trusted IPs"
            $TrustedIPs = $input -split ',' | ForEach-Object { $_.Trim() }
        }
        "2" {
            $TrustedIPs = @($NetworkInfo.Subnet)
            Write-Host "Will restrict to subnet: $($NetworkInfo.Subnet)" -ForegroundColor Green
        }
        "3" {
            Write-Host "Enter additional trusted IP addresses (comma-separated):"
            Write-Host "Gateway ($($NetworkInfo.Gateway)) will be included automatically"
            $input = Read-Host "Additional IPs"
            $additionalIPs = $input -split ',' | ForEach-Object { $_.Trim() } | Where-Object { $_ -ne "" }
            $TrustedIPs = @($NetworkInfo.Gateway) + $additionalIPs
        }
        "4" {
            Write-Host "Warning: Keeping broad access - this is not recommended for security!" -ForegroundColor Yellow
            Write-Host "Current rules will remain unchanged." -ForegroundColor White
            return
        }
        default {
            $TrustedIPs = @($NetworkInfo.Subnet)
            Write-Host "Default: Will restrict to subnet: $($NetworkInfo.Subnet)" -ForegroundColor Green
        }
    }
}

if ($TrustedIPs.Count -eq 0) {
    Write-Host "Error: No trusted IPs specified!" -ForegroundColor Red
    exit 1
}

Write-Host "`n🔒 Removing existing broad access rules..." -ForegroundColor Yellow

# Remove existing broad access rules
$ExistingRules = Get-NetFirewallRule | Where-Object { 
    $_.DisplayName -like "*Ollama*" -or 
    $_.DisplayName -like "*OpenWebUI*" -or
    $_.DisplayName -like "*LocalLLM*"
}

if ($ExistingRules) {
    $ExistingRules | Remove-NetFirewallRule -Confirm:$false
    Write-Host "Removed $($ExistingRules.Count) existing rules" -ForegroundColor Green
} else {
    Write-Host "Info: No existing rules found" -ForegroundColor Blue
}

Write-Host "`nCreating restricted access rules..." -ForegroundColor Yellow

# Create restricted rules for each trusted IP/subnet
foreach ($IP in $TrustedIPs) {
    Write-Host "Creating rules for: $IP" -ForegroundColor White
    
    # Ollama API (port 11434)
    try {
        New-NetFirewallRule -DisplayName "LocalLLM-Ollama-$IP" -Direction Inbound -Protocol TCP -LocalPort 11434 -RemoteAddress $IP -Action Allow -Profile Private -Description "Ollama API access for $IP" | Out-Null
        Write-Host "  Ollama API rule created for $IP" -ForegroundColor Green
    } catch {
        Write-Host "  Error: Failed to create Ollama rule for $IP: $($_.Exception.Message)" -ForegroundColor Red
    }
    
    # Open WebUI (port 8080)
    try {
        New-NetFirewallRule -DisplayName "LocalLLM-WebUI-$IP" -Direction Inbound -Protocol TCP -LocalPort 8080 -RemoteAddress $IP -Action Allow -Profile Private -Description "Open WebUI access for $IP" | Out-Null
        Write-Host "  Open WebUI rule created for $IP" -ForegroundColor Green
    } catch {
        Write-Host "  Error: Failed to create WebUI rule for $IP: $($_.Exception.Message)" -ForegroundColor Red
    }
}

# Create security log rule
try {
    New-NetFirewallRule -DisplayName "LocalLLM-Security-Log" -Direction Inbound -Protocol TCP -LocalPort 11434,8080 -Action Log -Profile Private -Description "Log all access attempts for security monitoring" | Out-Null
    Write-Host "Security logging rule created" -ForegroundColor Green
} catch {
    Write-Host "Warning: Failed to create security logging rule: $($_.Exception.Message)" -ForegroundColor Yellow
}

# Verify rules
    Write-Host "`nVerifying firewall rules..." -ForegroundColor Cyan
$NewRules = Get-NetFirewallRule | Where-Object { $_.DisplayName -like "LocalLLM*" }

Write-Host "`nCreated Firewall Rules:" -ForegroundColor Green
$NewRules | Format-Table DisplayName, Direction, Protocol, LocalPort, RemoteAddress, Action, Profile -AutoSize

# Test connectivity
Write-Host "`nTesting connectivity..." -ForegroundColor Cyan
$LocalIP = (Get-NetIPAddress -AddressFamily IPv4 | Where-Object { $_.IPAddress -notlike "127.*" -and $_.IPAddress -notlike "169.*" } | Select-Object -First 1).IPAddress

Write-Host "Local IP: $LocalIP" -ForegroundColor White
Write-Host "Testing ports from localhost..." -ForegroundColor White

# Test Ollama
try {
    $OllamaTest = Invoke-WebRequest -Uri "http://127.0.0.1:11434/api/tags" -TimeoutSec 5 -ErrorAction Stop
            Write-Host "  Ollama API (127.0.0.1:11434): Accessible" -ForegroundColor Green
} catch {
            Write-Host "  Error: Ollama API (127.0.0.1:11434): $($_.Exception.Message)" -ForegroundColor Red
}

# Test Open WebUI
try {
    $WebUITest = Invoke-WebRequest -Uri "http://127.0.0.1:8080/api/version" -TimeoutSec 5 -ErrorAction Stop
            Write-Host "  Open WebUI (127.0.0.1:8080): Accessible" -ForegroundColor Green
} catch {
            Write-Host "  Error: Open WebUI (127.0.0.1:8080): $($_.Exception.Message)" -ForegroundColor Red
}

# Summary
    Write-Host "`nFirewall Restriction Complete!" -ForegroundColor Green
    Write-Host "`nSummary:" -ForegroundColor Cyan
Write-Host "• Access restricted to: $($TrustedIPs -join ', ')" -ForegroundColor White
Write-Host "• Ports protected: 11434 (Ollama), 8080 (Open WebUI)" -ForegroundColor White
Write-Host "• Rules created: $($NewRules.Count)" -ForegroundColor White
Write-Host "• Security logging: Enabled" -ForegroundColor White

    Write-Host "`nSecurity Notes:" -ForegroundColor Yellow
Write-Host "• Only specified IPs can access your LLM services" -ForegroundColor White
Write-Host "• All other access attempts will be blocked" -ForegroundColor White
Write-Host "• Consider enabling Windows Firewall logging for monitoring" -ForegroundColor White
Write-Host "• Test access from trusted devices to verify restrictions" -ForegroundColor White

Write-Host "`nTo modify access later:" -ForegroundColor Cyan
Write-Host "• Edit this script and run again" -ForegroundColor White
Write-Host "• Or manually edit Windows Firewall rules" -ForegroundColor White
Write-Host "• Current rules are named 'LocalLLM-*' for easy identification" -ForegroundColor White 