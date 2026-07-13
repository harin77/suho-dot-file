#!/usr/bin/env bash

# Toggle the Python GTK music player
SCRIPT_PATH="$HOME/.config/waybar/music_player/music_player.py"

if pgrep -f "python.*music_player.py" > /dev/null; then
    pkill -f "python.*music_player.py"
else
    if [ -f "$SCRIPT_PATH" ]; then
        python "$SCRIPT_PATH" &
    else
        # Fallback to local workspace if not linked yet
        python "$HOME/suho-dot-file/config/waybar/music_player/music_player.py" &
    fi
fi
