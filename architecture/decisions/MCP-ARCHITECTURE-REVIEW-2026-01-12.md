# MCP Architektur-Review

> Strikte Prüfung der Implementierung gegen definierte Invarianten und Failure-Modes
> Datum: 2026-01-12

---

## 1. Invarianten-Check

### Eingehaltene Invarianten

| Invariante | Status | Nachweis |
|------------|--------|----------|
| **D-1** Idempotenz | ✅ | `deploy.ps1` überschreibt generierte Dateien deterministisch |
| **D-2** Fail-Fast bei node.env | ✅ | Zeilen 10-12, 21-23 in `deploy.ps1` prüfen vor Mutation |
| **D-4** Smoke-Test als Gate | ✅ | Zeilen 81-86 in `deploy.ps1` rufen Smoke-Test auf und brechen bei Failure ab |
| **O-1** /health = "ok" | ✅ | Caddyfile.template Zeile 16-18 |
| **O-3** /api/tags via Proxy | ✅ | Caddyfile.template Zeile 7-9 |
| **N-1** Host-Header-Routing | ✅ | Caddyfile.template Zeile 5 verwendet `{{HOST}}` |
| **N-4** Caddy-Admin-API-Prüfung | ✅ | `deploy.ps1` Zeile 51-62 prüft und killt Zombie-Prozesse |
| **4.7** Keine Secrets in Templates | ✅ | Templates enthalten keine Credentials |

### Verletzte Invarianten

| Invariante | Status | Befund |
|------------|--------|--------|
| **D-3** Deterministische Artefakte | ❌ | `capabilities.json.template` wird **nicht** durch `deploy.ps1` gerendert. Die Datei existiert als Template, aber der Rendering-Schritt fehlt im Deployment-Skript. |
| **I-2** base_url = NODE_FQDN | ❌ | `capabilities.json.template` verwendet `${NODE_FQDN}` Syntax, aber deploy.ps1 rendert nur Caddyfile mit `-replace "{{HOST}}"`. Die Variable-Syntax ist inkonsistent und die Ersetzung findet nicht statt. |
| **I-3** Identität nur in node.env | ❌ | `caddy/Caddyfile` enthält hartcodiert `ollama.valur.home:80` und `C:/work/tools/mcp`. Diese Datei existiert parallel zum Template-System und verletzt die Architektur. |
| **O-2** capabilities.json erreichbar | ⚠️ | Abhängig davon, ob `MCP_ROOT/.well-known/capabilities.json` existiert. Deploy kopiert/generiert diese Datei nicht. |

### Implizit erfüllte Invarianten (Gefahrenzone)

| Invariante | Risiko |
|------------|--------|
| **I-1** FQDN eindeutig pro Host | Keine technische Durchsetzung. Verlass auf manuelle Korrektheit von `node.env`. |
| **D-5** MCP_ROOT existiert | Geprüft wird dies nicht. `deploy.ps1` erstellt nur `generated/`, nicht `MCP_ROOT`. |
| **N-2** Ollama-Upstream erreichbar | Nur durch Smoke-Test geprüft, nicht vor Deployment. |

---

## 2. Failure-Exposure

### Begünstigte Failure-Modes

| Failure-Mode | Bewertung |
|--------------|-----------|
| **F-2** base_url-Inkonsistenz | **AKTIV**. capabilities.json wird nicht generiert. Wenn manuell erstellt, kann `base_url` von `NODE_FQDN` abweichen. |
| **D-1** Manuell editierte Dateien | **HOCH**. `caddy/Caddyfile` ist hartcodiert und steht im Widerspruch zum Template-System. |
| **T-3** capabilities.json nicht kopiert | **AKTIV**. Deploy-Prozess enthält keinen Schritt für diese Datei. |
| **D-3** Phantom-Capabilities | **MÖGLICH**. capabilities.json könnte Endpoints deklarieren, die im Caddyfile nicht geroutet sind. |

### Zuverlässig verhinderte Failure-Modes

| Failure-Mode | Mechanismus |
|--------------|-------------|
| **K-1** Fehlender NODE_FQDN | `deploy.ps1` Zeile 21: `throw "NODE_FQDN not set"` |
| **N-3** Caddy-Zombie | Admin-API-Check und Force-Kill in Zeilen 51-62 |
| **T-2** Caddy geladen, Smoke fehlt | `deploy.ps1` ruft immer Smoke-Test auf |

### Neu eingeführte Failure-Modes

| Neuer Failure-Mode | Beschreibung |
|--------------------|--------------|
| **Dualität der Caddyfiles** | `caddy/Caddyfile` und `generated/Caddyfile` existieren parallel. `deploy-local.ps1` kopiert `caddy/` nach `C:\work\tools\caddy`, aber `deploy.ps1` generiert in `generated/`. Unklar welche Config aktiv ist. |
| **Template-Syntax-Inkonsistenz** | `{{HOST}}` vs. `${NODE_FQDN}` in verschiedenen Templates. Ersetzungslogik erfasst nur `{{}}`. |
| **discover.py Syntaxfehler** | Zeile 95: `normalize_capabilities(caps)` erhält nur 1 Argument, Funktion erwartet 2 (`server_name`, `caps`). Code ist nicht lauffähig. |

---

## 3. Betriebsrealität

### Wiederholtes Deploy

| Szenario | Verhalten |
|----------|-----------|
| Identisches Re-Deploy | ✅ Generiertes Caddyfile wird überschrieben. Caddy reloaded. Idempotent. |
| node.env geändert, Re-Deploy | ⚠️ Caddyfile wird korrekt neu generiert. **capabilities.json bleibt unverändert**, da nicht Teil des Rendering-Prozesses. |

### Falsche node.env

| Szenario | Verhalten |
|----------|-----------|
| NODE_FQDN syntaktisch falsch | Deploy läuft durch, Caddy startet mit ungültigem Host. Smoke-Test mit korrektem Header schlägt fehl. ✅ Erkannt. |
| OLLAMA_UPSTREAM falscher Port | Deploy läuft durch. Smoke-Test prüft /api/tags und schlägt mit 502 fehl. ✅ Erkannt. |
| MCP_ROOT existiert nicht | Deploy läuft durch. Smoke-Test auf /.well-known/capabilities.json liefert 404. ✅ Erkannt. |

### Paralleler Betrieb mehrerer Nodes

| Szenario | Verhalten |
|----------|-----------|
| Zwei Nodes, gleiche Maschine | **Nicht unterstützt**. Caddy-Pfad ist hartcodiert auf `C:\work\tools\caddy\caddy.exe`. Port 80 ist global. |
| Zwei Nodes, verschiedene Maschinen | Design unterstützt dies. Jeder Node hat eigene `node.env`. Keine Cross-Node-Abhängigkeiten. ✅ |

### False-Green-Szenarien

| Szenario | Smoke-Test-Ergebnis | Tatsächlicher Zustand |
|----------|---------------------|------------------------|
| capabilities.json mit falscher base_url | PASS | Clients routen zu falschem Host |
| /api/tags liefert `{"models":[]}` | PASS | Kein Modell verfügbar, Node semantisch nutzlos |
| capabilities.json deklariert Endpoint, der nicht routet | PASS (wenn /api/tags ok) | Client-Request auf deklarierten Endpoint schlägt fehl |

---

## 4. Agententauglichkeit

### Eindeutigkeit für Agenten-Erweiterung

| Aspekt | Bewertung |
|--------|-----------|
| Wo liegt die Konfiguration? | ❌ Unklar. `caddy/Caddyfile` und `templates/Caddyfile.template` existieren beide mit unterschiedlichem Inhalt. |
| Wie füge ich einen Endpoint hinzu? | ⚠️ Template-System suggeriert: `Caddyfile.template` erweitern. Aber capabilities.json.template hat andere Syntax und wird nicht gerendert. |
| Welche Syntax für Variablen? | ❌ Inkonsistent. `{{VARIABLE}}` in Caddyfile.template, `${VARIABLE}` in capabilities.json.template. |
| Wie deploye ich? | ⚠️ Unklar ob `deploy.ps1` oder `scripts/deploy-local.ps1`. Letzteres kopiert `caddy/` statt `generated/`. |

### Versteckte Annahmen

| Annahme | Dokumentiert? |
|---------|---------------|
| Caddy-Pfad ist `C:\work\tools\caddy\caddy.exe` | Nein, hartcodiert |
| MCP_ROOT muss `.well-known/capabilities.json` enthalten | Nein, wird nicht erstellt |
| Ollama muss mit `OLLAMA_ORIGINS=*` gestartet werden | Ja, in start-ollama.ps1 |
| Port 80 muss frei sein | Nein |

### Fehlende Funktionen in discover.py

Die Datei `discover.py` hat folgende Defekte:
- `parse_args()` wird aufgerufen, aber nicht definiert
- `write_registry()` wird aufgerufen, aber nicht definiert
- `normalize_capabilities(caps)` Aufruf mit 1 Argument, Signatur erwartet 2

**Code ist nicht lauffähig.**

---

## 5. Gesamturteil

# ❌ ARCHITEKTURVERLETZEND

### Begründung

1. **Kritische Lücke im Deployment-Prozess**: `capabilities.json` wird nicht generiert. Das Template existiert, wird aber ignoriert. Invariante **D-3** und **O-2** verletzt.

2. **Duale Konfigurationsquellen**: `caddy/Caddyfile` mit hartcodierten Werten existiert parallel zum Template-System. Dies verletzt **I-3** (Identität nur in node.env) und schafft Drift-Gefahr.

3. **Template-Syntax-Inkonsistenz**: Zwei verschiedene Ersetzungssyntaxen (`{{}}` vs. `${}`) ohne gemeinsame Rendering-Logik.

4. **Nicht lauffähiger Code**: `discover.py` hat fehlende Funktionsdefinitionen und falsche Aufrufparameter.

5. **Deploy-Skript-Widerspruch**: `deploy.ps1` generiert nach `generated/`, aber `scripts/deploy-local.ps1` kopiert `caddy/` (mit hartcodierten Werten).

### Konkrete Verletzungen

| Verletzung | Schwere |
|------------|---------|
| capabilities.json nicht im Deploy-Prozess | Kritisch |
| Hartcodierte Werte in `caddy/Caddyfile` | Kritisch |
| Template-Syntax-Inkonsistenz | Mittel |
| discover.py nicht lauffähig | Hoch |
| Zwei Deploy-Skripte mit unterschiedlichem Verhalten | Mittel |

---

## Zusammenfassung

Die Implementierung zeigt solide Grundlagen bei:
- Fail-Fast-Mechanismen in `deploy.ps1`
- Smoke-Test-Integration
- Caddy-Zombie-Behandlung

Aber die Architektur ist **nicht in sich geschlossen**:
- Der Deployment-Prozess erfasst nicht alle Artefakte
- Hartcodierte Werte unterlaufen das Template-System
- Auxiliary-Code (`discover.py`) ist defekt
- Ein Agent könnte diese Implementierung nicht korrekt erweitern, ohne auf implizites Wissen angewiesen zu sein
