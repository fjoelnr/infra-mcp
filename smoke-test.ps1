#!/usr/bin/env pwsh
Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

Write-Host "=== MCP Smoke Test ==="

$ROOT = Split-Path -Parent $MyInvocation.MyCommand.Path
$NODE_ENV = Join-Path $ROOT "node.env"

if (-not (Test-Path $NODE_ENV)) {
    throw "node.env not found"
}

# node.env laden (KEY=VALUE)
Get-Content $NODE_ENV | ForEach-Object {
    if ($_ -match '^\s*#') { return }
    if ($_ -match '^\s*$') { return }

    $parts = $_ -split '=', 2
    if ($parts.Count -ne 2) { return }

    $key = $parts[0].Trim()
    $value = $parts[1].Trim()
    Set-Variable -Name $key -Value $value -Scope Script
}

if (-not $NODE_FQDN) {
    throw "NODE_FQDN not set in node.env"
}

$BaseUrl = "http://127.0.0.1"
$Headers = @{ Host = $NODE_FQDN }

function Check-Endpoint {
    param (
        [string]$Name,
        [string]$Path,
        [scriptblock]$Validator
    )

    $url = "$BaseUrl$Path"
    Write-Host "[CHECK] $Name -> $url (Host: $NODE_FQDN)"

    try {
        $resp = Invoke-WebRequest `
            -Uri $url `
            -Headers $Headers `
            -UseBasicParsing `
            -TimeoutSec 5
    }
    catch {
        throw "$Name request failed: $($_.Exception.Message)"
    }

    & $Validator $resp

    Write-Host "[OK] $Name"
}

try {
    Check-Endpoint "Health" "/health" {
        param($r)
        # Content can be string or byte[] depending on PS version
        if ($r.Content -is [byte[]]) {
            $body = [System.Text.Encoding]::UTF8.GetString($r.Content)
        }
        else {
            $body = $r.Content
        }
        if ($body.Trim() -ne "ok") {
            throw "Health returned '$body'"
        }
    }

    Check-Endpoint "Capabilities" "/.well-known/capabilities.json" {
        param($r)
        if ($r.Content -is [byte[]]) {
            $text = [System.Text.Encoding]::UTF8.GetString($r.Content)
        }
        else {
            $text = $r.Content
        }
        $json = $text | ConvertFrom-Json
        if (-not $json.mcp_version) {
            throw "Missing mcp_version"
        }
    }

    Check-Endpoint "Ollama API" "/api/tags" {
        param($r)
        if ($r.Content -is [byte[]]) {
            $text = [System.Text.Encoding]::UTF8.GetString($r.Content)
        }
        else {
            $text = $r.Content
        }
        $json = $text | ConvertFrom-Json
        if (-not $json.models) {
            throw "Missing models list"
        }
    }

    Write-Host "[PASS] Smoke test passed (local via Host header)"
    exit 0
}
catch {
    Write-Host "[FAIL] Smoke test failed:"
    Write-Host $_
    exit 1
}