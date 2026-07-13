#!/usr/bin/env python3
import gi
gi.require_version('Gtk', '3.0')
gi.require_version('Gdk', '3.0')
from gi.repository import Gtk, Gdk, GLib
import subprocess
import os
import sys

# Self-contained GTK CSS Stylesheet matching the glassmorphic dotfiles theme
CSS_STYLE = """
window {
    background-color: rgba(15, 8, 22, 0.90);
    border-radius: 16px;
    border: 1px solid rgba(89, 96, 156, 0.45);
}

.title-label {
    font-size: 16px;
    font-weight: bold;
    color: #ffffff;
    margin-bottom: 2px;
}

.artist-label {
    font-size: 13px;
    color: #b0a5c4;
}

.control-btn {
    background: rgba(255, 255, 255, 0.05);
    border: 1px solid rgba(255, 255, 255, 0.03);
    border-radius: 50%;
    color: #ffffff;
    font-size: 18px;
    padding: 8px;
    min-width: 44px;
    min-height: 44px;
    margin: 4px;
    transition: all 180ms ease;
}

.control-btn:hover {
    background: rgba(89, 96, 156, 0.40);
    color: #ffffff;
    border-color: rgba(89, 96, 156, 0.60);
}

.time-label {
    font-size: 11px;
    color: #b0a5c4;
}

progressbar trough {
    background-color: rgba(255, 255, 255, 0.08);
    border-radius: 4px;
    min-height: 6px;
}

progressbar progress {
    background-color: #59609c;
    border-radius: 4px;
}
"""

def run_cmd(args):
    try:
        return subprocess.check_output(args, stderr=subprocess.DEVNULL).decode('utf-8').strip()
    except Exception:
        return ""

class FloatingMusicPlayer(Gtk.Window):
    def __init__(self):
        super().__init__(title="Floating Music Player")
        
        # Set window name for window manager floating rules
        self.set_name("floating_music")
        self.set_default_size(440, 220)
        self.set_resizable(False)
        self.set_keep_above(True)
        self.set_position(Gtk.WindowPosition.CENTER)

        # Transparency support
        screen = self.get_screen()
        visual = screen.get_rgba_visual()
        if visual:
            self.set_visual(visual)

        # Apply CSS style provider
        style_provider = Gtk.CssProvider()
        style_provider.load_from_data(CSS_STYLE.encode())
        Gtk.StyleContext.add_provider_for_screen(
            Gdk.Screen.get_default(),
            style_provider,
            Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION
        )

        # Layout Container
        main_box = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=16)
        main_box.set_margin_start(16)
        main_box.set_margin_end(16)
        main_box.set_margin_top(16)
        main_box.set_margin_bottom(16)
        self.add(main_box)

        # Left Column: Cover art icon
        self.art_label = Gtk.Label()
        self.art_label.set_markup("<span size='80000' foreground='#59609c'>󰎆</span>")
        self.art_label.set_size_request(120, 120)
        
        art_frame = Gtk.Frame()
        art_frame.set_shadow_type(Gtk.ShadowType.NONE)
        art_frame.get_style_context().add_class("art-frame")
        art_frame.add(self.art_label)
        main_box.pack_start(art_frame, False, False, 0)

        # Right Column: Metadata & Controls
        right_box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=8)
        main_box.pack_start(right_box, True, True, 0)

        # Track Meta info
        self.title_label = Gtk.Label(label="No media playing")
        self.title_label.set_halign(Gtk.Align.START)
        self.title_label.set_line_wrap(True)
        self.title_label.set_max_width_chars(28)
        self.title_label.get_style_context().add_class("title-label")
        right_box.pack_start(self.title_label, False, False, 0)

        self.artist_label = Gtk.Label(label="-")
        self.artist_label.set_halign(Gtk.Align.START)
        self.artist_label.set_line_wrap(True)
        self.artist_label.set_max_width_chars(28)
        self.artist_label.get_style_context().add_class("artist-label")
        right_box.pack_start(self.artist_label, False, False, 0)

        # Progress bar
        self.progress_bar = Gtk.ProgressBar()
        self.progress_bar.set_fraction(0.0)
        right_box.pack_start(self.progress_bar, False, False, 4)

        # Progress time label
        self.time_label = Gtk.Label(label="0:00 / 0:00")
        self.time_label.set_halign(Gtk.Align.END)
        self.time_label.get_style_context().add_class("time-label")
        right_box.pack_start(self.time_label, False, False, 0)

        # Controls Row
        control_row = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=6)
        control_row.set_halign(Gtk.Align.CENTER)
        right_box.pack_start(control_row, True, False, 4)

        # Controls Buttons
        prev_btn = Gtk.Button(label="󰒮")
        prev_btn.get_style_context().add_class("control-btn")
        prev_btn.connect("clicked", self.on_prev_clicked)
        control_row.pack_start(prev_btn, False, False, 0)

        self.play_btn = Gtk.Button(label="󰐊")
        self.play_btn.get_style_context().add_class("control-btn")
        self.play_btn.connect("clicked", self.on_play_clicked)
        control_row.pack_start(self.play_btn, False, False, 0)

        next_btn = Gtk.Button(label="󰒭")
        next_btn.get_style_context().add_class("control-btn")
        next_btn.connect("clicked", self.on_next_clicked)
        control_row.pack_start(next_btn, False, False, 0)

        # Update metadata state every 1 second
        GLib.timeout_add(1000, self.update_player)

        # Run initial update
        self.update_player()

    def on_prev_clicked(self, widget):
        run_cmd(["playerctl", "previous"])
        self.update_player()

    def on_play_clicked(self, widget):
        run_cmd(["playerctl", "play-pause"])
        self.update_player()

    def on_next_clicked(self, widget):
        run_cmd(["playerctl", "next"])
        self.update_player()

    def format_time(self, seconds_val):
        try:
            sec = int(float(seconds_val))
            m, s = divmod(sec, 60)
            return f"{m}:{s:02d}"
        except ValueError:
            return "0:00"

    def update_player(self):
        # 1. Fetch metadata
        title = run_cmd(["playerctl", "metadata", "title"])
        artist = run_cmd(["playerctl", "metadata", "artist"])
        status = run_cmd(["playerctl", "status"])
        
        # 2. Update metadata labels
        if title:
            self.title_label.set_text(title)
        else:
            self.title_label.set_text("No media playing")
        
        if artist:
            self.artist_label.set_text(artist)
        else:
            self.artist_label.set_text("-")

        # 3. Update play/pause button icon
        if status == "Playing":
            self.play_btn.set_label("󰏤")  # Pause icon
        else:
            self.play_btn.set_label("󰐊")  # Play icon

        # 4. Fetch position and duration
        pos_raw = run_cmd(["playerctl", "position"])
        length_raw = run_cmd(["playerctl", "metadata", "mpris:length"])

        try:
            position = float(pos_raw) if pos_raw else 0.0
            # Length in metadata is in microseconds, convert to seconds
            duration = float(length_raw) / 1000000.0 if length_raw else 0.0
        except ValueError:
            position = 0.0
            duration = 0.0

        # 5. Update progress bar
        if duration > 0.0:
            fraction = min(position / duration, 1.0)
            self.progress_bar.set_fraction(fraction)
            self.time_label.set_text(f"{self.format_time(position)} / {self.format_time(duration)}")
        else:
            self.progress_bar.set_fraction(0.0)
            self.time_label.set_text("0:00 / 0:00")

        return True  # Keep GLib timeout running

if __name__ == "__main__":
    win = FloatingMusicPlayer()
    win.connect("destroy", Gtk.main_quit)
    win.show_all()
    Gtk.main()
