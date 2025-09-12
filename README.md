# Dell GNOME Config Backup

Kompletní nástroj pro zálohování a obnovení GNOME nastavení na Dell systémech s Ubuntu/GNOME.

## 🚀 Rychlý start

### Záloha
```bash
./uictl backup
```

### Obnovení
```bash
./uictl restore latest           # Obnoví nejnovější zálohu
./uictl restore backup_20240630  # Obnoví specifickou zálohu
```

### Seznam záloh
```bash
./uictl list
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

### UICTL - Unified Interface Control

UICTL poskytuje jednotné rozhraní pro všechny operace:

```bash
./uictl <příkaz> [možnosti] [argumenty]
```

#### Dostupné příkazy
- `backup` - Vytvoří zálohu GNOME nastavení
- `restore <backup>` - Obnoví zálohu GNOME nastavení  
- `list` - Zobrazí dostupné zálohy
- `status` - Zobrazí info o nejnovější záloze
- `clean [N]` - Vyčistí staré zálohy (ponechá N nejnovějších)
- `help [příkaz]` - Zobrazí nápovědu

#### Globální možnosti
- `-f, --force` - Neptat se na potvrzení
- `-d, --dry-run` - Pouze zobrazí co by se dělalo (restore/clean)
- `-q, --quiet` - Tichý režim
- `-v, --verbose` - Podrobný výstup
- `-h, --help` - Zobrazí nápovědu

#### Příklady použití
```bash
# Vytvořit zálohu
./uictl backup

# Zobrazit dostupné zálohy
./uictl list

# Zobrazit status nejnovější zálohy
./uictl status

# Obnovit nejnovější zálohu (s potvrzením)
./uictl restore latest

# Obnovit specifickou zálohu
./uictl restore backup_20240630_143022

# Dry-run - ukázat co by se dělalo
./uictl restore -d latest

# Obnovit bez ptání na potvrzení
./uictl restore -f latest

# Vyčistit staré zálohy (ponechat jen 5 nejnovějších)
./uictl clean 5

# Zobrazit co by se smazalo bez provedení
./uictl clean -d 3

# Nápověda pro konkrétní příkaz
./uictl help restore
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
