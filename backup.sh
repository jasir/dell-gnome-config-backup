#!/bin/bash

# GNOME Backup Script
# Vytvoří kompletní zálohu všech GNOME nastavení

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
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
CURRENT_BACKUP="$BACKUP_DIR/backup_$TIMESTAMP"

print_info "🔄 Spouštím zálohu GNOME nastavení..."
print_info "📂 Cílový adresář: $CURRENT_BACKUP"

# Vytvoření záložních adresářů
mkdir -p "$CURRENT_BACKUP"
mkdir -p "$CURRENT_BACKUP/config"
mkdir -p "$CURRENT_BACKUP/local"
mkdir -p "$CURRENT_BACKUP/dconf"

print_info "📊 Exportuji dconf nastavení..."
# Export všech dconf nastavení
dconf dump / > "$CURRENT_BACKUP/dconf/all-settings.ini"
dconf dump /org/gnome/shell/extensions/ > "$CURRENT_BACKUP/dconf/extensions-settings.ini"
dconf dump /org/gnome/desktop/ > "$CURRENT_BACKUP/dconf/desktop-settings.ini"
dconf dump /org/gnome/settings-daemon/ > "$CURRENT_BACKUP/dconf/settings-daemon.ini"
dconf dump /org/gnome/mutter/ > "$CURRENT_BACKUP/dconf/mutter-settings.ini"
print_success "Dconf nastavení exportována"

print_info "📁 Kopíruji konfigurační soubory..."
# Kopírování konfiguračních adresářů
[ -d ~/.config/dconf ] && cp -r ~/.config/dconf "$CURRENT_BACKUP/config/" && print_success "dconf složka zkopírována"
[ -d ~/.config/gtk-2.0 ] && cp -r ~/.config/gtk-2.0 "$CURRENT_BACKUP/config/" && print_success "GTK 2.0 nastavení zkopírována"
[ -d ~/.config/gtk-3.0 ] && cp -r ~/.config/gtk-3.0 "$CURRENT_BACKUP/config/" && print_success "GTK 3.0 nastavení zkopírována"
[ -d ~/.config/gtk-4.0 ] && cp -r ~/.config/gtk-4.0 "$CURRENT_BACKUP/config/" && print_success "GTK 4.0 nastavení zkopírována"
[ -d ~/.config/autostart ] && cp -r ~/.config/autostart "$CURRENT_BACKUP/config/" && print_success "Autostart aplikace zkopírovány"
[ -d ~/.config/tiling-assistant ] && cp -r ~/.config/tiling-assistant "$CURRENT_BACKUP/config/" && print_success "Tiling Assistant nastavení zkopírána"
[ -d ~/.config/gnome-session ] && cp -r ~/.config/gnome-session "$CURRENT_BACKUP/config/" && print_success "GNOME Session nastavení zkopírána"

# Jednotlivé soubory
[ -f ~/.config/monitors.xml ] && cp ~/.config/monitors.xml "$CURRENT_BACKUP/config/" && print_success "Monitor nastavení zkopírováno"
[ -f ~/.config/mimeapps.list ] && cp ~/.config/mimeapps.list "$CURRENT_BACKUP/config/" && print_success "MIME aplikace zkopírovány"
[ -f ~/.config/user-dirs.dirs ] && cp ~/.config/user-dirs.dirs "$CURRENT_BACKUP/config/" && print_success "Uživatelské adresáře zkopírovány"

print_info "🔌 Zálohuju GNOME Shell extensions..."
# Kopírování uživatelských extensions
if [ -d ~/.local/share/gnome-shell/extensions ]; then
    cp -r ~/.local/share/gnome-shell/extensions "$CURRENT_BACKUP/local/"
    print_success "Uživatelské extensions zkopírovány"
else
    print_warning "Žádné uživatelské extensions nenalezeny"
fi

# Kopírování dalších dat z .local/share
[ -d ~/.local/share/gnome-shell ] && cp -r ~/.local/share/gnome-shell "$CURRENT_BACKUP/local/" && print_success "GNOME Shell data zkopírována"
[ -d ~/.local/share/applications ] && cp -r ~/.local/share/applications "$CURRENT_BACKUP/local/" && print_success "Uživatelské aplikace zkopírovány"

print_info "📝 Ukládám metadata..."
# Seznam aktivních extensions
gsettings get org.gnome.shell enabled-extensions > "$CURRENT_BACKUP/enabled-extensions.txt"
print_success "Seznam aktivních extensions uložen"

# Seznam systémových extensions
ls /usr/share/gnome-shell/extensions/ > "$CURRENT_BACKUP/system-extensions.txt" 2>/dev/null || echo "Žádné systémové extensions" > "$CURRENT_BACKUP/system-extensions.txt"
print_success "Seznam systémových extensions uložen"

# Informace o systému
echo "GNOME Backup - $(date)" > "$CURRENT_BACKUP/backup-info.txt"
echo "Hostname: $(hostname)" >> "$CURRENT_BACKUP/backup-info.txt"
echo "User: $(whoami)" >> "$CURRENT_BACKUP/backup-info.txt"
echo "GNOME Version: $(gnome-shell --version 2>/dev/null || echo 'Unknown')" >> "$CURRENT_BACKUP/backup-info.txt"
echo "OS: $(lsb_release -d 2>/dev/null | cut -d: -f2 | xargs || echo 'Unknown')" >> "$CURRENT_BACKUP/backup-info.txt"
echo "Kernel: $(uname -r)" >> "$CURRENT_BACKUP/backup-info.txt"

# Vytvoření symlinku na nejnovější zálohu
ln -sf "backup_$TIMESTAMP" "$BACKUP_DIR/latest"

print_success "🎉 Záloha úspěšně dokončena!"
print_info "📂 Umístění zálohy: $CURRENT_BACKUP"
print_info "🔗 Symlink na nejnovější: $BACKUP_DIR/latest"

# Zobrazení velikosti zálohy
BACKUP_SIZE=$(du -sh "$CURRENT_BACKUP" | cut -f1)
print_info "💾 Velikost zálohy: $BACKUP_SIZE"

echo
print_info "📋 Obsah zálohy:"
find "$CURRENT_BACKUP" -type f | sed 's|^'"$CURRENT_BACKUP"'/||' | sort
