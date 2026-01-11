<# 
 smoke-test.ps1
 Local smoke test for MCP + Caddy + Ollama
 Uses explicit Host header to match Caddy site block
#>

$ErrorActionPreference = "Stop"

$TargetHost = "ollama.valur.home"
$BaseUrl    = "http://127.0.0.1"

function Get-TextContent {
    param ($Response)

    if ($Response.Content -is [byte[]]) {
        return [System.Text.Encoding]::UTF8.GetString($Response.Content)
    }
    return [string]$Response.Content
}

function Invoke-LocalRequest {
    param (
        [string]$Url
    )

    Invoke-WebRequest `
        -Uri $Url `
        -Headers @{ Host = $TargetHost } `
        -UseBasicParsing `
        -TimeoutSec 5
}

function Check-Endpoint {
    param (
        [string]$Name,
        [string]$Url,
        [ScriptBlock]$Validator
    )

    Write-Host "[CHECK] $Name -> $Url (Host: $TargetHost)"

    $r = Invoke-LocalRequest $Url
    $content = Get-TextContent $r

    & $Validator $r $content

    Write-Host "[OK] $Name"
}

try {
    # Health
    Check-Endpoint "Health" "$BaseUrl/health" {
        param($r, $content)
        if ($content.Trim() -ne "ok") {
            throw "Health returned '$content'"
        }
    }

    # Capabilities
    Check-Endpoint "Capabilities" "$BaseUrl/.well-known/capabilities.json" {
        param($r, $content)
        $json = $content | ConvertFrom-Json
        if (-not $json.mcp_version) {
            throw "Missing mcp_version"
        }
    }

    # Ollama API
    Check-Endpoint "Ollama API" "$BaseUrl/api/tags" {
        param($r, $content)
        $json = $content | ConvertFrom-Json
        if (-not $json.models) {
            throw "No models returned"
        }
    }

    Write-Host "[PASS] Smoke test passed (local via Host header)"
}
catch {
    Write-Host "[FAIL] Smoke test failed:"
    Write-Host $_.Exception.Message
    exit 1
}
