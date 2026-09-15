"""Small local control panel for the optional WayVNC service. No credentials in repo."""
import ipaddress
import json
import os
from pathlib import Path
import re
import subprocess

import gi
gi.require_version('Gtk', '3.0')
from gi.repository import GLib, Gtk
from backend import atomic_write

GLib.set_prgname('org.archdesktop.ScreenSharing')
CONFIG = Path(os.environ.get('XDG_CONFIG_HOME', Path.home() / '.config')) / 'wayvnc/config'


class Sharing(Gtk.ApplicationWindow):
    def __init__(self, app):
        super().__init__(application=app, title='Screen Sharing')
        header = Gtk.HeaderBar(title='Screen Sharing')
        header.set_show_close_button(True)
        self.set_titlebar(header)
        self.set_default_size(640, 470)
        self.set_border_width(24)
        box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=14)
        self.add(box)

        def label(text):
            item = Gtk.Label(label=text, xalign=0)
            item.set_line_wrap(True)
            box.pack_start(item, False, False, 0)
            return item

        label('Share this desktop with your MacBook')
        self.status = label('')
        if not CONFIG.exists():
            label('Screen sharing is not configured on this installation. See the desktop guide for optional setup.')
            return
        self.values = dict(line.split('=', 1) for line in CONFIG.read_text().splitlines()
                           if '=' in line and not line.lstrip().startswith('#'))
        self.address = Gtk.ComboBoxText()
        current = self.values.get('address', '')
        addresses = [current]
        try:
            interfaces = json.loads(subprocess.check_output(['ip', '-j', '-4', 'address', 'show', 'scope', 'global'], text=True))
            addresses += [a['local'] for i in interfaces for a in i['addr_info']
                          if ipaddress.ip_address(a['local']).is_private]
        except (OSError, ValueError, subprocess.SubprocessError):
            pass
        for address in dict.fromkeys(addresses):
            self.address.append(address, address)
        self.address.set_active_id(current)
        label('Listen on this local address:')
        box.pack_start(self.address, False, False, 0)
        label('On the MacBook: Finder → Go → Connect to Server (Command+K).')
        self.connection = label('vnc://' + current)
        self.connection.set_selectable(True)
        label('VNC password (separate from your Linux login; exactly 8 ASCII characters):')
        self.password = Gtk.Entry()
        self.password.set_visibility(False)
        self.password.set_text(self.values.get('password', ''))
        self.password.set_max_length(8)
        box.pack_start(self.password, False, False, 0)
        show = Gtk.CheckButton(label='Show password')
        show.connect('toggled', lambda widget: self.password.set_visibility(widget.get_active()))
        box.pack_start(show, False, False, 0)
        row = Gtk.Box(spacing=10)
        for title, callback in [('Save changes', self.save), ('Enable sharing', lambda *_: self.service('enable', '--now')),
                                ('Disable sharing', lambda *_: self.service('disable', '--now'))]:
            button = Gtk.Button(label=title)
            button.connect('clicked', callback)
            row.pack_start(button, True, True, 0)
        box.pack_start(row, False, False, 0)
        label('Enable also starts sharing at login; Disable stops it now and at login.\n'
              'Trusted home LAN only: this Apple-compatible VNC mode is unencrypted. Never forward port 5900 on your router.\n'
              'This shares your existing session. The Mac mini must be awake with Hyprland running. It does not forward audio.')
        self.refresh()

    def refresh(self):
        active = subprocess.run(['systemctl', '--user', 'is-active', '--quiet', 'wayvnc.service']).returncode == 0
        enabled = subprocess.run(['systemctl', '--user', 'is-enabled', '--quiet', 'wayvnc.service']).returncode == 0
        self.status.set_text(f"Sharing: {'running' if active else 'stopped'} · Start at login: {'on' if enabled else 'off'}")

    def service(self, *args):
        result = subprocess.run(['systemctl', '--user', *args, 'wayvnc.service'], capture_output=True, text=True)
        self.refresh()
        if result.returncode:
            self.status.set_text('Could not change service state: ' + result.stderr.strip())

    def save(self, *_):
        password = self.password.get_text()
        if len(password) != 8 or not all(33 <= ord(c) <= 126 for c in password):
            self.status.set_text('Use exactly 8 printable ASCII characters, without spaces.')
            return
        address = self.address.get_active_id()
        text = CONFIG.read_text()
        for key, value in {'address': address, 'password': password}.items():
            text = re.sub(rf'^{key}=.*$', lambda _: f'{key}={value}', text, flags=re.M)
        try:
            atomic_write(CONFIG, text.encode())
            CONFIG.chmod(0o600)
            self.connection.set_text('vnc://' + address)
            self.service('try-restart')
        except OSError:
            self.status.set_text('Could not save the private screen-sharing configuration.')


app = Gtk.Application(application_id='org.archdesktop.ScreenSharing')
def activate(application):
    if not application.get_windows():
        Sharing(application).show_all()
    application.get_windows()[0].present()
app.connect('activate', activate)
app.run()
