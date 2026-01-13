# MCP-Node Failure-Landkarte

> Systematische Analyse von Fehlerklassen, Szenarien und Erkennungsmechanismen
> für das Valur / Infra / MCP Setup
>
> Erstellt: 2026-01-12

---

## 1. Fehlerklassen (Taxonomie)

### 1.1 Konfigurationsfehler

**Definition:** Fehler in `node.env` oder Templates, die dazu führen, dass das System den gewünschten Zustand nicht erreichen kann.

**Charakteristik:**
- Meist deterministisch
- Treten zum Deploy-Zeitpunkt auf
- Sollten durch Fail-Fast erkennbar sein

### 1.2 Identitätsfehler

**Definition:** Der Node behauptet, etwas anderes zu sein als er tatsächlich ist. Es existiert eine Diskrepanz zwischen deklarierter Identität (`NODE_FQDN`) und tatsächlichem Routing-, Capabilities- oder API-Verhalten.

**Charakteristik:**
- Können unbemerkt bleiben, wenn nur oberflächlich geprüft wird
- Führen zu Inkonsistenzen zwischen MCP-Clients und Node
- Der Node "lügt"

### 1.3 Netzwerk-/Proxy-Fehler

**Definition:** Transport-Layer-Probleme zwischen Caddy, Ollama oder dem Host. Beinhalten Routing-Fehler, Port-Konflikte, Upstream-Ausfälle.

**Charakteristik:**
- Können sporadisch oder deterministisch sein
- Oft abhängig von externen Prozessen (Ollama-Start, Port-Belegung)
- Manifestieren sich als 502, Timeout, Connection Refused

### 1.4 Teil-Deployments

**Definition:** Das Deployment wurde gestartet, aber nicht vollständig abgeschlossen. Artefakte sind teilweise generiert, Caddy hat nicht die neueste Config, oder Smoke-Test wurde nicht ausgeführt.

**Charakteristik:**
- Entstehen durch Abbruch (manuell, Fehler, Systemcrash)
- Führen zu inkonsistentem Zustand
- Besonders gefährlich: System wirkt funktionsfähig

### 1.5 Drift (Konfiguration ≠ Laufzeitrealität)

**Definition:** Die tatsächliche Laufzeitumgebung weicht von der konfigurierten/erwarteten ab. Templates, generierte Dateien oder laufende Prozesse entsprechen nicht mehr dem deklarierten Zustand in `node.env`.

**Charakteristik:**
- Entsteht durch manuelle Eingriffe, Nicht-Neustart nach Änderungen
- Akkumuliert über Zeit
- Oft erst bei Re-Deployment sichtbar

### 1.6 "False Green"-Zustände

**Definition:** Das System wirkt gesund (alle oberflächlichen Checks bestehen), obwohl kritische Fehler vorliegen. Der Smoke-Test ist grün, aber der Node ist nicht korrekt.

**Charakteristik:**
- Gefährlichste Fehlerklasse
- Erfordert tiefere Inspektion
- Zeigt Lücken in der Test-Coverage

---

## 2. Konkrete Failure-Szenarien

### 2.1 Konfigurationsfehler

| ID | Szenario | Was ist falsch | Symptom | Betroffene Endpoints | Determinismus |
|----|----------|----------------|---------|---------------------|---------------|
| **K-1** | Fehlender NODE_FQDN | `node.env` enthält keinen oder leeren `NODE_FQDN` | Deploy-Skript bricht mit Exception ab | Keiner (Deploy schlägt fehl) | Deterministisch |
| **K-2** | OLLAMA_UPSTREAM falscher Port | `OLLAMA_UPSTREAM=http://localhost:11435` statt `:11434` | `/api/tags` liefert 502 Bad Gateway | `/api/tags` | Deterministisch |
| **K-3** | MCP_ROOT nicht existent | Pfad existiert nicht | `/.well-known/capabilities.json` liefert 404 | `/.well-known/capabilities.json` | Deterministisch |

### 2.2 Identitätsfehler

| ID | Szenario | Was ist falsch | Symptom | Betroffene Endpoints | Determinismus |
|----|----------|----------------|---------|---------------------|---------------|
| **I-1** | NODE_FQDN geändert, Deploy nicht ausgeführt | `node.env` enthält neuen FQDN, Caddy hat alte Config | Smoke-Test mit neuem Host-Header schlägt fehl | Alle (mit neuem Host-Header) | Deterministisch |
| **I-2** | base_url-Mismatch | Template manuell editiert oder Ersetzung fehlgeschlagen | `capabilities.json` zeigt falschen Host, Clients routen falsch | Indirekt alle | Deterministisch, verzögert sichtbar |
| **I-3** | Doppelter FQDN | Zwei Nodes mit gleichem `NODE_FQDN` | Nicht-deterministisches Routing, je nach Netzwerk | Alle | Sporadisch |

### 2.3 Netzwerk-/Proxy-Fehler

| ID | Szenario | Was ist falsch | Symptom | Betroffene Endpoints | Determinismus |
|----|----------|----------------|---------|---------------------|---------------|
| **N-1** | Ollama nicht gestartet | Ollama-Service läuft nicht | `/api/tags` liefert 502 | `/api/tags` | Deterministisch |
| **N-2** | Port 80 belegt | Anderer Webserver auf Port 80 | Caddy-Start schlägt fehl | Alle | Deterministisch |
| **N-3** | Caddy-Zombie | Prozess existiert, Admin-API tot | Reload schlägt fehl | Alle | Sporadisch |

### 2.4 Teil-Deployments

| ID | Szenario | Was ist falsch | Symptom | Betroffene Endpoints | Determinismus |
|----|----------|----------------|---------|---------------------|---------------|
| **T-1** | Template gerendert, Caddy nicht geladen | Abbruch nach Rendering | `/generated` zeigt neue Config, Caddy nutzt alte | Neue Routen nicht erreichbar | Deterministisch |
| **T-2** | Caddy geladen, Smoke-Test fehlt | Manueller Abbruch oder Skript-Fehler | Deploy gilt als unabgeschlossen | Potenziell alle | Deterministisch |
| **T-3** | capabilities.json nicht kopiert | Datei nicht im richtigen Pfad | 404 auf `/.well-known/capabilities.json` | `/.well-known/capabilities.json` | Deterministisch |

### 2.5 Drift

| ID | Szenario | Was ist falsch | Symptom | Betroffene Endpoints | Determinismus |
|----|----------|----------------|---------|---------------------|---------------|
| **D-1** | Manuell editierte Caddyfile | Operator ändert `/generated`, nicht Template | Nächstes Deploy überschreibt Änderung | Abhängig von Änderung | Sporadisch |
| **D-2** | Caddy mit fremder Config | Caddy manuell mit anderem Pfad gestartet | `/generated/Caddyfile` ≠ laufende Config | Alle | Deterministisch bei Inspektion |
| **D-3** | Phantom-Capabilities | Template erweitert, Caddy-Route fehlt | Client liest Capability, Request schlägt fehl | Neue Endpoints | Deterministisch |

### 2.6 "False Green"-Zustände

| ID | Szenario | Was ist falsch | Symptom | Betroffene Endpoints | Determinismus |
|----|----------|----------------|---------|---------------------|---------------|
| **F-1** | Leeres models-Array | Ollama ohne Modelle | `/api/tags` liefert `{"models":[]}`, strukturell ok | `/api/tags` (semantisch nutzlos) | Deterministisch |
| **F-2** | base_url-Inkonsistenz | `capabilities.json` zeigt falschen Host | Smoke-Test grün, aber Clients routen falsch | Keiner direkt | Deterministisch |
| **F-3** | Firewall blockiert extern | Lokaler Zugriff ok, externer blockiert | Smoke-Test grün, keine externe Erreichbarkeit | Alle (von extern) | Deterministisch |

---

## 3. Erkennungsmechanismen

### 3.1 Zuverlässige Signale

| Signal | Erkennt | Zuverlässigkeit |
|--------|---------|-----------------|
| `/health` antwortet nicht | Caddy down, Port belegt, falscher Host-Header | Hoch |
| `/api/tags` liefert 502 | Ollama-Upstream nicht erreichbar | Hoch |
| `capabilities.json` fehlt | MCP_ROOT falsch, Datei nicht generiert | Hoch |
| Deploy-Skript Exit-Code ≠ 0 | Fail-Fast bei node.env-Problemen | Hoch |
| `caddy reload` schlägt fehl | Syntax-Fehler, Admin-API tot | Hoch |

### 3.2 Trügerische Signale

| Signal | Warum trügerisch |
|--------|------------------|
| `/health = ok` | Sagt nichts über `base_url`-Konsistenz, Ollama-Status, externe Erreichbarkeit |
| `mcp_version` vorhanden | Prüft nicht Korrektheit oder Capability-Existenz |
| Caddy-Prozess existiert | Prozess kann Zombie sein, Admin-API tot |
| `/api/tags` liefert JSON | Leeres `models`-Array ist technisch korrekt |
| Smoke-Test lokal grün | Sagt nichts über Firewall, DNS, externe Pfade |

### 3.3 Erkennungsmatrix

| Failure-Mode | Primäres Signal | Zusätzliche Prüfung |
|--------------|-----------------|---------------------|
| NODE_FQDN fehlt | Deploy bricht ab | — |
| base_url-Mismatch | `jq .server.base_url` vs. `$NODE_FQDN` | Semantic Check |
| Ollama down | `/api/tags` 502 | Direkter Request an `OLLAMA_UPSTREAM` |
| Teil-Deployment | Smoke-Test fehlt | Exit-Code, Timestamp-Vergleich |
| Drift | Diff `/generated` vs. laufende Config | `caddy config` abrufen |
| False Green (leere models) | `jq '.models \| length'` | Inhaltsprüfung |

---

## 4. Grenzen von Health & Smoke-Tests

### 4.1 Was /health zuverlässig erkennt

- Caddy läuft
- Host-Header-Routing funktioniert
- Port 80 ist offen

### 4.2 Was /health NICHT erkennt

| Nicht erkannt | Grund |
|---------------|-------|
| Ollama-Status | `/health` ist Caddy-intern |
| Capability-Konsistenz | Keine Prüfung von `capabilities.json` |
| base_url-Korrektheit | Keine semantische Prüfung |
| Externe Erreichbarkeit | Test läuft lokal |
| Modell-Verfügbarkeit | Kein Inhalt von `/api/tags` geprüft |
| DNS-Korrektheit | Kein DNS-Lookup |

### 4.3 Kombinatorische Checks

| Prüfziel | Erforderliche Kombination |
|----------|---------------------------|
| Komplette Node-Validierung | `/health` + `capabilities.json` + `/api/tags` |
| Identitäts-Konsistenz | `base_url` vs. genutzter Host-Header |
| Deployment-Vollständigkeit | Smoke-Test + Exit-Code 0 |
| Externer Zugriff | Smoke-Test + Test von externer IP |
| Modell-Bereitschaft | `/api/tags` + `models.length > 0` |

### 4.4 Nicht durch Tests erkennbar

| Fehler | Grund |
|--------|-------|
| Zukünftiger Drift | Tests prüfen aktuellen Zustand |
| Performance-Degradation | Keine Latenz-Messung |
| Falsch deklarierte Capabilities | Keine Funktionsprüfung jeder Capability |
| Cross-Node-Konsistenz | Designentscheidung: Keine Cross-Node-Tests |

---

## 5. Prinzipielle Lehren

### 5.1 Bestätigte Invarianten

| Invariante | Bestätigung |
|------------|-------------|
| Smoke-Test = Wahrheitsquelle | Erfasste Failures werden zuverlässig erkannt |
| node.env = Single Source of Identity | Alle Identitätsfehler entstehen durch Abweichung |
| Fail-Fast schützt | Fehlende Pflichtfelder brechen vor Mutation ab |
| Idempotenz verhindert Drift | Wiederholtes Deploy stellt Konsistenz her |

### 5.2 Geschwächte Annahmen

| Annahme | Schwäche |
|---------|----------|
| "Smoke-Test = vollständige Validierung" | False-Green zeigt: Struktur ≠ Semantik |
| "Lokal = Extern" | Firewall-Szenario zeigt Lücke |
| "Existenz = Korrektheit" | Leeres models-Array zeigt: Struktur ≠ Funktion |

### 5.3 Abgeleitete Design-Regeln

| # | Regel |
|---|-------|
| **L-1** | Struktur-Checks sind notwendig, aber nicht hinreichend für Produktionsbereitschaft |
| **L-2** | Semantische Konsistenz (`base_url` = `NODE_FQDN`) muss explizit geprüft werden |
| **L-3** | Jede deklarierte Capability sollte durch Test abgedeckt sein |
| **L-4** | Lokale Tests validieren lokale Korrektheit. Externe Erreichbarkeit ist separates Prüfziel |
| **L-5** | "Green" ohne Exit-Code-Prüfung ist nicht "Green" |
| **L-6** | Manuelle Eingriffe in `/generated` erzeugen unsichtbaren Drift |
| **L-7** | Laufender Prozess ≠ steuerbarer Prozess (Admin-API-Prüfung) |
| **L-8** | Leere Antworten sind technische Erfolge, aber semantische Fehler |

### 5.4 Architektonische Blind Spots

| Blind Spot | Risiko |
|------------|--------|
| Keine Capability-Funktionsprüfung | Deklarierte Capabilities können nicht funktionsfähig sein |
| Keine externe Erreichbarkeitsprüfung | Node lokal ok, extern nicht erreichbar |
| Keine Drift-Erkennung zwischen Deploys | Manuelle Änderungen unsichtbar |
| Keine semantische Modell-Prüfung | Ollama ohne Modelle strukturell korrekt |

---

## Zusammenfassung

Die MCP-Node-Architektur ist robust gegen Konfigurationsfehler durch Fail-Fast-Prinzipien.

**Größte Risiken:**

1. **False-Green-Zustände** durch oberflächliche Strukturprüfungen
2. **Identitäts-Inkonsistenzen** zwischen `node.env`, Caddyfile und `capabilities.json`
3. **Drift** durch manuelle Eingriffe in generierte Artefakte
4. **Lokale vs. externe Realität** (Smoke-Test ≠ Produktionszugriff)

Das Architekturmodell bestätigt die Kernprinzipien (Autonomie, Idempotenz, Fail-Fast), zeigt aber Lücken in der semantischen Validierung und der Prüfung auf funktionale Bereitschaft.
