# infra-mcp

Infrastructure repository for local MCP services and reverse proxies.

## Components

### MCP
- Discovery client for MCP-capable services
- Normalized capability registry

### Caddy
- Local reverse proxy for MCP / Ollama endpoints
- Plain HTTP (LAN only)

## Runtime

Runtime lives outside this repository:

C:\work\tools\mcp  
C:\work\tools\caddy  

This repository is the source of truth.  
Deployment is done explicitly via scripts.


## Smoke Test (Node-lokal)

Jeder MCP-Node wird **nur lokal** getestet.

Der Smoke-Test prüft:
- `/health`
- `/.well-known/capabilities.json`
- `/api/tags`

### Ausführen

```powershell
.\smoke-test.ps1
````

### Bedeutung

* ✅ PASS → Node ist korrekt deployed
* ❌ FAIL → lokales Problem (Caddy, Ollama, MCP)

Netzwerk- oder Cross-Node-Tests sind **nicht Teil** des Smoke-Tests.

