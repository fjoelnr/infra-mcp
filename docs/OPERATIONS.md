# Operations

## Deploy Flow

The canonical deploy path is:

```powershell
.\deploy.ps1
```

`deploy.ps1` performs four steps:

1. load `node.env`
2. render deterministic artifacts into `generated/`
3. copy `generated/.well-known/capabilities.json` into `$env:MCP_ROOT/.well-known/`
4. reload or start Caddy, then run `smoke-test.ps1`

The repository does not treat `caddy/Caddyfile` as an active runtime input. That file is retained only as a historical reference until all downstream tooling uses the generated path exclusively.

## Local Validation

To validate the render path without touching the running node:

```powershell
.\scripts\validate-render.ps1
```

This command creates a temporary `node.env`, renders both runtime artifacts, asserts the expected substitutions, and removes the temporary files again.

## Example `node.env`

```dotenv
NODE_NAME=ollama-pc
NODE_FQDN=ollama.valur.home
OLLAMA_UPSTREAM=http://127.0.0.1:11434
MCP_ROOT=C:/work/tools/mcp
```

## Generated Artifacts

`generated/` is deterministic output and should be treated as derived state:

- `generated/Caddyfile`
- `generated/.well-known/capabilities.json`

Do not hand-edit either file. Update templates or `node.env`, then render again.

## Failure Expectations

- missing `node.env` or required keys: hard fail
- missing `MCP_ROOT`: hard fail
- Caddy reload/start failure: hard fail
- smoke-test failure after reload: hard fail

This repo prefers explicit breakage over silent drift.
