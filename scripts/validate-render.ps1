#!/usr/bin/env pwsh
Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$tempRoot = Join-Path ([System.IO.Path]::GetTempPath()) ("infra-mcp-validate-" + [guid]::NewGuid().ToString("N"))
$tempOutput = Join-Path $tempRoot "generated"
$tempMcpRoot = Join-Path $tempRoot "mcp-root"
$tempEnvFile = Join-Path $tempRoot "node.env"

try {
    New-Item -ItemType Directory -Force -Path $tempRoot | Out-Null
    New-Item -ItemType Directory -Force -Path $tempMcpRoot | Out-Null

    @(
        "NODE_NAME=validation-node"
        "NODE_FQDN=validation-node.local"
        "OLLAMA_UPSTREAM=http://127.0.0.1:11434"
        "MCP_ROOT=$($tempMcpRoot.Replace('\', '/'))"
    ) | Set-Content -Path $tempEnvFile -Encoding utf8

    & (Join-Path $PSScriptRoot "render-artifacts.ps1") -EnvFile $tempEnvFile -OutputRoot $tempOutput

    $caddyOut = Join-Path $tempOutput "Caddyfile"
    $capabilitiesOut = Join-Path $tempOutput ".well-known\capabilities.json"

    if (-not (Test-Path $caddyOut)) {
        throw "Rendered Caddyfile missing"
    }

    if (-not (Test-Path $capabilitiesOut)) {
        throw "Rendered capabilities.json missing"
    }

    $caddyContent = Get-Content $caddyOut -Raw
    $capabilitiesContent = Get-Content $capabilitiesOut -Raw

    if ($caddyContent -notmatch "validation-node\.local:80") {
        throw "Rendered Caddyfile does not contain NODE_FQDN"
    }

    if ($caddyContent -notmatch "http://127.0.0.1:11434") {
        throw "Rendered Caddyfile does not contain OLLAMA_UPSTREAM"
    }

    if ($capabilitiesContent -notmatch '"name": "validation-node"') {
        throw "Rendered capabilities.json does not contain NODE_NAME"
    }

    if ($capabilitiesContent -notmatch '"base_url": "http://validation-node.local"') {
        throw "Rendered capabilities.json does not contain NODE_FQDN"
    }

    Write-Host "[PASS] Render validation succeeded"
}
finally {
    if (Test-Path $tempRoot) {
        Remove-Item -Recurse -Force $tempRoot
    }
}
