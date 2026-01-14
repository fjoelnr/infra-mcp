# Pfad B – Sichtbarkeit & Bedeutung

Projekt: **Valur / Infra / MCP**  
Strang: **Infra / MCP – Pfad B**  
Status: **Zieldefinition (konzeptionell, nicht implementierend)**  

---

## 1. Zweck von Pfad B

Pfad B definiert **Sichtbarkeit, Bedeutung und Nutzbarkeit** eines MCP-Nodes *nachdem* dessen Existenz durch **Pfad A (Deploy-Gate)** bewiesen wurde.

Pfad B beantwortet **nicht**, ob ein Node existiert.  
Pfad B beantwortet **ausschließlich**, wie ein existierender Node im Gesamtsystem **wahrgenommen, eingeordnet und genutzt** wird.

Kurzform:
> **Pfad A entscheidet, ob ein Node real ist. Pfad B entscheidet, was dieser reale Node bedeutet.**

---

## 2. Explizite Abgrenzung zu Pfad A

Pfad B ist **hart entkoppelt** von Pfad A.

| Aspekt | Pfad A | Pfad B |
|------|-------|-------|
| Frage | „Existiert der Node?“ | „Welche Rolle spielt der Node?“ |
| Ebene | Lokal | Systemweit |
| Signal | Exit-Code | Registry / Graph / Snapshot |
| Natur | Binär | Semantisch |
| Fehler | Nicht-Existenz | Falsche Einordnung |

**Pfad B darf niemals:**
- Existenz implizieren
- Liveness testen
- Deploy-Ergebnisse überstimmen
- Fehler von Pfad A kaschieren

---

## 3. Grundinvarianten von Pfad B

### B1 – Existenz-Präzedenz
Pfad B darf ausschließlich Nodes berücksichtigen, deren Existenz durch Pfad A bewiesen wurde.

> Ein Node ohne erfolgreiches Deploy-Gate ist für Pfad B **nicht existent**.

---

### B2 – Lesender Charakter
Pfad B ist **read-only** gegenüber der Realität eines Nodes.

Er darf:
- lesen
- aggregieren
- gewichten
- darstellen

Er darf **nicht**:
- reparieren
- revalidieren
- simulieren
- überschreiben

---

### B3 – Keine eigene Wahrheit
Pfad B erzeugt **keine eigene Wahrheit**.

Alle Aussagen sind:
- abgeleitet
- zeitlich gebunden
- widerrufbar

Es gibt **keinen** Zustand „Node ist gut, obwohl Deploy fehlgeschlagen ist“.

---

### B4 – Zeitliche Unsicherheit ist erlaubt
Pfad B darf:
- veralten
- verzögert sein
- inkonsistent zwischen Konsumenten auftreten

Pfad A darf das **nicht**.

Diese Asymmetrie ist gewollt.

---

## 4. Erlaubte Aufgaben von Pfad B

Pfad B **darf**:
- Nodes in einer Registry führen
- Capabilities zusammenfassen
- Relevanz-Scores berechnen
- Agenten-Discovery ermöglichen
- Topologien darstellen
- Historische Sicht bereitstellen

Pfad B **darf nicht**:
- Health-Checks durchführen
- Deploy-Zustände bewerten
- Node-Identität definieren
- Defaults für kritische Felder setzen

---

## 5. Zentrale Failure-Modes (präventiv)

### FB-01 – Sichtbarkeit ohne Existenz
Ein Node erscheint nutzbar, obwohl Pfad A fehlgeschlagen ist.

**Verboten durch:** B1, B3

---

### FB-02 – Bedeutung ersetzt Wahrheit
Agenten priorisieren einen Node aufgrund alter Registry-Daten.

**Akzeptabel**, solange:
- Pfad A weiterhin das Existenz-Gate bleibt
- Aktionen erneut lokal validiert werden

---

### FB-03 – Registry als Ersatz-Gate
Registry wird faktisch zur Existenzentscheidung genutzt.

**Katastrophal.**

Pfad B darf niemals ein Gate sein.

---

## 6. Der Gelenkpunkt zwischen Pfad A und B

Der Übergang ist **kein Prozess**, sondern ein **Artefakt**.

Eigenschaften des Gelenks:
- entsteht nur nach erfolgreichem Deploy-Gate
- ist passiv konsumierbar
- ist zeitlich begrenzt gültig
- trägt keine Logik

Beispiele (nicht festgelegt):
- Capability-Snapshot
- Node-Alive-Beweis
- Signierter Statusmarker

Pfad B liest dieses Artefakt – sonst nichts.

---

## 7. Abnahmekriterium für Pfad B

Pfad B gilt als korrekt, wenn:

- Ein Node ohne Pfad-A-Erfolg **niemals** sichtbar wird
- Pfad-B-Ausfälle **keinen** Einfluss auf Existenz haben
- Agenten Pfad B ignorieren können, ohne Pfad A zu verletzen
- Falsche Registry-Daten keinen defekten Node „lebendig“ machen

Oder formal:
> **Pfad B darf lügen, aber niemals Wahrheit erzeugen.**

---

## 8. Status

✅ Zieldefinition abgeschlossen  
⛔ Keine Implementierung erlaubt  
➡️ Grundlage für Failure-Analyse, Agenten-Prompts und spätere Designentscheidungen

