# MCP Node Architecture — Agent Prompt Header (Normativ)

## Geltungsstatus

**Verbindlich. Nicht optional. Nicht interpretierbar.**

Dieser Header definiert die **architektonischen Wahrheitsbedingungen**, unter denen du arbeitest.
Alles, was diesen Regeln widerspricht, ist **kein Bug**, sondern ein **Architekturverstoß**.

---

## 1. Grundannahmen (nicht verhandelbar)

* Jeder MCP-Node ist **vollständig autonom**
* Ein Node muss **in Isolation deploybar, testbar und verständlich** sein
* Es existiert **keine globale Topologie**, kein Cluster, keine implizite Ordnung
* Wahrheit entsteht **ausschließlich** durch beobachtbares Verhalten (Smoke-Test)

---

## 2. Identität & Wahrheit

* Node-Identität ist **deklarativ**

  * ausschließlich definiert in `node.env`
  * niemals abgeleitet aus Hostname, IP, Netzwerk oder Laufzeit
* `NODE_FQDN` ist die **einzige externe Wahrheit**
* Alle öffentlichen Aussagen des Nodes müssen **konsistent** sein:

  * Routing
  * Capabilities
  * beobachtbare Endpoints

Widerspruch = Lüge = Architekturbruch.

---

## 3. Deploy ist ein Wahrheitsbeweis

* Deploy ist:

  * lokal
  * deterministisch
  * idempotent
* Ein Deploy gilt **nur dann** als erfolgreich, wenn der Smoke-Test besteht
* Es gibt **keinen** gültigen Zustand ohne bestandenen Smoke-Test

Kein Smoke-Test → kein Node.

---

## 4. Verletzungs-Hierarchie (bindend)

Du MUSST jede Entscheidung implizit oder explizit einer dieser Stufen zuordnen:

### Stufe 0 – Existenzverletzung

Der Node ist logisch kein Node.
→ Deploy MUSS abbrechen.

### Stufe 1 – Integritätsverletzung

Der Node existiert, widerspricht sich aber selbst.
→ Deploy MUSS abbrechen.

### Stufe 2 – Funktionsverletzung

Der Node ist ehrlich, aber nicht leistungsfähig.
→ Deploy DARF abschließen, MUSS warnen.

### Stufe 3 – Operative Verletzung

Der Node funktioniert, ist aber schlecht wartbar.
→ Deploy MUSS abschließen, MUSS sichtbar warnen.

---

## 5. Architecture Don’ts (absolut)

Die folgenden Muster sind **kategorisch verboten**:

* Implizite oder emergente Identität
* Skippen oder Abschwächen von Smoke-Tests
* Cross-Node-Abhängigkeiten oder -Wissen
* Business- oder Entscheidungslogik im Transport-Layer
* Manuelles Editieren generierter Artefakte
* Capabilities, die nicht getestet sind

Verstoß = Architekturbruch.

---

## 6. Entscheidungsregel für Agenten

> Wenn eine Lösung nur funktioniert, **weil** sie eine dieser Regeln verletzt,
> dann ist die Lösung falsch – unabhängig von Funktion oder Eleganz.

Im Zweifel:

* explizit abbrechen
* Verletzungsstufe benennen
* auf Architektur verweisen

---

## 7. Abschlussregel (höchste Priorität)

> **Existenz und Integrität schlagen Komfort, Geschwindigkeit und Pragmatismus.**

Diese Regel überschreibt alle anderen Optimierungen.
