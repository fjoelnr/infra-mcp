#!/usr/bin/env pwsh
Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

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

# --- Start or Reload Caddy ---
$caddyExe = "C:\work\tools\caddy\caddy.exe"

# Check if Caddy is already running by testing admin API
$caddyProcess = Get-Process -Name "caddy" -ErrorAction SilentlyContinue
$caddyRunning = $false

if ($caddyProcess) {
    try {
        $null = Invoke-WebRequest -Uri "http://localhost:2019/config/" -Method GET -TimeoutSec 5 -UseBasicParsing -ErrorAction Stop
        $caddyRunning = $true
    }
    catch {
        # Process exists but API not responding - kill stale process
        Write-Host "Caddy process found but not responding - restarting..."
        Stop-Process -Name "caddy" -Force -ErrorAction SilentlyContinue
        Start-Sleep -Seconds 2
    }
}

if ($caddyRunning) {
    Write-Host "Reloading Caddy..."
    & $caddyExe reload --config $CADDY_OUT --adapter caddyfile
    if ($LASTEXITCODE -ne 0) {
        throw "Caddy reload failed"
    }
}
else {
    Write-Host "Caddy not running - starting..."
    & $caddyExe start --config $CADDY_OUT --adapter caddyfile
    if ($LASTEXITCODE -ne 0) {
        throw "Caddy start failed"
    }
}

Write-Host "Deploy finished for $($env:NODE_FQDN)"

Write-Host "Running smoke test..."
& "$PSScriptRoot\smoke-test.ps1"

if ($LASTEXITCODE -ne 0) {
    Write-Host "[FAIL] Smoke test failed - deploy aborted"
    exit 1
}

Write-Host "Deploy + smoke test successful"