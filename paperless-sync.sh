#!/bin/bash

#################################################
# Paperless-ngx Document Sync Script
# 
# Kopiert alle von Paperless unterstützten Dateien
# von /home/macos (inkl. Unterordner) nach
# /home/paper/docker/paperless-ngx/data/consume/
# mit rsync für sichere und geprüfte Übertragung
#################################################

# Konfiguration
SOURCE_DIR="/home/macos"
DEST_DIR="/home/paper/docker/paperless-ngx/data/consume"
LOG_FILE="/var/log/paperless-sync.log"
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')

# Farben für Terminal-Ausgabe
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Unterstützte Dateiformate
# Basis-Formate (immer unterstützt)
BASE_FORMATS=(
    "pdf"    # PDF-Dokumente
    "png"    # PNG-Bilder
    "jpg"    # JPEG-Bilder
    "jpeg"   # JPEG-Bilder (alternative Endung)
    "tiff"   # TIFF-Bilder
    "tif"    # TIFF-Bilder (alternative Endung)
    "gif"    # GIF-Bilder
    "webp"   # WebP-Bilder
    "txt"    # Textdateien
)

# Office-Formate (wenn Tika aktiviert ist)
OFFICE_FORMATS=(
    "doc"    # Word-Dokumente (alt)
    "docx"   # Word-Dokumente
    "xls"    # Excel-Tabellen (alt)
    "xlsx"   # Excel-Tabellen
    "ppt"    # PowerPoint (alt)
    "pptx"   # PowerPoint
    "odt"    # LibreOffice Writer
    "ods"    # LibreOffice Calc
    "odp"    # LibreOffice Impress
    "eml"    # E-Mail-Dateien
    "msg"    # Outlook-Nachrichten
    "rtf"    # Rich Text Format
)

# Funktionen
log_message() {
    echo "[$TIMESTAMP] $1" | tee -a "$LOG_FILE"
}

check_directories() {
    # Prüfe ob Quellverzeichnis existiert
    if [ ! -d "$SOURCE_DIR" ]; then
        echo -e "${RED}Fehler: Quellverzeichnis $SOURCE_DIR existiert nicht!${NC}"
        exit 1
    fi
    
    # Prüfe ob Zielverzeichnis existiert, erstelle es falls nötig
    if [ ! -d "$DEST_DIR" ]; then
        echo -e "${YELLOW}Zielverzeichnis $DEST_DIR existiert nicht. Erstelle es...${NC}"
        mkdir -p "$DEST_DIR"
        if [ $? -ne 0 ]; then
            echo -e "${RED}Fehler: Konnte Zielverzeichnis nicht erstellen!${NC}"
            exit 1
        fi
    fi
    
    # Prüfe Schreibrechte für Zielverzeichnis
    if [ ! -w "$DEST_DIR" ]; then
        echo -e "${RED}Fehler: Keine Schreibrechte für $DEST_DIR!${NC}"
        exit 1
    fi
}

# Erstelle rsync Include-Pattern
create_include_patterns() {
    local patterns=""
    
    # Füge Basis-Formate hinzu
    for ext in "${BASE_FORMATS[@]}"; do
        patterns="$patterns --include='*.$ext' --include='*.${ext^^}'"
    done
    
    # Optional: Füge Office-Formate hinzu wenn Tika verfügbar ist
    # (Kommentieren Sie die nächsten Zeilen aus, wenn Sie Tika nicht verwenden)
    for ext in "${OFFICE_FORMATS[@]}"; do
        patterns="$patterns --include='*.$ext' --include='*.${ext^^}'"
    done
    
    echo "$patterns"
}

# Hauptfunktion für rsync
sync_documents() {
    local include_patterns=$(create_include_patterns)
    
    echo -e "${GREEN}Starte Synchronisation...${NC}"
    log_message "Starte Synchronisation von $SOURCE_DIR nach $DEST_DIR"
    
    # Zeige unterstützte Formate
    echo -e "${YELLOW}Unterstützte Basis-Formate:${NC}"
    printf '%s ' "${BASE_FORMATS[@]}"
    echo ""
    echo -e "${YELLOW}Unterstützte Office-Formate (wenn Tika aktiviert):${NC}"
    printf '%s ' "${OFFICE_FORMATS[@]}"
    echo -e "\n"
    
    # Führe rsync aus
    # -a: Archiv-Modus (erhält Berechtigungen, Zeitstempel etc.)
    # -v: Verbose (zeigt kopierte Dateien)
    # --progress: Zeigt Fortschritt
    # --checksum: Prüft Dateien via Checksumme statt nur Größe/Zeit
    # --dry-run: Testlauf (entfernen für echte Synchronisation)
    
    # Erstelle temporäre Include-Datei für bessere Übersicht
    INCLUDE_FILE=$(mktemp)
    
    # Schreibe alle Include-Patterns in die Datei
    for ext in "${BASE_FORMATS[@]}" "${OFFICE_FORMATS[@]}"; do
        echo "*.$ext" >> "$INCLUDE_FILE"
        echo "*.${ext^^}" >> "$INCLUDE_FILE"
    done
    
    # rsync Befehl mit allen Optionen
    rsync -av \
        --progress \
        --checksum \
        --include-from="$INCLUDE_FILE" \
        --include='*/' \
        --exclude='*' \
        --log-file="$LOG_FILE" \
        "$SOURCE_DIR/" \
        "$DEST_DIR/"
    
    RSYNC_STATUS=$?
    
    # Aufräumen
    rm -f "$INCLUDE_FILE"
    
    # Prüfe rsync Status
    if [ $RSYNC_STATUS -eq 0 ]; then
        echo -e "${GREEN}Synchronisation erfolgreich abgeschlossen!${NC}"
        log_message "Synchronisation erfolgreich abgeschlossen"
    elif [ $RSYNC_STATUS -eq 23 ]; then
        echo -e "${YELLOW}Synchronisation abgeschlossen mit Warnungen (einige Dateien konnten nicht übertragen werden)${NC}"
        log_message "Synchronisation mit Warnungen abgeschlossen (Code: $RSYNC_STATUS)"
    else
        echo -e "${RED}Fehler bei der Synchronisation! (Code: $RSYNC_STATUS)${NC}"
        log_message "Fehler bei der Synchronisation (Code: $RSYNC_STATUS)"
        exit $RSYNC_STATUS
    fi
}

# Zeige Statistiken
show_statistics() {
    echo -e "\n${GREEN}=== Statistiken ===${NC}"
    
    # Zähle Dateien im Zielverzeichnis
    local total_files=0
    for ext in "${BASE_FORMATS[@]}" "${OFFICE_FORMATS[@]}"; do
        count=$(find "$DEST_DIR" -type f \( -iname "*.$ext" \) 2>/dev/null | wc -l)
        if [ $count -gt 0 ]; then
            echo "  $ext: $count Datei(en)"
            total_files=$((total_files + count))
        fi
    done
    
    echo -e "${GREEN}Gesamt: $total_files Datei(en) im Consume-Verzeichnis${NC}"
}

# Testmodus-Funktion
test_run() {
    echo -e "${YELLOW}=== TESTMODUS ===${NC}"
    echo "Dies ist ein Testlauf. Es werden keine Dateien kopiert."
    echo ""
    
    echo "Suche nach unterstützten Dateien in $SOURCE_DIR..."
    local file_count=0
    
    for ext in "${BASE_FORMATS[@]}" "${OFFICE_FORMATS[@]}"; do
        count=$(find "$SOURCE_DIR" -type f \( -iname "*.$ext" \) 2>/dev/null | wc -l)
        if [ $count -gt 0 ]; then
            echo "  .$ext: $count Datei(en) gefunden"
            file_count=$((file_count + count))
        fi
    done
    
    echo -e "\n${GREEN}Gesamt: $file_count Datei(en) würden synchronisiert werden${NC}"
    echo -e "\nFühren Sie das Script ohne --test aus, um die Synchronisation durchzuführen."
}

# Hauptprogramm
main() {
    echo -e "${GREEN}==================================${NC}"
    echo -e "${GREEN}Paperless Document Sync Script${NC}"
    echo -e "${GREEN}==================================${NC}\n"
    
    # Prüfe ob Script als root läuft (optional, kann entfernt werden)
    if [ "$EUID" -eq 0 ]; then 
        echo -e "${YELLOW}Warnung: Script läuft als root!${NC}\n"
    fi
    
    # Prüfe auf Test-Parameter
    if [ "$1" == "--test" ] || [ "$1" == "-t" ]; then
        check_directories
        test_run
        exit 0
    fi
    
    # Prüfe auf Hilfe-Parameter
    if [ "$1" == "--help" ] || [ "$1" == "-h" ]; then
        echo "Verwendung: $0 [OPTIONEN]"
        echo ""
        echo "Optionen:"
        echo "  -t, --test    Führt einen Testlauf durch (zeigt nur, was kopiert würde)"
        echo "  -h, --help    Zeigt diese Hilfe"
        echo ""
        echo "Ohne Optionen wird die Synchronisation durchgeführt."
        exit 0
    fi
    
    # Führe Synchronisation durch
    check_directories
    sync_documents
    show_statistics
    
    echo -e "\n${GREEN}Script beendet.${NC}"
}

# Script starten
main "$@"
