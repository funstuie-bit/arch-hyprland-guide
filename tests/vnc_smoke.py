"""Opt-in local RFB test. Reads the private VNC config; never prints its password.

python tests/vnc_smoke.py --live
Tests password rejection, acceptance, desktop size and a one-pixel capture.
Does not send keyboard/mouse events. Uses OpenSSL's legacy DES for this test only.
"""
from pathlib import Path
import socket
import struct
import subprocess
import sys


def receive(sock, length):
    data = b''
    while len(data) < length:
        chunk = sock.recv(length - len(data))
        if not chunk:
            raise RuntimeError('Server disconnected early')
        data += chunk
    return data


def main():
    if sys.argv[1:] != ['--live']:
        raise SystemExit('Pass --live to connect to the configured screen-sharing server.')
    config = dict(line.split('=', 1) for line in (Path.home() / '.config/wayvnc/config').read_text().splitlines()
                  if '=' in line and not line.lstrip().startswith('#'))
    for valid in (False, True):
        with socket.create_connection((config['address'], int(config.get('port', '5900'))), timeout=10) as sock:
            version = receive(sock, 12)
            assert version.startswith(b'RFB 003.'), version
            sock.sendall(b'RFB 003.008\n')
            count = receive(sock, 1)[0]
            types = receive(sock, count)
            assert 2 in types and 1 not in types, 'Require password authentication; never offer no-auth'
            sock.sendall(b'\x02')
            challenge = receive(sock, 16)
            password = config['password'].encode('ascii')[:8] if valid else b'wrong!!!'
            key = bytes(int(f'{byte:08b}'[::-1], 2) for byte in password.ljust(8, b'\0'))
            cipher = subprocess.run(['openssl', 'enc', '-des-ecb', '-provider', 'default',
                                     '-provider', 'legacy', '-K', key.hex(), '-nopad', '-nosalt'],
                                    input=challenge, capture_output=True)
            if cipher.returncode:
                raise RuntimeError('OpenSSL legacy DES unavailable')
            sock.sendall(cipher.stdout)
            result = struct.unpack('!I', receive(sock, 4))[0]
            if not valid:
                assert result != 0, 'Wrong password accepted!'
                print('PASS wrong password rejected')
                continue
            assert result == 0, 'Correct password rejected'
            print('PASS password authentication (no anonymous access)')
            sock.sendall(b'\x01')  # Share; do not disconnect an existing viewer.
            width, height = struct.unpack('!HH', receive(sock, 4))
            pixel_format = receive(sock, 16)
            name_length = struct.unpack('!I', receive(sock, 4))[0]
            assert name_length < 4096
            receive(sock, name_length)
            print(f'PASS desktop offered at {width}x{height}')
            sock.sendall(struct.pack('!BBHi', 2, 0, 1, 0))  # Raw pixel encoding.
            sock.sendall(struct.pack('!BBHHHH', 3, 0, 0, 0, 1, 1))
            for _ in range(10):
                message = receive(sock, 1)[0]
                if message == 0:
                    header = receive(sock, 3)
                    break
                if message == 2:  # Bell.
                    continue
                if message == 3:  # Discard clipboard data without logging it.
                    header = receive(sock, 7)
                    length = struct.unpack('!I', header[3:])[0]
                    assert length < 8 * 1024 * 1024
                    receive(sock, length)
                    continue
                raise RuntimeError(f'Unexpected RFB message type {message}')
            else:
                raise RuntimeError('No framebuffer update received')
            rectangles = struct.unpack('!H', header[1:])[0]
            assert rectangles > 0
            x, y, w, h, encoding = struct.unpack('!HHHHi', receive(sock, 12))
            assert encoding == 0 and w == 1 and h == 1, (w, h, encoding)
            receive(sock, pixel_format[0] // 8)
            print('PASS live pixel capture; no remote input sent')


if __name__ == '__main__':
    main()
