"""Opt-in live test: python tests/window_controls_live.py --live.

Creates two disposable Foot windows on an unused workspace, tests loaded bindings,
then closes only those windows and restores the original workspace and focus.
Do not use the keyboard/mouse during the short test.
"""
import json
from pathlib import Path
import subprocess
import sys
import time
import uuid


def run(*args):
    return subprocess.check_output(args, text=True).strip()


def query(name):
    return json.loads(run('hyprctl', '-j', name))


def dispatch(name, args=''):
    result = run('hyprctl', 'dispatch', name, args)
    assert result == 'ok', result
    time.sleep(0.6)


def main():
    if sys.argv[1:] != ['--live']:
        raise SystemExit('This briefly changes focus. Explicitly pass --live to run.')
    layers = query('layers')
    if any(layer.get('namespace') in ('rofi', 'hyprlock')
           for monitor in layers.values() for level in monitor.get('levels', {}).values()
           for layer in level):
        raise SystemExit('Close the launcher/menu or unlock the desktop before testing.')
    original = query('activeworkspace')['id']
    original_window = query('activewindow').get('address')
    original_cursor = query('cursorpos')
    tag = 'arch-window-test-' + uuid.uuid4().hex[:10]
    workspace = str(max([97] + [w['id'] for w in query('workspaces')]) + 1)
    helper = str(Path.home() / '.config/hypr/bin/window-controls.sh')

    def windows():
        return [w for w in query('clients') if w['class'] == tag]

    def key(key, *modifiers):
        assert query('activewindow').get('class') == tag, 'Focus left test windows'
        mask = sum({'logo': 64, 'shift': 1, 'ctrl': 4, 'alt': 8}[m] for m in modifiers)
        bindings = [b for b in query('binds') if b['modmask'] == mask
                    and (b['key'].casefold() == key.casefold()
                         or b['keycode'] == {'equal': 21, 'minus': 20}.get(key, -1))]
        assert len(bindings) == 1, (key, mask, bindings)
        # Exercise the action actually registered for this combination. Virtual
        # keyboard injection is not a reliable physical-key test in Hyprland.
        dispatch(bindings[0]['dispatcher'], bindings[0]['arg'])
        time.sleep(0.3)

    try:
        for i in range(2):
            dispatch('exec', f'[{"workspace " + workspace} silent] foot -a {tag} -T "Window control test {i + 1}"')
        for _ in range(40):
            if len(windows()) == 2:
                break
            time.sleep(0.1)
        assert len(windows()) == 2, 'Test windows did not open'
        dispatch('workspace', workspace)
        first = windows()[0]
        dispatch('movecursor', f"{first['at'][0] + first['size'][0] // 2} {first['at'][1] + first['size'][1] // 2}")
        dispatch('focuswindow', 'address:' + windows()[0]['address'])
        key('t', 'logo')
        assert query('activewindow')['floating'], 'Super+T did not float'
        before = query('activewindow')['size']
        key('equal', 'logo')
        after = query('activewindow')['size']
        assert after[0] > before[0], (before, after)
        key('equal', 'logo', 'shift')
        assert query('activewindow')['size'][1] > after[1], 'Height did not grow'
        key('t', 'logo')
        assert not query('activewindow')['floating'], 'Super+T did not retile'
        print('PASS loaded Super+T; width and height resize actions', flush=True)

        before = {w['address']: (w['at'], w['size']) for w in windows()}
        key('j', 'logo')
        after = {w['address']: (w['at'], w['size']) for w in windows()}
        assert before != after, 'Super+J did not change split'
        pair = windows()
        assert pair[0]['at'][1] != pair[1]['at'][1], 'Expected top/bottom split'
        before_size = query('activewindow')['size'][1]
        key('equal', 'logo', 'shift')
        assert query('activewindow')['size'][1] != before_size, 'Tiled height did not change'
        print('PASS top/bottom split and tiled vertical resizing', flush=True)

        pair = sorted(windows(), key=lambda w: w['at'][1])
        dispatch('focuswindow', 'address:' + pair[0]['address'])
        key('Down', 'logo', 'shift')
        assert query('activewindow')['at'][1] > pair[0]['at'][1], 'Directional swap failed'
        print('PASS loaded Super+Shift+Down directional swap', flush=True)

        key('f', 'logo', 'alt')
        assert query('activewindow')['fullscreen'] == 1, 'Maximize failed'
        key('f', 'logo', 'alt')
        assert query('activewindow')['fullscreen'] == 0, 'Maximize restore failed'
        key('f', 'logo', 'ctrl')
        assert query('activewindow')['fullscreen'] == 0
        assert query('activewindow')['fullscreenClient'] == 2
        key('f', 'logo', 'ctrl')
        assert query('activewindow')['fullscreenClient'] == 0
        print('PASS maximize and application-fullscreen-inside-tile toggles', flush=True)

        key('l', 'logo')
        assert query('activeworkspace')['tiledLayout'] == 'scrolling', 'No scrolling layout'
        key('l', 'logo')
        assert query('activeworkspace')['tiledLayout'] == 'dwindle', 'No dwindle layout'
        print('PASS loaded Super+L switches both layouts', flush=True)

        run(helper, 'pop')
        assert query('activewindow')['pinned'] and query('activewindow')['floating']
        run(helper, 'pop')
        assert not query('activewindow')['pinned'] and not query('activewindow')['floating']
        print('PASS floating/pinned pop and restore', flush=True)
        assert not run('hyprctl', 'configerrors')
    finally:
        for window in windows():
            dispatch('closewindow', 'address:' + window['address'])
        dispatch('workspace', str(original))
        dispatch('movecursor', f"{original_cursor['x']} {original_cursor['y']}")
        if original_window and any(w['address'] == original_window for w in query('clients')):
            dispatch('focuswindow', 'address:' + original_window)


if __name__ == '__main__':
    main()
