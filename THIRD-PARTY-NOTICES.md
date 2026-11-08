# third-party and credits

Maid Suite is Maidware work under the **GPL-3.0-or-later** license in `LICENSE`. This file names third-party software and services it references or calls, so credit is clear.

## Bundled / vendored into this repository (GPL-compatible distribution)
- **Maid Helper core modules** (copied into `libexec/helper/`): originated in the Maidware “Maid Helper” project; preserved behavior, relicensed/distributed here under GPL-3.0-or-later as part of Maid Suite.
- **Maid AU updater core** (`libexec/au/update-all.sh`, `pm-*.sh`): originated in the Maidware “Maid AU” project; preserved behavior, distributed here under GPL-3.0-or-later as part of Maid Suite.

## Called at runtime, not bundled
Maid Suite orchestrates or invokes tools your system/distribution provides (it does not ship them):
- **bash**, coreutils, common POSIX userland.
- **curl**: fetching official installers and repo tarballs over HTTPS (curl project license; typically MIT/X11-style derivative).
- **git** (optional, for development workflows).
- **adb** (Android platform-tools, Apache-2.0 components; optional): used only by the **read-only** phone discovery helper (`libexec/phone/adb-discovery.sh`, `adb devices -l` — no device control/pairing).
- **Package managers / system tools** invoked by embedded cores or orchestrated installers (varies by distro): e.g. `pacman`, `apt`, `dnf`, `zypper`, `flatpak`, `fwupd`/`fwupdmgr`, `snapper`/`timeshift`, `systemctl`, `bluetoothctl`, `pactl` — all provided by your distribution under their own licenses.
- **Terminal emulators** (for GUI-launched interactive tasks): detected best-effort (konsole, xterm, kitty, etc.), not bundled.

## Optional runtime (GUI)
- **Python 3** and **PyQt6** (Riverbank/Qt, GPL/commercial terms as applicable to your environment): required only for `maid-suite-gui`. If missing, Suite falls back to the TUI.

## Referenced (documentation/roadmap), not bundled
- **KDE Connect**, **Android/ADB documentation**, and [Tasker Permissions](https://github.com/joaomgcd/Tasker-Permissions) (Apache-2.0) are referenced for workflows/guidance; no code from them is bundled.

Everything else in this repository is original Maidware work (or Maidware work vendored as noted above). Corrections welcome via issues/PRs.
