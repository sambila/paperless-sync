#!/bin/bash

#################################################
# Paperless-ngx Document Sync Script
# 
# Kopiert alle von Paperless unterstützten Dateien
# von /home/macos (inkl. Unterordner) nach
# /home/paper/docker/paperless-ngx/data/consume/
# mit rsync für sichere und geprüfte Übertragung
# 
# WICHTIG: Alle Dateien werden flach ins Zielverzeichnis
# kopiert, da Paperless keine Unterordner verarbeiten kann!
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

# Funktion zum Kopieren mit Konfliktbehandlung
copy_with_conflict_handling() {
    local src_file="$1"
    local filename=$(basename "$src_file")
    local dest_file="$DEST_DIR/$filename"
    local base_name="${filename%.*}"
    local extension="${filename##*.}"
    local counter=1
    
    # Falls Datei bereits existiert, füge Nummer hinzu
    while [ -f "$dest_file" ]; do
        # Prüfe ob die Dateien identisch sind (gleiche Checksumme)
        if [ -f "$dest_file" ]; then
            src_checksum=$(md5sum "$src_file" | cut -d' ' -f1)
            dest_checksum=$(md5sum "$dest_file" | cut -d' ' -f1)
            
            if [ "$src_checksum" = "$dest_checksum" ]; then
                echo "  Überspringe: $filename (identische Datei existiert bereits)"
                return 0
            fi
        fi
        
        # Erstelle neuen Dateinamen mit Zähler
        if [ "$base_name" = "$filename" ]; then
            # Datei hat keine Erweiterung
            dest_file="$DEST_DIR/${filename}_${counter}"
        else
            dest_file="$DEST_DIR/${base_name}_${counter}.${extension}"
        fi
        counter=$((counter + 1))
    done
    
    # Kopiere Datei
    cp -p "$src_file" "$dest_file"
    if [ $? -eq 0 ]; then
        echo -e "  ${GREEN}✓${NC} Kopiert: $(basename "$src_file") → $(basename "$dest_file")"
        log_message "Kopiert: $src_file → $dest_file"
        return 0
    else
        echo -e "  ${RED}✗${NC} Fehler beim Kopieren: $filename"
        log_message "FEHLER beim Kopieren: $src_file"
        return 1
    fi
}

# Hauptfunktion für Synchronisation
sync_documents() {
    echo -e "${GREEN}Starte Synchronisation...${NC}"
    log_message "Starte Synchronisation von $SOURCE_DIR nach $DEST_DIR"
    
    # Zeige unterstützte Formate
    echo -e "${YELLOW}Unterstützte Basis-Formate:${NC}"
    printf '%s ' "${BASE_FORMATS[@]}"
    echo ""
    echo -e "${YELLOW}Unterstützte Office-Formate (wenn Tika aktiviert):${NC}"
    printf '%s ' "${OFFICE_FORMATS[@]}"
    echo -e "\n"
    
    echo -e "${YELLOW}WICHTIG: Alle Dateien werden flach kopiert (ohne Unterordner-Struktur)${NC}\n"
    
    # Zähler für Statistik
    local copied_count=0
    local skipped_count=0
    local error_count=0
    
    # Erstelle Liste aller unterstützten Erweiterungen
    local all_formats=("${BASE_FORMATS[@]}" "${OFFICE_FORMATS[@]}")
    
    # Durchsuche alle Dateien im Quellverzeichnis
    for ext in "${all_formats[@]}"; do
        echo -e "\n${YELLOW}Verarbeite .$ext Dateien...${NC}"
        
        # Finde alle Dateien mit dieser Erweiterung (case-insensitive)
        while IFS= read -r -d '' file; do
            copy_with_conflict_handling "$file"
            case $? in
                0)
                    if [[ $(basename "$file") == *"identische Datei"* ]]; then
                        ((skipped_count++))
                    else
                        ((copied_count++))
                    fi
                    ;;
                1)
                    ((error_count++))
                    ;;
            esac
        done < <(find "$SOURCE_DIR" -type f \( -iname "*.$ext" \) -print0 2>/dev/null)
    done
    
    # Zeige Zusammenfassung
    echo -e "\n${GREEN}=== Synchronisation abgeschlossen ===${NC}"
    echo -e "  ${GREEN}✓${NC} Kopiert: $copied_count Datei(en)"
    echo -e "  ${YELLOW}⊘${NC} Übersprungen: $skipped_count Datei(en) (bereits vorhanden)"
    if [ $error_count -gt 0 ]; then
        echo -e "  ${RED}✗${NC} Fehler: $error_count Datei(en)"
    fi
    
    log_message "Synchronisation abgeschlossen - Kopiert: $copied_count, Übersprungen: $skipped_count, Fehler: $error_count"
}

# Zeige Statistiken
show_statistics() {
    echo -e "\n${GREEN}=== Statistiken ===${NC}"
    
    # Zähle Dateien im Zielverzeichnis
    local total_files=0
    for ext in "${BASE_FORMATS[@]}" "${OFFICE_FORMATS[@]}"; do
        count=$(find "$DEST_DIR" -maxdepth 1 -type f \( -iname "*.$ext" \) 2>/dev/null | wc -l)
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
    
    echo -e "${YELLOW}WICHTIG: Alle Dateien werden flach kopiert (ohne Unterordner-Struktur)${NC}\n"
    
    echo "Suche nach unterstützten Dateien in $SOURCE_DIR..."
    local file_count=0
    local duplicate_warning=false
    
    # Temporäres Array für Dateinamen zur Duplikat-Prüfung
    declare -A filenames
    
    for ext in "${BASE_FORMATS[@]}" "${OFFICE_FORMATS[@]}"; do
        while IFS= read -r -d '' file; do
            basename_file=$(basename "$file")
            if [ -n "${filenames[$basename_file]}" ]; then
                if [ "$duplicate_warning" = false ]; then
                    echo -e "\n${YELLOW}WARNUNG: Namenskonflikte erkannt!${NC}"
                    echo "Folgende Dateien haben identische Namen (aus verschiedenen Ordnern):"
                    duplicate_warning=true
                fi
                echo -e "  ${YELLOW}!${NC} $basename_file"
                echo "    - ${filenames[$basename_file]}"
                echo "    - $file"
            else
                filenames[$basename_file]="$file"
            fi
            ((file_count++))
        done < <(find "$SOURCE_DIR" -type f \( -iname "*.$ext" \) -print0 2>/dev/null)
    done
    
    echo -e "\n${GREEN}Gesamt: $file_count Datei(en) würden synchronisiert werden${NC}"
    
    if [ "$duplicate_warning" = true ]; then
        echo -e "\n${YELLOW}Hinweis: Bei Namenskonflikten werden Dateien automatisch nummeriert (_1, _2, etc.)${NC}"
    fi
    
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
        echo ""
        echo "WICHTIG: Alle Dateien werden flach ins Zielverzeichnis kopiert,"
        echo "         da Paperless keine Unterordner verarbeiten kann!"
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
