param()

# Reset E:\ caches permissions and recreate directories to avoid permission/space issues on C:
if (Test-Path "$(Split-Path $MyInvocation.MyCommand.Path -Parent)\..\config\env.ps1") {
  . "$(Split-Path $MyInvocation.MyCommand.Path -Parent)\..\config\env.ps1"
}

function Ensure-Directory([string]$path) {
  if (-not [string]::IsNullOrWhiteSpace($path)) {
    New-Item -ItemType Directory -Path $path -Force | Out-Null
  }
}

$user = "$env:USERDOMAIN\\$env:USERNAME"

foreach ($p in @(
  (Join-Path $env:DATA_ROOT 'cache'),
  $env:PIP_CACHE_DIR,
  $env:TRANSFORMERS_CACHE,
  $env:PLAYWRIGHT_BROWSERS_PATH,
  $env:TEMP
)) {
  if ([string]::IsNullOrWhiteSpace($p)) { continue }
  if (Test-Path $p) {
    try { icacls "$p" /grant "$user":(OI)(CI)F /T | Out-Null } catch {}
  } else {
    Ensure-Directory $p
    try { icacls "$p" /grant "$user":(OI)(CI)F /T | Out-Null } catch {}
  }
}

# Clear pip cache if it exists to remove any locked or partial files
if (-not [string]::IsNullOrWhiteSpace($env:PIP_CACHE_DIR) -and (Test-Path $env:PIP_CACHE_DIR)) {
  try { Remove-Item -Recurse -Force "$env:PIP_CACHE_DIR" } catch {}
  Ensure-Directory $env:PIP_CACHE_DIR
}

Write-Host "Cache dirs ready on E:. PIP_CACHE_DIR=$($env:PIP_CACHE_DIR) TEMP=$($env:TEMP)"

