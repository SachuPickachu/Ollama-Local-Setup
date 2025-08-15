# =============================================================================
# Local LLM Stack - Common Functions Library
# =============================================================================
# This file contains common functions used across all scripts
# Import this file in your scripts: . "$PSScriptRoot\..\config\functions.ps1"

# =============================================================================
# Path Resolution Functions
# =============================================================================

function Get-ScriptRoot {
    <#
    .SYNOPSIS
    Gets the root directory of the Local LLM Stack project
    .DESCRIPTION
    Returns the absolute path to the project root, regardless of where the script is called from
    .EXAMPLE
    $projectRoot = Get-ScriptRoot
    .NOTES
    This function ensures scripts work correctly regardless of current working directory
    #>
    param()
    
    # Use PROJECT_ROOT environment variable if available
    if (Test-Path "env:PROJECT_ROOT") {
        return $env:PROJECT_ROOT
    }
    
    # Fallback: Try to find the project root by looking for config/env.ps1
    $currentPath = $PSScriptRoot
    while ($currentPath -and -not (Test-Path (Join-Path $currentPath "config\env.ps1"))) {
        $currentPath = Split-Path $currentPath -Parent
    }
    
    if (-not $currentPath) {
        throw "Could not find project root (config/env.ps1 not found in any parent directory)"
    }
    
    return $currentPath
}

function Get-ProjectPath {
    <#
    .SYNOPSIS
    Gets a path relative to the project root
    .DESCRIPTION
    Returns the absolute path for a file or directory relative to the project root
    .PARAMETER RelativePath
    The relative path from the project root
    .EXAMPLE
    $envPath = Get-ProjectPath "config\env.ps1"
    $scriptsPath = Get-ProjectPath "scripts"
    .NOTES
    Use this function to ensure paths work regardless of current working directory
    #>
    param([string]$RelativePath)
    
    $projectRoot = Get-ScriptRoot
    return Join-Path $projectRoot $RelativePath
}

function Load-Environment {
    <#
    .SYNOPSIS
    Loads the environment configuration
    .DESCRIPTION
    Loads and validates the environment configuration from config/env.ps1
    .EXAMPLE
    Load-Environment
    .NOTES
    This function should be called at the beginning of every script
    #>
    param()
    
    try {
        $envPath = Get-ProjectPath "config\env.ps1"
        if (-not (Test-Path $envPath)) {
            throw "Environment configuration file not found: $envPath"
        }
        
        . $envPath
        
        # Validate critical environment variables
        $requiredVars = @(
            'DATA_ROOT',
            'OLLAMA_PORT',
            'WEB_UI_PORT',
            'OLLAMA_BASE_URL',
            'WEB_UI_BASE_URL'
        )
        
        foreach ($var in $requiredVars) {
            if (-not (Test-Path "env:$var")) {
                throw "Required environment variable not set: $var"
            }
        }
        
        Write-Verbose "Environment loaded successfully from: $envPath"
        return $true
        
    } catch {
        Write-Error "Failed to load environment: $($_.Exception.Message)"
        return $false
    }
}

# =============================================================================
# Logging Functions
# =============================================================================

function Initialize-Logging {
    <#
    .SYNOPSIS
    Initializes logging for the current script
    .DESCRIPTION
    Sets up logging with file output and console display
    .PARAMETER ScriptName
    Name of the script for log file naming
    .PARAMETER LogLevel
    Minimum log level to display (DEBUG, INFO, WARN, ERROR)
    .EXAMPLE
    Initialize-Logging -ScriptName "start-all" -LogLevel "INFO"
    .NOTES
    Creates log directory if it doesn't exist and sets up global logging variables
    #>
    param(
        [string]$ScriptName,
        [ValidateSet("DEBUG", "INFO", "WARN", "ERROR")]
        [string]$LogLevel = "INFO"
    )
    
    try {
        # Ensure log directory exists
        $logDir = $env:LOG_DIR
        if (-not (Test-Path $logDir)) {
            New-Item -ItemType Directory -Path $logDir -Force | Out-Null
        }
        
        # Create log file name
        $timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
        $logFile = Join-Path $logDir "${ScriptName}-${timestamp}.log"
        
        # Set global variables for logging
        $script:LogFile = $logFile
        $script:LogLevel = $LogLevel
        
        # Define log level priorities
        $script:LogLevels = @{
            "DEBUG" = 0
            "INFO" = 1
            "WARN" = 2
            "ERROR" = 3
        }
        
        Write-Verbose "Logging initialized: $logFile (Level: $LogLevel)"
        return $true
        
    } catch {
        Write-Error "Failed to initialize logging: $($_.Exception.Message)"
        return $false
    }
}

function Write-Log {
    <#
    .SYNOPSIS
    Writes a log message with timestamp and level
    .DESCRIPTION
    Writes a formatted log message to both console and log file
    .PARAMETER Message
    The message to log
    .PARAMETER Level
    The log level (DEBUG, INFO, WARN, ERROR)
    .PARAMETER NoConsole
    Skip console output if true
    .EXAMPLE
    Write-Log "Service started successfully" "INFO"
    Write-Log "Debug information" "DEBUG"
    .NOTES
    Requires Initialize-Logging to be called first
    #>
    param(
        [string]$Message,
        [ValidateSet("DEBUG", "INFO", "WARN", "ERROR")]
        [string]$Level = "INFO",
        [switch]$NoConsole
    )
    
    try {
        # Check if logging is initialized
        if (-not $script:LogFile -or -not $script:LogLevel) {
            throw "Logging not initialized. Call Initialize-Logging first."
        }
        
        # Check log level
        if ($script:LogLevels[$Level] -lt $script:LogLevels[$script:LogLevel]) {
            return
        }
        
        # Format log entry
        $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        $logEntry = "[$timestamp] [$Level] $Message"
        
        # Write to log file
        Add-Content -Path $script:LogFile -Value $logEntry -ErrorAction Stop
        
        # Write to console (unless NoConsole is specified)
        if (-not $NoConsole) {
            $color = switch ($Level) {
                "DEBUG" { "Gray" }
                "INFO" { "White" }
                "WARN" { "Yellow" }
                "ERROR" { "Red" }
            }
            Write-Host $logEntry -ForegroundColor $color
        }
        
    } catch {
        Write-Error "Failed to write log: $($_.Exception.Message)"
    }
}

# =============================================================================
# Service Management Functions
# =============================================================================

function Test-ServiceHealth {
    <#
    .SYNOPSIS
    Tests the health of a service by checking its endpoint
    .DESCRIPTION
    Performs an HTTP health check on a service endpoint
    .PARAMETER Url
    The health check URL
    .PARAMETER Timeout
    Timeout in seconds for the health check
    .PARAMETER RetryCount
    Number of retries for the health check
    .EXAMPLE
    $healthy = Test-ServiceHealth -Url "http://127.0.0.1:11434/api/tags" -Timeout 5
    .NOTES
    Returns true if the service responds successfully, false otherwise
    #>
    param(
        [string]$Url,
        [int]$Timeout = 5,
        [int]$RetryCount = 1
    )
    
    for ($i = 0; $i -le $RetryCount; $i++) {
        try {
            $response = Invoke-WebRequest -Uri $Url -TimeoutSec $Timeout -ErrorAction Stop
            if ($response.StatusCode -eq 200) {
                return $true
            }
        } catch {
            if ($i -eq $RetryCount) {
                Write-Verbose "Health check failed after $($RetryCount + 1) attempts: $($_.Exception.Message)"
                return $false
            }
            Start-Sleep -Seconds 1
        }
    }
    
    return $false
}

function Wait-ForService {
    <#
    .SYNOPSIS
    Waits for a service to become healthy
    .DESCRIPTION
    Polls a service endpoint until it becomes healthy or timeout is reached
    .PARAMETER Url
    The health check URL
    .PARAMETER Timeout
    Maximum time to wait in seconds
    .PARAMETER Interval
    Polling interval in seconds
    .PARAMETER ServiceName
    Name of the service for logging
    .EXAMPLE
    $ready = Wait-ForService -Url "http://127.0.0.1:11434/api/tags" -Timeout 60 -ServiceName "Ollama"
    .NOTES
    Returns true if service becomes healthy within timeout, false otherwise
    #>
    param(
        [string]$Url,
        [int]$Timeout = 60,
        [int]$Interval = 2,
        [string]$ServiceName = "Service"
    )
    
    $elapsed = 0
    Write-Host "⏳ Waiting for $ServiceName to be ready..." -ForegroundColor Cyan
    
    while ($elapsed -lt $Timeout) {
        if (Test-ServiceHealth -Url $Url -Timeout 5) {
            Write-Host "✅ $ServiceName is ready (${elapsed}s)" -ForegroundColor Green
            return $true
        }
        
        Start-Sleep -Seconds $Interval
        $elapsed += $Interval
        
        if ($elapsed -lt $Timeout) {
            Write-Host "⏳ Waiting for $ServiceName... (${elapsed}s/${Timeout}s)" -ForegroundColor Yellow
        }
    }
    
    Write-Host "❌ $ServiceName failed to start within ${Timeout} seconds" -ForegroundColor Red
    return $false
}

function Get-ProcessInfo {
    <#
    .SYNOPSIS
    Gets detailed information about a process
    .DESCRIPTION
    Returns process information including memory usage and uptime
    .PARAMETER ProcessName
    Name of the process to get information about
    .EXAMPLE
    $info = Get-ProcessInfo -ProcessName "ollama"
    .NOTES
    Returns null if process is not found
    #>
    param([string]$ProcessName)
    
    try {
        $process = Get-Process -Name $ProcessName -ErrorAction SilentlyContinue
        if ($process) {
            return @{
                Id = $process.Id
                ProcessName = $process.ProcessName
                MemoryMB = [math]::Round($process.WorkingSet / (1024*1024), 2)
                UptimeMinutes = [math]::Round(((Get-Date) - $process.StartTime).TotalMinutes, 1)
                StartTime = $process.StartTime
            }
        }
        return $null
    } catch {
        Write-Verbose "Failed to get process info for $ProcessName - $($_.Exception.Message)"
        return $null
    }
}

# =============================================================================
# Port Management Functions
# =============================================================================

function Test-PortActive {
    <#
    .SYNOPSIS
    Tests if a port is active
    .DESCRIPTION
    Checks if a specific port is listening on the system
    .PARAMETER Port
    The port number to check
    .EXAMPLE
    $active = Test-PortActive -Port 11434
    .NOTES
    Returns true if port is active, false otherwise
    #>
    param([int]$Port)
    
    try {
        # Check for listening ports (State = Listen)
        $listeningPorts = Get-NetTCPConnection -LocalPort $Port -State Listen -ErrorAction SilentlyContinue
        if ($listeningPorts) {
            return $true
        }
        
        # Also check for established connections as fallback
        $establishedPorts = Get-NetTCPConnection -LocalPort $Port -State Established -ErrorAction SilentlyContinue
        return [bool]$establishedPorts
    } catch {
        return $false
    }
}

function Get-PortProcess {
    <#
    .SYNOPSIS
    Gets the process using a specific port
    .DESCRIPTION
    Returns information about the process bound to a port
    .PARAMETER Port
    The port number to check
    .EXAMPLE
    $process = Get-PortProcess -Port 11434
    .NOTES
    Returns null if no process is using the port
    #>
    param([int]$Port)
    
    try {
        $connection = Get-NetTCPConnection -LocalPort $Port -ErrorAction SilentlyContinue | Select-Object -First 1
        if ($connection) {
            $process = Get-Process -Id $connection.OwningProcess -ErrorAction SilentlyContinue
            if ($process) {
                return @{
                    Id = $process.Id
                    ProcessName = $process.ProcessName
                    Path = $process.Path
                }
            }
        }
        return $null
    } catch {
        Write-Verbose "Failed to get port process info for port $Port - $($_.Exception.Message)"
        return $null
    }
}

# =============================================================================
# Error Handling Functions
# =============================================================================

function Invoke-WithErrorHandling {
    <#
    .SYNOPSIS
    Executes a script block with comprehensive error handling
    .DESCRIPTION
    Wraps script execution with try-catch and logging
    .PARAMETER ScriptBlock
    The script block to execute
    .PARAMETER ErrorMessage
    Custom error message if execution fails
    .PARAMETER ExitOnError
    Whether to exit the script on error
    .EXAMPLE
    Invoke-WithErrorHandling -ScriptBlock { . .\scripts\start-ollama.ps1 } -ErrorMessage "Failed to start Ollama"
    .NOTES
    Provides consistent error handling across all scripts
    #>
    param(
        [scriptblock]$ScriptBlock,
        [string]$ErrorMessage = "Script execution failed",
        [switch]$ExitOnError
    )
    
    try {
        $result = & $ScriptBlock
        return $result
    } catch {
        $errorMsg = "$ErrorMessage - $($_.Exception.Message)"
        Write-Log $errorMsg "ERROR"
        Write-Error $errorMsg
        
        if ($ExitOnError) {
            exit 1
        }
        return $false
    }
}

# =============================================================================
# Validation Functions
# =============================================================================

function Test-Environment {
    <#
    .SYNOPSIS
    Validates the environment configuration
    .DESCRIPTION
    Checks that all required environment variables and paths are properly configured
    .EXAMPLE
    $valid = Test-Environment
    .NOTES
    Returns true if environment is valid, false otherwise
    #>
    param()
    
    try {
        # Check required environment variables
        $requiredVars = @{
            'DATA_ROOT' = 'Data root directory'
            'OLLAMA_PORT' = 'Ollama port'
            'WEB_UI_PORT' = 'WebUI port'
            'OLLAMA_BASE_URL' = 'Ollama base URL'
            'WEB_UI_BASE_URL' = 'WebUI base URL'
        }
        
        foreach ($var in $requiredVars.Keys) {
            if (-not (Test-Path "env:$var")) {
                Write-Error "Missing required environment variable: $var ($($requiredVars[$var]))"
                return $false
            }
        }
        
        # Check required directories
        $requiredDirs = @(
            $env:DATA_ROOT,
            $env:LOG_DIR
        )
        
        foreach ($dir in $requiredDirs) {
            if (-not (Test-Path $dir)) {
                Write-Error "Required directory does not exist: $dir"
                return $false
            }
        }
        
        Write-Verbose "Environment validation passed"
        return $true
        
    } catch {
        Write-Error "Environment validation failed: $($_.Exception.Message)"
        return $false
    }
}

# Functions are now available for use in other scripts via dot-sourcing
