# Valur / Infra / MCP

## Governance & Architecture Contract

**Status:** verbindlich
**Gültig für:** alle MCP-Nodes, Deployments, Tests, Agenten-Ausgaben
**Scope:** Architektur, Invarianten, Betriebslogik
**Nicht-Ziel:** konkrete Implementierungen

---

## 0. Zweck des Dokuments

Dieses Dokument definiert **nicht verhandelbare Invarianten** für das Projekt
**Valur / Infra / MCP**.

Ziel ist es, systemische Fehler zu verhindern, bevor sie in Code gegossen werden.

Ein Ergebnis, das diesem Contract widerspricht, gilt als **architektonisch ungültig** –
auch wenn es funktional erscheint.

---

## 1. Grundprinzipien

### 1.1 Architektur vor Implementierung

Keine Implementierung darf entstehen, bevor die zugrunde liegende Architektur explizit beschrieben ist.

„Der Code zeigt es schon“ ist kein gültiges Argument.

---

### 1.2 Explizit schlägt implizit

Alle Annahmen müssen sichtbar, benennbar und prüfbar sein.

Implizite Defaults, versteckte Konventionen oder „das ist doch klar“-Logik sind unzulässig.

---

### 1.3 Determinismus vor Komfort

Ein System, das vorhersehbar scheitert, ist wertvoller als eines, das manchmal funktioniert.

---

## 2. Zentrale Invarianten

### 2.1 Node-Agnostik (A1)

Kein Artefakt darf Annahmen über die Identität des Nodes enthalten, auf dem es ausgeführt wird.

**Verboten:**

* fest kodierte FQDNs
* Rollenannahmen („dieser Node ist der PC“)
* implizite Zielsysteme

**Erlaubt:**

* explizite Node-Identität über externe Konfiguration (z. B. `node.env`)
* Ableitungsregeln: Input → deterministischer Output

Ein Artefakt muss auf **jedem Node gleich funktionieren**, sofern die Node-Identität korrekt geliefert wird.

---

### 2.2 Single Source of Truth (A2)

Jede Information hat **genau eine autoritative Quelle**.

Beispiele:

* Node-Identität → `node.env`
* Öffentliche HTTP-Oberfläche → Caddy
* Interne Services → Loopback / private Bindings
* Capability-Wahrheit → `.well-known/capabilities.json`

Doppelte Pflege derselben Information ist ein Architekturfehler.

---

### 2.3 Idempotenz (A3)

Ein Deployment ist nur gültig, wenn:

> Mehrfaches Ausführen desselben Deployments **keine zusätzlichen Zustandsänderungen** erzeugt.

Unzulässig sind:

* verdeckte Migrationen
* zustandsabhängige Seiteneffekte
* „beim zweiten Mal geht es“

Ein Deploy ist kein Skript, sondern eine **Zustandsbehauptung**.

---

### 2.4 Beobachtbarkeit (A4)

Beobachtbarkeit ist Voraussetzung für Korrektheit.

Pflichtbestandteile:

* stabiler `/health`-Endpunkt
* maschinenlesbare Ergebnisse
* deterministische Fehlersignale

Reihenfolge ist invariant:

1. Health
2. Capabilities
3. Fachliche APIs / Proxies

---

## 3. Verantwortlichkeiten (RACI-Logik)

### Mensch

* trifft Architekturentscheidungen
* definiert Invarianten
* akzeptiert oder verwirft Ergebnisse

### Agent (Antigravity)

* erzeugt Implementierungen **ausschließlich auf Basis expliziter Prompts**
* darf keine stillschweigenden Annahmen treffen
* muss auf Unklarheiten hinweisen

### System

* erzwingt Regeln durch Tests, Contracts und Reviews
* bestraft Abweichungen durch deterministisches Scheitern

---

## 4. Naming & Semantik

Namen sind Teil der Architektur.

### Verboten:

* reservierte Begriffe (`Host` in PowerShell)
* mehrdeutige Namen (`server`, `node`, `target`)
* Bedeutungsüberladung

### Pflicht:

* klare Trennung von:

  * Node-Identität
  * Zieladresse
  * Bind-Adresse
  * Host-Header

Wenn ein Name missverständlich ist, ist das ein Architekturfehler.

---

## 5. Tests & Validierung

### Smoke-Tests

* prüfen ausschließlich **Erreichbarkeit und Routing**
* laufen **lokal**
* machen keine Annahmen über andere Nodes

### Cross-Node-Tests

* sind explizit
* sind getrennt von lokalen Smoke-Tests
* gehören nicht in den Default-Deploy-Pfad

---

## 6. Verbotene Praktiken (Auszug)

* harte Kodierung von Infrastruktur-Identitäten
* implizite Defaults
* Environment-Magie ohne Dokumentation
* Tests, die nur auf einem Node funktionieren
* Fixes ohne Ursachenanalyse

---

## 7. Änderungsprozess

Änderungen an diesem Contract:

* erfolgen bewusst
* werden dokumentiert
* haben Begründung

„Weil es sonst nicht geht“ ist keine Begründung.

---

## 8. Leitsatz

> **Wenn ein System sich nicht erklären lässt, darf es nicht automatisiert werden.**
