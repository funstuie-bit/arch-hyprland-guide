"""Run with python -m unittest discover -s settings. No live desktop writes."""
import json
import os
from pathlib import Path
import shutil
import tempfile
import unittest
from unittest.mock import patch

from backend import DisplayPreview, Settings, THEMES, ini_set, palette, theme_files

ROOT = Path(__file__).resolve().parents[1]
MONITOR = dict(name="DP-1", width=5120, height=2160, refreshRate=29.995, scale=1, x=0, y=0)


class SettingsTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.config = Path(self.temp.name) / "config"
        shutil.copytree(ROOT / "dotfiles", self.config)
        self.calls = []
        self.fail_once = False

        def runner(args):
            self.calls.append(args)
            if args == ["hyprctl", "configerrors"] and self.fail_once:
                self.fail_once = False
                return "Example invalid setting"
            if args == ["hyprctl", "-j", "monitors"]:
                return json.dumps([MONITOR])
            return ""

        self.settings = Settings(self.config, Path(self.temp.name) / "state", runner)

    def contents(self):
        return {str(p.relative_to(self.config)): p.read_bytes() for p in self.config.rglob('*') if p.is_file()}

    def test_all_themes_preserve_behavior_and_undo_exactly(self):
        before = self.contents()
        for name, colors in THEMES.items():
            self.settings.apply_theme(name, colors['accent'])
            config = self.settings.read('hypr/hyprland.conf')
            self.assertIn('5120x2160@30, 0x0, 1', config)
            self.assertIn('layoutmsg, swapsplit', config)
            self.assertIn('volume.sh up', config)
            self.assertEqual(config.count('# desktop-settings:start'), 1)
            self.settings.undo()
            self.assertEqual(self.contents(), before)

    def test_repeated_theme_updates_do_not_accumulate_blocks(self):
        for name, colors in THEMES.items():
            self.settings.apply_theme(name, colors['accent'])
        for file in ('hypr/hyprland.conf', 'waybar/style.css', 'rofi/config.rasi'):
            self.assertEqual(self.settings.read(file).count('desktop-settings:start'), 1)

    def test_invalid_theme_reload_rolls_back(self):
        before = self.contents()
        self.fail_once = True
        with self.assertRaisesRegex(RuntimeError, 'invalid setting'):
            self.settings.apply_theme('nord', '88c0d0')
        self.assertEqual(self.contents(), before)
        self.assertFalse(self.settings.undo_path.exists())

    def test_undo_does_not_overwrite_external_edits(self):
        self.settings.apply_theme('forest', 'a9cb8d')
        path = self.config / 'hypr/hyprland.conf'
        path.write_text(path.read_text() + '\n# An edit made outside Settings\n')
        with self.assertRaisesRegex(RuntimeError, 'changed since'):
            self.settings.undo()
        self.assertIn('outside Settings', path.read_text())

    def test_failed_undo_restores_current_theme(self):
        self.settings.apply_theme('nord', '88c0d0')
        before = self.contents()
        self.fail_once = True
        with self.assertRaisesRegex(RuntimeError, 'invalid setting'):
            self.settings.undo()
        self.assertEqual(before, self.contents())
        self.assertTrue(self.settings.undo_path.exists())

    def test_bad_display_arguments_rejected(self):
        with self.assertRaises(ValueError):
            DisplayPreview(self.settings, MONITOR, 'invalid,disable', '1')
        with self.assertRaises(ValueError):
            DisplayPreview(self.settings, MONITOR, '5120x2160@30', '0')

    def test_theme_does_not_replace_symlinks(self):
        path = self.config / 'foot/foot.ini'
        target = Path(self.temp.name) / 'foot.ini'
        path.rename(target)
        path.symlink_to(target)
        before = target.read_bytes()
        with self.assertRaisesRegex(RuntimeError, 'linked'):
            self.settings.apply_theme('nord', '88c0d0')
        self.assertEqual(before, target.read_bytes())
        self.assertTrue(path.is_symlink())

    def test_ini_edits_only_target_section(self):
        result = ini_set('font=one\n[other]\nfont=two\n', '', {'font': 'three'})
        self.assertEqual(result, 'font=three\n[other]\nfont=two\n')

    def test_invalid_accent_rejected(self):
        with self.assertRaises(ValueError):
            palette('midnight', 'red; invalid')

    def test_wallpaper_saved_and_undo_restores_file(self):
        before = self.contents()
        image = Path(self.temp.name) / 'picture.png'
        image.write_bytes(b'UI validates images before backend use')
        self.settings.set_wallpaper(image, 'cover')
        self.assertIn(str(image), self.settings.read('hypr/hyprpaper.conf'))
        self.assertTrue(any(c[:3] == ['hyprctl', 'hyprpaper', 'wallpaper'] for c in self.calls))
        self.settings.undo()
        self.assertEqual(before, self.contents())

    @patch.dict(os.environ, {'HYPRLAND_INSTANCE_SIGNATURE': 'test-instance'})
    def test_display_timer_armed_before_change_and_revert(self):
        before = self.contents()
        preview = DisplayPreview(self.settings, MONITOR, '2560x1080@60', '1')
        preview.start()
        self.assertEqual(self.calls[0][0], 'systemd-run')
        self.assertIn('--on-active=25s', self.calls[0])
        self.assertEqual(self.calls[1][-1], 'DP-1,2560x1080@60,0x0,1')
        preview.revert()
        self.assertEqual(self.calls[-2][-1], 'DP-1,5120x2160@29.995,0x0,1')
        self.assertEqual(before, self.contents())
        self.assertFalse(preview.active)

    @patch.dict(os.environ, {'HYPRLAND_INSTANCE_SIGNATURE': 'test-instance'})
    def test_display_keep_updates_only_monitor_rule(self):
        preview = DisplayPreview(self.settings, MONITOR, '5120x2160@30', '1.333333')
        preview.start()
        preview.keep()
        config = self.settings.read('hypr/hyprland.conf')
        self.assertIn('monitor = DP-1, 5120x2160@30, 0x0, 1.333333', config)
        self.assertIn('monitor = DP-3, 2560x1080@60, 0x0, 1', config)
        self.assertFalse(preview.active)


if __name__ == '__main__':
    unittest.main()
