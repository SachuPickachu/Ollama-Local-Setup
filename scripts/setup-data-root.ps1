param()

# Load environment
if (Test-Path "$(Split-Path $MyInvocation.MyCommand.Path -Parent)\..\config\env.ps1") {
  . "$(Split-Path $MyInvocation.MyCommand.Path -Parent)\..\config\env.ps1"
}

$paths = @(
  $env:DATA_ROOT,
  $(Join-Path $env:DATA_ROOT 'models\ollama'),
  $(Join-Path $env:DATA_ROOT 'webui'),
  $(Join-Path $env:DATA_ROOT 'rags\chroma'),
  $(Join-Path $env:DATA_ROOT 'corpus'),
  $(Join-Path $env:DATA_ROOT 'prompts'),
  $(Join-Path $env:DATA_ROOT 'configs'),
  $(Join-Path $env:DATA_ROOT 'exports')
)

foreach ($p in $paths) {
  if (-not [string]::IsNullOrWhiteSpace($p)) {
    New-Item -ItemType Directory -Path $p -Force | Out-Null
    Write-Host "Ensured directory: $p"
  }
}

Write-Host "Data root initialized at $($env:DATA_ROOT)"

