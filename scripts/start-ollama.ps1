#!/usr/bin/env pwsh
# Start Ollama with OLLAMA_ORIGINS set to allow all origins
# This is required for Caddy reverse proxy to work with custom Host headers

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# Set environment variable for this session
$env:OLLAMA_ORIGINS = "*"

# Find Ollama executable
$ollamaPath = "C:\Users\$env:USERNAME\AppData\Local\Programs\Ollama\ollama.exe"
if (-not (Test-Path $ollamaPath)) {
    $ollamaPath = (Get-Command ollama -ErrorAction SilentlyContinue).Source
    if (-not $ollamaPath) {
        throw "Ollama not found"
    }
}

Write-Host "Starting Ollama with OLLAMA_ORIGINS=*"
Write-Host "Using: $ollamaPath"

# Start Ollama serve
& $ollamaPath serve
