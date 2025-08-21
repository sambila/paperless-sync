{
  `path`: `/Users/ms/paperless-remote-sync.sh`,
  `content`: `#!/bin/bash

#################################################
# Paperless-ngx Remote Sync Script für macOS
# Version: 2.0 - Komplett überarbeitet
#################################################

# ============= KONFIGURATION =============
# BITTE DIESE WERTE ANPASSEN:

SOURCE_DIR=\"$HOME/Documents\"                              # Lokaler Ordner auf Mac
REMOTE_HOST=\"10.10.1.1\"                                  # Server IP
REMOTE_USER=\"paper\"                                       # SSH Benutzer
REMOTE_DIR=\"/home/paper/docker/paperless-ngx/data/consume\" # Ziel auf Server
SSH_PORT=\"22\"                                             # SSH Port
LOG_FILE=\"$HOME/paperless-sync.log\"                      # Log-Datei

# ============= DATEIFORMATE =============

# Basis-Formate (immer von Paperless unterstützt)
BASE_FORMATS=\"pdf png jpg jpeg tiff tif gif webp txt\"

# Office-Formate (wenn Tika aktiviert)  
OFFICE_FORMATS=\"doc docx xls xlsx ppt pptx odt ods odp eml msg rtf\"

# Alle Formate kombiniert
ALL_FORMATS=\"$BASE_FORMATS $OFFICE_FORMATS\"

# ============= FARBEN =============

RED='\\033[0;31m'
GREEN='\\033[0;32m'
YELLOW='\\033[1;33m'
BLUE='\\033[0;34m'
NC='\\033[0m'

# ============= FUNKTIONEN =============

# Logging
log_message() {
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo \"[$timestamp] $1\" >> \"$LOG_FILE\"
    echo \"$1\"
}

# Banner anzeigen
show_banner() {
    echo -e \"${GREEN}=====================================${NC}\"
    echo -e \"${GREEN}  Paperless Remote Sync für macOS   ${NC}\"
    echo -e \"${GREEN}=====================================${NC}\"
    echo \"\"
}

# SSH-Verbindung testen
test_ssh() {
    echo -e \"${BLUE}Teste SSH-Verbindung...${NC}\"
    
    if ssh -p \"$SSH_PORT\" -o ConnectTimeout=5 -o BatchMode=yes \\
        \"$REMOTE_USER@$REMOTE_HOST\" \"echo OK\" &>/dev/null; then
        echo -e \"${GREEN}✓ SSH-Verbindung erfolgreich${NC}\"
        return 0
    else
        echo -e \"${RED}✗ SSH-Verbindung fehlgeschlagen${NC}\"
        echo \"\"
        echo \"Tipps:\"
        echo \"1. Prüfen: ssh $REMOTE_USER@$REMOTE_HOST\"
        echo \"2. SSH-Key einrichten: ssh-copy-id $REMOTE_USER@$REMOTE_HOST\"
        return 1
    fi
}

# Remote-Verzeichnis prüfen/erstellen
check_remote_dir() {
    echo -e \"${BLUE}Prüfe Remote-Verzeichnis...${NC}\"
    
    ssh -p \"$SSH_PORT\" \"$REMOTE_USER@$REMOTE_HOST\" \\
        \"mkdir -p '$REMOTE_DIR' 2>/dev/null; test -w '$REMOTE_DIR'\" &>/dev/null
    
    if [ $? -eq 0 ]; then
        echo -e \"${GREEN}✓ Remote-Verzeichnis bereit${NC}\"
        return 0
    else
        echo -e \"${RED}✗ Problem mit Remote-Verzeichnis${NC}\"
        return 1
    fi
}

# Lokales Verzeichnis prüfen
check_local_dir() {
    if [ ! -d \"$SOURCE_DIR\" ]; then
        echo -e \"${RED}✗ Lokales Verzeichnis existiert nicht: $SOURCE_DIR${NC}\"
        return 1
    fi
    echo -e \"${GREEN}✓ Lokales Verzeichnis gefunden${NC}\"
    return 0
}

# Dateinamen bereinigen (Sonderzeichen entfernen)
clean_filename() {
    local filename=\"$1\"
    # Ersetze Leerzeichen und Sonderzeichen
    echo \"$filename\" | sed 's/[[:space:]]/_/g' | sed 's/[^a-zA-Z0-9._-]/_/g' | sed 's/__*/_/g'
}

# Hauptsynchronisation
sync_files() {
    echo \"\"
    echo -e \"${GREEN}Starte Synchronisation...${NC}\"
    echo \"Von: $SOURCE_DIR\"
    echo \"Nach: $REMOTE_USER@$REMOTE_HOST:$REMOTE_DIR\"
    echo \"\"
    
    # Zähler initialisieren
    local total=0
    local copied=0
    local skipped=0
    local failed=0
    
    # Temporäre Dateiliste
    local tmpfile=$(mktemp)
    
    # Finde alle relevanten Dateien (MIT Unterordnern)
    echo \"Suche Dateien...\"
    
    for ext in $ALL_FORMATS; do
        find \"$SOURCE_DIR\" -type f -iname \"*.$ext\" 2>/dev/null >> \"$tmpfile\"
    done
    
    # Sortieren und Duplikate entfernen
    sort -u \"$tmpfile\" -o \"$tmpfile\"
    
    # Anzahl gefundener Dateien
    total=$(wc -l < \"$tmpfile\")
    
    if [ \"$total\" -eq 0 ]; then
        echo -e \"${YELLOW}Keine unterstützten Dateien gefunden${NC}\"
        rm \"$tmpfile\"
        return 0
    fi
    
    echo \"Gefunden: $total Datei(en)\"
    echo \"\"
    echo \"Kopiere Dateien (flach, ohne Unterordner)...\"
    echo \"\"
    
    # Jede Datei einzeln kopieren
    while IFS= read -r filepath; do
        if [ -z \"$filepath\" ]; then
            continue
        fi
        
        # Original Dateiname
        local original=$(basename \"$filepath\")
        
        # Bereinigter Dateiname
        local cleaned=$(clean_filename \"$original\")
        
        # Fortschritt anzeigen
        printf \"  %-50s ... \" \"$original\"
        
        # Datei mit rsync kopieren
        rsync -az \\
            -e \"ssh -p $SSH_PORT\" \\
            \"$filepath\" \\
            \"$REMOTE_USER@$REMOTE_HOST:$REMOTE_DIR/$cleaned\" 2>/dev/null
        
        local result=$?
        
        if [ $result -eq 0 ]; then
            echo -e \"${GREEN}✓${NC}\"
            ((copied++))
            log_message \"OK: $filepath -> $cleaned\"
        else
            # Prüfe ob Datei schon existiert
            ssh -p \"$SSH_PORT\" \"$REMOTE_USER@$REMOTE_HOST\" \\
                \"test -f '$REMOTE_DIR/$cleaned'\" 2>/dev/null
            
            if [ $? -eq 0 ]; then
                echo -e \"${YELLOW}⊘ existiert${NC}\"
                ((skipped++))
                log_message \"SKIP: $filepath (existiert bereits)\"
            else
                echo -e \"${RED}✗ Fehler${NC}\"
                ((failed++))
                log_message \"FEHLER: $filepath\"
            fi
        fi
    done < \"$tmpfile\"
    
    # Aufräumen
    rm \"$tmpfile\"
    
    # Zusammenfassung
    echo \"\"
    echo -e \"${GREEN}=== Zusammenfassung ===${NC}\"
    echo \"  Gesamt:       $total Datei(en)\"
    echo -e \"  ${GREEN}Kopiert:${NC}      $copied\"
    echo -e \"  ${YELLOW}Übersprungen:${NC} $skipped\"
    if [ $failed -gt 0 ]; then
        echo -e \"  ${RED}Fehler:${NC}       $failed\"
    fi
    
    log_message \"Sync abgeschlossen: Kopiert=$copied, Übersprungen=$skipped, Fehler=$failed\"
}

# Testmodus
test_mode() {
    echo -e \"${YELLOW}=== TESTMODUS ===${NC}\"
    echo \"\"
    echo \"Konfiguration:\"
    echo \"  Quelle:  $SOURCE_DIR\"
    echo \"  Ziel:    $REMOTE_USER@$REMOTE_HOST:$REMOTE_DIR\"
    echo \"  Port:    $SSH_PORT\"
    echo \"\"
    
    # SSH testen
    test_ssh || return 1
    
    # Verzeichnisse prüfen
    check_local_dir || return 1
    check_remote_dir || return 1
    
    echo \"\"
    echo \"Suche Dateien...\"
    
    local count=0
    for ext in $ALL_FORMATS; do
        local found=$(find \"$SOURCE_DIR\" -type f -iname \"*.$ext\" 2>/dev/null | wc -l)
        if [ $found -gt 0 ]; then
            printf \"  %-10s %d Datei(en)\
\" \".$ext:\" \"$found\"
            ((count += found))
        fi
    done
    
    echo \"\"
    echo -e \"${GREEN}Gesamt: $count Datei(en) würden synchronisiert${NC}\"
    
    if [ $count -gt 0 ]; then
        echo \"\"
        echo \"Beispiele (max. 5):\"
        local i=0
        for ext in $ALL_FORMATS; do
            find \"$SOURCE_DIR\" -type f -iname \"*.$ext\" 2>/dev/null | while read -r file; do
                if [ $i -lt 5 ]; then
                    local orig=$(basename \"$file\")
                    local clean=$(clean_filename \"$orig\")
                    if [ \"$orig\" != \"$clean\" ]; then
                        echo \"  $orig → $clean\"
                    else
                        echo \"  $orig\"
                    fi
                    ((i++))
                fi
            done
        done
    fi
}

# SSH-Key Setup
setup_ssh() {
    echo -e \"${BLUE}=== SSH-Key Setup ===${NC}\"
    echo \"\"
    
    # Prüfe ob Key existiert
    if [ ! -f \"$HOME/.ssh/id_rsa\" ]; then
        echo \"Erstelle SSH-Key...\"
        ssh-keygen -t rsa -b 4096 -f \"$HOME/.ssh/id_rsa\" -N \"\"
    else
        echo \"SSH-Key existiert bereits\"
    fi
    
    echo \"\"
    echo \"Kopiere Key zum Server...\"
    echo \"Passwort für $REMOTE_USER@$REMOTE_HOST wird benötigt:\"
    
    ssh-copy-id -p \"$SSH_PORT\" \"$REMOTE_USER@$REMOTE_HOST\"
    
    if [ $? -eq 0 ]; then
        echo -e \"${GREEN}✓ SSH-Key eingerichtet${NC}\"
    else
        echo -e \"${RED}✗ Fehler beim Setup${NC}\"
    fi
}

# ============= HAUPTPROGRAMM =============

main() {
    show_banner
    
    # Prüfe rsync
    if ! command -v rsync &>/dev/null; then
        echo -e \"${RED}rsync nicht gefunden!${NC}\"
        echo \"Installation: brew install rsync\"
        exit 1
    fi
    
    # Parameter verarbeiten
    case \"${1:-}\" in
        --test|-t)
            test_mode
            ;;
        --setup-ssh)
            setup_ssh
            ;;
        --help|-h)
            echo \"Verwendung: $0 [OPTION]\"
            echo \"\"
            echo \"Optionen:\"
            echo \"  --test, -t     Testlauf (zeigt was synchronisiert würde)\"
            echo \"  --setup-ssh    SSH-Keys einrichten\"
            echo \"  --help, -h     Diese Hilfe\"
            echo \"\"
            echo \"Ohne Option: Führt Synchronisation durch\"
            ;;
        \"\")
            # Normale Synchronisation
            test_ssh || exit 1
            check_local_dir || exit 1
            check_remote_dir || exit 1
            sync_files
            ;;
        *)
            echo -e \"${RED}Unbekannte Option: $1${NC}\"
            echo \"Verwenden Sie --help für Hilfe\"
            exit 1
            ;;
    esac
}

# Script starten
main \"$@\"
`
}
