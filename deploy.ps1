#!/usr/bin/env pwsh
param(
    [switch]$SkipSmokeTest
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

Write-Host "=== MCP Deploy starting ==="

$ROOT = Split-Path -Parent $MyInvocation.MyCommand.Path
$ENV_FILE = Join-Path $ROOT "node.env"

if (-not (Test-Path $ENV_FILE)) {
    throw "node.env not found"
}

& (Join-Path $ROOT "scripts\render-artifacts.ps1") -EnvFile $ENV_FILE

Write-Host "Loaded node.env for $($env:NODE_FQDN)"

$GENERATED = Join-Path $ROOT "generated"
$CADDY_OUT = Join-Path $GENERATED "Caddyfile"
$CAPABILITIES_SOURCE = Join-Path $GENERATED ".well-known\capabilities.json"
$CAPABILITIES_TARGET_ROOT = Join-Path $env:MCP_ROOT ".well-known"
$CAPABILITIES_TARGET = Join-Path $CAPABILITIES_TARGET_ROOT "capabilities.json"

New-Item -ItemType Directory -Force -Path $CAPABILITIES_TARGET_ROOT | Out-Null
Copy-Item -Force -Path $CAPABILITIES_SOURCE -Destination $CAPABILITIES_TARGET

Write-Host "Rendered deploy artifacts and published capabilities.json"

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

if (-not $SkipSmokeTest) {
    Write-Host "Running smoke test..."
    & "$PSScriptRoot\smoke-test.ps1"

    if ($LASTEXITCODE -ne 0) {
        Write-Host "[FAIL] Smoke test failed - deploy aborted"
        exit 1
    }

    Write-Host "Deploy + smoke test successful"
}
