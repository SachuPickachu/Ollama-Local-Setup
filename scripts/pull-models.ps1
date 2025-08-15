param(
    [string[]]$Models
)

# Load environment
if (Test-Path "$(Split-Path $MyInvocation.MyCommand.Path -Parent)\..\config\env.ps1") {
  . "$(Split-Path $MyInvocation.MyCommand.Path -Parent)\..\config\env.ps1"
}

# Locate ollama executable
$ollamaCmd = $null
$cmd = Get-Command ollama -ErrorAction SilentlyContinue
if ($cmd -and $cmd.Source) { $ollamaCmd = $cmd.Source }
if (-not $ollamaCmd -and (Test-Path 'C:\\Program Files\\Ollama\\ollama.exe')) { $ollamaCmd = 'C:\\Program Files\\Ollama\\ollama.exe' }
if (-not $ollamaCmd -and $env:LOCALAPPDATA) {
  $candidate = Join-Path $env:LOCALAPPDATA 'Programs\Ollama\ollama.exe'
  if (Test-Path $candidate) { $ollamaCmd = $candidate }
}
if (-not $ollamaCmd) {
  Write-Error "Could not find ollama executable. Ensure Ollama is installed."
  exit 1
}

# If no models specified, prompt user
if (-not $Models -or $Models.Count -eq 0) {
    Write-Host "No models specified. Please enter model names to pull." -ForegroundColor Yellow
    Write-Host "Format: modelname:tag (e.g., llama3.2:8b, mistral:7b)" -ForegroundColor Cyan
    Write-Host "Enter 'done' when finished, or press Enter to use default models." -ForegroundColor Cyan
    
    $Models = @()
    $defaultModels = @('qwen2.5:7b-instruct-q4_K_M', 'qwen2.5-coder:7b-q4_K_M', 'phi3.5:mini-instruct')
    
    while ($true) {
        $input = Read-Host "Enter model name (or 'done' to finish)"
        if ($input -eq 'done') { break }
        if ($input -eq '') { 
            Write-Host "Using default models: $($defaultModels -join ', ')" -ForegroundColor Green
            $Models = $defaultModels
            break 
        }
        $Models += $input
    }
    
    # If still no models, use defaults
    if ($Models.Count -eq 0) {
        $Models = $defaultModels
    }
}

Write-Host "Models to pull: $($Models -join ', ')" -ForegroundColor Green

foreach ($m in $Models) {
  Write-Host "Pulling model: $m" -ForegroundColor Cyan
  try {
    & $ollamaCmd pull $m
    if ($LASTEXITCODE -eq 0) {
        Write-Host "Successfully pulled: $m" -ForegroundColor Green
    } else {
        Write-Host "Failed to pull: $m" -ForegroundColor Red
    }
  } catch {
    Write-Host "Error pulling $m : $($_.Exception.Message)" -ForegroundColor Red
  }
}

Write-Host "Model pulls complete." -ForegroundColor Green

