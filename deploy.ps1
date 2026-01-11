Write-Host "=== MCP Deploy starting ==="

$ROOT = Split-Path -Parent $MyInvocation.MyCommand.Path
$ENV_FILE = Join-Path $ROOT "node.env"

if (-not (Test-Path $ENV_FILE)) {
    throw "node.env not found"
}

# --- node.env laden ---
Get-Content $ENV_FILE | ForEach-Object {
    if ($_ -match "^\s*#" -or $_ -notmatch "=") { return }
    $key, $value = $_ -split "=", 2
    [System.Environment]::SetEnvironmentVariable($key, $value)
}

if (-not $env:NODE_FQDN) { throw "NODE_FQDN not set" }
if (-not $env:OLLAMA_UPSTREAM) { throw "OLLAMA_UPSTREAM not set" }
if (-not $env:MCP_ROOT) { throw "MCP_ROOT not set" }

Write-Host "Loaded node.env for $($env:NODE_FQDN)"

# --- Pfade ---
$TEMPLATES = Join-Path $ROOT "templates"
$GENERATED = Join-Path $ROOT "generated"
New-Item -ItemType Directory -Force -Path $GENERATED | Out-Null

$CADDY_TEMPLATE = Join-Path $TEMPLATES "Caddyfile.template"
$CADDY_OUT = Join-Path $GENERATED "Caddyfile"

# --- Render Caddyfile ---
(Get-Content $CADDY_TEMPLATE -Raw) `
    -replace "{{HOST}}", $env:NODE_FQDN `
    -replace "{{OLLAMA_UPSTREAM}}", $env:OLLAMA_UPSTREAM `
    -replace "{{MCP_ROOT}}", $env:MCP_ROOT `
| Set-Content $CADDY_OUT -Encoding UTF8

Write-Host "Rendered Caddyfile"

# --- Reload Caddy ---
Write-Host "Reloading Caddy..."
& "C:\work\tools\caddy\caddy.exe" reload --config $CADDY_OUT --adapter caddyfile
if ($LASTEXITCODE -ne 0) {
    throw "Caddy reload failed"
}

Write-Host "Deploy finished for $($env:NODE_FQDN)"
