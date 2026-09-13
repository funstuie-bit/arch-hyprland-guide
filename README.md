# A clean Arch + Hyprland setup for a 2018 Mac mini

This guide describes a small, independently configured desktop inspired by the useful parts of Omarchy:

- fast keyboard-driven window management;
- normal mouse use, including moving and resizing windows;
- a simple launcher, status bar, terminal, notifications, and graphical file manager;
- no Omarchy shell, themes, update layer, or bundled configuration.

The examples assume a 2018 Intel Mac mini. That model has Apple's T2 chip, so read the T2 Linux installation instructions before starting.

## Before you install

Back up anything important. Decide whether you are replacing macOS or dual-booting, and make sure you have a second computer or phone available if you need to troubleshoot.

The 2018 Mac mini is a T2 Mac. Use the [T2 Linux Arch installation guide](https://wiki.t2linux.org/distributions/arch/installation/) and its recommended T2-aware installation media/kernel. The regular Arch installer may boot while leaving Wi-Fi, Bluetooth, audio, or other hardware incomplete.

For a guided installation, see [Archinstall](https://wiki.archlinux.org/title/Archinstall). Install a UEFI system with:

- NetworkManager;
- a normal user with `sudo` access;
- the T2 Linux kernel and support packages recommended by T2 Linux;
- no desktop environment initially.

Do not run a large third-party desktop bootstrap script unless you have read it and are comfortable maintaining everything it changes.

## Install the desktop pieces

After booting into the new system:

```bash
sudo pacman -Syu

sudo pacman -S \
  hyprland waybar wofi foot \
  thunar file-roller \
  mako \
  pipewire pipewire-audio pipewire-pulse pipewire-alsa wireplumber \
  network-manager-applet \
  pavucontrol \
  bluez bluez-utils \
  xdg-desktop-portal-hyprland xdg-desktop-portal-gtk \
  hyprlock hypridle \
  grim slurp wl-clipboard \
  brightnessctl playerctl \
  polkit-gnome \
  git
```

Enable networking and Bluetooth if needed:

```bash
sudo systemctl enable --now NetworkManager
sudo systemctl enable --now bluetooth
```

Hyprland needs a Polkit authentication agent or `seatd`. Start `polkit-gnome` from your session if you use it. Audio is normally provided by PipeWire and WirePlumber; the ArchWiki has further [PipeWire details](https://wiki.archlinux.org/title/PipeWire).

## Start Hyprland

You can select Hyprland from a display manager, or start it from a TTY with:

```bash
start-hyprland
```

On current Hyprland releases, configuration is Lua-based. Start with the generated example at `~/.config/hypr/hyprland.lua`, then split your own configuration into small files as it grows. Use the [current Hyprland documentation](https://wiki.hypr.land/) for the syntax installed on your machine; older examples using `bind = ...` may not apply to newer releases.

## Mouse behavior

Hyprland supports normal mouse use. A useful convention is:

- `Alt` + left-drag: move the active window;
- `Alt` + right-drag: resize the active window;
- optionally, `Alt` + left-click: toggle floating.

For current Lua configuration, the mouse bindings are:

```lua
hl.bind("ALT + mouse:272", hl.dsp.window.drag(), {
    mouse = true
})

hl.bind("ALT + mouse:273", hl.dsp.window.resize(), {
    mouse = true
})
```

Left mouse is `mouse:272`; right mouse is `mouse:273`. See the [Hyprland mouse-bind documentation](https://wiki.hypr.land/configuring/core/binds/devices/mouse/).

If you prefer a more traditional desktop, configure most windows as floating or use KDE Plasma instead of Hyprland. Hyprland does not require you to use strict tiling all the time.

## A small keyboard layout

Keep the initial keymap deliberately small:

| Shortcut | Action |
| --- | --- |
| `Super + Enter` | Open terminal |
| `Super + Space` | Open application launcher |
| `Super + Q` | Close active window |
| `Super + F` | Toggle fullscreen |
| `Super + 1..9` | Switch workspace |
| `Super + Shift + 1..9` | Move window to workspace |
| `Super + E` | Open file manager |
| `Super + B` | Open browser |

Use `waybar` for the bar, `wofi` for the launcher, `foot` for the terminal, `mako` for notifications, and `thunar` for graphical file management. Each is a separate package and can be replaced without replacing the desktop.

## Sensible next additions

Add these only when you need them:

- a browser such as Firefox or Chromium;
- `polkit-gnome` startup if graphical authentication prompts do not appear;
- `hyprlock` and `hypridle` startup for locking and idle handling;
- `grim` and `slurp` bindings for screenshots;
- `pavucontrol` for detailed audio control;
- `blueman` if you prefer a graphical Bluetooth manager;
- a display manager such as `greetd` only after the TTY setup works.

Keep configuration in `~/.config/`. Avoid editing package-owned files under `/usr/share`, and keep a copy of your configuration in this repository so the system remains reproducible.

## Troubleshooting principles

1. Check the T2 Linux documentation first for Mac-specific hardware problems.
2. Check the ArchWiki and the current upstream Hyprland documentation for package or syntax changes.
3. Test one component at a time: compositor, network, audio, portals, then applications.
4. Prefer official Arch packages; use the AUR only when a needed package is unavailable in the official repositories.
5. After changing Hyprland configuration, reload and inspect errors:

   ```bash
   hyprctl reload
   hyprctl configerrors
   ```

## Alternatives

- **KDE Plasma on Wayland:** best if mouse-first interaction and familiar desktop controls matter more than tiling.
- **Sway + Waybar:** a simpler, more conservative keyboard-driven Wayland desktop.
- **Hyprland:** the closest fit to the Omarchy experience, while remaining independently configurable.

For the preferences described here, start with Hyprland and a short configuration. Add polish only after the basic mouse, keyboard, networking, audio, and suspend behavior are reliable.
