param()

# Purpose: Install Open WebUI with all heavy caches and temp redirected to E: (DATA_ROOT)
# - Creates a fresh Python 3.12 (or 3.11) venv under .venv
# - Forces pip cache and TEMP/TMP to E:\
# - Installs open-webui
# - Starts Open WebUI bound to our configured DATA_DIR and OLLAMA_BASE_URL

# 1) Load environment and ensure directories
if (Test-Path "$(Split-Path $MyInvocation.MyCommand.Path -Parent)\..\config\env.ps1") {
  . "$(Split-Path $MyInvocation.MyCommand.Path -Parent)\..\config\env.ps1"
}

function Ensure-Directory([string]$path) {
  if (-not [string]::IsNullOrWhiteSpace($path)) {
    New-Item -ItemType Directory -Path $path -Force | Out-Null
  }
}

Ensure-Directory $env:DATA_ROOT
Ensure-Directory (Join-Path $env:DATA_ROOT 'cache')
Ensure-Directory $env:PIP_CACHE_DIR
Ensure-Directory $env:TRANSFORMERS_CACHE
Ensure-Directory $env:PLAYWRIGHT_BROWSERS_PATH
Ensure-Directory $env:TEMP

# 2) Persist pip cache dir and set TEMP/TMP for this session (heavy writes stay on E:)
try { & pip config set global.cache-dir "$env:PIP_CACHE_DIR" | Out-Null } catch { }
$env:TEMP = $env:TEMP
$env:TMP = $env:TMP

Write-Host "PIP_CACHE_DIR=$($env:PIP_CACHE_DIR)"
Write-Host "TEMP=$($env:TEMP)"
Write-Host "TMP=$($env:TMP)"

# 3) Resolve a Python 3.12/3.11 interpreter
function Resolve-Python() {
  try { & py -3.12 --version | Out-Null; return 'py -3.12' } catch { }
  try { & py -3.11 --version | Out-Null; return 'py -3.11' } catch { }
  $pyexe = Get-Command python -ErrorAction SilentlyContinue
  if ($pyexe) { return 'python' }
  throw "Python 3.12/3.11 not found. Install Python 3.12 and retry."
}

$pythonCmd = Resolve-Python
Write-Host "Using Python command: $pythonCmd"

# 4) Create fresh venv
$repoRoot = Join-Path (Split-Path $MyInvocation.MyCommand.Path -Parent) '..'
$venvRoot = Join-Path $repoRoot '.venv'
if (Test-Path $venvRoot) {
  Remove-Item -Recurse -Force $venvRoot
}
Invoke-Expression "$pythonCmd -m venv `"$venvRoot`""

$venvPython = Join-Path $venvRoot 'Scripts\python.exe'
if (-not (Test-Path $venvPython)) {
  Write-Error "Venv python not found at $venvPython"
  exit 1
}

# 5) Upgrade pip tooling and install Open WebUI (caches on E:)
& $venvPython -m pip install --upgrade pip wheel setuptools
& $venvPython -m pip config set global.cache-dir "$env:PIP_CACHE_DIR"

# Pre-download wheels to E: and then install from there to further avoid C:
$downloadDir = Join-Path $env:PIP_CACHE_DIR 'pkgs'
Ensure-Directory $downloadDir
& $venvPython -m pip download --only-binary=:all: --prefer-binary -d "$downloadDir" open-webui
& $venvPython -m pip install --no-index --find-links "$downloadDir" open-webui

Write-Host "Open WebUI installed. Starting..."

# 6) Start Open WebUI
Start-Process -FilePath $venvPython -ArgumentList "-m open_webui" -WindowStyle Minimized
Write-Host "Started Open WebUI on http://127.0.0.1:8080  DataDir=$($env:DATA_DIR)  Ollama=$($env:OLLAMA_BASE_URL)"

