# Window controls: Omarchy-like workflow, independent Arch implementation

Reviewed September 15, 2026 against the [Omarchy hotkey manual](https://learn.omacom.io/books/2/pages/53), [upstream tiling bindings](https://github.com/basecamp/omarchy/blob/master/default/hypr/bindings/tiling.lua), [layout defaults](https://github.com/basecamp/omarchy/blob/master/default/hypr/looknfeel.conf), and the locally installed Hyprland 0.56.2. Upstream may change; this is a documented compatibility snapshot, not a dependency on Omarchy updates.

The previous configuration did **not** reproduce that workflow: Super+T swapped split halves, keyboard resizing and directional swaps were absent, and several Mac-style aliases occupied Omarchy's desktop shortcuts. Those mismatches are corrected here. No Omarchy packages, updater, branding, or helper scripts are installed.

## Start here: get out of full-height columns

`Super` means the Command key on an Apple keyboard.

1. Focus one of two neighbouring tiles and press **Super+J**. Their split changes between side-by-side and top/bottom. It changes that pair/subtree, not every window at once; repeat on another pair if you want two stacks.
2. Resize their shared divider with **Super+right-drag**, or hold **Super+Shift+Minus/Equal** to adjust height. **Super+Minus/Equal** adjusts width.
3. For a window you can size and position independently, press **Super+T**. Then **Super+left-drag** moves it and **Super+right-drag** resizes it. Press Super+T again to return it to the tiled layout.
4. For a large browser with its tabs still visible, use **Super+Alt+F**. Press again to restore its tile.

A tiled window cannot leave a hole in the desktop just because you shrink its bottom edge. Its size is constrained by surrounding tiles. Four full-height tiles have vertical dividers but no horizontal divider to move. That is not the same as floating-window resizing being broken.

If a launcher, power menu, or cheatsheet is open, press Escape before using window controls: it holds keyboard focus rather than a normal application window.

## Core compatibility

| Shortcut | This desktop's action |
| --- | --- |
| Super+T | Toggle tiled/floating |
| Super+J | Toggle side-by-side/top-bottom split (dwindle) |
| Super+W (or Super+Q) | Close focused window |
| Super+Arrow | Focus neighbouring window |
| Super+Shift+Arrow | Swap with neighbouring window |
| Super+Minus / Equal | Width resize, 100 logical pixels per step; hold to repeat |
| Super+Shift+Minus / Equal | Height resize, 100 logical pixels per step |
| Add Alt to those resize keys | Smaller 25-pixel steps |
| Add Ctrl to those resize keys | Larger 300-pixel steps |
| Super+left-drag / right-drag | Move / resize; tiled windows remain constrained by the layout |
| Super+F | Fullscreen, including application fullscreen behaviour |
| Super+Alt+F | Maximize while keeping application tabs/chrome |
| Super+Ctrl+F | Request application fullscreen inside its existing tile |
| Super+P | Toggle pseudo-tiling (natural size inside a reserved tile) |
| Super+O | Float and pin across workspaces; repeat to unpin and retile |
| Super+L | Switch current workspace between dwindle and scrolling |
| Super+1…0 | Workspaces 1…10 |
| Super+Shift+1…0 | Move focused window to workspace and follow |
| Super+Shift+Alt+1…0 | Send focused window to workspace without following |
| Super+Tab / Super+Shift+Tab | Next / previous occupied workspace |
| Super+Ctrl+Tab | Previously used workspace |
| Alt+Tab / Alt+Shift+Tab | Next / previous application window |
| Ctrl+Alt+Tab / Ctrl+Alt+Shift+Tab | Next / previous monitor |
| Super+Shift+Alt+Arrow | Move workspace to directional monitor |
| Super+S / Super+Alt+S | Show scratchpad / send window there without following |
| Super+G / Super+Alt+G | Toggle group / remove window from group |
| Super+Alt+Arrow | Move window into adjacent group |
| Super+Alt+Tab / Super+Alt+Shift+Tab | Next / previous grouped window |
| Super+Ctrl+Left/Right | Previous / next grouped window |
| Super+Alt+1…5 | Select numbered window within group |
| Super+K | Search shortcuts; new described bindings are read from the running compositor |
| Super+Alt+Space | Local desktop-controls menu |
| Super+Shift+Space | Toggle top bar visibility |
| Super+Shift+F | File manager |
| Super+Ctrl+Shift+Space | Settings theme chooser |
| Super+Ctrl+Space | Settings wallpaper chooser |
| Super+Ctrl+A / B / W | Sound / Bluetooth / Wi-Fi controls |

In a tiled layout, the physical direction a divider moves depends on which side of the split is focused. The resize commands match the upstream signed deltas; the labels above describe the dimension rather than promising a particular edge moves left or right.

## Layouts, without installing a different desktop

**Dwindle** fills the available area with a tree of side-by-side and top/bottom splits. It remains the default. It preserves deliberate split orientations and places a new window on the right/bottom of a split, matching the reviewed upstream defaults. Existing windows are not automatically rearranged just by reloading the configuration.

**Scrolling** keeps columns at a comfortable width and moves the view as you focus windows. It does not force every open window to be visible at once. Super+L switches the current workspace back to dwindle when you want everything tiled into the available screen. This is an option, not a replacement imposed on all workspaces. As in the reviewed upstream helper, the toggle is a live workspace override, not a persistent preference saved by this script.

See Hyprland's [dwindle](https://wiki.hypr.land/Configuring/Layouts/Dwindle-Layout/) and [scrolling](https://wiki.hypr.land/Configuring/Layouts/Scrolling-Layout/) documentation for the underlying behaviour. Their latest examples use Lua; this installation still uses supported legacy `.conf` syntax. Do not paste current Lua snippets directly into `hyprland.conf`.

## Deliberate differences and work not included

- **Super+comma remains Settings**, not notification dismissal. The gear and launcher entry remain available too.
- **Ctrl+L is the browser address bar.** Super+L is now the layout switch. Super+R remains the existing refresh alias.
- Super+Shift+W still closes a window instead of launching a writing app. Existing Super+Shift+A and music shortcuts remain tied to the user's chosen applications, not commercial services.
- Sound, Bluetooth, and Wi-Fi shortcuts open pavucontrol, blueman-manager, and nmtui. The desktop menu is local Rofi plus the local Settings app, not Omarchy's installation/update menu.
- Super+E, bracket-based group navigation, Alt+mouse dragging, and middle-click floating remain useful extra aliases.
- Existing screenshot shortcuts are preserved. The complete Omarchy recording/OCR/dictation, reminder, notification, zoom, and web-app shortcut sets are **not** reproduced by this change.
- Monitor scaling stays in Settings with a preview/recovery timer; no instant scaling shortcuts were added. Resolution, theme selection, networking, and audio output are not changed by this update.
- The destructive close-all-windows shortcut is not added. App preferences, terminal/tmux layouts, and application-specific keybindings are separate from window-manager controls.

## Maintain and test

Most added controls live in `~/.config/hypr/window-controls.conf`, sourced by `hyprland.conf`. Its `bindd`/`binded` descriptions appear automatically in Super+K. The local menu/layout/pin helper is `~/.config/hypr/bin/window-controls.sh`. Change those files or add a later-sourced overrides file; nothing requires an AI connection or Omarchy tooling. Use Hyprland's `unbind` before replacing an existing combination.

The repository installer copies both files with the rest of `dotfiles/hypr`; **do not rerun the full installer merely to update shortcuts**. Existing copies must be backed up and deployed explicitly.

Non-disruptive checks:

```bash
bash -n dotfiles/hypr/bin/window-controls.sh dotfiles/hypr/bin/shortcuts-menu.sh
python -m unittest discover -s settings -v
hyprctl configerrors
```

An optional live test creates disposable Foot windows on an unused workspace, resolves the registered shortcut actions from `hyprctl binds`, exercises them, closes only those test windows, then restores workspace/focus. This tests the configured actions, not physical key presses or mouse dragging. Close any menus and leave the keyboard/mouse alone while it runs:

```bash
python tests/window_controls_live.py --live
```

Before the September 15 change, the live Hyprland directory was backed up to `/home/stu/window-controls-backup.WFHQQl/hypr`; the Settings UI source was also backed up alongside it. Restoring that backup would also restore the incorrect Super+T binding. A later local theme selection should be preserved when making selective config repairs.
