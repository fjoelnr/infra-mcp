```markdown
# SSH-Zugriff auf Home Assistant einrichten - Tutorial

## Überblick
Dieses Tutorial erklärt, wie du SSH-Zugriff auf deinen Home Assistant im lokalen Netzwerk einrichtest, um per Kommandozeile auf das System zuzugreifen und zu arbeiten.

## Voraussetzungen
- Home Assistant Installation (Home Assistant OS, Supervised oder Container)
- Zugriff auf die Home Assistant Weboberfläche
- Ein weiterer Rechner im gleichen lokalen Netzwerk
- SSH-Client auf dem Client-Rechner (Linux/Mac: vorinstalliert, Windows: PowerShell, PuTTY oder WSL)

## Schritt 1: SSH Add-on in Home Assistant installieren

Home Assistant hat standardmäßig keinen SSH-Server aktiv. Du musst das SSH Add-on installieren:

1. Öffne die Home Assistant Weboberfläche im Browser:
   ```
   http://homeassistant.local:8123
   ```
   oder über die IP-Adresse:
   ```
   http://192.168.1.XXX:8123
   ```

2. Navigiere zu: **Einstellungen** → **Add-ons**

3. Klicke unten rechts auf den Button **Add-on Store**

4. Suche nach "SSH" in der Suchleiste

5. Du findest zwei Optionen:
   - **Terminal & SSH** (offizielles Add-on, empfohlen)
   - **Advanced SSH & Web Terminal** (erweiterte Version)

6. Wähle **Terminal & SSH** aus

7. Klicke auf **Installieren** und warte, bis die Installation abgeschlossen ist

## Schritt 2: SSH Add-on konfigurieren

Nach der Installation musst du das Add-on konfigurieren:

1. Bleibe auf der Add-on Seite von "Terminal & SSH"

2. Klicke oben auf den Tab **Konfiguration**

3. Wähle eine Authentifizierungsmethode:

### Option A: SSH-Key Authentifizierung (empfohlen, sicherer)

Wenn du bereits einen SSH-Key hast, füge den Public Key hinzu:

```yaml
authorized_keys:
  - "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC... dein-public-key hier einfügen"
```

**SSH-Key erstellen (falls noch nicht vorhanden):**

Auf deinem Client-Rechner (Linux/Mac/Windows WSL):
```bash
ssh-keygen -t rsa -b 4096 -C "deine-email@example.com"
```

Public Key anzeigen:
```bash
cat ~/.ssh/id_rsa.pub
```

Kopiere die komplette Ausgabe und füge sie in die Konfiguration ein.

### Option B: Passwort-Authentifizierung (einfacher, weniger sicher)

```yaml
password: "dein-sicheres-passwort-hier"
```

Wähle ein starkes Passwort mit mindestens 12 Zeichen, Groß-/Kleinbuchstaben, Zahlen und Sonderzeichen.

### Optionale Einstellungen

**SSH-Port ändern (optional):**
```yaml
ssh:
  port: 22
```

Standard ist Port 22. Du kannst einen anderen Port wählen, z.B. 2222.

4. Klicke auf **Speichern** unten auf der Seite

## Schritt 3: SSH Add-on starten

1. Wechsle zurück zum Tab **Info**

2. Klicke auf den Button **Start**

3. Warte, bis der Status auf grün wechselt (läuft)

4. Aktiviere die folgenden Optionen:
   - **Start on boot** (Häkchen setzen) - Add-on startet automatisch beim Booten
   - **Watchdog** (Häkchen setzen) - Automatischer Neustart bei Problemen

5. Optional: Klicke auf **Logs**, um zu prüfen, ob das Add-on korrekt gestartet ist

## Schritt 4: IP-Adresse von Home Assistant ermitteln

Du benötigst die IP-Adresse deines Home Assistant Systems:

### Methode 1: In Home Assistant
1. Gehe zu **Einstellungen** → **System** → **Netzwerk**
2. Notiere die IPv4-Adresse (z.B. `192.168.1.100`)

### Methode 2: Router-Interface
1. Logge dich in deinen Router ein
2. Suche nach verbundenen Geräten
3. Finde "homeassistant" in der Liste

### Methode 3: Ping-Befehl (wenn mDNS funktioniert)
```bash
ping homeassistant.local
```

## Schritt 5: SSH-Verbindung vom Client-Rechner herstellen

Öffne auf deinem Client-Rechner ein Terminal oder eine Eingabeaufforderung:

### Linux / Mac / Windows (PowerShell oder WSL)

**Mit IP-Adresse:**
```bash
ssh root@192.168.1.100 -p 22
```

**Mit Hostname (wenn mDNS funktioniert):**
```bash
ssh root@homeassistant.local -p 22
```

Ersetze:
- `192.168.1.100` mit der tatsächlichen IP-Adresse
- `22` mit dem konfigurierten Port (falls geändert)

### Windows (mit PuTTY)

1. Öffne PuTTY
2. Gib die IP-Adresse ein: `192.168.1.100`
3. Port: `22` (oder dein konfigurierter Port)
4. Connection type: **SSH**
5. Klicke auf **Open**

### Erste Verbindung

Beim ersten Verbindungsaufbau erscheint eine Warnung über den Host-Key:
```
The authenticity of host '192.168.1.100' can't be established.
Are you sure you want to continue connecting (yes/no)?
```

Tippe `yes` und drücke Enter.

**Bei Passwort-Authentifizierung:**
Gib dein konfiguriertes Passwort ein.

**Bei Key-Authentifizierung:**
Die Verbindung wird automatisch hergestellt (kein Passwort nötig).

## Schritt 6: Im Home Assistant System arbeiten

Nach erfolgreicher Anmeldung bist du im Home Assistant System eingeloggt.

### Wichtige Verzeichnisse

```bash
/config              # Hauptkonfigurationsverzeichnis
/config/configuration.yaml   # Hauptkonfigurationsdatei
/config/automations.yaml     # Automationen
/config/scripts.yaml         # Skripte
/config/custom_components/   # Benutzerdefinierte Komponenten
/config/home-assistant.log   # Log-Datei
```

### Grundlegende Befehle

**Dateien auflisten:**
```bash
ls /config
```

**In Verzeichnis wechseln:**
```bash
cd /config
```

**Datei anzeigen:**
```bash
cat configuration.yaml
```

**Datei bearbeiten:**
```bash
nano configuration.yaml
```

### Home Assistant CLI-Befehle

Das Add-on stellt das `ha` CLI-Tool bereit:

**Home Assistant neustarten:**
```bash
ha core restart
```

**Home Assistant stoppen:**
```bash
ha core stop
```

**Home Assistant starten:**
```bash
ha core start
```

**Konfiguration prüfen (ohne Neustart):**
```bash
ha core check
```

**Logs anzeigen:**
```bash
ha core logs
```

**System-Informationen:**
```bash
ha info
```

**Supervisor-Informationen:**
```bash
ha supervisor info
```

**Add-ons auflisten:**
```bash
ha addons
```

**Add-on neu starten:**
```bash
ha addons restart [addon-slug]
```

**Updates prüfen:**
```bash
ha supervisor update
ha core update
```

**Backup erstellen:**
```bash
ha backups new --name "manuelles-backup"
```

**Backups auflisten:**
```bash
ha backups list
```

### Konfigurationsdateien bearbeiten

**Mit nano (einfacher Editor):**
```bash
nano /config/configuration.yaml
```

Speichern: `Ctrl+O`, dann `Enter`
Beenden: `Ctrl+X`

**Mit vi/vim (fortgeschritten):**
```bash
vi /config/configuration.yaml
```

### Nach Änderungen: Konfiguration prüfen und neustarten

```bash
# Konfiguration prüfen
ha core check

# Wenn keine Fehler: Neustarten
ha core restart
```

## Schritt 7: Verbindung beenden

```bash
exit
```

oder drücke `Ctrl+D`

## Sicherheitshinweise

### Für lokales Netzwerk (empfohlen)
- SSH-Zugriff nur im lokalen Netzwerk verwenden
- SSH-Port NICHT im Router nach außen öffnen
- Starkes Passwort oder besser SSH-Keys verwenden

### Wenn Fernzugriff notwendig ist
- VPN verwenden (WireGuard, OpenVPN) statt direkte SSH-Portfreigabe
- Falls direkte Portfreigabe nötig:
  - Port von 22 auf eine hohe Nummer ändern (z.B. 52222)
  - Nur SSH-Key-Authentifizierung verwenden
  - Fail2ban installieren
  - Firewall-Regeln konfigurieren

### Best Practices
- Regelmäßig Backups erstellen
- System-Updates regelmäßig durchführen
- Logs auf Anomalien prüfen
- Zwei-Faktor-Authentifizierung für Home Assistant Web-Interface aktivieren

## Troubleshooting

### Problem: Verbindung schlägt fehl

**Prüfungen:**

1. Ist das SSH Add-on gestartet?
   - In Home Assistant: Add-ons → Terminal & SSH → Status sollte grün sein

2. Ist die IP-Adresse korrekt?
   ```bash
   ping 192.168.1.100
   ```

3. Sind beide Geräte im gleichen Netzwerk?
   - Prüfe die IP-Bereiche (z.B. beide 192.168.1.x)

4. Firewall blockiert die Verbindung?
   - Auf Home Assistant sollte keine Firewall SSH blockieren
   - Auf Client-Rechner: Ausgehende Verbindung zu Port 22 erlauben

5. Falscher Port?
   - Prüfe die Konfiguration des Add-ons

### Problem: "Permission denied" Fehler

**Bei Passwort-Authentifizierung:**
- Passwort korrekt eingegeben?
- Caps Lock aktiviert?
- Passwort in der Add-on Konfiguration korrekt gesetzt?

**Bei SSH-Key-Authentifizierung:**
- Public Key korrekt in Konfiguration eingefügt?
- Komplette Zeile kopiert? (beginnt mit ssh-rsa oder ssh-ed25519)
- Keine Leerzeichen oder Zeilenumbrüche im Key?
- Richtiger Private Key wird verwendet?

**Lösung:**
```bash
# Prüfe welcher Key verwendet wird
ssh -v root@192.168.1.100
```

Die Option `-v` zeigt Debug-Informationen.

### Problem: "Connection refused"

- SSH Add-on läuft nicht → Starte es in Home Assistant
- Falscher Port → Prüfe Konfiguration
- Falsche IP-Adresse → Prüfe IP erneut

### Problem: "Host key verification failed"

Der gespeicherte Host-Key stimmt nicht überein (z.B. nach Neuinstallation):

```bash
ssh-keygen -R 192.168.1.100
```

oder für Hostname:

```bash
ssh-keygen -R homeassistant.local
```

Dann erneut verbinden.

### Problem: Verbindung bricht ab oder ist sehr langsam

**Keepalive aktivieren:**

Erstelle/bearbeite `~/.ssh/config` auf dem Client:

```
Host homeassistant
    HostName 192.168.1.100
    User root
    Port 22
    ServerAliveInterval 60
    ServerAliveCountMax 3
```

Dann verbinden mit:
```bash
ssh homeassistant
```

## Erweiterte Nutzung

### SSH-Alias erstellen

Erstelle `~/.ssh/config` auf deinem Client-Rechner:

```
Host ha
    HostName 192.168.1.100
    User root
    Port 22
    IdentityFile ~/.ssh/id_rsa
```

Dann kannst du einfach verbinden mit:
```bash
ssh ha
```

### SCP: Dateien kopieren

**Datei von Client zu Home Assistant:**
```bash
scp /pfad/zur/datei.yaml root@192.168.1.100:/config/
```

**Datei von Home Assistant zu Client:**
```bash
scp root@192.168.1.100:/config/configuration.yaml ~/backup/
```

**Komplettes Verzeichnis:**
```bash
scp -r root@192.168.1.100:/config/custom_components/ ~/backup/
```

### SSHFS: Home Assistant als Netzlaufwerk einbinden

**Linux/Mac:**
```bash
# SSHFS installieren (falls nicht vorhanden)
# Ubuntu/Debian:
sudo apt install sshfs

# macOS:
brew install macfuse sshfs

# Verzeichnis erstellen
mkdir ~/homeassistant

# Einbinden
sshfs root@192.168.1.100:/config ~/homeassistant

# Aushängen
umount ~/homeassistant
```

**Windows:**
Verwende SSHFS-Win oder WinFsp + SSHFS-Win

### VS Code Remote SSH

1. Installiere die Extension "Remote - SSH" in VS Code
2. Drücke `F1` → "Remote-SSH: Connect to Host"
3. Gib ein: `root@192.168.1.100`
4. Öffne `/config` Verzeichnis

Jetzt kannst du Dateien direkt in VS Code bearbeiten.

## Nützliche Workflow-Beispiele

### Beispiel 1: Konfiguration bearbeiten und testen

```bash
# Verbinden
ssh root@homeassistant.local

# Backup erstellen
cp /config/configuration.yaml /config/configuration.yaml.backup

# Bearbeiten
nano /config/configuration.yaml

# Änderungen speichern (Ctrl+O, Enter, Ctrl+X)

# Konfiguration prüfen
ha core check

# Bei Erfolg: Neustarten
ha core restart

# Logs überwachen
ha core logs -f
```

### Beispiel 2: Custom Component installieren

```bash
# Verbinden
ssh root@homeassistant.local

# Ins custom_components Verzeichnis
cd /config/custom_components

# Falls nicht vorhanden, erstellen
mkdir -p /config/custom_components

# Beispiel: Mit wget herunterladen
wget https://github.com/example/component/archive/main.zip
unzip main.zip
rm main.zip

# Home Assistant neustarten
ha core restart
```

### Beispiel 3: Logs analysieren

```bash
# Verbinden
ssh root@homeassistant.local

# Letzte 100 Zeilen
tail -n 100 /config/home-assistant.log

# Live-Logs verfolgen
tail -f /config/home-assistant.log

# Nach Fehler suchen
grep ERROR /config/home-assistant.log

# Nach bestimmter Integration suchen
grep "homekit" /config/home-assistant.log
```

## Zusammenfassung

Du hast nun gelernt:
1. SSH Add-on in Home Assistant zu installieren
2. SSH mit Passwort oder Key-Authentifizierung zu konfigurieren
3. Eine SSH-Verbindung herzustellen
4. Im Home Assistant System zu arbeiten
5. Home Assistant CLI-Befehle zu verwenden
6. Probleme zu beheben

SSH-Zugriff gibt dir volle Kontrolle über dein Home Assistant System und ermöglicht professionelle Workflows für Konfiguration, Wartung und Troubleshooting.

## Weitere Ressourcen

- Home Assistant Dokumentation: https://www.home-assistant.io/docs/
- SSH Add-on Dokumentation: https://github.com/home-assistant/addons/tree/master/ssh
- Home Assistant Community Forum: https://community.home-assistant.io/
- Home Assistant Discord: https://discord.gg/home-assistant

