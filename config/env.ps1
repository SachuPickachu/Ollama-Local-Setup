# =============================================================================
# Local LLM Stack Environment Configuration
# =============================================================================

# Set the single data root for all portable state
$env:DATA_ROOT = "E:\\OLLAMA"

# =============================================================================
# Project Configuration
# =============================================================================

# Project root directory (auto-detected)
# This will automatically find the project root regardless of where the repository is cloned
# Since this file is in config/, we need to go up one level to find the project root
$env:PROJECT_ROOT = Split-Path $PSScriptRoot -Parent

# =============================================================================
# Service Configuration
# =============================================================================

# Ollama Configuration
$env:OLLAMA_HOST = "127.0.0.1:11434"
$env:OLLAMA_PORT = "11434"
$env:OLLAMA_BASE_URL = "http://127.0.0.1:11434"
$env:OLLAMA_BIND_ADDRESS = "127.0.0.1"
$env:OLLAMA_MODELS = "$env:DATA_ROOT\models\ollama"

# Open WebUI Configuration
$env:WEB_UI_PORT = "8080"
$env:WEB_UI_HOST = "127.0.0.1"
$env:WEB_UI_BASE_URL = "http://127.0.0.1:8080"
$env:WEB_UI_BIND_ADDRESS = "0.0.0.0"
$env:DATA_DIR = "$env:DATA_ROOT\webui"

# =============================================================================
# Timeout and Retry Configuration
# =============================================================================

# Service startup timeouts (seconds)
$env:OLLAMA_STARTUP_TIMEOUT = "60"
$env:WEB_UI_STARTUP_TIMEOUT = "60"
$env:HEALTH_CHECK_TIMEOUT = "10"
$env:HEALTH_CHECK_RETRY_COUNT = "3"

# =============================================================================
# Logging Configuration
# =============================================================================

$env:LOG_LEVEL = "INFO"  # DEBUG, INFO, WARN, ERROR
$env:LOG_DIR = "$env:DATA_ROOT\logs"
$env:LOG_RETENTION_DAYS = "30"

# =============================================================================
# Cache and Temporary Directories
# =============================================================================

# RAG (Phase 3): local on-disk vector store
$env:CHROMA_PERSIST_DIRECTORY = "$env:DATA_ROOT\rags\chroma"

# Optional: steer caches/temp away from C: to save space
$env:PIP_CACHE_DIR = "$env:DATA_ROOT\cache\pip"
$env:PLAYWRIGHT_BROWSERS_PATH = "$env:DATA_ROOT\cache\playwright"
$env:TRANSFORMERS_CACHE = "$env:DATA_ROOT\cache\huggingface"
$env:HF_HOME = "$env:DATA_ROOT\cache\huggingface"
$env:PYTHONPYCACHEPREFIX = "$env:DATA_ROOT\cache\pyc"

# TEMP locations — set to user-local temp to avoid C: pressure only if desired
# To force E: temp again, change to: "$env:DATA_ROOT\temp"
$env:TEMP = "$env:LOCALAPPDATA\Temp"
$env:TMP = "$env:LOCALAPPDATA\Temp"

# =============================================================================
# Validation and Display
# =============================================================================

# Validate critical paths exist
$criticalPaths = @(
    $env:DATA_ROOT,
    $env:OLLAMA_MODELS,
    $env:DATA_DIR,
    $env:LOG_DIR
)

foreach ($path in $criticalPaths) {
    if (-not (Test-Path $path)) {
        try {
            New-Item -ItemType Directory -Path $path -Force | Out-Null
            Write-Host "Created directory: $path" -ForegroundColor Yellow
        } catch {
            Write-Warning "Failed to create directory: $path"
        }
    }
}

Write-Host "Environment configured successfully:" -ForegroundColor Green
Write-Host "  PROJECT_ROOT: $($env:PROJECT_ROOT)" -ForegroundColor Cyan
Write-Host "  DATA_ROOT: $($env:DATA_ROOT)" -ForegroundColor Cyan
Write-Host "  Ollama: $($env:OLLAMA_BASE_URL)" -ForegroundColor Cyan
Write-Host "  WebUI: $($env:WEB_UI_BASE_URL)" -ForegroundColor Cyan
Write-Host "  Logs: $($env:LOG_DIR)" -ForegroundColor Cyan

