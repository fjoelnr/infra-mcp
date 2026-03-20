# AGENTS.md

## Project Intent

`infra-mcp` is the infrastructure contract and deploy source-of-truth for local MCP-facing services.

## Working Rules

- Keep infrastructure identity externalized in `node.env`.
- Do not hardcode node-specific hostnames, machine roles, or local secrets.
- Treat `GOVERNANCE.md` and `FAILURE_MODES.md` as binding design inputs, not optional reference docs.
- Prefer deterministic failure over silent fallback behavior.

## Operational Boundaries

- Runtime binaries live outside the repo.
- This repo owns templates, generated artifacts, deploy scripts, and smoke tests.
- Smoke tests stay local by default and should not silently become cross-node tests.

## Delivery Flow

Use `feature -> develop -> main`. Keep README, templates, and scripts aligned with the actual deploy path.
