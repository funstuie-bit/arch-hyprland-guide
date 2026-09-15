"""Opt-in actual WayVNC input test; temporary windows, no user app input.

Run with --live and leave keyboard/mouse alone until it finishes. Requires the
local authenticated WayVNC service. Password is never printed. Reuses the test
workspace lifecycle and restores focus/cursor afterwards.
"""
from pathlib import Path
import json
import socket
import struct
import subprocess
import sys
import time
import uuid
from vnc_smoke import receive


def run(*args):
    return subprocess.check_output(args, text=True).strip()


def query(name):
    return json.loads(run('hyprctl', '-j', name))


def dispatch(action, args=''):
    reply = run('hyprctl', 'dispatch', action, args)
    assert reply == 'ok', reply
    time.sleep(0.25)


def connect():
    config = dict(line.split('=', 1) for line in (Path.home() / '.config/wayvnc/config').read_text().splitlines()
                  if '=' in line and not line.lstrip().startswith('#'))
    sock = socket.create_connection((config['address'], int(config.get('port', '5900'))), timeout=10)
    receive(sock, 12)
    sock.sendall(b'RFB 003.008\n')
    assert 2 in receive(sock, receive(sock, 1)[0])
    sock.sendall(b'\x02')
    challenge = receive(sock, 16)
    key = bytes(int(f'{b:08b}'[::-1], 2) for b in config['password'].encode('ascii')[:8].ljust(8, b'\0'))
    result = subprocess.run(['openssl', 'enc', '-des-ecb', '-provider', 'default', '-provider', 'legacy',
                             '-K', key.hex(), '-nopad', '-nosalt'], input=challenge, capture_output=True)
    assert result.returncode == 0, 'DES test unavailable'
    sock.sendall(result.stdout)
    assert receive(sock, 4) == b'\0\0\0\0', 'Authentication failed'
    sock.sendall(b'\x01')
    header = receive(sock, 24)
    receive(sock, struct.unpack('!I', header[20:24])[0])
    return sock


def main():
    if sys.argv[1:] != ['--live']:
        raise SystemExit('Pass --live. This temporarily moves the pointer on a test workspace.')
    original = query('activeworkspace')['id']
    focus = query('activewindow').get('address')
    cursor = query('cursorpos')
    tag = 'tiling-input-test-' + uuid.uuid4().hex[:8]
    workspace = str(max([97] + [w['id'] for w in query('workspaces')]) + 1)
    sock = connect()
    def windows():
        return [w for w in query('clients') if w['class'] == tag]
    def key(symbol, down):
        sock.sendall(struct.pack('!BBHI', 4, int(down), 0, symbol))
        time.sleep(0.08)
    def pointer(x, y, buttons=0):
        sock.sendall(struct.pack('!BBHH', 5, buttons, int(x), int(y)))
        time.sleep(0.12)
    try:
        for _ in range(2):
            dispatch('exec', f'[workspace {workspace} silent] foot -a {tag}')
        for _ in range(30):
            if len(windows()) == 2:
                break
            time.sleep(0.1)
        assert len(windows()) == 2
        dispatch('workspace', workspace)
        time.sleep(0.5)
        pair = sorted(windows(), key=lambda w: w['at'][0])
        first = pair[0]
        pointer(first['at'][0] + first['size'][0] / 2, first['at'][1] + 300)
        assert query('activewindow').get('class') == tag
        # Actual VNC Super+J, not a direct layout dispatcher call.
        key(0xffeb, True)
        key(ord('j'), True)
        key(ord('j'), False)
        key(0xffeb, False)
        time.sleep(0.4)
        assert len({w['at'][1] for w in windows()}) == 2, 'Actual Super+J did not stack windows'
        print('PASS actual VNC Super+J creates top/bottom tiles', flush=True)
        # Restore columns, then drag one tile onto the TOP of the other.
        dispatch('layoutmsg', 'togglesplit')
        pair = sorted(windows(), key=lambda w: w['at'][0])
        first, second = pair
        x = first['at'][0] + first['size'][0] / 2
        y = first['at'][1] + 300
        pointer(x, y)
        key(0xffeb, True)
        pointer(x, y, 1)
        # During drag the target expands; drop near its top edge, away from corners.
        for t in range(1, 9):
            pointer(x + (3000 - x) * t / 8, y + (220 - y) * t / 8, 1)
        pointer(3000, 220)
        key(0xffeb, False)
        time.sleep(0.5)
        pair = sorted(windows(), key=lambda w: w['at'][1])
        assert all(not w['floating'] for w in pair), 'Drag left a floating window'
        assert pair[0]['at'][1] != pair[1]['at'][1], 'Top drop did not create horizontal divider'
        print('PASS real pointer drag/drop creates top/bottom tiles', flush=True)
        top = pair[0]
        x = top['at'][0] + top['size'][0] - 200
        y = top['at'][1] + top['size'][1] - 100
        pointer(x, y)
        key(0xffeb, True)
        pointer(x, y, 4)
        for delta in range(30, 151, 30):
            pointer(x, y + delta, 4)
        pointer(x, y + 150)
        key(0xffeb, False)
        time.sleep(0.4)
        resized = next(w for w in windows() if w['address'] == top['address'])
        assert resized['size'][1] != top['size'][1], 'Vertical mouse resizing had no effect'
        print('PASS real right-drag changes tiled window HEIGHT', flush=True)
        pair = sorted(windows(), key=lambda w: w['at'][1])
        dispatch('focuswindow', 'address:' + pair[1]['address'])
        dispatch('moveintoorcreategroup', 'u')
        assert all(len(w['grouped']) == 2 for w in windows()), 'Tab grouping failed'
        before = query('activewindow')['address']
        dispatch('changegroupactive', 'f')
        assert query('activewindow')['address'] != before, 'Tab switching failed'
        print('PASS two windows form a tab group and switch tabs', flush=True)
    finally:
        key(0xffeb, False)
        pointer(cursor['x'], cursor['y'])
        sock.close()
        for window in windows():
            dispatch('closewindow', 'address:' + window['address'])
        dispatch('workspace', str(original))
        dispatch('movecursor', f"{cursor['x']} {cursor['y']}")
        if focus:
            dispatch('focuswindow', 'address:' + focus)


if __name__ == '__main__':
    main()
