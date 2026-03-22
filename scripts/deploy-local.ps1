#!/usr/bin/env pwsh
Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$root = Resolve-Path (Join-Path $PSScriptRoot "..")

Write-Host "scripts/deploy-local.ps1 is deprecated. Calling deploy.ps1 to keep the generated deploy path canonical."
& (Join-Path $root "deploy.ps1")
