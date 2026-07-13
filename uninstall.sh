#!/usr/bin/env bash

# Setup colors
GREEN="\e[32m"
YELLOW="\e[33m"
BLUE="\e[34m"
RED="\e[31m"
BOLD="\e[1m"
END="\e[0m"

echo -e "${RED}${BOLD}==================================================${END}"
echo -e "${RED}${BOLD}     Uninstalling Suho's New Hyprland Dotfiles    ${END}"
echo -e "${RED}${BOLD}==================================================${END}"

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="$HOME/.config"

folders=("hypr" "rofi" "waybar")

for folder in "${folders[@]}"; do
    dest="$CONFIG_DIR/$folder"

    if [ -L "$dest" ]; then
        # Check if the symlink points to our dotfiles directory
        target="$(readlink "$dest")"
        if [[ "$target" == "$DOTFILES_DIR"* ]]; then
            echo -e "${YELLOW}Removing symlink:${END} $dest"
            rm "$dest"

            # Check if a backup directory exists and restore the latest one
            # Look for backup folders matching "folder.backup.*" sorted by date (latest last)
            backups=($(find "$CONFIG_DIR" -maxdepth 1 -name "${folder}.backup.*" | sort))
            if [ ${#backups[@]} -gt 0 ]; then
                latest_backup="${backups[-1]}"
                echo -e "${GREEN}Restoring latest backup:${END} $latest_backup -> $dest"
                mv "$latest_backup" "$dest"
            else
                echo -e "${YELLOW}No backup found to restore for $folder.${END}"
            fi
        else
            echo -e "${YELLOW}Skipping $folder: symlink does not point to this repository.${END}"
        fi
    elif [ -e "$dest" ]; then
        echo -e "${YELLOW}Skipping $folder: it is a regular directory (not a symlink to this repository).${END}"
    else
        echo -e "${YELLOW}Skipping $folder: no active config folder or symlink found.${END}"
    fi
done

echo -e "\n${GREEN}${BOLD}Uninstallation completed successfully!${END}"
