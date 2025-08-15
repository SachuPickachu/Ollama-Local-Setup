# =============================================================================
# Local LLM Stack - Production Readiness Test Script
# =============================================================================
# This script tests all the production-ready scripts to ensure they work correctly
# with the new functions library and environment configuration.

param(
    [switch]$Verbose,
    [switch]$SkipStartup,
    [switch]$SkipShutdown
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
if (-not (Initialize-Logging -ScriptName "test-production" -LogLevel $(if ($Verbose) { "DEBUG" } else { "INFO" }))) {
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

Write-Log "Starting production readiness test" "INFO"

# Helper function for colored output
function Write-Status {
    param([string]$Message, [string]$Color = "White")
    Write-Host $Message -ForegroundColor $Color
}

function Write-TestResult {
    param([string]$TestName, [bool]$Passed, [string]$Details = "")
    $icon = if ($Passed) { "PASS" } else { "FAIL" }
    $color = if ($Passed) { "Green" } else { "Red" }
    Write-Status "$icon $TestName" $color
    if ($Details -and -not $Passed) {
        Write-Status "   Details: $Details" "Yellow"
    }
}

try {
    Write-Status "Production Readiness Test Suite" "Cyan"
    Write-Status "=====================================" "Cyan"
    Write-Log "Production readiness test suite started" "INFO"

    $testResults = @{}
    $overallPassed = $true

    # =============================================================================
    # Test 1: Environment Configuration
    # =============================================================================
    Write-Status "`n1. Environment Configuration Test" "Yellow"
    
    # Test environment variables dynamically
    Write-Log "Checking environment variables from loaded configuration" "INFO"
    
    # Get the environment file path
    $envFile = Get-ProjectPath "config\env.ps1"
    $envTestPassed = $true
    
    if (Test-Path $envFile) {
        Write-Log "Environment file found: $envFile" "INFO"
        
        # Read the environment file content to see what variables are defined
        $envContent = Get-Content $envFile -Raw
        $envTestPassed = $true
        
        # Parse environment file to find all defined variables dynamically
        $definedVars = @()
        $envLines = Get-Content $envFile
        
        foreach ($line in $envLines) {
            $line = $line.Trim()
            # Look for lines that set environment variables (e.g., $env:VAR = "value")
            if ($line -match '^\$env:(\w+)\s*=') {
                $varName = $matches[1]
                $definedVars += $varName
            }
        }
        
        Write-Log "Found $($definedVars.Count) environment variables defined in config file" "INFO"
        
        # Check which of the defined variables are actually set in the current environment
        $setVars = @()
        $missingVars = @()
        
        foreach ($var in $definedVars) {
            # Check if environment variable is set using proper syntax
            $envValue = Get-Item "env:$var" -ErrorAction SilentlyContinue
            if ($envValue) {
                $setVars += $var
            } else {
                $missingVars += $var
                Write-Log "Environment variable defined but not set: $var" "WARN"
            }
        }
        
        # Determine test result based on whether critical variables are set
        $criticalPatterns = @('DATA_ROOT', 'OLLAMA', 'WEB_UI', 'PORT', 'BASE_URL', 'TIMEOUT')
        $criticalSet = @()
        foreach ($var in $setVars) {
            foreach ($pattern in $criticalPatterns) {
                if ($var -like "*$pattern*") {
                    $criticalSet += $var
                    break  # Found a match, move to next variable
                }
            }
        }
        
        if ($criticalSet.Count -ge 5) {  # At least 5 critical variables should be set
            $envTestPassed = $true
        } else {
            $envTestPassed = $false
        }
        
        # Show what we found
        if ($envTestPassed) {
            Write-Log "Sufficient critical environment variables are set" "INFO"
            Write-Status "   Defined: $($definedVars.Count) variables in config" "Green"
            Write-Status "   Set: $($setVars.Count) variables in environment" "Green"
            Write-Status "   Critical: $($criticalSet.Count) critical variables" "Green"
        } else {
            Write-Log "Insufficient critical environment variables are set" "WARN"
            Write-Status "   Defined: $($definedVars.Count) variables in config" "Yellow"
            Write-Status "   Set: $($setVars.Count) variables in environment" "Yellow"
            Write-Status "   Critical: $($criticalSet.Count) critical variables (need 5+)" "Red"
        }
        
        if ($missingVars.Count -gt 0) {
            Write-Status "   Not set: $($missingVars.Count) variables" "Yellow"
        }
        
        # Also show some non-critical variables that are set
        $allEnvVars = Get-ChildItem Env: | Where-Object { $_.Name -like "*OLLAMA*" -or $_.Name -like "*WEB_UI*" -or $_.Name -like "*DATA*" -or $_.Name -like "*LOG*" }
        if ($allEnvVars) {
            Write-Log "Found $($allEnvVars.Count) project-related environment variables" "INFO"
            Write-Status "   Project vars: $($allEnvVars.Count) found" "Cyan"
        }
        
    } else {
        $envTestPassed = $false
        Write-Log "Environment file not found: $envFile" "ERROR"
        Write-Status "   Error: Environment file missing" "Red"
    }
    
    Write-TestResult "Environment Variables" $envTestPassed
    $testResults['Environment'] = $envTestPassed
    $overallPassed = $overallPassed -and $envTestPassed

    # Test directory creation
    $dirTestPassed = $true
    $requiredDirs = @($env:DATA_ROOT, $env:LOG_DIR)
    foreach ($dir in $requiredDirs) {
        if (-not (Test-Path $dir)) {
            $dirTestPassed = $false
            Write-Log "Required directory does not exist: $dir" "ERROR"
        }
    }
    
    Write-TestResult "Directory Structure" $dirTestPassed
    $testResults['Directories'] = $dirTestPassed
    $overallPassed = $overallPassed -and $dirTestPassed

    # =============================================================================
    # Test 2: Functions Library
    # =============================================================================
    Write-Status "`n2. Functions Library Test" "Yellow"
    
    $functionsTestPassed = $true
    
    # Test key functions
    $testFunctions = @(
        'Get-ScriptRoot',
        'Get-ProjectPath', 
        'Load-Environment',
        'Test-Environment',
        'Test-ServiceHealth',
        'Test-PortActive'
    )
    
    foreach ($func in $testFunctions) {
        if (-not (Get-Command $func -ErrorAction SilentlyContinue)) {
            $functionsTestPassed = $false
            Write-Log "Function not available: $func" "ERROR"
        }
    }
    
    Write-TestResult "Functions Availability" $functionsTestPassed
    $testResults['Functions'] = $functionsTestPassed
    $overallPassed = $overallPassed -and $functionsTestPassed

    # Test path resolution
    try {
        $projectRoot = Get-ScriptRoot
        $envPath = Get-ProjectPath "config\env.ps1"
        $pathTestPassed = (Test-Path $envPath)
    } catch {
        $pathTestPassed = $false
        Write-Log "Path resolution test failed: $($_.Exception.Message)" "ERROR"
    }
    
    Write-TestResult "Path Resolution" $pathTestPassed
    $testResults['PathResolution'] = $pathTestPassed
    $overallPassed = $overallPassed -and $pathTestPassed

    # =============================================================================
    # Test 3: Script Availability
    # =============================================================================
    Write-Status "`n3. Script Availability Test" "Yellow"
    
    $scriptsTestPassed = $true
    
    # Get the scripts directory
    $scriptsDir = Get-ProjectPath "scripts"
    if (Test-Path $scriptsDir) {
        Write-Log "Scripts directory found: $scriptsDir" "INFO"
        
        # Get all PowerShell scripts in the scripts directory
        $allScripts = Get-ChildItem -Path $scriptsDir -Filter "*.ps1" | Select-Object -ExpandProperty Name
        Write-Log "Found $($allScripts.Count) PowerShell scripts in scripts directory" "INFO"
        Write-Log "Available scripts: $($allScripts -join ', ')" "DEBUG"
        
        # Define critical script patterns (more flexible than exact names)
        $criticalPatterns = @(
            "start-all",
            "stop-all", 
            "status",
            "start-ollama",
            "start-webui"
        )
        
        # Find scripts that match critical patterns
        $criticalScripts = @()
        foreach ($pattern in $criticalPatterns) {
            $matchingScripts = @()
            foreach ($script in $allScripts) {
                if ($script -like "*$pattern*") {
                    $matchingScripts += $script
                }
            }
            if ($matchingScripts.Count -gt 0) {
                $criticalScripts += $matchingScripts[0]  # Take first match
                Write-Log "Pattern '$pattern' matched script: $($matchingScripts[0])" "DEBUG"
            } else {
                Write-Log "Pattern '$pattern' found no matches" "DEBUG"
            }
        }
        
        # Debug: Show what we found
        Write-Log "Critical patterns: $($criticalPatterns -join ', ')" "DEBUG"
        Write-Log "Found critical scripts: $($criticalScripts -join ', ')" "DEBUG"
        
        $missingScripts = @()
        foreach ($script in $criticalScripts) {
            $scriptPath = Get-ProjectPath "scripts\$script"
            if (-not (Test-Path $scriptPath)) {
                $scriptsTestPassed = $false
                $missingScripts += $script
                Write-Log "Critical script not found: $script" "ERROR"
            }
        }
        
        # Check if we found enough critical scripts
        if ($criticalScripts.Count -lt 4) {  # Should have at least 4 critical scripts
            $scriptsTestPassed = $false
            Write-Log "Insufficient critical scripts found: $($criticalScripts.Count)/5 expected" "WARN"
        }
        
        # Show what we found
        if ($scriptsTestPassed) {
            Write-Log "All critical scripts are available" "INFO"
            Write-Status "   Found: $($criticalScripts.Count) critical scripts" "Green"
        } else {
            Write-Log "Some critical scripts are missing" "WARN"
            Write-Status "   Missing: $($missingScripts -join ', ')" "Red"
        }
        
        # Show total script count
        Write-Status "   Total scripts: $($allScripts.Count) found" "Cyan"
        
    } else {
        $scriptsTestPassed = $false
        Write-Log "Scripts directory not found: $scriptsDir" "ERROR"
        Write-Status "   Error: Scripts directory missing" "Red"
    }
    
    Write-TestResult "Script Availability" $scriptsTestPassed
    $testResults['Scripts'] = $scriptsTestPassed
    $overallPassed = $overallPassed -and $scriptsTestPassed

    # =============================================================================
    # Test 4: Service Status Check
    # =============================================================================
    Write-Status "`n4. Service Status Test" "Yellow"
    
    $statusTestPassed = $true
    
    # Test status script execution
    try {
        $statusScript = Get-ProjectPath "scripts\status.ps1"
        $statusResult = & $statusScript -NoLogging 2>&1
        $statusExitCode = $LASTEXITCODE
        
        # Status script should return 0 if services are running, 1 if not running
        # This is expected behavior, not an error
        if ($statusExitCode -eq 0 -or $statusExitCode -eq 1) {
            Write-Log "Status script executed successfully (exit code: $statusExitCode)" "INFO"
            if ($statusExitCode -eq 1) {
                Write-Log "Status script correctly reported no services running" "INFO"
            }
        } else {
            $statusTestPassed = $false
            Write-Log "Status script failed with unexpected exit code: $statusExitCode" "ERROR"
        }
    } catch {
        $statusTestPassed = $false
        Write-Log "Status script execution failed: $($_.Exception.Message)" "ERROR"
    }
    
    Write-TestResult "Status Script Execution" $statusTestPassed
    $testResults['StatusScript'] = $statusTestPassed
    $overallPassed = $overallPassed -and $statusTestPassed

    # =============================================================================
    # Test 5: Service Startup/Shutdown (Optional)
    # =============================================================================
    if (-not $SkipStartup) {
        Write-Status "`n5. Service Lifecycle Test" "Yellow"
        Write-Status "Warning: This will start and stop services - ensure no critical work is running" "Yellow"
        
        $response = Read-Host "Continue with service lifecycle test? (y/N)"
        if ($response -match "^[Yy]") {
            Write-Log "User approved service lifecycle test" "INFO"
            
            # Test startup
            try {
                Write-Status "Testing service startup..." "Cyan"
                $startScript = Get-ProjectPath "scripts\start-all.ps1"
                $startResult = & $startScript -SkipHealthCheck -NoLogging 2>&1
                $startExitCode = $LASTEXITCODE
                
                if ($startExitCode -eq 0) {
                    Write-TestResult "Service Startup" $true
                    $testResults['Startup'] = $true
                    
                    # Wait for services to stabilize
                    Start-Sleep -Seconds 5
                    
                    # Test shutdown
                    if (-not $SkipShutdown) {
                        Write-Status "Testing service shutdown..." "Cyan"
                        $stopScript = Get-ProjectPath "scripts\stop-all.ps1"
                        $stopResult = & $stopScript -NoLogging 2>&1
                        $stopExitCode = $LASTEXITCODE
                        
                        if ($stopExitCode -eq 0) {
                            Write-TestResult "Service Shutdown" $true
                            $testResults['Shutdown'] = $true
                        } else {
                            Write-TestResult "Service Shutdown" $false "Exit code: $stopExitCode"
                            $testResults['Shutdown'] = $false
                            $overallPassed = $false
                        }
                    }
                } else {
                    Write-TestResult "Service Startup" $false "Exit code: $startExitCode"
                    $testResults['Startup'] = $false
                    $overallPassed = $false
                }
            } catch {
                Write-TestResult "Service Lifecycle" $false $($_.Exception.Message)
                $testResults['Lifecycle'] = $false
                $overallPassed = $false
            }
        } else {
            Write-Status "Skipping service lifecycle test" "Yellow"
            $testResults['Lifecycle'] = $null
        }
    } else {
        Write-Status "`n5. Service Lifecycle Test" "Yellow"
        Write-Status "Skipped as requested" "Yellow"
        $testResults['Lifecycle'] = $null
    }

    # =============================================================================
    # Test Results Summary
    # =============================================================================
    Write-Status "`nTest Results Summary" "Cyan"
    Write-Status "=======================" "Cyan"
    
    foreach ($test in $testResults.Keys) {
        if ($testResults[$test] -ne $null) {
            $result = if ($testResults[$test]) { "PASS" } else { "FAIL" }
            $color = if ($testResults[$test]) { "Green" } else { "Red" }
            Write-Status "   $test`: $result" $color
        } else {
            Write-Status "   $test`: SKIP" "Yellow"
        }
    }
    
    Write-Status "`nOverall Result:" "Cyan"
    if ($overallPassed) {
        Write-Status "ALL TESTS PASSED - Production Ready!" "Green"
        Write-Log "All production readiness tests passed" "INFO"
        exit 0
    } else {
        Write-Status "SOME TESTS FAILED - Review Issues Above" "Red"
        Write-Log "Some production readiness tests failed" "ERROR"
        exit 1
    }
    
} catch {
    $errorMsg = "Critical error in production readiness test: $($_.Exception.Message)"
    Write-Log $errorMsg "ERROR"
    Write-Status $errorMsg "Red"
    exit 1
}
