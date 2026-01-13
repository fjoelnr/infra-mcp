# MCP-Node Architekturmodell

> Invarianten, Failure-Modes und Entscheidungsregeln für verteilte MCP-Nodes.
> Erstellt: 2026-01-12

---

## 1. Kern-Invarianten

### 1.1 Netzwerk-Invarianten

| ID | Invariante | Prüfkriterium |
|----|------------|---------------|
| **N-1** | Jeder Node lauscht auf Port 80 und routet ausschließlich über HTTP Host Header. | `curl -H "Host: $NODE_FQDN" http://127.0.0.1/health` liefert 200. |
| **N-2** | Der Ollama-Upstream ist von Caddy aus erreichbar. | Direkter Request an `$OLLAMA_UPSTREAM/api/tags` liefert JSON mit `models`-Array. |
| **N-3** | Kein Node nimmt Verbindungen an, die nicht seinem FQDN entsprechen. | Request mit falschem Host-Header liefert 404 oder wird verworfen. |
| **N-4** | Caddy-Admin-API ist lokal erreichbar (Port 2019). | `http://localhost:2019/config/` antwortet bei laufendem Caddy. |

### 1.2 Identitäts-Invarianten

| ID | Invariante | Prüfkriterium |
|----|------------|---------------|
| **I-1** | `NODE_NAME` und `NODE_FQDN` sind eindeutig pro physischem Host. | Keine zwei Nodes im Gesamtsystem teilen denselben FQDN. |
| **I-2** | `capabilities.json` enthält exakt die `base_url`, die `NODE_FQDN` entspricht. | `jq '.server.base_url'` liefert `http://$NODE_FQDN`. |
| **I-3** | Die Node-Identität ist ausschließlich in `node.env` definiert. | Keine hartcodierten Hostnamen in Templates oder Skripten. |
| **I-4** | Der FQDN im Caddy entspricht dem FQDN in `capabilities.json`. | Mismatch führt zu Smoke-Test-Failure. |

### 1.3 Deployment-Invarianten

| ID | Invariante | Prüfkriterium |
|----|------------|---------------|
| **D-1** | Deployment ist idempotent. | Zweifaches Ausführen von `deploy.ps1` ändert keinen Systemzustand. |
| **D-2** | Deployment ohne `node.env` schlägt fehl (fail-fast). | Fehlende `node.env` führt zu Abbruch vor jeder Mutation. |
| **D-3** | Generierte Artefakte sind deterministisch. | Identische `node.env` + Templates = identische `/generated/*`. |
| **D-4** | Deploy ohne erfolgreichen Smoke-Test gilt als nicht abgeschlossen. | Exit-Code ≠ 0 bei Smoke-Failure. |
| **D-5** | Runtime-Pfade existieren vor Deployment. | `MCP_ROOT` existiert und ist schreibbar. |

### 1.4 Beobachtbarkeits-Invarianten

| ID | Invariante | Prüfkriterium |
|----|------------|---------------|
| **O-1** | `/health` antwortet mit exakt `ok` (200). | String-Vergleich, keine JSON-Interpretation. |
| **O-2** | `/.well-known/capabilities.json` enthält `mcp_version`. | Pflichtfeld, fehlendes Feld = invalider Node. |
| **O-3** | `/api/tags` liefert JSON mit `models`-Array. | Strukturprüfung, nicht Inhaltsvalidierung. |
| **O-4** | Smoke-Test ist die einzige Quelle der Deployment-Bestätigung. | Keine implizite Annahme "es läuft, also ist es deployed". |

---

## 2. Failure-Modes

### 2.1 Host-Header-Mismatch

| Aspekt | Beschreibung |
|--------|--------------|
| **Erkennung** | Smoke-Test schlägt fehl mit Connection-Error oder 404. |
| **Verletzte Invariante** | **N-1**, **I-4** |
| **Ursache** | `NODE_FQDN` in `node.env` entspricht nicht dem, was Caddy erwartet. |

### 2.2 Inkonsistente Capabilities

| Aspekt | Beschreibung |
|--------|--------------|
| **Erkennung** | `capabilities.json` ist erreichbar, aber `base_url` zeigt auf falschen Host. |
| **Verletzte Invariante** | **I-2** |
| **Ursache** | Template wurde nicht neu gerendert nach Änderung von `NODE_FQDN`. |

### 2.3 Ollama-Upstream nicht erreichbar

| Aspekt | Beschreibung |
|--------|--------------|
| **Erkennung** | `/api/tags` liefert 502 oder Timeout. |
| **Verletzte Invariante** | **N-2** |
| **Ursache** | Ollama nicht gestartet; `OLLAMA_UPSTREAM` falsch konfiguriert. |

### 2.4 Partielles Deployment

| Aspekt | Beschreibung |
|--------|--------------|
| **Erkennung** | Caddy läuft mit alter Config; neue Capabilities nicht sichtbar. |
| **Verletzte Invariante** | **D-3**, **D-4** |
| **Ursache** | `caddy reload` fehlgeschlagen; Smoke-Test nicht ausgeführt oder ignoriert. |

### 2.5 Stale Caddy-Prozess

| Aspekt | Beschreibung |
|--------|--------------|
| **Erkennung** | Caddy-Prozess existiert, aber Admin-API antwortet nicht. |
| **Verletzte Invariante** | **N-4** |
| **Ursache** | Vorheriger Crash oder manueller Kill ohne Cleanup. |

### 2.6 Fehlende Pflichtfelder in node.env

| Aspekt | Beschreibung |
|--------|--------------|
| **Erkennung** | Deploy-Skript wirft Exception vor erster Mutation. |
| **Verletzte Invariante** | **D-2** |
| **Ursache** | Manuelle Bearbeitung von `node.env` mit Syntaxfehler oder fehlendem Key. |

### 2.7 MCP_ROOT nicht existent

| Aspekt | Beschreibung |
|--------|--------------|
| **Erkennung** | `capabilities.json` Request liefert 404. |
| **Verletzte Invariante** | **D-5**, **O-2** |
| **Ursache** | Pfad verschoben oder nie angelegt. |

---

## 3. Entscheidungsregeln

### Deployment-Phase

| # | Regel |
|---|-------|
| **E-1** | Wenn `node.env` fehlt oder unlesbar ist, dann bricht das Deployment vor jeder Mutation ab. |
| **E-2** | Wenn `NODE_FQDN`, `OLLAMA_UPSTREAM` oder `MCP_ROOT` nicht gesetzt sind, dann gilt die Konfiguration als ungültig. |
| **E-3** | Wenn Caddy bereits läuft und die Admin-API antwortet, dann wird `reload` verwendet; andernfalls `start`. |
| **E-4** | Wenn der Smoke-Test fehlschlägt, dann gilt das Deployment als nicht abgeschlossen. |
| **E-5** | Wenn generierte Dateien manuell editiert wurden, dann überschreibt das nächste Deploy diese ohne Warnung. |

### Laufzeit-Phase

| # | Regel |
|---|-------|
| **R-1** | Wenn `/health` nicht `ok` liefert, dann ist der Node nicht betriebsbereit. |
| **R-2** | Wenn `capabilities.json` fehlt oder `mcp_version` leer ist, dann ist der Node nicht discoverable. |
| **R-3** | Wenn `/api/tags` keinen `models`-Array liefert, dann ist Ollama-Upstream defekt. |
| **R-4** | Wenn ein externer Request einen unbekannten Host-Header enthält, dann wird er abgewiesen. |

### Wartungs-Phase

| # | Regel |
|---|-------|
| **W-1** | Wenn eine neue Capability hinzugefügt wird, dann muss das Template erweitert werden, nicht die generierte Datei. |
| **W-2** | Wenn ein Node umbenannt wird, dann muss `node.env` angepasst und `deploy.ps1` erneut ausgeführt werden. |
| **W-3** | Wenn Caddy-Logik geändert werden soll, die über Routing hinausgeht, dann muss eine neue ADR erstellt werden. |

---

## 4. Nicht-Ziele & Bewusste Grenzen

### 4.1 Kein Node-Discovery

| Nicht-Ziel | Begründung |
|------------|------------|
| Nodes sollen sich **nicht** gegenseitig finden. | Discovery impliziert Netzwerkabhängigkeit. Jeder Node ist autonom. Cross-Node-Kommunikation ist ein separates Architekturproblem. |

### 4.2 Kein Cross-Node-Smoke-Test

| Nicht-Ziel | Begründung |
|------------|------------|
| Smoke-Tests prüfen **nur** den lokalen Node. | Remote-Tests führen zu Netzwerk-Abhängigkeiten, Timing-Problemen und nicht-deterministischen Ergebnissen. |

### 4.3 Keine Business-Logik in Caddy

| Nicht-Ziel | Begründung |
|------------|------------|
| Caddy enthält **keine** Transformationen, Auth-Entscheidungen oder Conditional Logic. | Caddy ist Transport-Layer. Jede Logik in Caddy erschwert Debugging und macht Deployments zustandsbehaftet. |

### 4.4 Kein dynamisches Template-Rendering

| Nicht-Ziel | Begründung |
|------------|------------|
| Generierung findet **nur** zum Deploy-Zeitpunkt statt, nicht zur Laufzeit. | Laufzeit-Rendering macht Fehleranalyse unmöglich. Der generierte Zustand muss inspizierbar sein. |

### 4.5 Keine globale Capability-Registry

| Nicht-Ziel | Begründung |
|------------|------------|
| Es gibt **keinen** zentralen Dienst, der alle Capabilities aggregiert. | Zentralisierung erzeugt Single-Point-of-Failure. Jeder Node ist selbstbeschreibend. Aggregation ist Client-Verantwortung. |

### 4.6 Keine automatische Rollback-Strategie

| Nicht-Ziel | Begründung |
|------------|------------|
| Fehlgeschlagene Deploys werden **nicht** automatisch zurückgerollt. | Rollback erfordert Zustandsverwaltung. Stattdessen: Fail-fast + manuelles Re-Deploy nach Korrektur. |

### 4.7 Keine Secrets in Templates

| Nicht-Ziel | Begründung |
|------------|------------|
| Templates enthalten **keine** Credentials oder API-Keys. | `node.env` ist gitignored, aber Templates sind versioniert. Secrets gehören ausschließlich in `node.env` oder externe Secret-Stores. |

---

## Zusammenfassung als Prüfmatrix

```
┌─────────────────────────────────────────────────────────────────────────┐
│                         MCP-Node Validierung                            │
├─────────────────────────────────────────────────────────────────────────┤
│  ┌─────────────┐    ┌─────────────┐    ┌─────────────┐                  │
│  │ node.env    │───▶│  deploy.ps1 │───▶│ smoke-test  │                  │
│  │ (Identität) │    │ (Rendering) │    │  (Proof)    │                  │
│  └─────────────┘    └─────────────┘    └──────┬──────┘                  │
│                                               │                          │
│         ┌─────────────────────────────────────┘                          │
│         ▼                                                                │
│  ┌──────────────────────────────────────────────────────────────────┐   │
│  │  /health = "ok"  │  /.well-known/capabilities.json  │  /api/tags │   │
│  │    [O-1, N-1]    │         [O-2, I-2]               │   [O-3]    │   │
│  └──────────────────────────────────────────────────────────────────┘   │
│                                                                          │
│  PASS = Node ist korrekt deployed und betriebsbereit                    │
│  FAIL = Invariante verletzt → Fehlermodus analysieren                   │
└─────────────────────────────────────────────────────────────────────────┘
```

---

## Ableitbare Implementierungs-Prompts

Dieses Modell erlaubt die Ableitung konkreter Implementierungs-Prompts für:

1. **Template-Erweiterungen** — Neue Endpoints hinzufügen
2. **Smoke-Test-Erweiterungen** — Neue Invarianten-Checks
3. **Node-Replikation** — Laptop-Setup mit eigener `node.env`
4. **Fehlerdiagnose** — Systematische Invarianten-Prüfung anhand der Failure-Mode-Tabelle
