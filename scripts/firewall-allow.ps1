param(
  [int]$Port = 11434,
  [string]$RuleName = "Ollama $([int]$Port) (Private)"
)

# Allow inbound TCP on the given port for Private profile only
$existing = Get-NetFirewallRule -DisplayName $RuleName -ErrorAction SilentlyContinue
if ($null -eq $existing) {
  New-NetFirewallRule -DisplayName $RuleName -Direction Inbound -Action Allow -Protocol TCP -LocalPort $Port -Profile Private | Out-Null
  Write-Host "Firewall rule created: $RuleName"
} else {
  Write-Host "Firewall rule already exists: $RuleName"
}

