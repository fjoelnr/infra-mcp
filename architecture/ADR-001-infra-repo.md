# ADR-001: Dedicated Infrastructure Repository

## Status
Accepted

## Context
MCP services and Caddy configuration are runtime infrastructure,
not application code. They must be reproducible, versioned,
and deployable across multiple machines.

## Decision
We use a dedicated repository `infra-mcp` as the source of truth.
Runtime directories remain outside Git and are populated via
explicit deployment scripts.

## Consequences
- Clean separation of source and runtime
- Safe experimentation
- Easy replication to laptop / future nodes
