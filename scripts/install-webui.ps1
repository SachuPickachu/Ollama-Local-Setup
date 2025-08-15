param()

# Load environment so DATA_DIR and OLLAMA_BASE_URL are available to the UI later
if (Test-Path "$(Split-Path $MyInvocation.MyCommand.Path -Parent)\..\config\env.ps1") {
  . "$(Split-Path $MyInvocation.MyCommand.Path -Parent)\..\config\env.ps1"
}

function Resolve-PythonCmd {
  $py = Get-Command py -ErrorAction SilentlyContinue
  if ($py) {
    # Prefer 3.12 then 3.11 to avoid 3.13 incompatibility
    try { & py -3.12 --version | Out-Null; return 'py -3.12' } catch { }
    try { & py -3.11 --version | Out-Null; return 'py -3.11' } catch { }
    # Fallback to default launcher
    return 'py -3'
  }
  $pyexe = Get-Command python -ErrorAction SilentlyContinue
  if ($pyexe) { return 'python' }
  $py3 = Get-Command python3 -ErrorAction SilentlyContinue
  if ($py3) { return 'python3' }
  return $null
}

$pythonCmd = Resolve-PythonCmd
if (-not $pythonCmd) {
  Write-Error "Python not found (neither 'py', 'python', nor 'python3'). Install Python 3.x and try again."
  exit 1
}

# Create venv if missing
$venvRoot = Join-Path (Join-Path (Split-Path $MyInvocation.MyCommand.Path -Parent) '..') '.venv'

# If venv exists but has incompatible Python (>=3.13 or <3.11), recreate with preferred version
if (Test-Path $venvRoot) {
  $currentVenvPython = Join-Path $venvRoot 'Scripts\python.exe'
  if (Test-Path $currentVenvPython) {
    $verOut = & $currentVenvPython --version 2>$null
    if ($verOut -match 'Python\s+(\d+)\.(\d+)\.(\d+)') {
      $maj = [int]$matches[1]; $min = [int]$matches[2]
      if ($maj -gt 3 -or ($maj -eq 3 -and $min -ge 13) -or ($maj -eq 3 -and $min -lt 11)) {
        Write-Host "Existing venv uses Python $maj.$min; recreating with Python 3.12/3.11..."
        Remove-Item -Recurse -Force $venvRoot
      }
    }
  } else {
    Remove-Item -Recurse -Force $venvRoot
  }
}

if (-not (Test-Path $venvRoot)) {
  Invoke-Expression "$pythonCmd -m venv `"$venvRoot`""
  Write-Host "Created venv at $venvRoot"
}

$venvPython = Join-Path $venvRoot 'Scripts\python.exe'
if (-not (Test-Path $venvPython)) {
  Write-Error "Venv python not found at $venvPython"
  exit 1
}

# Upgrade pip and install Open WebUI (requires Python >=3.11 and <3.13)
& $venvPython -m pip install --upgrade pip
& $venvPython -m pip install open-webui

Write-Host "Open WebUI installed in venv. Use scripts/start-webui.ps1 to launch."

