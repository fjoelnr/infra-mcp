# infra-mcp

Infrastructure source-of-truth for local MCP-facing services, generated Caddy routing, and deterministic smoke tests.

## Purpose

`infra-mcp` defines how local MCP and Ollama-facing infrastructure is rendered, deployed, and validated on a node. The repository does not contain the long-running runtime itself; it contains the templates, scripts, contracts, and generated artifacts that make deployment reproducible.

## Scope

- render Caddy configuration from explicit node metadata
- expose a deterministic local HTTP surface for health and capabilities
- smoke-test the deployed local MCP/Ollama path through the configured Host header
- keep architecture and failure modes explicit before implementation drift happens

## Repository Layout

- `templates/`: canonical templates for generated runtime artifacts
- `generated/`: rendered output generated from templates and `node.env`
- `mcp/`: MCP-side code, currently including discovery tooling
- `scripts/`: helper scripts for local startup and deployment support
- `deploy.ps1`: main deploy path
- `smoke-test.ps1`: local routing and capability smoke test
- `GOVERNANCE.md`: binding architecture contract
- `FAILURE_MODES.md`: system-level anti-pattern catalog

## Runtime Model

Runtime lives outside this repository:

- `C:\work\tools\mcp`
- `C:\work\tools\caddy`

This repository remains the source of truth. Deployment is explicit and script-driven.

## Configuration

Create a local `node.env` from [node.env.example](node.env.example).

Required values:

- `NODE_NAME`
- `NODE_FQDN`
- `OLLAMA_UPSTREAM`
- `MCP_ROOT`

The deploy path fails fast if required inputs are missing.

## Core Commands

```powershell
.\deploy.ps1
.\smoke-test.ps1
.\scripts\validate-render.ps1
```

See [docs/OPERATIONS.md](docs/OPERATIONS.md) for the canonical deploy flow, example `node.env`, and generated-artifact rules.

## Status

This repository now has a public baseline with a deterministic render path for both the Caddy config and `/.well-known/capabilities.json`. The main architecture and governance intent are already present; the next work is mostly incremental hardening around deploy automation and node composition.

See [docs/STATUS.md](docs/STATUS.md) for the current state.
