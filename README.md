# Paperless-ngx Document Sync Script

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Paperless-ngx](https://img.shields.io/badge/Paperless--ngx-Compatible-green.svg)](https://github.com/paperless-ngx/paperless-ngx)
[![Shell Script](https://img.shields.io/badge/Shell-Bash-blue.svg)](https://www.gnu.org/software/bash/)

Ein robustes Bash-Script zur automatischen Synchronisation von Dokumenten für [Paperless-ngx](https://github.com/paperless-ngx/paperless-ngx). Das Script kopiert alle unterstützten Dateiformate aus einem Quellverzeichnis (inklusive aller Unterordner) **flach** in das Paperless-Consume-Verzeichnis.

## ⚠️ Wichtiger Hinweis

**Paperless-ngx kann keine Unterordner im Consume-Verzeichnis verarbeiten!** Daher kopiert dieses Script alle Dateien flach in das Hauptverzeichnis. Bei Dateinamen-Konflikten werden Dateien automatisch nummeriert (_1, _2, etc.).

## 🎯 Features

- ✅ **Flache Kopie** aller Dateien ohne Unterordner-Struktur (Paperless-Anforderung)
- 🔄 **Intelligente Konfliktbehandlung** bei doppelten Dateinamen
- 🔍 **Checksummen-Vergleich** überspringt identische Dateien
- 📁 **Rekursive Suche** in allen Unterordnern der Quelle
- 📝 **Umfassende Formatunterstützung** für alle Paperless-kompatiblen Dateitypen
- 🧪 **Testmodus** mit Duplikat-Warnung
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
SOURCE_DIR="/home/macos"  # Ihr Quellverzeichnis (mit Unterordnern)
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
Zeigt welche Dateien kopiert würden und warnt vor Dateinamen-Konflikten.

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

## 🔄 Funktionsweise

1. **Durchsucht** rekursiv alle Unterordner im Quellverzeichnis
2. **Findet** alle Dateien mit unterstützten Erweiterungen
3. **Kopiert** diese flach ins Zielverzeichnis
4. **Behandelt Konflikte:**
   - Vergleicht Checksummen bei gleichen Dateinamen
   - Überspringt identische Dateien
   - Nummeriert unterschiedliche Dateien mit gleichem Namen (_1, _2, etc.)
5. **Protokolliert** alle Aktionen

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
Falls Sie Tika nicht verwenden, kommentieren Sie die Office-Formate im Script aus (Zeilen 42-54).

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

WICHTIG: Alle Dateien werden flach kopiert (ohne Unterordner-Struktur)

Verarbeite .pdf Dateien...
  ✓ Kopiert: Rechnung_2024.pdf → Rechnung_2024.pdf
  ✓ Kopiert: Rechnung_2024.pdf → Rechnung_2024_1.pdf
  Überspringe: Brief.pdf (identische Datei existiert bereits)

=== Synchronisation abgeschlossen ===
  ✓ Kopiert: 15 Datei(en)
  ⊘ Übersprungen: 3 Datei(en) (bereits vorhanden)

=== Statistiken ===
  pdf: 18 Datei(en)
  jpg: 8 Datei(en)
  docx: 3 Datei(en)
Gesamt: 29 Datei(en) im Consume-Verzeichnis

Script beendet.
```

## 🛡️ Sicherheit

- ✅ MD5-Checksummen-Vergleich zur Duplikat-Erkennung
- ✅ Automatische Konfliktbehandlung bei gleichen Dateinamen
- ✅ Prüft Verzeichnisberechtigungen vor der Ausführung
- ✅ Detailliertes Logging aller Operationen
- ✅ Keine Änderung der Originaldateien
- ✅ Sichere Dateinamen-Behandlung mit Null-Byte-Separation

## 🐛 Fehlerbehebung

### Keine Schreibrechte
```bash
# Berechtigungen für Consume-Verzeichnis prüfen
ls -la /home/paper/docker/paperless-ngx/data/consume/

# Ggf. Berechtigungen anpassen
sudo chown -R $USER:$USER /home/paper/docker/paperless-ngx/data/consume/
```

### Log-Datei nicht beschreibbar
```bash
# Log-Verzeichnis erstellen und Rechte setzen
sudo mkdir -p /var/log
sudo touch /var/log/paperless-sync.log
sudo chown $USER:$USER /var/log/paperless-sync.log
```

### Viele Namenskonflikte
Wenn Sie viele Dateien mit gleichen Namen aus verschiedenen Ordnern haben, erwägen Sie:
- Dateien vor dem Sync umzubenennen
- Ein Naming-Schema mit Ordnernamen im Dateinamen zu verwenden

## 📝 Anforderungen

- **Bash** 4.0 oder höher
- **find** (Standard Unix-Tool)
- **cp** (Standard Unix-Tool) 
- **md5sum** (Standard Unix-Tool)
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

## 👤 Autor

Erstellt für die Paperless-ngx Community

## 🙏 Danksagung

- [Paperless-ngx Team](https://github.com/paperless-ngx) für das großartige Dokumenten-Management-System
- Allen Contributoren und Testern

---

**Hinweis:** Dieses Script ist ein Community-Beitrag und nicht offiziell vom Paperless-ngx Team unterstützt.
