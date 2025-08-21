#!/bin/bash

#################################################
# Paperless-ngx Remote Document Sync Script
# 
# Kopiert alle von Paperless unterstützten Dateien
# von einem macOS Client zu einem Remote Server
# via SSH/rsync für sichere und geprüfte Übertragung
# 
# WICHTIG: Alle Dateien werden flach ins Zielverzeichnis
# kopiert, da Paperless keine Unterordner verarbeiten kann!
#################################################

# Konfiguration
SOURCE_DIR="$HOME/Documents"  # Lokales Verzeichnis auf macOS (anpassen!)
REMOTE_HOST="10.10.1.1"
REMOTE_USER="paper"
REMOTE_DIR="/home/paper/docker/paperless-ngx/data/consume"
LOG_FILE="$HOME/Library/Logs/paperless-sync.log"
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')

# SSH Optionen
SSH_PORT="22"  # SSH Port (Standard: 22)
SSH_KEY=""     # Pfad zum SSH-Key (optional, z.B. "$HOME/.ssh/id_rsa")

# Farben für Terminal-Ausgabe
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
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
    
    # Erstelle Log-Verzeichnis falls nicht vorhanden (macOS spezifisch)
    if [ ! -d "$(dirname "$LOG_FILE")" ]; then
        mkdir -p "$(dirname "$LOG_FILE")"
    fi
}

# SSH Verbindung testen
test_ssh_connection() {
    echo -e "${BLUE}Teste SSH-Verbindung zu $REMOTE_USER@$REMOTE_HOST...${NC}"
    
    # Baue SSH Befehl
    SSH_CMD="ssh -p $SSH_PORT"
    if [ -n "$SSH_KEY" ]; then
        SSH_CMD="$SSH_CMD -i $SSH_KEY"
    fi
    
    # Teste Verbindung
    $SSH_CMD -o ConnectTimeout=5 -o BatchMode=yes "$REMOTE_USER@$REMOTE_HOST" "echo 'SSH OK'" > /dev/null 2>&1
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ SSH-Verbindung erfolgreich${NC}"
        return 0
    else
        echo -e "${RED}✗ SSH-Verbindung fehlgeschlagen!${NC}"
        echo -e "${YELLOW}Hinweise:${NC}"
        echo "  1. Prüfen Sie ob der Server erreichbar ist: ping $REMOTE_HOST"
        echo "  2. Prüfen Sie SSH-Zugang: ssh $REMOTE_USER@$REMOTE_HOST"
        echo "  3. Richten Sie ggf. SSH-Keys ein für passwortlosen Zugang:"
        echo "     ssh-keygen -t rsa"
        echo "     ssh-copy-id $REMOTE_USER@$REMOTE_HOST"
        return 1
    fi
}

check_directories() {
    # Prüfe ob lokales Quellverzeichnis existiert
    if [ ! -d "$SOURCE_DIR" ]; then
        echo -e "${RED}Fehler: Lokales Verzeichnis $SOURCE_DIR existiert nicht!${NC}"
        exit 1
    fi
    
    # Prüfe ob Remote-Verzeichnis existiert und erstelle es ggf.
    echo -e "${BLUE}Prüfe Remote-Verzeichnis...${NC}"
    
    SSH_CMD="ssh -p $SSH_PORT"
    if [ -n "$SSH_KEY" ]; then
        SSH_CMD="$SSH_CMD -i $SSH_KEY"
    fi
    
    # Prüfe und erstelle Remote-Verzeichnis
    $SSH_CMD "$REMOTE_USER@$REMOTE_HOST" "
        if [ ! -d '$REMOTE_DIR' ]; then
            echo 'Erstelle Remote-Verzeichnis...'
            mkdir -p '$REMOTE_DIR'
        fi
        
        if [ -w '$REMOTE_DIR' ]; then
            echo 'Remote-Verzeichnis bereit.'
            exit 0
        else
            echo 'FEHLER: Keine Schreibrechte für $REMOTE_DIR'
            exit 1
        fi
    "
    
    if [ $? -ne 0 ]; then
        echo -e "${RED}Fehler beim Zugriff auf Remote-Verzeichnis!${NC}"
        exit 1
    fi
}

# Hauptfunktion für Synchronisation
sync_documents() {
    echo -e "${GREEN}Starte Remote-Synchronisation...${NC}"
    log_message "Starte Synchronisation von $SOURCE_DIR nach $REMOTE_USER@$REMOTE_HOST:$REMOTE_DIR"
    
    # Zeige unterstützte Formate
    echo -e "${YELLOW}Unterstützte Basis-Formate:${NC}"
    printf '%s ' "${BASE_FORMATS[@]}"
    echo ""
    echo -e "${YELLOW}Unterstützte Office-Formate (wenn Tika aktiviert):${NC}"
    printf '%s ' "${OFFICE_FORMATS[@]}"
    echo -e "\n"
    
    echo -e "${YELLOW}WICHTIG: Alle Dateien werden flach kopiert (ohne Unterordner-Struktur)${NC}\n"
    
    # Baue SSH Befehl für rsync
    local SSH_CMD="ssh -p $SSH_PORT"
    if [ -n "$SSH_KEY" ]; then
        SSH_CMD="$SSH_CMD -i $SSH_KEY"
    fi
    
    echo -e "${BLUE}Synchronisiere Dateien...${NC}"
    
    # Zähler für Statistik - WICHTIG: Initialisierung!
    copied=0
    skipped=0
    failed=0
    
    # Erstelle temporäre Datei für Dateiliste
    TEMP_FILE_LIST=$(mktemp)
    
    # Finde alle relevanten Dateien
    cd "$SOURCE_DIR"
    
    # Baue find-Befehl für alle Formate
    echo "Suche Dateien..."
    for ext in "${BASE_FORMATS[@]}" "${OFFICE_FORMATS[@]}"; do
        # Suche case-insensitive
        find . -type f -iname "*.$ext" >> "$TEMP_FILE_LIST" 2>/dev/null
    done
    
    # Sortiere und entferne Duplikate
    sort -u "$TEMP_FILE_LIST" -o "$TEMP_FILE_LIST"
    
    # Zähle gefundene Dateien
    total_files=$(wc -l < "$TEMP_FILE_LIST")
    echo "Gefunden: $total_files Datei(en)"
    echo ""
    
    # Kopiere jede Datei einzeln (flach)
    while IFS= read -r file; do
        # Entferne führendes ./ und hole nur Dateinamen
        original_filename=$(basename "$file")
        # Entferne Leerzeichen und Sonderzeichen aus Dateinamen
        filename=$(echo "$original_filename" | tr ' ' '_' | tr -d '()[]{}$' | tr -s '_')
        
        # Zeige Fortschritt
        if [ "$original_filename" != "$filename" ]; then
            echo -n "  Kopiere: $original_filename → $filename ... "
        else
            echo -n "  Kopiere: $filename ... "
        fi
        
        # Kopiere Datei mit rsync
        rsync -av \
            -e "$SSH_CMD" \
            --checksum \
            "$file" \
            "$REMOTE_USER@$REMOTE_HOST:$REMOTE_DIR/$filename" > /dev/null 2>&1
        
        if [ $? -eq 0 ]; then
            echo -e "${GREEN}✓${NC}"
            ((copied++))
            log_message "Kopiert: $file → $REMOTE_DIR/$filename"
        else
            # Prüfe ob Datei bereits existiert
            $SSH_CMD "$REMOTE_USER@$REMOTE_HOST" "test -f \"$REMOTE_DIR/$filename\"" 2>/dev/null
            if [ $? -eq 0 ]; then
                echo -e "${YELLOW}⊘ (existiert bereits)${NC}"
                ((skipped++))
            else
                echo -e "${RED}✗${NC}"
                ((failed++))
                log_message "FEHLER beim Kopieren: $file"
            fi
        fi
    done < "$TEMP_FILE_LIST"
    
    # Aufräumen
    rm -f "$TEMP_FILE_LIST"
    
    # Zeige Zusammenfassung - NUR EINMAL!
    echo -e "\n${GREEN}=== Synchronisation abgeschlossen ===${NC}"
    echo -e "  ${GREEN}✓${NC} Kopiert: $copied Datei(en)"
    echo -e "  ${YELLOW}⊘${NC} Übersprungen: $skipped Datei(en)"
    
    # Prüfe ob failed größer als 0 ist
    if [ "$failed" -gt 0 ]; then
        echo -e "  ${RED}✗${NC} Fehler: $failed Datei(en)"
    fi
    
    log_message "Synchronisation abgeschlossen - Kopiert: $copied, Übersprungen: $skipped, Fehler: $failed"
}

# Zeige Statistiken
show_statistics() {
    echo -e "\n${GREEN}=== Remote Statistiken ===${NC}"
    
    # Konsistente SSH_CMD Definition
    local SSH_CMD="ssh -p $SSH_PORT"
    if [ -n "$SSH_KEY" ]; then
        SSH_CMD="$SSH_CMD -i $SSH_KEY"
    fi
    
    # Zähle Dateien auf dem Remote-Server
    $SSH_CMD "$REMOTE_USER@$REMOTE_HOST" "
        cd '$REMOTE_DIR' 2>/dev/null || exit 1
        total=0
        for ext in pdf png jpg jpeg tiff tif gif webp txt doc docx xls xlsx ppt pptx odt ods odp eml msg rtf; do
            count=\$(find . -maxdepth 1 -type f -iname \"*.\$ext\" 2>/dev/null | wc -l)
            if [ \$count -gt 0 ]; then
                echo \"  \$ext: \$count Datei(en)\"
                total=\$((total + count))
            fi
        done
        echo \"Gesamt: \$total Datei(en) im Remote Consume-Verzeichnis\"
    "
}

# Testmodus-Funktion
test_run() {
    echo -e "${YELLOW}=== TESTMODUS ===${NC}"
    echo "Dies ist ein Testlauf. Es werden keine Dateien kopiert."
    echo ""
    
    echo -e "${BLUE}Lokale Konfiguration:${NC}"
    echo "  Quelle: $SOURCE_DIR"
    echo "  Ziel: $REMOTE_USER@$REMOTE_HOST:$REMOTE_DIR"
    echo "  SSH-Port: $SSH_PORT"
    if [ -n "$SSH_KEY" ]; then
        echo "  SSH-Key: $SSH_KEY"
    fi
    echo ""
    
    # Teste SSH-Verbindung
    test_ssh_connection
    if [ $? -ne 0 ]; then
        exit 1
    fi
    
    echo -e "\n${YELLOW}Suche nach unterstützten Dateien...${NC}"
    local file_count=0
    
    for ext in "${BASE_FORMATS[@]}" "${OFFICE_FORMATS[@]}"; do
        count=$(find "$SOURCE_DIR" -type f -iname "*.$ext" 2>/dev/null | wc -l)
        if [ $count -gt 0 ]; then
            echo "  .$ext: $count Datei(en) gefunden"
            file_count=$((file_count + count))
        fi
    done
    
    echo -e "\n${GREEN}Gesamt: $file_count lokale Datei(en) würden synchronisiert werden${NC}"
    
    # Zeige ein paar Beispieldateien
    if [ $file_count -gt 0 ]; then
        echo -e "\n${BLUE}Beispiel-Dateien (max. 5):${NC}"
        local shown=0
        for ext in "${BASE_FORMATS[@]}" "${OFFICE_FORMATS[@]}"; do
            find "$SOURCE_DIR" -type f -iname "*.$ext" -print 2>/dev/null | head -5 | while IFS= read -r file; do
                if [ $shown -lt 5 ]; then
                    basename=$(basename "$file")
                    cleaned=$(echo "$basename" | tr ' ' '_' | tr -d '()[]{}$' | tr -s '_')
                    if [ "$basename" != "$cleaned" ]; then
                        echo "  - $basename → $cleaned"
                    else
                        echo "  - $basename"
                    fi
                    shown=$((shown + 1))
                fi
            done
        done
    fi
    
    echo -e "\nFühren Sie das Script ohne --test aus, um die Synchronisation durchzuführen."
}

# Setup SSH-Keys
setup_ssh_keys() {
    echo -e "${BLUE}=== SSH-Key Setup ===${NC}"
    echo "Dieser Assistent hilft Ihnen, SSH-Keys für passwortlosen Zugang einzurichten."
    echo ""
    
    # Prüfe ob SSH-Key existiert
    if [ ! -f "$HOME/.ssh/id_rsa" ]; then
        echo "Erstelle neuen SSH-Key..."
        ssh-keygen -t rsa -b 4096 -f "$HOME/.ssh/id_rsa" -N ""
    else
        echo "SSH-Key existiert bereits: $HOME/.ssh/id_rsa"
    fi
    
    echo ""
    echo "Kopiere SSH-Key zum Server..."
    echo "Sie werden nach dem Passwort für $REMOTE_USER@$REMOTE_HOST gefragt:"
    
    ssh-copy-id -p "$SSH_PORT" "$REMOTE_USER@$REMOTE_HOST"
    
    if [ $? -eq 0 ]; then
        echo -e "\n${GREEN}✓ SSH-Key erfolgreich eingerichtet!${NC}"
        echo "Sie können nun ohne Passwort synchronisieren."
    else
        echo -e "\n${RED}✗ Fehler beim Einrichten des SSH-Keys${NC}"
    fi
}

# Hauptprogramm
main() {
    echo -e "${GREEN}======================================${NC}"
    echo -e "${GREEN}Paperless Remote Document Sync Script${NC}"
    echo -e "${GREEN}         macOS → Remote Server        ${NC}"
    echo -e "${GREEN}======================================${NC}\n"
    
    # Prüfe ob rsync installiert ist (macOS hat es normalerweise)
    if ! command -v rsync &> /dev/null; then
        echo -e "${RED}rsync ist nicht installiert!${NC}"
        echo "Installation mit Homebrew: brew install rsync"
        exit 1
    fi
    
    # Parse Parameter
    case "$1" in
        --test|-t)
            test_run
            exit 0
            ;;
        --setup-ssh)
            setup_ssh_keys
            exit 0
            ;;
        --help|-h)
            echo "Verwendung: $0 [OPTIONEN]"
            echo ""
            echo "Optionen:"
            echo "  -t, --test       Führt einen Testlauf durch"
            echo "  --setup-ssh      Richtet SSH-Keys für passwortlosen Zugang ein"
            echo "  -h, --help       Zeigt diese Hilfe"
            echo ""
            echo "Konfiguration:"
            echo "  Bearbeiten Sie das Script und passen Sie folgende Variablen an:"
            echo "  - SOURCE_DIR: Lokales Verzeichnis mit Dokumenten"
            echo "  - REMOTE_HOST: IP oder Hostname des Servers"
            echo "  - REMOTE_USER: Benutzername auf dem Server"
            echo "  - REMOTE_DIR: Paperless Consume-Verzeichnis"
            echo "  - SSH_PORT: SSH-Port (Standard: 22)"
            echo "  - SSH_KEY: Pfad zum SSH-Key (optional)"
            echo ""
            echo "Erste Schritte:"
            echo "  1. Script anpassen (Variablen oben)"
            echo "  2. $0 --setup-ssh (für passwortlosen Zugang)"
            echo "  3. $0 --test (Testlauf)"
            echo "  4. $0 (Synchronisation)"
            exit 0
            ;;
    esac
    
    # Führe Synchronisation durch
    test_ssh_connection || exit 1
    check_directories
    sync_documents
    show_statistics
    
    echo -e "\n${GREEN}Script beendet.${NC}"
}

# Script starten
main "$@"
