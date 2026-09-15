#!/usr/bin/env python3
"""A small local settings window for the Arch / Hyprland desktop."""
import hashlib
import os
from pathlib import Path
import shutil
import subprocess
import sys
import time

import gi
gi.require_version("Gtk", "3.0")
gi.require_version("Gdk", "3.0")
from gi.repository import Gdk, GdkPixbuf, Gio, GLib, Gtk

from backend import DisplayPreview, Settings, THEMES, palette

GLib.set_prgname("org.archdesktop.Settings")
HERE = Path(__file__).resolve().parent


def label(text, style=None):
    widget = Gtk.Label(label=text, xalign=0)
    widget.set_line_wrap(True)
    widget.set_max_width_chars(65)
    if style:
        widget.get_style_context().add_class(style)
    return widget


def button(text, callback, primary=False):
    widget = Gtk.Button(label=text)
    widget.connect("clicked", callback)
    if primary:
        widget.get_style_context().add_class("suggested-action")
    return widget


class Window(Gtk.ApplicationWindow):
    def __init__(self, app):
        super().__init__(application=app, title="Settings")
        self.set_default_size(940, 720)
        self.set_size_request(760, 550)
        self.settings = Settings()
        self.preview = None
        self.css = Gtk.CssProvider()
        self.apply_style()
        self.connect("delete-event", self.on_close)
        header = Gtk.HeaderBar(title="Settings", subtitle="Make this desktop yours", show_close_button=True)
        self.set_titlebar(header)
        root = Gtk.Box(orientation=Gtk.Orientation.VERTICAL)
        self.add(root)
        body = Gtk.Box(spacing=0)
        root.pack_start(body, True, True, 0)
        self.stack = Gtk.Stack(transition_type=Gtk.StackTransitionType.CROSSFADE, transition_duration=150)
        sidebar = Gtk.StackSidebar(stack=self.stack)
        sidebar.set_size_request(180, -1)
        body.pack_start(sidebar, False, False, 0)
        body.pack_start(self.stack, True, True, 0)
        self.status = label("Changes are saved when you apply them.", "status")
        self.status.set_margin_start(20)
        self.status.set_margin_end(20)
        self.status.set_margin_top(12)
        self.status.set_margin_bottom(12)
        root.pack_end(self.status, False, False, 0)
        self.appearance_page()
        self.wallpaper_page()
        self.display_page()
        self.devices_page()
        self.help_page()
        self.show_all()

    def apply_style(self):
        c = palette(self.settings.state.get("theme", "midnight"), self.settings.state.get("accent"))
        self.css.load_from_data(f"""
        window {{ background: #{c['bg']}; color: #{c['fg']}; }}
        headerbar {{ background: #{c['surface']}; color: #{c['fg']}; border: none; }}
        stackswitcher, stacksidebar, stacksidebar list {{ background: #{c['bg']}; color: #{c['fg']}; }}
        stacksidebar row {{ padding: 14px 18px; }}
        stacksidebar row:selected {{ background: #{c['surface']}; color: #{c['accent']}; }}
        .title {{ font-size: 24px; font-weight: bold; }}
        .section {{ font-size: 17px; font-weight: bold; margin-top: 12px; }}
        .muted, .status {{ color: #{c['muted']}; }}
        button {{ background: #{c['surface']}; color: #{c['fg']}; border: 1px solid #{c['surface']}; border-radius: 8px; padding: 10px 14px; box-shadow: none; text-shadow: none; }}
        button:hover {{ border-color: #{c['accent']}; }}
        button.suggested-action {{ background: #{c['accent']}; color: #{c['bg']}; }}
        combobox button, spinbutton, entry {{ background: #{c['surface']}; color: #{c['fg']}; }}
        .card {{ border-radius: 12px; padding: 14px; }}
        """.encode())
        Gtk.StyleContext.add_provider_for_screen(Gdk.Screen.get_default(), self.css, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION)

    def page(self, name, title, description):
        scroll = Gtk.ScrolledWindow()
        scroll.set_policy(Gtk.PolicyType.NEVER, Gtk.PolicyType.AUTOMATIC)
        box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=16)
        for edge in ("start", "end", "top", "bottom"):
            getattr(box, "set_margin_" + edge)(28)
        box.pack_start(label(title, "title"), False, False, 0)
        box.pack_start(label(description, "muted"), False, False, 0)
        scroll.add(box)
        self.stack.add_titled(scroll, name, title)
        return box

    def action(self, callback, success):
        try:
            callback()
            self.status.set_text(success)
            self.apply_style()
        except Exception as error:
            self.status.set_text("The change could not be applied.")
            dialog = Gtk.MessageDialog(transient_for=self, modal=True, message_type=Gtk.MessageType.ERROR,
                                       buttons=Gtk.ButtonsType.CLOSE, text="Couldn't apply that change")
            dialog.format_secondary_text(str(error))
            dialog.run()
            dialog.destroy()

    def appearance_page(self):
        page = self.page("appearance", "Appearance", "Choose a coordinated look for your windows, top bar, launcher, terminal and notifications.")
        self.theme = self.settings.state.get("theme", "midnight")
        grid = Gtk.Grid(column_spacing=12, row_spacing=12, column_homogeneous=True)
        self.theme_buttons = {}
        for i, (key, colors) in enumerate(THEMES.items()):
            card = Gtk.Button()
            card.get_style_context().add_class("card")
            content = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=10)
            swatches = Gtk.Box(spacing=0)
            for field in ("bg", "surface", "accent", "blue", "green"):
                swatch = Gtk.Label(label=" ")
                swatch.set_size_request(40, 42)
                provider = Gtk.CssProvider()
                provider.load_from_data(f"label {{ background-color: #{colors[field]}; }}".encode())
                swatch.get_style_context().add_provider(provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION + 1)
                swatches.pack_start(swatch, True, True, 0)
            content.pack_start(swatches, False, False, 0)
            content.pack_start(label(colors['name']), False, False, 0)
            card.add(content)
            card.connect("clicked", lambda _button, selected=key: self.select_theme(selected))
            grid.attach(card, i % 2, i // 2, 1, 1)
            self.theme_buttons[key] = card
        page.pack_start(grid, False, False, 0)
        row = Gtk.Box(spacing=12)
        row.pack_start(label("Accent color"), True, True, 0)
        self.accent = Gtk.ColorButton(title="Choose an accent color")
        self.accent.set_property("use-alpha", False)
        row.pack_end(self.accent, False, False, 0)
        page.pack_start(row, False, False, 0)
        self.select_theme(self.theme, self.settings.state.get("accent"))
        page.pack_start(button("Apply theme", self.apply_theme, True), False, False, 0)
        page.pack_start(button("Undo last appearance change", self.undo), False, False, 0)
        page.pack_start(label("New terminal windows use the new colors. Individual applications may have their own theme settings.", "muted"), False, False, 0)

    def select_theme(self, key, accent=None):
        self.theme = key
        color = Gdk.RGBA()
        color.parse("#" + (accent or THEMES[key]['accent']))
        self.accent.set_rgba(color)
        for name, card in self.theme_buttons.items():
            context = card.get_style_context()
            (context.add_class if name == key else context.remove_class)("suggested-action")

    def apply_theme(self, _button):
        color = self.accent.get_rgba()
        accent = ''.join(f"{round(value * 255):02x}" for value in (color.red, color.green, color.blue))
        self.action(lambda: self.settings.apply_theme(self.theme, accent), "Theme saved. Open a new terminal to see its new colors.")

    def undo(self, _button):
        def restore():
            self.settings.undo()
            self.select_theme(self.settings.state.get('theme', 'midnight'), self.settings.state.get('accent'))
            self.update_wallpaper_preview()
        self.action(restore, "Your previous appearance has been restored.")

    def wallpaper_page(self):
        page = self.page("wallpaper", "Wallpaper", "Choose a built-in background or any picture on this computer. Applies to all connected displays.")
        self.wallpaper_image = Gtk.Image()
        page.pack_start(self.wallpaper_image, False, False, 0)
        self.wallpaper_name = label("Current wallpaper", "muted")
        page.pack_start(self.wallpaper_name, False, False, 0)
        self.update_wallpaper_preview()
        builtins = Gtk.Box(spacing=8, homogeneous=True)
        for title, file in (("Midnight hills", "midnight.svg"), ("Northern sky", "north.svg"), ("Desert dusk", "desert.svg")):
            item = button(title, lambda _b, name=file: self.choose_wallpaper(HERE / "wallpapers" / name))
            builtins.pack_start(item, True, True, 0)
        page.pack_start(builtins, False, False, 0)
        page.pack_start(button("Choose a picture…", self.browse_wallpaper), False, False, 0)
        fit_row = Gtk.Box(spacing=12)
        fit_row.pack_start(label("Picture fit"), True, True, 0)
        self.fit = Gtk.ComboBoxText()
        for key, title in (("cover", "Fill screen (crop edges)"), ("contain", "Fit whole picture"), ("tile", "Repeat as tiles")):
            self.fit.append(key, title)
        self.fit.set_active_id(self.settings.state.get("fit", "cover"))
        fit_row.pack_end(self.fit, False, False, 0)
        page.pack_start(fit_row, False, False, 0)
        page.pack_start(button("Apply wallpaper", self.apply_wallpaper, True), False, False, 0)
        page.pack_start(button("Undo last appearance change", self.undo), False, False, 0)
        page.pack_start(label("A copy is saved here, so moving the original picture won't break your wallpaper.", "muted"), False, False, 0)

    def update_wallpaper_preview(self):
        current = self.settings.state.get("wallpaper")
        if not current:
            import re
            found = re.search(r"^\s*path\s*=\s*(.+)$", self.settings.read("hypr/hyprpaper.conf"), re.M)
            current = found[1].strip() if found else None
        self.wallpaper_choice = Path(current).expanduser() if current else None
        if self.wallpaper_choice and self.wallpaper_choice.exists():
            self.choose_wallpaper(self.wallpaper_choice)

    def choose_wallpaper(self, path):
        try:
            preview = GdkPixbuf.Pixbuf.new_from_file_at_scale(str(path), 590, 245, True)
            self.wallpaper_image.set_from_pixbuf(preview)
            self.wallpaper_choice = Path(path)
            self.wallpaper_name.set_text(Path(path).name)
        except GLib.Error as error:
            self.status.set_text("Couldn't open this picture: " + str(error))

    def browse_wallpaper(self, _button):
        chooser = Gtk.FileChooserNative.new("Choose a wallpaper", self, Gtk.FileChooserAction.OPEN, "Choose", "Cancel")
        images = Gtk.FileFilter()
        images.set_name("Pictures")
        images.add_pixbuf_formats()
        chooser.add_filter(images)
        if chooser.run() == Gtk.ResponseType.ACCEPT:
            self.choose_wallpaper(chooser.get_filename())
        chooser.destroy()

    def apply_wallpaper(self, _button):
        def apply():
            path = self.wallpaper_choice
            if not path or not path.is_file():
                raise ValueError("Choose a picture first.")
            if path.stat().st_size > 100 * 1024 * 1024:
                raise ValueError("Choose an image smaller than 100 MB.")
            # Normalize to a bounded-size PNG, including bundled vector artwork.
            pixbuf = GdkPixbuf.Pixbuf.new_from_file_at_scale(str(path), 7680, 4320, True)
            digest = hashlib.sha256(path.read_bytes()).hexdigest()[:24]
            directory = Path(os.environ.get("XDG_DATA_HOME", Path.home() / ".local/share")) / "desktop-settings/wallpapers"
            directory.mkdir(parents=True, exist_ok=True)
            saved = directory / (digest + ".png")
            if not saved.exists():
                pixbuf.savev(str(saved), "png", [], [])
            self.settings.set_wallpaper(saved, self.fit.get_active_id())
        self.action(apply, "Wallpaper saved and applied to your displays.")

    def display_page(self):
        page = self.page("display", "Display", "Choose your screen size and text scale. Changes are previewed before you keep them.")
        self.monitor_combo = Gtk.ComboBoxText()
        self.mode_combo = Gtk.ComboBoxText()
        self.scale_combo = Gtk.ComboBoxText()
        for value, text in ((1, "100% — most workspace"), (1.25, "125%"), (1.333333, "133%"), (1.5, "150%"), (1.6, "160%"), (1.75, "175%"), (2, "200% — largest text")):
            self.scale_combo.append(str(value), text)
        self.display_summary = label("", "muted")
        for title, widget in (("Screen", self.monitor_combo), ("Resolution and refresh rate", self.mode_combo), ("Text and interface size", self.scale_combo)):
            page.pack_start(label(title, "section"), False, False, 0)
            page.pack_start(widget, False, False, 0)
        page.pack_start(self.display_summary, False, False, 0)
        page.pack_start(button("Preview display change", self.preview_display, True), False, False, 0)
        page.pack_start(button("Refresh connected displays", lambda _b: self.refresh_displays()), False, False, 0)
        page.pack_start(label("Higher refresh rates make motion smoother. Higher resolution gives more detail; a larger scale makes text bigger and leaves less room for windows.", "muted"), False, False, 0)
        self.monitor_combo.connect("changed", self.monitor_changed)
        self.mode_combo.connect("changed", self.update_display_summary)
        self.scale_combo.connect("changed", self.update_display_summary)
        self.refresh_displays()

    def refresh_displays(self):
        try:
            self.monitors = self.settings.monitors()
            self.monitor_combo.remove_all()
            for monitor in self.monitors:
                self.monitor_combo.append(monitor['name'], f"{monitor.get('model') or monitor['name']} · {monitor['name']}")
            self.monitor_combo.set_active(0)
        except Exception as error:
            self.status.set_text("Display controls unavailable: " + str(error))

    def monitor_changed(self, _combo):
        name = self.monitor_combo.get_active_id()
        monitor = next((m for m in self.monitors if m['name'] == name), None)
        if not monitor:
            return
        self.mode_combo.remove_all()
        modes = monitor.get('availableModes', [])
        best = None
        for i, mode in enumerate(modes):
            self.mode_combo.append(mode.removesuffix('Hz'), mode.replace('@', '  ·  '))
            try:
                size, hz = mode.removesuffix('Hz').split('@')
                if size == f"{monitor['width']}x{monitor['height']}" and abs(float(hz) - monitor['refreshRate']) < 0.1:
                    best = i
            except ValueError:
                continue
        if best is None:
            current = f"{monitor['width']}x{monitor['height']}@{monitor['refreshRate']}"
            self.mode_combo.append(current, current + " Hz (current)")
            best = len(modes)
        self.mode_combo.set_active(best)
        value = str(monitor['scale'])
        if float(value).is_integer():
            value = str(int(float(value)))
        self.scale_combo.set_active_id(value)
        if self.scale_combo.get_active() < 0:
            self.scale_combo.append(value, f"{float(value)*100:.1f}% (current)")
            self.scale_combo.set_active_id(value)
        self.update_display_summary()

    def update_display_summary(self, *_args):
        mode, scale = self.mode_combo.get_active_id(), self.scale_combo.get_active_id()
        if mode and scale:
            w, h = map(int, mode.split('@')[0].split('x'))
            self.display_summary.set_text(f"Usable workspace: about {round(w/float(scale))} × {round(h/float(scale))}.")

    def preview_display(self, _button):
        def preview():
            name = self.monitor_combo.get_active_id()
            monitor = next(m for m in self.settings.monitors() if m['name'] == name)
            mode, scale = self.mode_combo.get_active_id(), self.scale_combo.get_active_id()
            if not mode or not scale:
                raise ValueError("Select a resolution and scale first.")
            self.preview = DisplayPreview(self.settings, monitor, mode, scale)
            self.preview.start()
            dialog = Gtk.MessageDialog(transient_for=self, modal=True, message_type=Gtk.MessageType.QUESTION,
                                       buttons=Gtk.ButtonsType.NONE, text="Keep these display settings?")
            dialog.add_button("Revert", Gtk.ResponseType.CANCEL)
            dialog.add_button("Keep changes", Gtk.ResponseType.ACCEPT)
            dialog.set_default_response(Gtk.ResponseType.CANCEL)
            deadline = time.monotonic() + 20
            def tick():
                remaining = max(0, int(deadline - time.monotonic()))
                dialog.format_secondary_text(f"Reverting automatically in {remaining} seconds.")
                if remaining == 0:
                    dialog.response(Gtk.ResponseType.CANCEL)
                    return False
                return True
            tick()
            timer = GLib.timeout_add_seconds(1, tick)
            response = dialog.run()
            if time.monotonic() < deadline:
                GLib.source_remove(timer)
            dialog.destroy()
            try:
                if response == Gtk.ResponseType.ACCEPT and time.monotonic() < deadline:
                    self.preview.keep()
                else:
                    self.preview.revert()
            finally:
                if self.preview.active:
                    self.preview.revert()
                self.preview = None
                self.refresh_displays()
        self.action(preview, "Display settings updated. Only changes you kept are saved.")

    def launch(self, command):
        if not shutil.which(command[0]):
            self.status.set_text("This tool isn't installed: " + command[0])
            return
        subprocess.Popen(command, start_new_session=True)

    def devices_page(self):
        page = self.page("devices", "Sound & connections", "Open the controls for your speakers, Wi-Fi, wired network and Bluetooth devices.")
        for title, description, command in (
            ("Sound", "Choose speakers or headphones, adjust volume, and move each app's audio.", ["pavucontrol"]),
            ("Network", "Edit wired and Wi-Fi connections.", ["nm-connection-editor"]),
            ("Connect to Wi-Fi", "Choose a network using the interactive network manager.", ["foot", "-T", "Network Setup", "-e", "nmtui"]),
            ("Bluetooth", "Pair headphones, keyboards, mice and other devices.", ["blueman-manager"]),
        ):
            page.pack_start(label(title, "section"), False, False, 0)
            page.pack_start(label(description, "muted"), False, False, 0)
            page.pack_start(button("Open " + title.lower(), lambda _b, cmd=command: self.launch(cmd)), False, False, 0)

    def help_page(self):
        page = self.page("help", "Shortcuts & help", "Everyday controls for your desktop.")
        for title, description in (("Super + ,", "Open Settings"), ("Super + K", "Search the full shortcut list"), ("Super + T", "Swap tiled windows"), ("Super + W", "Close the focused window"), ("Super + Space", "Find and open an application")):
            row = Gtk.Box(spacing=16)
            key = label(title, "section")
            key.set_size_request(180, -1)
            row.pack_start(key, False, False, 0)
            row.pack_start(label(description), True, True, 0)
            page.pack_start(row, False, False, 0)
        page.pack_start(button("Show all keyboard shortcuts", lambda _b: self.launch([str(self.settings.config / "hypr/bin/shortcuts-menu.sh")])), False, False, 0)
        page.pack_start(button("Read the desktop guide", lambda _b: self.launch(["xdg-open", "https://github.com/funstuie-bit/arch-hyprland-guide#readme"])), False, False, 0)
        page.pack_start(label("Appearance changes have a one-step Undo. Display previews revert automatically if you don't keep them. No administrator password or AI connection is needed to change your appearance.", "muted"), False, False, 0)

    def on_close(self, *_args):
        if self.preview:
            self.preview.revert()
        return False


class Application(Gtk.Application):
    def __init__(self):
        super().__init__(application_id="org.archdesktop.Settings", flags=Gio.ApplicationFlags.HANDLES_COMMAND_LINE)
        self.requested_page = None

    def do_command_line(self, command_line):
        args = command_line.get_arguments()[1:]
        if args:
            if len(args) != 2 or args[0] != '--page' or args[1] not in ('appearance', 'wallpaper', 'display', 'devices', 'help'):
                return 2
            self.requested_page = args[1]
        self.activate()
        return 0

    def do_activate(self):
        window = self.get_active_window()
        if window is None:
            window = Window(self)
        if self.requested_page:
            window.stack.set_visible_child_name(self.requested_page)
            self.requested_page = None
        window.present()


if __name__ == "__main__":
    raise SystemExit(Application().run(sys.argv))
