# Suho's Hyprland & Waybar Dotfiles (New Project)

Welcome to the new generation of Suho's dotfiles! This repository contains a clean, modern, high-performance, and glassmorphic Wayland desktop environment setup designed for CachyOS and Arch Linux.

![Aesthetic](https://raw.githubusercontent.com/harin77/suho-dot-file/main/screenshots/dashboard_monitors.png)

## 󰏘 Key Features
* **Hyprland 0.55+ (Lua native)**: Compositor configuration rewritten entirely in the native Lua system (`hyprland.lua`), providing cleaner modular modules and faster loading.
* **Waybar Floating Status Bar**: Transparent top bar configuration featuring custom workspace indicators, CPU/RAM/Battery meters, backlight, volume, network controls, and tray support.
* **Custom Python GTK3 Music Player**: A native Python-based GTK3 floating player (`music_player.py`) that queries MPRIS players via `playerctl` and centers cleanly on the screen using Hyprland window rules.
* **Automated Installer/Uninstaller**: Scripts designed to manage file backups, symlinking, systemd service enablement, and hardware-specific graphics driver installation.

---

## 󰏖 Directory Structure
```
suho-dot-file/
├── config/
│   ├── hypr/               # Hyprland Lua settings (autostart, binds, lookup)
│   ├── rofi/               # Rofi configuration & dark-transparency colors.rasi
│   └── waybar/             # Waybar jsonc, stylesheet, and python scripts
├── install.sh              # Unified hardware-detecting installer script
├── uninstall.sh            # Safe uninstaller restoring latest config backups
├── packages.txt            # Pacman dependencies (kitty, dolphin, networkmanager, etc.)
└── packages-aur.txt        # AUR dependencies (quickshell, etc.)
```

---

## 󰆍 Installation

To install this setup, clone the repository and execute the installer:

```bash
git clone https://github.com/harin77/suho-dot-file.git
cd suho-dot-file
chmod +x install.sh
./install.sh
```

### What `install.sh` does automatically:
1. Installs official packages from `packages.txt` using `pacman`.
2. Installs AUR packages from `packages-aur.txt` using `paru` or `yay`.
3. Backs up your existing configuration folders to `~/.config/*.backup.<timestamp>` (so you never lose your old settings!).
4. Symlinks the repository folders (`hypr`, `rofi`, `waybar`) to `~/.config/`.
5. Configures and starts system services (SDDM, Bluetooth, and NetworkManager).
6. **Detects your hardware** (AMD/Intel CPU for microcode; AMD/Intel/Nvidia GPU) and installs the latest appropriate graphics drivers.

---

## 󰆎 Uninstallation

If you need to revert the settings, run:

```bash
./uninstall.sh
```
This removes the symlinks and automatically restores the latest backup of your configuration folders.
