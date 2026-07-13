# Changes Log

This document records the design choices, architectural updates, and refactoring implemented during the transition from the legacy repository structure to this new project format.

## 1. Native Lua Compositor Configuration
* **Shift to Lua**: Replaced the legacy Hyprlang (`.conf`) configurations with the native Lua config format (`hyprland.lua`), which is mandatory starting with Hyprland v0.55.
* **Autostart Integrations**: Configured default start hooks to automatically launch the `waybar` bar and the `quickshell` desktop environment at boot.

## 2. Refactored Music Player
* **From HTML to Native Python**: Retired the previous Brave app/HTML-based music player interface (`index.html` and `music_server.py`).
* **GTK3 Implementation**: Rebuilt the player as a standalone PyGObject GTK3 application (`music_player.py`) containing embedded CSS styles, providing a cleaner desktop layout, faster startup, and lower resource footprint.
* **MPRIS Integration**: Fully mapped media controls (Play/Pause, Skip, Previous) and seek progress bar status dynamically to system media players via `playerctl` command line queries.

## 3. Intelligent Installer Updates
* **Hardware Detection**: Added bash routines to detect whether the user is running an AMD or Intel CPU, installing the corresponding `amd-ucode` or `intel-ucode` microcode dynamically.
* **GPU Driver Mapping**: Analyzed `lspci` entries to determine the graphics cards present and automatically install corresponding packages (`nvidia` for NVIDIA, `xf86-video-amdgpu` for AMD, `mesa` for Intel integrated chips).
* **System Services**: Automated the activation of key daemons (`sddm.service`, `NetworkManager.service`, `bluetooth.service`) via systemctl calls.

## 4. UI/UX Polishing
* **Rofi Transparency**: Fixed Rofi launcher's fallback-to-white visual bug by adding a default theme color scheme (`colors.rasi`) with custom transparency values.
* **Waybar Float Styles**: Configured `window#waybar` to render as fully transparent, allowing individual status pills to float freely on the screen.
