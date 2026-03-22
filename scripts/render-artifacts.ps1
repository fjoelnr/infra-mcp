#!/usr/bin/env pwsh
param(
    [string]$EnvFile = (Join-Path $PSScriptRoot "..\node.env"),
    [string]$OutputRoot = (Join-Path $PSScriptRoot "..\generated"),
    [switch]$SkipMcpRootCheck
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Import-NodeEnv {
    param([string]$Path)

    if (-not (Test-Path $Path)) {
        throw "node.env not found at '$Path'"
    }

    $values = @{}
    Get-Content $Path | ForEach-Object {
        if ($_ -match '^\s*#' -or $_ -match '^\s*$' -or $_ -notmatch '=') {
            return
        }

        $key, $value = $_ -split '=', 2
        $trimmedKey = $key.Trim()
        $trimmedValue = $value.Trim()
        $values[$trimmedKey] = $trimmedValue
        [System.Environment]::SetEnvironmentVariable($trimmedKey, $trimmedValue)
    }

    return $values
}

$root = Split-Path -Parent $PSScriptRoot
$templatesRoot = Join-Path $root "templates"
$caddyTemplate = Join-Path $templatesRoot "Caddyfile.template"
$capabilitiesTemplate = Join-Path $templatesRoot "capabilities.json.template"

if (-not (Test-Path $caddyTemplate)) {
    throw "Caddy template not found at '$caddyTemplate'"
}

if (-not (Test-Path $capabilitiesTemplate)) {
    throw "Capabilities template not found at '$capabilitiesTemplate'"
}

$envValues = Import-NodeEnv -Path $EnvFile

foreach ($requiredKey in @("NODE_NAME", "NODE_FQDN", "OLLAMA_UPSTREAM", "MCP_ROOT")) {
    if (-not $envValues.ContainsKey($requiredKey) -or [string]::IsNullOrWhiteSpace($envValues[$requiredKey])) {
        throw "$requiredKey not set"
    }
}

if (-not $SkipMcpRootCheck -and -not (Test-Path $envValues["MCP_ROOT"])) {
    throw "MCP_ROOT '$($envValues["MCP_ROOT"])' does not exist"
}

New-Item -ItemType Directory -Force -Path $OutputRoot | Out-Null
$wellKnownRoot = Join-Path $OutputRoot ".well-known"
New-Item -ItemType Directory -Force -Path $wellKnownRoot | Out-Null

$caddyOut = Join-Path $OutputRoot "Caddyfile"
$capabilitiesOut = Join-Path $wellKnownRoot "capabilities.json"

$caddyContent = (Get-Content $caddyTemplate -Raw) `
    -replace "{{HOST}}", $envValues["NODE_FQDN"] `
    -replace "{{OLLAMA_UPSTREAM}}", $envValues["OLLAMA_UPSTREAM"] `
    -replace "{{MCP_ROOT}}", $envValues["MCP_ROOT"]

$capabilitiesContent = (Get-Content $capabilitiesTemplate -Raw) `
    -replace "\$\{NODE_NAME\}", $envValues["NODE_NAME"] `
    -replace "\$\{NODE_FQDN\}", $envValues["NODE_FQDN"]

Set-Content -Path $caddyOut -Value $caddyContent -Encoding utf8
Set-Content -Path $capabilitiesOut -Value $capabilitiesContent -Encoding utf8

Write-Host "Rendered artifacts:"
Write-Host "  - $caddyOut"
Write-Host "  - $capabilitiesOut"
