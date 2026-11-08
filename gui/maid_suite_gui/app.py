"""Maid Suite GUI — a small, native Qt window (KDE Plasma friendly).

Covers the main Suite workflows: open TUI, run embedded Helper/AU in a terminal
(interactive, safe), view doctor/status, and show session/compositor info.
Requires PyQt6 and a display. Falls back gracefully when unavailable.
"""
import os
import shlex
import shutil
import subprocess
import sys

from PyQt6.QtCore import Qt
from PyQt6.QtGui import QFont
from PyQt6.QtWidgets import (
    QApplication, QHBoxLayout, QLabel, QMainWindow, QMessageBox,
    QPlainTextEdit, QPushButton, QVBoxLayout, QWidget,
)

HERE = os.path.abspath(os.path.dirname(__file__))
# repo: gui/maid_suite_gui -> libexec; installed: ~/.local/share/maid-suite/libexec
CANDIDATE_LIBEXEC = [
    os.path.abspath(os.path.join(HERE, "..", "..", "libexec")),
    os.path.expanduser("~/.local/share/maid-suite/libexec"),
]
CANDIDATE_BIN = [
    os.path.abspath(os.path.join(HERE, "..", "..", "bin")),
    os.path.expanduser("~/.local/bin"),
]


def _find(name, subdir):
    for base in CANDIDATE_LIBEXEC:
        p = os.path.join(base, subdir, name)
        if os.path.isfile(p) and os.access(p, os.X_OK):
            return p
    return shutil.which(name) or os.path.expanduser(f"~/.local/bin/{name}")


def _find_bin(name):
    for base in CANDIDATE_BIN:
        p = os.path.join(base, name)
        if os.path.isfile(p):
            return p
    return shutil.which(name) or os.path.expanduser(f"~/.local/bin/{name}")


def terminal_run(cmd):
    """Launch *cmd* (string for a shell) in a terminal; best-effort."""
    candidates = [
        os.environ.get("TERMINAL"),
        "x-terminal-emulator", "konsole", "gnome-terminal", "kitty",
        "xfce4-terminal", "alacritty", "xterm",
    ]
    for t in candidates:
        if not t:
            continue
        exe = shutil.which(t) or t
        if not shutil.which(exe) and not os.path.isabs(exe):
            continue
        name = os.path.basename(exe)
        if name == "gnome-terminal":
            argv = [exe, "--", "bash", "-lc", cmd]
        elif name in ("konsole", "kitty", "alacritty", "xfce4-terminal", "xterm"):
            argv = [exe, "-e", "bash", "-lc", cmd]
        elif name == "x-terminal-emulator":
            argv = [exe, "-e", f"bash -lc {shlex.quote(cmd)}"]
        else:
            argv = [exe, "-e", "bash", "-lc", cmd]
        try:
            subprocess.Popen(argv)
            return True
        except Exception:
            continue
    return False


class MainWindow(QMainWindow):
    def __init__(self):
        super().__init__()
        self.setWindowTitle("Maid Suite")
        self.resize(760, 520)
        root = QWidget()
        self.setCentralWidget(root)
        lay = QVBoxLayout(root)

        title = QLabel("Maid Suite — install, update, check (Helper + AU, canonical)")
        f = QFont(); f.setBold(True); f.setPointSize(max(11, f.pointSize()+1))
        title.setFont(f)
        lay.addWidget(title)
        lay.addWidget(QLabel("Native Qt GUI (KDE Plasma friendly). Interactive tasks open in a terminal."))

        self.log = QPlainTextEdit()
        self.log.setReadOnly(True)
        self.log.setMinimumHeight(220)
        lay.addWidget(self.log, 1)

        row1 = QHBoxLayout(); lay.addLayout(row1)
        row2 = QHBoxLayout(); lay.addLayout(row2)

        def btn(label, fn, row=row1):
            b = QPushButton(label); b.clicked.connect(fn); row.addWidget(b); return b

        btn("Open TUI (terminal)", self.open_tui)
        btn("Helper check/fix (terminal)", self.run_helper)
        btn("AU updater (terminal)", self.run_au)
        btn("Doctor / status", self.doctor, row2)
        btn("Compositor/session info", self.session_info, row2)
        btn("About", self.about, row2)

        self.statusBar().showMessage("Ready")
        self.doctor()

    def append(self, text):
        self.log.appendPlainText(text.rstrip())

    def open_tui(self):
        tui = _find_bin("maid-suite")
        cmd = f"{shlex.quote(tui)}; echo; read -r -p 'Press Enter to close...'"
        if not terminal_run(cmd):
            QMessageBox.warning(self, "Maid Suite", "Could not find a terminal emulator. Run: maid-suite")
        else:
            self.append("opened TUI in a terminal")

    def run_helper(self):
        h = _find("maid-helper", "helper")
        if not os.path.isfile(h):
            QMessageBox.information(self, "Maid Suite", "Embedded Helper not found. Reinstall Maid Suite.")
            return
        cmd = f"{shlex.quote(h)} --check; echo; echo 'Tip: run with --fix to apply safe fixes.'; read -r -p 'Press Enter to close...'"
        if terminal_run(cmd):
            self.append(f"Helper launched in terminal: {h}")
        else:
            QMessageBox.warning(self, "Maid Suite", "Could not open a terminal.")

    def run_au(self):
        au = _find("update-all.sh", "au")
        if not os.path.isfile(au):
            QMessageBox.information(self, "Maid Suite", "Embedded AU updater not found. Reinstall Maid Suite.")
            return
        cmd = f"{shlex.quote(au)}; echo; read -r -p 'Press Enter to close...'"
        if terminal_run(cmd):
            self.append(f"AU updater launched in terminal: {au}")
        else:
            QMessageBox.warning(self, "Maid Suite", "Could not open a terminal.")

    def doctor(self):
        self.log.clear()
        self.append("== Maid Suite doctor/status ==")
        self.append(f"embedded Helper: {_find('maid-helper','helper')}")
        self.append(f"embedded AU:     {_find('update-all.sh','au')}")
        self.append(f"TUI:             {_find_bin('maid-suite')}")
        self.append(f"desktop={os.environ.get('XDG_CURRENT_DESKTOP','n/a')} session={os.environ.get('XDG_SESSION_DESKTOP','n/a')} "
                    f"wayland={'yes' if os.environ.get('WAYLAND_DISPLAY') else 'no'} x11={'yes' if os.environ.get('DISPLAY') else 'no'}")
        desk = (os.environ.get("XDG_CURRENT_DESKTOP") or "").lower()
        if "plasma" in desk or "kde" in desk:
            self.append("KDE Plasma: supported for KDE-specific integrations.")
        elif any(x in desk for x in ("hyprland","sway","i3")):
            self.append(f"{os.environ.get('XDG_CURRENT_DESKTOP')}: core CLI/TUI works; compositor adapters partial/experimental (roadmap).")
        else:
            self.append("session: core CLI/TUI expected to work; desktop integration varies.")
        # read-only ADB presence hint
        self.append(f"adb present: {'yes' if shutil.which('adb') else 'no'} (phone discovery is read-only/experimental)")
        self.statusBar().showMessage("Doctor refreshed", 3000)

    def session_info(self):
        self.doctor()

    def about(self):
        QMessageBox.information(self, "About Maid Suite",
            "Maid Suite (GPL-3.0-or-later)\n\n"
            "Unified, canonical front end: embeds Helper + AU updater cores and orchestrates other tools via official installers.\n"
            "TUI: maid-suite  ·  GUI: maid-suite-gui\n"
            "Roadmap (compositor support, phone integration): docs/ROADMAP-2.md")


def main():
    if not os.environ.get("DISPLAY") and not os.environ.get("WAYLAND_DISPLAY"):
        print("Maid Suite GUI needs a display (Wayland or X11). Use: maid-suite", file=sys.stderr)
        return 2
    try:
        app = QApplication(sys.argv)
    except Exception as e:
        print(f"Maid Suite GUI failed to start ({e}). Use: maid-suite", file=sys.stderr)
        return 2
    app.setApplicationName("Maid Suite")
    w = MainWindow(); w.show()
    return app.exec()
