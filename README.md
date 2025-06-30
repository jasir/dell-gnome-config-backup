# Dell GNOME Config Backup

Kompletní nástroj pro zálohování a obnovení GNOME nastavení na Dell systémech s Ubuntu/GNOME.

## 🚀 Rychlý start

### Záloha
```bash
./backup.sh
```

### Obnovení
```bash
./restore.sh                    # Obnoví nejnovější zálohu
./restore.sh backup_20240630_143022  # Obnoví specifickou zálohu
```

### Seznam záloh
```bash
./restore.sh -l
```

## 📋 Co se zálohuje

### 🔧 Nastavení systému
- **Dconf databáze** - všechna GNOME nastavení
- **GTK témata** - GTK 2.0, 3.0, 4.0 nastavení
- **Monitor konfigurace** - rozlišení, pozice monitorů
- **Klávesové zkratky** - vlastní zkratky
- **MIME aplikace** - výchozí aplikace pro soubory

### 🔌 Extensions
- **Uživatelské extensions** z `~/.local/share/gnome-shell/extensions/`
- **Seznam aktivních extensions**
- **Nastavení jednotlivých extensions**

### 🎨 Vzhled a chování
- **Témata** - GTK téma, ikony, kurzory
- **Autostart aplikace**
- **Tiling Assistant** nastavení
- **Panel konfigurace** (Dash to Panel)

### 📁 Konfigurační soubory
- Uživatelské adresáře
- GNOME session nastavení
- Notifications nastavení

## 🛠️ Použití

### Backup script

Základní použití:
```bash
./backup.sh
```

Script automaticky:
1. Vytvoří timestampovanou zálohu v `backups/backup_YYYYMMDD_HHMMSS/`
2. Exportuje všechna dconf nastavení
3. Zkopíruje relevantní konfigurační soubory
4. Vytvoří symlink `backups/latest` na nejnovější zálohu
5. Uloží metadata o systému a extensions

### Restore script

#### Možnosti
- `-l, --list` - Zobrazí dostupné zálohy
- `-f, --force` - Neptat se na potvrzení
- `-d, --dry-run` - Pouze zobrazí co by se dělalo
- `-h, --help` - Zobrazí nápovědu

#### Příklady použití
```bash
# Zobrazit dostupné zálohy
./restore.sh -l

# Obnovit nejnovější zálohu (s potvrzením)
./restore.sh

# Obnovit specifickou zálohu
./restore.sh backup_20240630_143022

# Dry-run - ukázat co by se dělalo
./restore.sh -d backup_20240630_143022

# Obnovit bez ptání na potvrzení
./restore.sh -f latest
```

## 🔒 Bezpečnost

- **Automatická záloha** - před každým obnovením se vytvoří záloha současného stavu
- **Dry-run režim** - možnost otestovat co se bude dělat bez provedení změn
- **Potvrzení** - script se ptá na potvrzení před přepsáním nastavení

## 📂 Struktura zálohy

```
backups/
├── latest → backup_20240630_143022/
├── backup_20240630_143022/
│   ├── backup-info.txt
│   ├── enabled-extensions.txt
│   ├── system-extensions.txt
│   ├── config/
│   │   ├── dconf/
│   │   ├── gtk-3.0/
│   │   ├── autostart/
│   │   ├── tiling-assistant/
│   │   └── monitors.xml
│   ├── dconf/
│   │   ├── all-settings.ini
│   │   ├── extensions-settings.ini
│   │   ├── desktop-settings.ini
│   │   └── ...
│   └── local/
│       └── extensions/
└── pre-restore-backup_20240630_150000/
```

## 🔄 Po obnovení

Po úspěšném obnovení nastavení doporučujeme:

1. **Restart GNOME Shell**: `Alt+F2` → napište `r` → Enter
2. **Nebo se odhlaste a znovu přihlaste**
3. **Zkontrolujte extensions**: některé možná budou potřebovat restart

## ⚙️ Aktuální konfigurace

### Aktivní Extensions
- Tiling Assistant (Ubuntu)
- Workspace Indicator  
- Dash to Panel
- Desktop Icons NG (DING)
- Apps Menu
- Light Style
- System Monitor
- Ubuntu AppIndicators

### Klávesová konfigurace
- Layout: `czcoder` (vlastní český layout)
- Dodatečné možnosti: `lv3:ralt_switch`

### Vzhled
- **Téma**: Yaru-dark
- **Ikony**: Yaru
- **Barevné schéma**: prefer-dark

## 🚨 Troubleshooting

### Extensions se nezobrazují
```bash
# Restartujte GNOME Shell
Alt+F2 → r → Enter

# Nebo resetujte extensions
gsettings reset org.gnome.shell enabled-extensions
```

### Problémy s tématy
```bash
# Resetujte GTK nastavení
gsettings reset org.gnome.desktop.interface gtk-theme
gsettings reset org.gnome.desktop.interface icon-theme
```

### Záloha je neúplná
Zkontrolujte, zda máte potřebná oprávnění k souborům v `~/.config/` a `~/.local/share/`

## 📄 Licence

MIT License - můžete volně používat a upravovat.

## 🤝 Přispívání

1. Forkněte repozitář
2. Vytvořte feature branch
3. Commitujte změny
4. Pushněte do branche
5. Vytvořte Pull Request

---

**Poznámka**: Tento nástroj byl vytvořen specificky pro Dell systémy s Ubuntu GNOME, ale měl by fungovat na jakémkoliv GNOME systému.
