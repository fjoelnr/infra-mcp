# Valur / Infra / MCP – Zukunftsbild & Arbeitsplan

> **Zweck dieses Dokuments**  
> Dieses Dokument dient als *Gedächtnisanker*.  
> Es soll ausreichen, um nach vollständigem Kontextverlust zu verstehen:
> - was bereits geschaffen wurde,
> - warum es so gebaut wurde,
> - und wie die Weiterentwicklung der MCP-Funktionalität im lokalen Valur-Ökosystem geplant ist.

---

## 1. Aktueller Stand (Ist-Zustand)

### 1.1 Was existiert bereits

Das Projekt **Valur / Infra / MCP** stellt aktuell ein **stabiles, invariantensicheres Fundament** bereit:

- **MCP-Nodes** auf mehreren Maschinen (PC, Laptop)
- **Caddy** als deterministischer, lokaler Entry-Point
- **Ollama** als lokaler Modell-Provider
- **MCP Capability Descriptor** (`/.well-known/capabilities.json`)
- **Deploy-Gate mit Smoke-Test**

Ein Node gilt *nur dann* als existent, wenn:
- Deploy erfolgreich war **und**
- der lokale Smoke-Test bestanden wurde (Exit-Code 0)

Diese Eigenschaft ist **hart garantiert**.

---

### 1.2 Zentrale Invarianten (bereits beschlossen)

Diese Regeln gelten systemweit und dürfen **niemals** verletzt werden:

1. **Node-Agnostik**  
   Kein Artefakt darf implizit wissen, auf welchem Rechner es läuft.

2. **Single Source of Truth**  
   Node-Identität stammt ausschließlich aus `node.env`.

3. **Lokale Wahrheit**  
   Smoke-Tests laufen immer gegen `127.0.0.1`.

4. **Binäre Existenz**  
   Ein Node existiert entweder korrekt oder gar nicht.

5. **Beobachtbarkeit**  
   Jeder Fehler muss maschinenlesbar und deterministisch sein (Exit-Code ≠ 0).

6. **Keine Cross-Node-Annahmen**  
   Kein Node testet oder bewertet andere Nodes.

7. **Keine impliziten Defaults**  
   Fehlende Information → harter Fehler.

Diese Invarianten bilden den **Contract**, auf dem alles Weitere aufsetzt.

---

## 2. Zielbild: MCP im lokalen Valur-Ökosystem

### 2.1 Das Ökosystem

MCP soll als *gemeinsame Bedeutungsschicht* dienen zwischen:

- PC
- Laptop
- Family Hub
- Ollama-Instanzen
- NotebookLM-Instanzen
- n8n
- Home Assistant
- zukünftigen Agenten und Tools

**Wichtig:**  
MCP ist **kein Orchestrator**, **kein Scheduler** und **kein Controller**.

MCP beschreibt – es befiehlt nicht.

---

### 2.2 Rolle von MCP

MCP ist im Zielbild:

- ein **Discovery-System** (Was existiert?)
- ein **Vertragssystem** (Was ist versprochen?)
- ein **Koordinationsmedium** (Wer kann was – unter welchen Annahmen?)

Nicht:
- keine Workflow-Engine
- kein Self-Healing-System
- kein Monitoring

---

## 3. Zukünftige MCP-Funktionalität (konzeptionell)

### Phase I – Wahrnehmung (Discovery)

**Ziel:** Agenten können MCP-Nodes *verstehen*, ohne sie zu benutzen.

Konzepte:
- Capability-Graph
- stabile Semantik von Fähigkeiten
- Versions- und Gültigkeitslogik
- explizite Nicht-Ziele pro Node

Leitfrage:
> *Was muss ein Agent wissen, um entscheiden zu können, ob er diesen Node überhaupt in Betracht zieht?*

---

### Phase II – Vertrag (Intention & Verantwortung)

**Ziel:** Klarheit über Verantwortung und Grenzen.

Konzepte:
- Verantwortlichkeitsmatrix (Node ↔ Capability ↔ Agent)
- Erwartungshorizonte (Latenz, Stabilität, Verfügbarkeit)
- explizite Failure-Semantik

Leitfrage:
> *Was schuldet ein Node dem Ökosystem – und was ausdrücklich nicht?*

---

### Phase III – Koordination (ohne Kontrolle)

**Ziel:** Zusammenarbeit ohne zentrale Steuerung.

Konzepte:
- Capability-Auswahl durch Agenten
- konkurrierende Anbieter derselben Fähigkeit
- bewusste Redundanz (PC vs. Laptop)

Leitfrage:
> *Wie treffen Agenten Entscheidungen, ohne dass MCP selbst entscheidet?*

---

## 4. Grober Arbeitsplan (zukünftiges Vorgehen)

### 4.1 Arbeitsmodus

- **Keine direkte Implementierung im Diskussionskontext**
- Architektur & Konzepte zuerst
- Implementierung ausschließlich über spezialisierte Agenten (Antigravity-Pattern)

---

### 4.2 Empfohlene Reihenfolge

1. Phase I vollständig klären
2. Contract & Invarianten verschriftlichen
3. Erst dann Phase II öffnen
4. Phase III zuletzt, sehr bewusst

---

## 5. Mentales Modell (Kurzfassung)

- MCP ist **Wahrheit**, nicht Aktion
- Nodes sind **Aussagen**, keine Akteure
- Agenten handeln – MCP beschreibt
- Stabilität ist wichtiger als Features

---

## 6. Warum das alles existiert

Dieses System soll:
- langfristig erweiterbar sein
- auch nach Monaten noch verständlich sein
- Agenten erlauben, **gute Entscheidungen** zu treffen
- menschliche Kontrolle ermöglichen, ohne Mikromanagement

Oder kurz:

> *MCP ist die Sprache, in der das lokale Ökosystem sich selbst beschreibt.*

---

**Status:** Architektur-Fundament abgeschlossen.  
**Nächster bewusster Schritt:** Phase I – Discovery als reines Denkmodell.

