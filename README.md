# Paperless-ngx Document Sync Script

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Paperless-ngx](https://img.shields.io/badge/Paperless--ngx-Compatible-green.svg)](https://github.com/paperless-ngx/paperless-ngx)
[![Shell Script](https://img.shields.io/badge/Shell-Bash-blue.svg)](https://www.gnu.org/software/bash/)

Ein robustes Bash-Script zur automatischen Synchronisation von Dokumenten für [Paperless-ngx](https://github.com/paperless-ngx/paperless-ngx). Das Script kopiert alle unterstützten Dateiformate sicher mit `rsync` von einem Quellverzeichnis in das Paperless-Consume-Verzeichnis.

## 🎯 Features

- ✅ **Sichere Übertragung** mit `rsync` und Checksummen-Verifikation
- 📁 **Rekursive Verarbeitung** aller Unterordner
- 📝 **Umfassende Formatunterstützung** für alle Paperless-kompatiblen Dateitypen
- 🔍 **Testmodus** zur Vorschau ohne tatsächliche Kopie
- 📊 **Detaillierte Statistiken** nach der Synchronisation
- 🎨 **Farbige Terminal-Ausgabe** für bessere Übersicht
- 📜 **Vollständiges Logging** aller Operationen
- ⚡ **Optimiert für Automatisierung** via Cron

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

## 🚀 Installation

### 1. Repository klonen
```bash
git clone https://github.com/sambila/paperless-sync.git
cd paperless-sync
```

### 2. Script ausführbar machen
```bash
chmod +x paperless-sync.sh
```

### 3. Pfade anpassen
Bearbeiten Sie die Pfade im Script entsprechend Ihrer Umgebung:
```bash
# In paperless-sync.sh anpassen:
SOURCE_DIR="/home/macos"  # Ihr Quellverzeichnis
DEST_DIR="/home/paper/docker/paperless-ngx/data/consume"  # Paperless Consume-Ordner
LOG_FILE="/var/log/paperless-sync.log"  # Log-Datei Pfad
```

## 💻 Verwendung

### Testlauf (empfohlen für den ersten Test)
```bash
./paperless-sync.sh --test
# oder
./paperless-sync.sh -t
```
Zeigt welche Dateien synchronisiert würden, ohne sie tatsächlich zu kopieren.

### Normale Synchronisation
```bash
./paperless-sync.sh
```

### Hilfe anzeigen
```bash
./paperless-sync.sh --help
# oder
./paperless-sync.sh -h
```

## ⚙️ Automatisierung mit Cron

### Crontab einrichten
```bash
# Crontab bearbeiten
crontab -e

# Beispiele:
# Alle 30 Minuten
*/30 * * * * /pfad/zu/paperless-sync.sh >> /var/log/paperless-sync-cron.log 2>&1

# Täglich um 2:00 Uhr
0 2 * * * /pfad/zu/paperless-sync.sh >> /var/log/paperless-sync-cron.log 2>&1

# Stündlich
0 * * * * /pfad/zu/paperless-sync.sh >> /var/log/paperless-sync-cron.log 2>&1
```

## 🔧 Konfiguration

### Tika deaktivieren
Falls Sie Tika nicht verwenden, kommentieren Sie die Office-Formate aus:
```bash
# In Zeile 91-94 des Scripts:
# for ext in "${OFFICE_FORMATS[@]}"; do
#     patterns="$patterns --include='*.$ext' --include='*.${ext^^}'"
# done
```

### Log-Rotation einrichten
```bash
# /etc/logrotate.d/paperless-sync erstellen:
/var/log/paperless-sync.log {
    daily
    rotate 7
    compress
    delaycompress
    missingok
    notifempty
}
```

## 📊 Ausgabe-Beispiel

```
==================================
Paperless Document Sync Script
==================================

Starte Synchronisation...
Unterstützte Basis-Formate:
pdf png jpg jpeg tiff tif gif webp txt 
Unterstützte Office-Formate (wenn Tika aktiviert):
doc docx xls xlsx ppt pptx odt ods odp eml msg rtf 

sending incremental file list
Dokumente/Rechnung_2024.pdf
Bilder/Scan_001.jpg
Briefe/Brief_Versicherung.docx

Synchronisation erfolgreich abgeschlossen!

=== Statistiken ===
  pdf: 15 Datei(en)
  jpg: 8 Datei(en)
  docx: 3 Datei(en)
Gesamt: 26 Datei(en) im Consume-Verzeichnis

Script beendet.
```

## 🛡️ Sicherheit

- ✅ Verwendet `rsync --checksum` für Datenintegrität
- ✅ Prüft Verzeichnisberechtigungen vor der Ausführung
- ✅ Detailliertes Logging aller Operationen
- ✅ Fehlerbehandlung mit aussagekräftigen Meldungen
- ✅ Keine Änderung der Originaldateien

## 🐛 Fehlerbehebung

### Keine Schreibrechte
```bash
# Berechtigungen für Consume-Verzeichnis prüfen
ls -la /home/paper/docker/paperless-ngx/data/consume/

# Ggf. Berechtigungen anpassen
sudo chown -R $USER:$USER /home/paper/docker/paperless-ngx/data/consume/
```

### rsync nicht installiert
```bash
# Debian/Ubuntu
sudo apt-get install rsync

# RHEL/CentOS
sudo yum install rsync

# macOS
brew install rsync
```

### Log-Datei nicht beschreibbar
```bash
# Log-Verzeichnis erstellen und Rechte setzen
sudo mkdir -p /var/log
sudo touch /var/log/paperless-sync.log
sudo chown $USER:$USER /var/log/paperless-sync.log
```

## 📝 Anforderungen

- **Bash** 4.0 oder höher
- **rsync** 3.0 oder höher
- **find** (Standard Unix-Tool)
- Schreibrechte für das Zielverzeichnis
- Optional: **Paperless-ngx mit Tika** für Office-Dokumente

## 🤝 Beitragen

Beiträge sind willkommen! Bitte erstellen Sie einen Pull Request oder öffnen Sie ein Issue für:
- Bug-Reports
- Feature-Anfragen
- Verbesserungsvorschläge
- Dokumentations-Updates

## 📄 Lizenz

Dieses Projekt ist unter der MIT-Lizenz lizenziert - siehe [LICENSE](LICENSE) Datei für Details.

## 🔗 Links

- [Paperless-ngx Dokumentation](https://docs.paperless-ngx.com/)
- [Paperless-ngx GitHub](https://github.com/paperless-ngx/paperless-ngx)
- [rsync Dokumentation](https://rsync.samba.org/documentation.html)

## 👤 Autor

Erstellt für die Paperless-ngx Community

## 🙏 Danksagung

- [Paperless-ngx Team](https://github.com/paperless-ngx) für das großartige Dokumenten-Management-System
- Allen Contributoren und Testern

---

**Hinweis:** Dieses Script ist ein Community-Beitrag und nicht offiziell vom Paperless-ngx Team unterstützt.
