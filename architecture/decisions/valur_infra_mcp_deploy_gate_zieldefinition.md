# Valur / Infra / MCP
## Deploy-Gate als operative Wahrheit

**Datum:** 2026-01-12  
**Status:** Beschlossen  
**Gültigkeit:** Verbindlich für alle MCP-Nodes

---

## 1. Zieldefinition (Pfad A)

### Ziel (Kurzfassung)
Ein MCP-Node gilt **erst dann** als existent, vertrauenswürdig und nutzbar, wenn ein **lokales, deterministisches Deploy-Gate** erfolgreich durchlaufen wurde.

> Existenz wird über Funktion definiert – nicht über Konfiguration.

---

## 2. Problemstellung
Ohne ein hartes Deploy-Gate entstehen systemische Fehlannahmen:

- Nodes gelten als verfügbar, sind aber faktisch defekt
- Agenten sehen Capabilities, die nicht erreichbar sind
- Fehler werden zeitlich und logisch entkoppelt („False Green“)

Dies ist kein Implementierungsfehler, sondern ein **Wahrheitsproblem** der Infrastruktur.

---

## 3. Operative Definition von „existiert“
Ein MCP-Node **existiert**, wenn **alle** folgenden Bedingungen erfüllt sind:

1. Lokales Deploy wurde ausgeführt
2. Lokaler Smoke-Test wurde ausgeführt
3. Smoke-Test war erfolgreich
4. Deploy-Prozess endete mit **Exit-Code 0**

Alles andere ist Vorstufe, Entwurf oder Annahme – aber kein operativer Zustand.

---

## 4. Invarianten des Deploy-Gates

### A-I1: Lokalität
- Prüfung ausschließlich gegen den lokalen Node
- Keine Cross-Node-Abhängigkeiten
- Keine externen Netzwerkannahmen

**Prinzip:** Wahrheit entsteht lokal.

### A-I2: Determinismus
- Gleicher Zustand ⇒ gleiches Ergebnis
- Keine Retry-Magie
- Kein „wahrscheinlich ok“

**Prinzip:** Unsicherheit ist ein Fehlerzustand.

### A-I3: Binäres Ergebnis
- Erfolg = Exit-Code 0
- Fehler = Exit-Code ≠ 0

Keine Warn-Success-Mischformen.

### A-I4: Sichtbarkeitssperre
- Kein Registry-Eintrag
- Keine Capability-Sichtbarkeit
- Kein Agenten-Routing

**solange das Deploy-Gate nicht erfolgreich war**.

---

## 5. Expliziter Nicht-Scope
Pfad A tut **nicht**:

- Keine Governance erfinden
- Keine CI/CD-Pipelines bauen
- Keine Agentenlogik verändern
- Keine globale Koordination

Pfad A ist **operativ**, nicht normativ.

---

## 6. Erfolgskriterium (Abnahme)

Pfad A gilt als abgeschlossen, wenn folgende Aussage wahr ist:

> „Es ist unmöglich, dass ein defekter MCP-Node als funktional betrachtet wird.“

Nicht unwahrscheinlich. Nicht selten. **Unmöglich.**

---

## 7. Checkliste – Revalidierung Pfad A

Diese Checkliste muss jederzeit mit **Ja** beantwortet werden können:

- [ ] Wird jeder Deploy lokal ausgeführt?
- [ ] Läuft der Smoke-Test ausschließlich gegen 127.0.0.1?
- [ ] Stammt die Node-Identität ausschließlich aus `node.env`?
- [ ] Gibt es genau zwei Exit-Zustände (0 / ≠0)?
- [ ] Bricht ein Smoke-Test-Fehler den Deploy hart ab?
- [ ] Gibt es keine Registry- oder Agentenwirkung ohne erfolgreiches Deploy?

Wenn ein Punkt **Nein** ist → Pfad A verletzt.

---

## 8. Agenten-Prompt (Implementierungsvorlage)

```
Du arbeitest im Projekt Valur / Infra / MCP.

Deine Aufgabe ist es, ein lokales Deploy-Gate zu implementieren oder zu überprüfen.

Zwingende Regeln:
- Ein Node gilt nur als existent, wenn ein lokales Deploy + Smoke-Test erfolgreich war
- Smoke-Tests laufen ausschließlich lokal (127.0.0.1)
- Node-Identität stammt ausschließlich aus node.env
- Ein fehlgeschlagener Smoke-Test MUSS den Deploy mit Exit-Code ≠ 0 abbrechen
- Keine neuen Konfigurationsquellen
- Keine Cross-Node-Tests
- Keine impliziten Defaults

Bewerte jede Entscheidung gegen diese Invarianten.
Wenn eine Regel verletzt wird, lehne die Implementierung ab und erkläre warum.
```

---

## 9. Übergang zu Pfad B
Pfad B (Governance & Normierung) darf **erst** beginnen, wenn Pfad A stabil, bewährt und revalidierbar ist.

Erst Verhalten – dann Verpflichtung.

