# Paperless-ngx Document Sync Scripts

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Paperless-ngx](https://img.shields.io/badge/Paperless--ngx-Compatible-green.svg)](https://github.com/paperless-ngx/paperless-ngx)
[![Shell Script](https://img.shields.io/badge/Shell-Bash-blue.svg)](https://www.gnu.org/software/bash/)

Robuste Bash-Scripts zur automatischen Synchronisation von Dokumenten für [Paperless-ngx](https://github.com/paperless-ngx/paperless-ngx). 

## 📦 Verfügbare Scripts

### 1. **paperless-sync.sh** - Lokale Synchronisation
Für Server-lokale Synchronisation (gleiche Maschine)

### 2. **paperless-sync-remote.sh** - Remote Synchronisation (NEU!)
Für macOS → Linux Server Synchronisation via SSH

## ⚠️ Wichtiger Hinweis

**Paperless-ngx kann keine Unterordner im Consume-Verzeichnis verarbeiten!** Beide Scripts kopieren alle Dateien flach in das Hauptverzeichnis. Bei Dateinamen-Konflikten werden Dateien automatisch nummeriert (_1, _2, etc.).

---

## 🖥️ Remote Sync (macOS → Server)

### Features
- 🔐 **Sichere Übertragung** via SSH/rsync
- 🍎 **macOS optimiert** mit nativen Pfaden
- 🔑 **SSH-Key Setup** Assistent integriert
- 🌐 **Netzwerk-optimiert** mit Fehlerbehandlung
- 📁 **Flache Kopie** ohne Unterordner-Struktur

### Quick Start

#### 1. Script herunterladen
```bash
curl -O https://raw.githubusercontent.com/sambila/paperless-sync/main/paperless-sync-remote.sh
chmod +x paperless-sync-remote.sh
```

#### 2. Script anpassen
```bash
nano paperless-sync-remote.sh

# Ändern Sie diese Variablen:
SOURCE_DIR="$HOME/Documents"           # Ihre lokalen Dokumente
REMOTE_HOST="10.10.1.1"               # Server IP
REMOTE_USER="paper"                    # SSH Benutzer
REMOTE_DIR="/home/paper/docker/paperless-ngx/data/consume"
```

#### 3. SSH-Keys einrichten (für passwortlosen Zugang)
```bash
./paperless-sync-remote.sh --setup-ssh
```

#### 4. Testlauf
```bash
./paperless-sync-remote.sh --test
```

#### 5. Synchronisation starten
```bash
./paperless-sync-remote.sh
```

### Automatisierung mit launchd (macOS)

Erstellen Sie `~/Library/LaunchAgents/com.paperless.sync.plist`:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" 
  "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.paperless.sync</string>
    <key>ProgramArguments</key>
    <array>
        <string>/Users/IhrName/paperless-sync-remote.sh</string>
    </array>
    <key>StartInterval</key>
    <integer>3600</integer> <!-- Alle 60 Minuten -->
    <key>StandardOutPath</key>
    <string>/Users/IhrName/Library/Logs/paperless-sync.log</string>
    <key>StandardErrorPath</key>
    <string>/Users/IhrName/Library/Logs/paperless-sync-error.log</string>
</dict>
</plist>
```

Aktivieren:
```bash
launchctl load ~/Library/LaunchAgents/com.paperless.sync.plist
```

---

## 💻 Lokale Synchronisation (Server)

### Features
- ✅ **Flache Kopie** aller Dateien ohne Unterordner-Struktur
- 🔄 **Intelligente Konfliktbehandlung** bei doppelten Dateinamen
- 🔍 **Checksummen-Vergleich** überspringt identische Dateien
- 📊 **Detaillierte Statistiken** nach der Synchronisation

### Quick Start

```bash
# Download
git clone https://github.com/sambila/paperless-sync.git
cd paperless-sync

# Anpassen
nano paperless-sync.sh
# SOURCE_DIR und DEST_DIR anpassen

# Ausführen
chmod +x paperless-sync.sh
./paperless-sync.sh --test  # Testlauf
./paperless-sync.sh         # Synchronisation
```

### Automatisierung mit Cron

```bash
crontab -e
# Stündlich:
0 * * * * /pfad/zu/paperless-sync.sh >> /var/log/paperless-sync.log 2>&1
```

---

## 📋 Unterstützte Dateiformate

### Basis-Formate (immer unterstützt)
- **PDF** - Portable Document Format
- **PNG, JPG/JPEG, TIFF, GIF, WebP** - Bildformate
- **TXT** - Textdateien

### Office-Formate (mit Tika-Integration)
- **DOC/DOCX** - Microsoft Word
- **XLS/XLSX** - Microsoft Excel
- **PPT/PPTX** - Microsoft PowerPoint
- **ODT/ODS/ODP** - LibreOffice/OpenOffice
- **EML/MSG** - E-Mail-Formate
- **RTF** - Rich Text Format

## 🔄 Funktionsweise

Beide Scripts:
1. **Durchsuchen** rekursiv alle Unterordner im Quellverzeichnis
2. **Finden** alle Dateien mit unterstützten Erweiterungen
3. **Kopieren** diese flach ins Zielverzeichnis
4. **Behandeln Konflikte** intelligent mit Checksummen-Vergleich
5. **Protokollieren** alle Aktionen

## 📊 Ausgabe-Beispiel

```
======================================
Paperless Remote Document Sync Script
         macOS → Remote Server        
======================================

Teste SSH-Verbindung zu paper@10.10.1.1...
✓ SSH-Verbindung erfolgreich

Starte Remote-Synchronisation...
Unterstützte Basis-Formate:
pdf png jpg jpeg tiff tif gif webp txt 

Synchronisiere Dateien...
  ✓ Rechnung_2024.pdf
  ✓ Scan_001.jpg
  ✓ Brief_Versicherung.docx

=== Remote Statistiken ===
  pdf: 15 Datei(en)
  jpg: 8 Datei(en)
  docx: 3 Datei(en)
Gesamt: 26 Datei(en) im Remote Consume-Verzeichnis

Script beendet.
```

## 🛡️ Sicherheit

- 🔐 SSH-verschlüsselte Übertragung (Remote)
- 🔑 SSH-Key Authentifizierung unterstützt
- ✅ MD5-Checksummen-Vergleich
- 📝 Vollständiges Logging
- 🚫 Keine Änderung der Originaldateien

## 🐛 Fehlerbehebung

### SSH-Verbindung schlägt fehl
```bash
# SSH-Keys einrichten
./paperless-sync-remote.sh --setup-ssh

# Oder manuell testen
ssh paper@10.10.1.1
```

### Permission denied
```bash
# Auf dem Server als user 'paper':
chmod 755 /home/paper/docker/paperless-ngx/data/consume
```

### rsync nicht installiert (macOS)
```bash
# Mit Homebrew installieren
brew install rsync
```

## 📝 Anforderungen

### Für Remote-Sync (macOS → Server)
- **macOS** 10.12 oder höher
- **rsync** (via Homebrew)
- **SSH-Zugang** zum Server
- **Schreibrechte** im Zielverzeichnis

### Für lokalen Sync (Server)
- **Bash** 4.0 oder höher
- **Standard Unix-Tools** (find, cp, md5sum)
- **Schreibrechte** im Zielverzeichnis

## 🤝 Beitragen

Beiträge sind willkommen! Bitte erstellen Sie einen Pull Request oder öffnen Sie ein Issue.

## 📄 Lizenz

MIT License - siehe [LICENSE](LICENSE)

## 🔗 Links

- [Paperless-ngx Dokumentation](https://docs.paperless-ngx.com/)
- [Paperless-ngx GitHub](https://github.com/paperless-ngx/paperless-ngx)

## 👤 Autor

Erstellt für die Paperless-ngx Community

---

**Hinweis:** Diese Scripts sind Community-Beiträge und nicht offiziell vom Paperless-ngx Team unterstützt.
