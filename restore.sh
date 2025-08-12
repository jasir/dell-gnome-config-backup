#!/bin/bash

# GNOME Restore Script
# Obnoví GNOME nastavení ze zálohy

set -e  # Zastavit při chybě

# Barevné výstupy
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Funkce pro barevné výpisy
print_info() { echo -e "${BLUE}ℹ️  $1${NC}"; }
print_success() { echo -e "${GREEN}✅ $1${NC}"; }
print_warning() { echo -e "${YELLOW}⚠️  $1${NC}"; }
print_error() { echo -e "${RED}❌ $1${NC}"; }

# Získání aktuálního adresáře scriptu
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUP_DIR="$SCRIPT_DIR/backups"

# Funkce pro zobrazení nápovědy
show_help() {
    echo "🔄 GNOME Restore Script"
    echo "Obnoví GNOME nastavení ze zálohy"
    echo
    echo "Použití: $0 [možnosti] [záloha]"
    echo
    echo "Možnosti:"
    echo "  -l, --list              Zobrazí dostupné zálohy"
    echo "  -h, --help              Zobrazí tuto nápovědu"
    echo "  -f, --force             Neptat se na potvrzení"
    echo "  -d, --dry-run           Pouze zobrazí co by se dělalo"
    echo
    echo "Argumenty:"
    echo "  záloha                  Název zálohy (např. backup_20240630_143022)"
    echo "                          nebo 'latest' pro nejnovější zálohu"
    echo
    echo "Příklady:"
    echo "  $0 -l                   Zobrazí seznam dostupných záloh"
    echo "  $0 latest               Obnoví nejnovější zálohu"
    echo "  $0 backup_20240630_143022  Obnoví specifickou zálohu"
    echo "  $0 -d latest            Dry-run - ukáže co by se dělalo"
    echo "  $0 -f latest            Obnoví bez ptání na potvrzení"
    echo
    echo "⚠️  POZOR: Restore přepíše vaše současné GNOME nastavení!"
    echo "📋 Pro zobrazení záloh použijte: $0 -l"
}

# Funkce pro výpis dostupných záloh
list_backups() {
    print_info "📂 Dostupné zálohy v $BACKUP_DIR:"
    echo
    if [ ! -d "$BACKUP_DIR" ]; then
        print_warning "Adresář se zálohami neexistuje: $BACKUP_DIR"
        return 1
    fi
    
    if [ ! "$(ls -A "$BACKUP_DIR"/backup_* 2>/dev/null)" ]; then
        print_warning "Žádné zálohy nenalezeny"
        return 1
    fi
    
    for backup in "$BACKUP_DIR"/backup_*; do
        if [ -d "$backup" ]; then
            backup_name=$(basename "$backup")
            backup_date=$(echo "$backup_name" | sed 's/backup_//' | sed 's/_/ /')
            backup_size=$(du -sh "$backup" 2>/dev/null | cut -f1 || echo "N/A")
            printf "  %-25s %s (%s)\n" "$backup_name" "$backup_date" "$backup_size"
        fi
    done
    
    echo
    if [ -L "$BACKUP_DIR/latest" ]; then
        latest_target=$(readlink "$BACKUP_DIR/latest")
        print_info "🔗 Nejnovější záloha: $latest_target"
    fi
}

# Funkce pro vytvoření zálohy před obnovením
create_pre_restore_backup() {
    print_info "💾 Vytvářím zálohu před obnovením..."
    PRE_RESTORE_BACKUP="$BACKUP_DIR/pre-restore-backup_$(date +%Y%m%d_%H%M%S)"
    
    mkdir -p "$PRE_RESTORE_BACKUP/config"
    mkdir -p "$PRE_RESTORE_BACKUP/dconf"
    
    # Rychlá záloha současného stavu
    dconf dump / > "$PRE_RESTORE_BACKUP/dconf/current-settings.ini" 2>/dev/null || true
    [ -d ~/.config/dconf ] && cp -r ~/.config/dconf "$PRE_RESTORE_BACKUP/config/" 2>/dev/null || true
    [ -d ~/.local/share/gnome-shell/extensions ] && cp -r ~/.local/share/gnome-shell/extensions "$PRE_RESTORE_BACKUP/" 2>/dev/null || true
    
    print_success "Záloha před obnovením vytvořena: $(basename "$PRE_RESTORE_BACKUP")"
}

# Funkce pro obnovení nastavení
restore_settings() {
    local restore_path="$1"
    local dry_run="$2"
    
    if [ ! -d "$restore_path" ]; then
        print_error "Záloha neexistuje: $restore_path"
        exit 1
    fi
    
    print_info "🔄 Obnovuji GNOME nastavení ze zálohy: $(basename "$restore_path")"
    
    if [ "$dry_run" = "true" ]; then
        print_warning "🧪 DRY-RUN režim - pouze zobrazuji co by se dělalo"
    fi
    
    # Kontrola obsahu zálohy
    if [ ! -f "$restore_path/backup-info.txt" ]; then
        print_warning "Záloha neobsahuje info soubor - možná je neúplná"
    else
        print_info "📋 Informace o záloze:"
        cat "$restore_path/backup-info.txt" | sed 's/^/  /'
        echo
    fi
    
    # Obnovení dconf nastavení
    if [ -f "$restore_path/dconf/all-settings.ini" ]; then
        print_info "📊 Obnovuji dconf nastavení..."
        if [ "$dry_run" != "true" ]; then
            dconf load / < "$restore_path/dconf/all-settings.ini"
            print_success "Dconf nastavení obnovena"
        else
            print_info "  Obnovil bych: $restore_path/dconf/all-settings.ini"
        fi
    else
        print_warning "Dconf záloha nenalezena"
    fi
    
    # Obnovení konfiguračních souborů
    if [ -d "$restore_path/config" ]; then
        print_info "📁 Obnovuji konfigurační soubory..."
        for config_item in "$restore_path/config"/*; do
            if [ -e "$config_item" ]; then
                item_name=$(basename "$config_item")
                target_path="$HOME/.config/$item_name"
                
                if [ "$dry_run" != "true" ]; then
                    # Vytvořit zálohu existujícího nastavení v /tmp
                    if [ -e "$target_path" ]; then
                        mv "$target_path" "/tmp/$(basename "$target_path").backup-$(date +%s)" 2>/dev/null || true
                    fi
                    cp -r "$config_item" "$target_path"
                    print_success "Obnoveno: $item_name"
                else
                    print_info "  Obnovil bych: $item_name -> $target_path"
                fi
            fi
        done
    fi
    
    # Obnovení extensions
    if [ -d "$restore_path/local/extensions" ]; then
        print_info "🔌 Obnovuji GNOME Shell extensions..."
        if [ "$dry_run" != "true" ]; then
            mkdir -p "$HOME/.local/share/gnome-shell"
            # Záloha současných extensions do /tmp
            if [ -d "$HOME/.local/share/gnome-shell/extensions" ]; then
                mv "$HOME/.local/share/gnome-shell/extensions" "/tmp/extensions.backup-$(date +%s)" 2>/dev/null || true
            fi
            cp -r "$restore_path/local/extensions" "$HOME/.local/share/gnome-shell/extensions"
            print_success "Extensions obnoveny"
        else
            print_info "  Obnovil bych uživatelské extensions"
        fi
    fi
    
    # Obnovení seznamu aktivních extensions
    if [ -f "$restore_path/enabled-extensions.txt" ]; then
        print_info "✅ Obnovuji seznam aktivních extensions..."
        if [ "$dry_run" != "true" ]; then
            enabled_extensions=$(cat "$restore_path/enabled-extensions.txt")
            gsettings set org.gnome.shell enabled-extensions "$enabled_extensions"
            print_success "Seznam aktivních extensions obnoven"
        else
            print_info "  Obnovil bych: $(cat "$restore_path/enabled-extensions.txt")"
        fi
    fi
    
    if [ "$dry_run" != "true" ]; then
        echo
        print_success "🎉 Obnovení dokončeno!"
        print_warning "⚠️  Doporučuje se restartovat GNOME Shell (Alt+F2, pak napište 'r')"
        print_info "💡 Nebo se odhlaste a znovu přihlaste"
    else
        echo
        print_info "🧪 DRY-RUN dokončen - žádné změny nebyly provedeny"
    fi
}

# Parsování argumentů
FORCE=false
DRY_RUN=false
BACKUP_NAME=""

while [[ $# -gt 0 ]]; do
    case $1 in
        -l|--list)
            list_backups
            exit 0
            ;;
        -h|--help)
            show_help
            exit 0
            ;;
        -f|--force)
            FORCE=true
            shift
            ;;
        -d|--dry-run)
            DRY_RUN=true
            shift
            ;;
        -*)
            print_error "Neznámá možnost: $1"
            show_help
            exit 1
            ;;
        *)
            BACKUP_NAME="$1"
            shift
            ;;
    esac
done

# Určení cesty k záloze
if [ -z "$BACKUP_NAME" ]; then
    # Bez parametrů zobrazit help
    show_help
    exit 0
else
    if [[ "$BACKUP_NAME" == "latest" ]]; then
        if [ -L "$BACKUP_DIR/latest" ]; then
            RESTORE_PATH="$BACKUP_DIR/$(readlink "$BACKUP_DIR/latest")"
            BACKUP_NAME="latest ($(readlink "$BACKUP_DIR/latest"))"
        else
            print_error "'latest' symlink neexistuje"
            print_info "Použijte -l pro zobrazení dostupných záloh"
            exit 1
        fi
    elif [[ "$BACKUP_NAME" == backup_* ]]; then
        RESTORE_PATH="$BACKUP_DIR/$BACKUP_NAME"
    else
        RESTORE_PATH="$BACKUP_DIR/backup_$BACKUP_NAME"
    fi
fi

# Kontrola existence zálohy
if [ ! -d "$RESTORE_PATH" ]; then
    print_error "Záloha neexistuje: $RESTORE_PATH"
    list_backups
    exit 1
fi

# Potvrzení (pokud není force mode)
if [ "$FORCE" != "true" ] && [ "$DRY_RUN" != "true" ]; then
    echo
    print_warning "🚨 POZOR: Tato operace přepíše vaše současné GNOME nastavení!"
    print_info "Záloha k obnovení: $BACKUP_NAME"
    print_info "Před obnovením bude vytvořena záloha současného stavu."
    echo
    read -p "Pokračovat? (ano/ne): " -r
    if [[ ! $REPLY =~ ^[Aa]no$ ]]; then
        print_info "Operace zrušena"
        exit 0
    fi
fi

# Vytvoření zálohy před obnovením (pokud není dry-run)
if [ "$DRY_RUN" != "true" ]; then
    create_pre_restore_backup
fi

# Provedení obnovení
restore_settings "$RESTORE_PATH" "$DRY_RUN"
