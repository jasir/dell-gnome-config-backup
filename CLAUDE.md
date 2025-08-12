# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a GNOME configuration backup and restore system for Dell Ubuntu systems. The project provides comprehensive backup/restore functionality for GNOME desktop environment settings, extensions, and configurations.

## Core Commands

### UICTL - Unified Interface Control
```bash
./uictl backup                 # Create timestamped backup of all GNOME settings
./uictl restore <backup>       # Restore backup with safety features
./uictl list                   # List available backups  
./uictl status                 # Show info about latest backup
./uictl clean [N]              # Clean old backups (keep N newest)
./uictl help [command]         # Show help
```

### Global Options
```bash
-f, --force                    # Don't ask for confirmation
-d, --dry-run                  # Only show what would be done (restore/clean)
-q, --quiet                    # Quiet mode
-v, --verbose                  # Verbose output
-h, --help                     # Show help
```

## Architecture

### Main Components
- `uictl`: Unified command-line interface for all backup/restore operations
- `backups/`: Directory containing timestamped backup folders and `latest` symlink

### Backup Structure
Each backup contains:
- `dconf/`: Exported GNOME settings (all-settings.ini, extensions-settings.ini, etc.)
- `config/`: Configuration files from ~/.config (gtk themes, autostart, monitors.xml, etc.)
- `local/`: Extensions and application data from ~/.local/share
- `backup-info.txt`: System metadata and backup information
- `enabled-extensions.txt`: List of active GNOME extensions

### What Gets Backed Up
- All dconf/gsettings (GNOME configuration database)
- GTK 2.0/3.0/4.0 themes and settings
- Monitor configurations and display settings
- GNOME Shell extensions (user-installed)
- Autostart applications
- MIME type associations
- Custom keyboard shortcuts
- Tiling Assistant and panel configurations

## Development Notes

### Safety Features
- Automatic pre-restore backup before any restore operation
- Confirmation prompts (can be bypassed with `-f`)
- Dry-run mode to preview changes
- Backup of existing files before overwriting

### Error Handling
- Scripts use `set -e` to stop on errors
- Colorized output with proper success/warning/error indicators
- Graceful handling of missing directories/files

### File Operations
- Uses `dconf dump/load` for GNOME settings
- Recursive copying with `cp -r` for directory structures
- Symlink management for `latest` backup pointer
- Timestamped naming convention: `backup_YYYYMMDD_HHMMSS`