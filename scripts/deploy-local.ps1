$SRC = Resolve-Path ".."
$DST = "C:\work\tools"

Write-Host "Deploying MCP..."
robocopy "$SRC\mcp" "$DST\mcp" /MIR /XD __pycache__

Write-Host "Deploying Caddy..."
robocopy "$SRC\caddy" "$DST\caddy" /MIR

Write-Host "Deployment finished."
