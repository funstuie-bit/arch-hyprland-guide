"""Desktop Settings: narrow, reversible edits to this desktop's configuration."""
import base64
import hashlib
import json
import os
from pathlib import Path
import re
import subprocess
import tempfile
import uuid


THEMES = {
    "midnight": dict(name="Midnight", bg="1e1e2e", surface="313244", fg="cdd6f4", muted="a6adc8", accent="cba6f7", blue="89b4fa", red="f38ba8", green="a6e3a1", yellow="f9e2af", pink="f5c2e7", cyan="94e2d5", light=False),
    "nord": dict(name="Northern sky", bg="2e3440", surface="434c5e", fg="eceff4", muted="d8dee9", accent="88c0d0", blue="81a1c1", red="bf616a", green="a3be8c", yellow="ebcb8b", pink="b48ead", cyan="8fbcbb", light=False),
    "forest": dict(name="Forest", bg="202b27", surface="34443b", fg="e2ead8", muted="afc3ac", accent="a9cb8d", blue="90b7c2", red="e79686", green="a6c98c", yellow="e1c58e", pink="c6a0b6", cyan="87bdb1", light=False),
    "paper": dict(name="Warm paper", bg="f4efe6", surface="e3dbcf", fg="343b42", muted="626b72", accent="7659a3", blue="356a9a", red="a73943", green="426b41", yellow="886020", pink="92536e", cyan="286f73", light=True),
}


def run(args, timeout=10):
    result = subprocess.run(args, text=True, capture_output=True, timeout=timeout)
    if result.returncode:
        raise RuntimeError((result.stderr or result.stdout or "Command failed").strip())
    return result.stdout.strip()


def atomic_write(path, content):
    path = Path(path)
    if path.is_symlink():
        raise RuntimeError(f"{path.name} is a symbolic link. Its linked configuration needs a separate edit.")
    path.parent.mkdir(parents=True, exist_ok=True)
    mode = path.stat().st_mode & 0o777 if path.exists() else 0o600
    fd, temporary = tempfile.mkstemp(dir=path.parent, prefix=".settings-")
    try:
        with os.fdopen(fd, "wb") as stream:
            stream.write(content)
        os.chmod(temporary, mode)
        os.replace(temporary, path)
    finally:
        if os.path.exists(temporary):
            os.unlink(temporary)


def block(text, body, css=False):
    start, end = ("/* desktop-settings:start */", "/* desktop-settings:end */") if css else ("# desktop-settings:start", "# desktop-settings:end")
    text = re.sub(re.escape(start) + r".*?" + re.escape(end) + r"\n?", "", text, flags=re.S)
    return text.rstrip() + "\n\n" + start + "\n" + body.strip() + "\n" + end + "\n"


def ini_set(text, section, values):
    """Set exact keys in one section, retaining comments and unrelated settings."""
    lines = text.splitlines()
    header = f"[{section}]" if section else None
    if header and header not in lines:
        lines.extend(["", header])
    start = lines.index(header) + 1 if header else 0
    end = next((i for i in range(start, len(lines)) if lines[i].lstrip().startswith("[")), len(lines))
    remaining = dict(values)
    for i in range(start, end):
        match = re.match(r"\s*([^#;=]+?)\s*=", lines[i])
        if match and match[1] in values:
            lines[i] = f"{match[1]}={values[match[1]]}"
            remaining.pop(match[1], None)
    lines[end:end] = [f"{key}={value}" for key, value in remaining.items()]
    return "\n".join(lines) + "\n"


def palette(theme, accent=None):
    colors = THEMES[theme].copy()
    if accent:
        if not re.fullmatch(r"[0-9a-fA-F]{6}", accent):
            raise ValueError("Choose a valid accent color.")
        colors["accent"] = accent.lower()
    return colors


def theme_files(read, colors):
    c = colors
    hypr = f"""general {{
    col.active_border = rgba({c['accent']}ee) rgba({c['blue']}ee) 45deg
    col.inactive_border = rgba({c['surface']}aa)
}}
group {{
    col.border_active = rgba({c['accent']}ee)
    col.border_inactive = rgba({c['surface']}aa)
    groupbar {{
        text_color = rgba({c['fg']}ff)
        col.active = rgba({c['surface']}ff)
        col.inactive = rgba({c['bg']}ff)
    }}
}}"""
    modules = "#custom-menu, #custom-settings, #workspaces, #window, #clock, #pulseaudio, #cpu, #memory, #network, #custom-clipboard, #custom-shortcuts, #tray, #custom-power"
    css = f"""window#waybar {{ color: #{c['fg']}; }}
{modules} {{ background: #{c['bg']}; color: #{c['fg']}; border-color: #{c['surface']}; }}
#workspaces button {{ color: #{c['muted']}; }}
#workspaces button.active {{ background: #{c['accent']}; color: #{c['bg']}; }}
#workspaces button.urgent {{ background: #{c['red']}; color: #{c['bg']}; }}
#custom-menu, #custom-settings, #custom-shortcuts, #custom-clipboard {{ color: #{c['accent']}; }}
#pulseaudio {{ color: #{c['green']}; }}
#custom-power, #network.disconnected {{ color: #{c['red']}; }}
#pulseaudio.muted {{ background: #{c['surface']}; color: #{c['muted']}; }}
#custom-menu:hover, #custom-settings:hover, #window:hover, #clock:hover,
#pulseaudio:hover, #cpu:hover, #memory:hover, #network:hover,
#custom-clipboard:hover, #custom-shortcuts:hover, #custom-power:hover {{
    background: #{c['surface']}; color: #{c['fg']}; border-color: #{c['accent']};
}}"""
    rofi = f"""* {{
    bg: #{c['bg']}; bg-alt: #{c['surface']}; fg: #{c['fg']};
    fg-dim: #{c['muted']}; fg-muted: #{c['muted']}; accent: #{c['accent']};
    accent-alt: #{c['blue']}; selected-bg: #{c['surface']};
    selected-border: #{c['accent']}; border-subtle: #{c['surface']};
}}
element selected.normal, element selected.active {{ text-color: #{c['fg']}; }}
error-message {{ text-color: #{c['red']}; }}"""
    terminal = {"background": c["bg"], "foreground": c["fg"]}
    ansi = [c['surface'], c['red'], c['green'], c['yellow'], c['blue'], c['pink'], c['cyan'], c['fg']]
    for i, color in enumerate(ansi):
        terminal[f"regular{i}"] = color
        terminal[f"bright{i}"] = color if i else c['muted']
    mako = ini_set(read("mako/config"), "", {"background-color": "#" + c['bg'] + "f5", "text-color": "#" + c['fg'], "border-color": "#" + c['accent'], "progress-color": "over #" + c['accent'] + "55"})
    mako = ini_set(mako, "urgency=high", {"border-color": "#" + c['red']})
    mako = ini_set(mako, "app-name=desktop-volume", {"border-color": "#" + c['accent'], "progress-color": "over #" + c['accent'] + "55"})
    return {
        "hypr/hyprland.conf": block(read("hypr/hyprland.conf"), hypr),
        "waybar/style.css": block(read("waybar/style.css"), css, True),
        "rofi/config.rasi": block(read("rofi/config.rasi"), rofi, True),
        "foot/foot.ini": ini_set(read("foot/foot.ini"), "colors-dark", terminal),
        "mako/config": mako,
    }


class Settings:
    def __init__(self, config=None, data=None, runner=run):
        self.config = Path(config or os.environ.get("XDG_CONFIG_HOME", Path.home() / ".config"))
        self.data = Path(data or Path(os.environ.get("XDG_STATE_HOME", Path.home() / ".local/state")) / "desktop-settings")
        self.state_path = self.config / "desktop-settings/state.json"
        self.undo_path = self.data / "undo.json"
        self.run = runner
        self.state = json.loads(self.state_path.read_text()) if self.state_path.exists() else {}

    def read(self, name):
        path = self.config / name
        return path.read_text() if path.exists() else ""

    def reload(self):
        self.run(["hyprctl", "reload"])
        errors = self.run(["hyprctl", "configerrors"])
        if errors:
            raise RuntimeError(errors)
        self.run(["makoctl", "reload"])
        # Waybar's default SIGUSR2 action reloads configuration and style.
        try:
            self.run(["pkill", "-USR2", "-x", "waybar"])
        except RuntimeError:
            pass  # The bar may not be running in this session.
        wallpaper = self.state.get("wallpaper")
        if wallpaper:
            for monitor in self.monitors():
                self.run(["hyprctl", "hyprpaper", "wallpaper", f"{monitor['name']},{wallpaper},{self.state.get('fit', 'cover')}"])

    def apply(self, files, state):
        """Keep a before/after journal, and restore files if a reload fails."""
        files = {name: text.encode() for name, text in files.items()}
        files["desktop-settings/state.json"] = (json.dumps(state, indent=2) + "\n").encode()
        entries = {}
        for name, content in files.items():
            path = self.config / name
            if path.is_symlink():
                raise RuntimeError(f"{name} is linked to another file; this app will not replace that link.")
            entries[name] = {"before": base64.b64encode(path.read_bytes()).decode() if path.exists() else None,
                             "after": hashlib.sha256(content).hexdigest()}
        previous = self.state.copy()
        written = []
        try:
            for name, content in files.items():
                atomic_write(self.config / name, content)
                written.append(name)
            self.state = state
            self.reload()
            atomic_write(self.undo_path, json.dumps({"entries": entries, "state": previous}).encode())
        except Exception:
            for name in reversed(written):
                self.restore_file(name, entries[name]["before"])
            self.state = previous
            try:
                self.reload()
            except Exception:
                pass
            raise

    def restore_file(self, name, encoded):
        path = self.config / name
        if encoded is None:
            path.unlink(missing_ok=True)
        else:
            atomic_write(path, base64.b64decode(encoded))

    def undo(self):
        if not self.undo_path.exists():
            raise RuntimeError("There is no appearance change to undo yet.")
        journal = json.loads(self.undo_path.read_text())
        for name, entry in journal["entries"].items():
            path = self.config / name
            if not path.exists() or hashlib.sha256(path.read_bytes()).hexdigest() != entry["after"]:
                raise RuntimeError("A configuration file has changed since the last appearance update. Undo would overwrite that edit.")
        current = {name: (self.config / name).read_bytes() for name in journal['entries']}
        current_state = self.state.copy()
        try:
            for name, entry in journal["entries"].items():
                self.restore_file(name, entry["before"])
            self.state = journal["state"]
            self.reload()
        except Exception:
            for name, content in current.items():
                atomic_write(self.config / name, content)
            self.state = current_state
            try:
                self.reload()
            except Exception:
                pass
            raise
        self.undo_path.unlink()

    def apply_theme(self, name, accent):
        colors = palette(name, accent)
        self.apply(theme_files(self.read, colors), dict(self.state, theme=name, accent=colors['accent']))

    def set_wallpaper(self, path, fit):
        if fit not in ("cover", "contain", "tile"):
            raise ValueError("Unsupported wallpaper fit.")
        # The UI decodes and stores a PNG under an app-controlled path first.
        if not Path(path).is_file() or any(c in str(path) for c in "\n\r,#{}"):
            raise ValueError("Wallpaper path is invalid.")
        body = f"ipc = on\nsplash = false\n\nwallpaper {{\n    monitor =\n    path = {path}\n    fit_mode = {fit}\n}}\n"
        previous = self.state.copy()
        if not self.state.get("wallpaper"):
            found = re.search(r"^\s*path\s*=\s*(.+)$", self.read("hypr/hyprpaper.conf"), re.M)
            if found:
                self.state["wallpaper"] = found[1].strip()
                self.state["fit"] = "cover"
        try:
            self.apply({"hypr/hyprpaper.conf": body}, dict(self.state, wallpaper=str(path), fit=fit))
        except Exception:
            self.state = previous
            raise

    def monitors(self):
        return json.loads(self.run(["hyprctl", "-j", "monitors"]))

    def save_display(self, name, mode, scale, position):
        line = f"monitor = {name}, {mode}, {position}, {scale}"
        text = self.read("hypr/hyprland.conf")
        pattern = r"^\s*monitor\s*=\s*" + re.escape(name) + r"\s*,.*$"
        if re.search(pattern, text, re.M):
            text = re.sub(pattern, line, text, flags=re.M)
        else:
            text += "\n" + line + "\n"
        original = self.read("hypr/hyprland.conf")
        atomic_write(self.config / "hypr/hyprland.conf", text.encode())
        try:
            self.run(["hyprctl", "reload"])
            errors = self.run(["hyprctl", "configerrors"])
            if errors:
                raise RuntimeError(errors)
        except Exception:
            atomic_write(self.config / "hypr/hyprland.conf", original.encode())
            self.run(["hyprctl", "reload"])
            raise


class DisplayPreview:
    """An independent systemd timer restores the mode even if the UI crashes."""
    def __init__(self, settings, monitor, mode, scale):
        if not re.fullmatch(r"\d+x\d+@\d+(?:\.\d+)?", mode) or not re.fullmatch(r"\d+(?:\.\d+)?", str(scale)):
            raise ValueError("Select a valid resolution and scale.")
        if not 0.5 <= float(scale) <= 4:
            raise ValueError("Choose a scale between 50% and 400%.")
        self.settings, self.monitor, self.mode, self.scale = settings, monitor, mode, scale
        self.position = f"{monitor['x']}x{monitor['y']}"
        self.old = f"{monitor['name']},{monitor['width']}x{monitor['height']}@{monitor['refreshRate']},{self.position},{monitor['scale']}"
        self.unit = "desktop-settings-display-" + uuid.uuid4().hex
        self.active = False

    def start(self):
        sig = os.environ.get("HYPRLAND_INSTANCE_SIGNATURE")
        if not sig:
            raise RuntimeError("Open Settings from your Hyprland desktop to change the display.")
        self.settings.run(["systemd-run", "--user", "--unit=" + self.unit, "--on-active=25s", "/usr/bin/hyprctl", "-i", sig, "keyword", "monitor", self.old])
        self.active = True
        try:
            self.settings.run(["hyprctl", "keyword", "monitor", f"{self.monitor['name']},{self.mode},{self.position},{self.scale}"])
        except Exception:
            self.revert()
            raise

    def revert(self):
        if self.active:
            self.settings.run(["hyprctl", "keyword", "monitor", self.old])
            self.settings.run(["systemctl", "--user", "stop", self.unit + ".timer"])
            self.active = False

    def keep(self):
        if self.active:
            self.settings.save_display(self.monitor['name'], self.mode, self.scale, self.position)
            self.settings.run(["systemctl", "--user", "stop", self.unit + ".timer"])
            self.active = False
