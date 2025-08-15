# =============================================================================
# Ollama Models Listing Script
# =============================================================================
# This script lists all available Ollama models with detailed information
# including versions, sizes, and metadata.

param(
    [switch]$Verbose,
    [switch]$NoColor,
    [switch]$ShowSizes,
    [switch]$ShowMetadata
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
if (-not (Initialize-Logging -ScriptName "list-models" -LogLevel $(if ($Verbose) { "DEBUG" } else { "INFO" }))) {
    Write-Error "Failed to initialize logging"
    exit 1
}

Write-Log "Starting Ollama Models Listing" "INFO"

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
    Write-Status "Ollama Models Listing" "Cyan"
    Write-Status "=====================" "Cyan"
    Write-Log "Models listing started" "INFO"

    $modelsPath = $env:OLLAMA_MODELS
    if (-not (Test-Path $modelsPath)) {
        Write-Status "Models directory not found: $modelsPath" "Red"
        Write-Log "Models directory not found: $modelsPath" "ERROR"
        exit 1
    }

    # Check for model manifests
    $manifestPath = Join-Path $modelsPath "manifests\registry.ollama.ai\library"
    if (-not (Test-Path $manifestPath)) {
        Write-Status "No model manifests found in: $manifestPath" "Yellow"
        Write-Log "No model manifests found in: $manifestPath" "WARN"
        exit 1
    }

    # Get all model families
    $modelFamilies = Get-ChildItem -Path $manifestPath -Directory -ErrorAction SilentlyContinue
    if (-not $modelFamilies) {
        Write-Status "No model families found" "Yellow"
        Write-Log "No model families found in manifests directory" "WARN"
        exit 1
    }

    # Collect all models with their versions
    $allModels = @()
    $totalSize = 0

    foreach ($family in $modelFamilies) {
        $modelVersions = Get-ChildItem -Path $family.FullName -File -ErrorAction SilentlyContinue
        if ($modelVersions) {
            foreach ($version in $modelVersions) {
                $modelInfo = @{
                    Family = $family.Name
                    Version = $version.Name
                    FullName = "$($family.Name):$($version.Name)"
                    Path = $version.FullName
                    Size = 0
                    Metadata = $null
                }

                # Get model size if requested
                if ($ShowSizes) {
                    try {
                        $modelFiles = Get-ChildItem -Path $family.FullName -Recurse -File -ErrorAction SilentlyContinue
                        if ($modelFiles) {
                            $modelSize = ($modelFiles | Measure-Object -Property Length -Sum).Sum
                            $modelInfo.Size = $modelSize
                            $totalSize += $modelSize
                        }
                    } catch {
                        Write-Log "Failed to get size for $($modelInfo.FullName): $($_.Exception.Message)" "WARN"
                    }
                }

                # Get metadata if requested
                if ($ShowMetadata) {
                    try {
                        $manifestFile = Join-Path $family.FullName "$($version.Name).json"
                        if (Test-Path $manifestFile) {
                            $manifestContent = Get-Content -Path $manifestFile -Raw -ErrorAction Stop | ConvertFrom-Json
                            if ($manifestContent) {
                                $modelInfo.Metadata = $manifestContent
                            }
                        }
                    } catch {
                        Write-Log "Failed to get metadata for $($modelInfo.FullName): $($_.Exception.Message)" "WARN"
                    }
                }

                $allModels += $modelInfo
            }
        } else {
            # Single model without version
            $modelInfo = @{
                Family = $family.Name
                Version = "latest"
                FullName = $family.Name
                Path = $family.FullName
                Size = 0
                Metadata = $null
            }
            $allModels += $modelInfo
        }
    }

    if ($allModels.Count -eq 0) {
        Write-Status "No models found" "Yellow"
        Write-Log "No models found in manifests" "WARN"
        exit 1
    }

    # Display summary
    Write-Status "`nFound $($allModels.Count) model(s)" "Green"
    if ($ShowSizes -and $totalSize -gt 0) {
        $totalSizeGB = [math]::Round($totalSize / (1024*1024*1024), 2)
        Write-Status "Total size: $totalSizeGB GB" "Cyan"
    }
        Write-Log "Found $($allModels.Count) models" "INFO"
    
    # Group models by family for better display
    $modelsByFamily = $allModels | Group-Object -Property Family | Sort-Object Name

    foreach ($familyGroup in $modelsByFamily) {
        foreach ($model in $familyGroup.Group) {
            $versionInfo = if ($model.Version -eq "latest") { "" } else { ":$($model.Version)" }
            $sizeInfo = if ($ShowSizes -and $model.Size -gt 0) { 
                $sizeMB = [math]::Round($model.Size / (1024*1024), 2)
                " ($sizeMB MB)" 
            } else { "" }
            
            Write-Status "    - $($model.Family)$versionInfo$sizeInfo" "Cyan"
            
            if ($ShowMetadata -and $model.Metadata) {
                if ($model.Metadata.description) {
                    Write-Status "      Description: $($model.Metadata.description)" "Gray"
                }
                if ($model.Metadata.license) {
                    Write-Status "      License: $($model.Metadata.license)" "Gray"
                }
                if ($model.Metadata.size) {
                    $metaSizeGB = [math]::Round($model.Metadata.size / (1024*1024*1024), 2)
                    Write-Status "      Model Size: $metaSizeGB GB" "Gray"
                }
            }
            
            Write-Log "Model: $($model.FullName)" "DEBUG"
        }
    }

    # Show quick access commands
    Write-Status "`nQuick Access Commands:" "Yellow"
    Write-Status "  To run a model: ollama run <model_name>" "Cyan"
    Write-Status "  To pull a model: ollama pull <model_name>" "Cyan"
    Write-Status "  To remove a model: ollama rm <model_name>" "Cyan"

    Write-Log "Models listing completed successfully" "INFO"
    exit 0

} catch {
    $errorMsg = "Error listing models: $($_.Exception.Message)"
    Write-Log $errorMsg "ERROR"
    Write-Status $errorMsg "Red"
    exit 1
}
