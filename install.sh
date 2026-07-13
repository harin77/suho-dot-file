#!/usr/bin/env bash

# Exit immediately if a command exits with a non-zero status
set -e

# Setup colors
GREEN="\e[32m"
YELLOW="\e[33m"
BLUE="\e[34m"
RED="\e[31m"
BOLD="\e[1m"
END="\e[0m"

echo -e "${BLUE}${BOLD}==================================================${END}"
echo -e "${BLUE}${BOLD}      Installing Suho's New Hyprland Dotfiles     ${END}"
echo -e "${BLUE}${BOLD}==================================================${END}"

# 1. Locate Dotfiles directory
DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="$HOME/.config"

echo -e "${YELLOW}Dotfiles source directory:${END} $DOTFILES_DIR"
echo -e "${YELLOW}Target config directory:  ${END} $CONFIG_DIR"

# 2. Package installation function
install_packages() {
    local file=$1
    local helper=$2
    local pkgs=()

    if [ ! -f "$file" ]; then
        echo -e "${RED}Error: $file not found!${END}"
        return
    fi

    # Read packages, ignore comments/blank lines
    while IFS= read -r line || [ -n "$line" ]; do
        # Strip comments
        line="${line%%#*}"
        # Trim leading/trailing whitespace
        line="${line##*[[:space:]]}"
        line="${line%%*[[:space:]]}"
        if [ -n "$line" ]; then
            pkgs+=("$line")
        fi
    done < "$file"

    if [ ${#pkgs[@]} -eq 0 ]; then
        echo -e "${GREEN}No packages to install from $file.${END}"
        return
    fi

    echo -e "${YELLOW}Installing packages from $(basename "$file")...${END}"
    if [ "$helper" = "pacman" ]; then
        sudo pacman -S --needed --noconfirm "${pkgs[@]}"
    else
        $helper -S --needed --noconfirm "${pkgs[@]}"
    fi
}

# 3. Detect AUR helper
detect_aur_helper() {
    if command -v paru &>/dev/null; then
        echo "paru"
    elif command -v yay &>/dev/null; then
        echo "yay"
    else
        echo ""
    fi
}

# 4. Perform package installation
echo -e "\n${BLUE}[1/5] Checking and installing dependencies...${END}"
# Install official packages
install_packages "$DOTFILES_DIR/packages.txt" "pacman"

# Install AUR packages
AUR_HELPER=$(detect_aur_helper)
if [ -n "$AUR_HELPER" ]; then
    echo -e "${GREEN}Detected AUR helper:${END} $AUR_HELPER"
    install_packages "$DOTFILES_DIR/packages-aur.txt" "$AUR_HELPER"
else
    echo -e "${YELLOW}Warning: No AUR helper (yay or paru) found. Skipping AUR packages installation.${END}"
    echo -e "${YELLOW}Please install yay or paru first, then re-run to get custom AUR components.${END}"
fi

# 5. Backup and Symlink Config Folders
echo -e "\n${BLUE}[2/5] Linking configuration folders...${END}"
mkdir -p "$CONFIG_DIR"

# Folders to link
folders=("hypr" "rofi" "waybar")

for folder in "${folders[@]}"; do
    src="$DOTFILES_DIR/config/$folder"
    dest="$CONFIG_DIR/$folder"

    if [ ! -d "$src" ]; then
        echo -e "${RED}Source config folder not found:${END} $src"
        continue
    fi

    # If destination exists
    if [ -e "$dest" ] || [ -L "$dest" ]; then
        if [ -L "$dest" ]; then
            # If it's a symlink, delete it
            echo -e "${YELLOW}Removing existing symlink:${END} $dest"
            rm "$dest"
        else
            # Backup active directory
            backup="${dest}.backup.$(date +%Y%m%d-%H%M%S)"
            echo -e "${YELLOW}Backing up existing config:${END} $dest -> $backup"
            mv "$dest" "$backup"
        fi
    fi

    # Create symlink
    echo -e "${GREEN}Linking:${END} $src -> $dest"
    ln -s "$src" "$dest"
done

# 6. Ensure executable scripts
echo -e "\n${BLUE}[3/5] Setting executable permissions on scripts...${END}"
music_script="$DOTFILES_DIR/config/waybar/music_player/toggle_music.sh"
if [ -f "$music_script" ]; then
    echo -e "${GREEN}Making executable:${END} $music_script"
    chmod +x "$music_script"
fi

# 7. Configure system services
echo -e "\n${BLUE}[4/5] Configuring system services (SDDM, Bluetooth, Wi-Fi)...${END}"

# Enable SDDM
if systemctl list-unit-files | grep -q sddm.service; then
    echo -e "${GREEN}Enabling SDDM service...${END}"
    sudo systemctl enable sddm.service
else
    echo -e "${YELLOW}Warning: sddm.service not found. Make sure sddm is installed properly.${END}"
fi

# Enable and start NetworkManager
if systemctl list-unit-files | grep -q NetworkManager.service; then
    echo -e "${GREEN}Enabling and starting NetworkManager (Wi-Fi)...${END}"
    sudo systemctl enable --now NetworkManager.service
else
    echo -e "${YELLOW}Warning: NetworkManager.service not found.${END}"
fi

# Enable and start Bluetooth
if systemctl list-unit-files | grep -q bluetooth.service; then
    echo -e "${GREEN}Enabling and starting Bluetooth...${END}"
    sudo systemctl enable --now bluetooth.service
else
    echo -e "${YELLOW}Warning: bluetooth.service not found.${END}"
fi

# 8. Detect CPU and GPU and install microcode / drivers
echo -e "\n${BLUE}[5/5] Detecting hardware (CPU & GPU) for driver installation...${END}"

# CPU Microcode Detection
if grep -q "GenuineIntel" /proc/cpuinfo; then
    echo -e "${GREEN}Intel CPU detected. Installing intel-ucode...${END}"
    sudo pacman -S --needed --noconfirm intel-ucode
elif grep -q "AuthenticAMD" /proc/cpuinfo; then
    echo -e "${GREEN}AMD CPU detected. Installing amd-ucode...${END}"
    sudo pacman -S --needed --noconfirm amd-ucode
else
    echo -e "${YELLOW}Unknown CPU manufacturer. Skipping microcode installation.${END}"
fi

# GPU Driver Detection
GPU_DRIVERS=()

# Check for Nvidia
if lspci | grep -i "nvidia" > /dev/null; then
    echo -e "${GREEN}Nvidia GPU detected. Preparing Nvidia drivers...${END}"
    GPU_DRIVERS+=("nvidia" "nvidia-utils" "nvidia-settings")
fi

# Check for AMD
if lspci | grep -i -E "vga|3d" | grep -i "amd" > /dev/null; then
    echo -e "${GREEN}AMD GPU detected. Preparing AMD drivers...${END}"
    GPU_DRIVERS+=("xf86-video-amdgpu" "vulkan-radeon" "libva-mesa-driver")
fi

# Check for Intel GPU
if lspci | grep -i -E "vga|3d" | grep -i "intel" > /dev/null; then
    echo -e "${GREEN}Intel Integrated GPU detected. Preparing Intel drivers...${END}"
    GPU_DRIVERS+=("mesa" "vulkan-intel" "intel-media-driver")
fi

if [ ${#GPU_DRIVERS[@]} -gt 0 ]; then
    echo -e "${YELLOW}Installing GPU drivers: ${GPU_DRIVERS[*]}${END}"
    sudo pacman -S --needed --noconfirm "${GPU_DRIVERS[@]}"
else
    echo -e "${YELLOW}No matching GPU detected for driver installation.${END}"
fi

echo -e "\n${GREEN}${BOLD}Installation completed successfully!${END}"
echo -e "You can reload Hyprland or run 'quickshell' to start the new shell layout!"
