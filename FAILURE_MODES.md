# Valur / Infra / MCP

## Failure Modes & Anti-Patterns

**Zweck:**
Dieses Dokument beschreibt **typische, systemische Fehlerbilder**, ihre Ursachen und die jeweils verletzte Invariante aus dem Governance-Contract.

Ein Fehler gilt als *verstanden*, wenn:

* sein **Failure-Mode benannt**
* seine **Ursache erklärt**
* seine **Gegenmaßnahme klar** ist

---

## FM-01: Node-Identitäts-Leak

**Symptom**

* Deployment funktioniert auf einem Node, aber nicht auf einem anderen
* Laptop „glaubt“, er sei der PC
* FQDNs stimmen nicht mit der Maschine überein

**Ursache**

* Node-Identität ist implizit oder hart kodiert
* `node.env` wird nicht als Single Source of Truth behandelt
* Artefakte enthalten feste Hostnamen

**Verletzte Invariante**

* A1: Node-Agnostik
* A2: Single Source of Truth

**Gegenmaßnahme**

* Node-Identität ausschließlich extern definieren
* Templates dürfen keine realen FQDNs enthalten
* Jede Ableitung: `node.env → generierte Artefakte`

**Merksatz**

> Wenn ein Artefakt weiß, *wo* es läuft, ist es falsch.

---

## FM-02: Implizite Defaults (Environment-Magie)

**Symptom**

* Verhalten ändert sich „plötzlich“
* Skripte verhalten sich je nach Shell / Maschine anders
* Dinge funktionieren „ohne dass man weiß warum“

**Ursache**

* Nutzung impliziter Environment-Variablen
* reservierte Namen (`Host`, `$env:HOST`, etc.)
* Annahmen über vorhandene Tools / Pfade

**Verletzte Invariante**

* 1.2 Explizit schlägt implizit
* 4 Beobachtbarkeit

**Gegenmaßnahme**

* Alle Inputs explizit dokumentieren
* Reservierte Namen vermeiden
* Fehlermeldungen bei fehlenden Inputs erzwingen

**Merksatz**

> Magie ist nur fehlende Dokumentation.

---

## FM-03: Nicht-idempotentes Deployment

**Symptom**

* Erster Deploy geht, zweiter nicht
* „Nach Neustart kaputt“
* Zustand hängt von Ausführungsreihenfolge ab

**Ursache**

* Deploy-Skripte erzeugen impliziten Zustand
* Nebenwirkungen ohne Prüfung
* fehlende Existenz-Checks

**Verletzte Invariante**

* A3: Idempotenz

**Gegenmaßnahme**

* Deploy als Zustandsbehauptung denken
* Vorher/Nachher klar definieren
* Mehrfachausführung als Normalfall behandeln

**Merksatz**

> Wenn ein Deploy Angst vor Wiederholung hat, ist es kein Deploy.

---

## FM-04: Beobachtbarkeits-Illusion

**Symptom**

* „Service läuft“, aber nichts antwortet
* Health ok, API tot (oder umgekehrt)
* Fehlersuche nur per Bauchgefühl möglich

**Ursache**

* `/health` prüft nicht das Wesentliche
* fehlende Trennung von Health / Capability / Fach-API
* nicht-deterministische Antworten

**Verletzte Invariante**

* A4: Beobachtbarkeit

**Gegenmaßnahme**

* Health minimal, aber ehrlich
* Capabilities maschinenlesbar und stabil
* klare Fehlercodes statt stiller Leere

**Merksatz**

> Ein grünes Licht ohne Aussage ist wertlos.

---

## FM-05: Vermischte Testebenen

**Symptom**

* Smoke-Tests schlagen nur auf bestimmten Nodes fehl
* Tests testen plötzlich Netzwerk, DNS, Firewall
* „Bei mir geht’s“

**Ursache**

* Lokale Tests greifen auf Remote-Systeme zu
* Cross-Node-Annahmen im Default-Testpfad
* fehlende Trennung von Testarten

**Verletzte Invariante**

* A1: Node-Agnostik
* Abschnitt 5: Tests & Validierung

**Gegenmaßnahme**

* Smoke-Tests immer lokal
* Cross-Node-Tests explizit und optional
* Host-Header vs. Ziel-IP sauber trennen

**Merksatz**

> Ein Test, der mehr prüft als er sagt, ist ein Lügner.

---

## FM-06: Naming-Collision / Semantischer Drift

**Symptom**

* Skripte brechen mit kryptischen PowerShell-Fehlern
* Variablen lassen sich nicht setzen
* Verhalten ändert sich nach „harmlosen“ Umbenennungen

**Ursache**

* Nutzung reservierter Begriffe
* Mehrdeutige Variablennamen
* fehlende semantische Trennung

**Verletzte Invariante**

* Abschnitt 4: Naming & Semantik

**Gegenmaßnahme**

* Bedeutungspräzise Namen
* keine Überladung
* technische und fachliche Namen trennen

**Merksatz**

> Namen sind Schnittstellen.

---

## FM-07: Agenten-Halluzination

**Symptom**

* Code enthält nicht existierende Variablen
* „aus dem Hut gezauberte“ Konzepte
* Lösungen ohne Bezug zur Architektur

**Ursache**

* Agent erhält zu vage Prompts
* fehlender Contract
* fehlender Review-Mechanismus

**Verletzte Invariante**

* 1.1 Architektur vor Implementierung
* RACI-Logik

**Gegenmaßnahme**

* Agenten nur mit Contract + Scope arbeiten lassen
* Review-Prompts erzwingen
* Unsicherheit explizit machen

**Merksatz**

> Ein Agent ohne Leitplanken fährt schnell – und falsch.

---

## 8. Abschluss

Dieser Katalog ist **nicht vollständig**, aber **erweiterbar**.
Neue Failure-Modes werden ergänzt, nicht verdrängt.
