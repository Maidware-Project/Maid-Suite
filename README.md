# Maid Suite - the Maidware front end

a lightweight, unified front end for the Maidware toolset: a TUI and a native Qt GUI (KDE Plasma app-menu entry) to install, update, and check everything from one place. it embeds the Maid Helper and Maid AU updater cores (self-contained in `libexec/`, behavior preserved) and orchestrates the other tools by running each tool's **official** installer over HTTPS (URLs shown). no accounts, no telemetry.

```
bin/maid-suite.sh        TUI: install/update selected or all tools, doctor, updater
bin/maid-suite-gui       native Qt GUI launcher (menus aligned with the TUI)
gui/maid_suite_gui/      the GUI app (PyQt6)
libexec/helper/          embedded Maid Helper core
libexec/au/              embedded Maid AU updater core (update-all.sh, pm-*)
libexec/phone/           read-only ADB phone discovery (adb-discovery.sh)
desktop/                 KDE Plasma application entry
install.sh               installer (piped-safe; deploys libexec + gui)
docs/                    roadmap and notes
```

## quick start

```sh
# one line, straight from GitHub:
bash <(curl -fsSL https://raw.githubusercontent.com/Maidware-Project/Maid-Suite/main/install.sh)

maid-suite                 # TUI
maid-suite-gui             # native GUI (PyQt6)
```

if a piped run behaves oddly on your shell:

```sh
curl -fsSL https://raw.githubusercontent.com/Maidware-Project/Maid-Suite/main/install.sh | bash
```

## what it does

- **install/update all** (recommended) or **selected** tools: Maid AU core, Maid Helper core, Maid Runner, Maidshare, Maid BT.
- **doctor/status**: detects what’s on your system (command markers) and reports compositor/session info truthfully (Plasma supported; other compositors use the core CLI/TUI paths where applicable).
- **embedded cores, canonical front end**: Maid Suite is the recommended, all-in-one front end. the standalone Maid Helper and Maid AU repos are archived; their cores live here in `libexec/` (GPL-3.0-or-later, behavior preserved).
- **easy navigation**: type a number and press Enter · `q` cancels/back. the TUI and GUI expose the same actions.
- **phone (read-only discovery)**: ADB device discovery slice (`libexec/phone/adb-discovery.sh`) - no pairing/control actions.

## safety

- runs each tool’s official `install.sh` from `https://raw.githubusercontent.com/Maidware-Project/<repo>/main/install.sh` (downloaded to a temp file, shown before run).
- **no surprise sudo in non-interactive runs:** when Suite isn’t attached to a TTY it passes `--no-packages` to child installers; run a tool with `--packages` yourself if/when you want distro packages installed.
- review scripts before running if you prefer (open the raw URL or clone the repo). tools keep their own backups/`--check` behavior.

## installation

```sh
bash install.sh                # deploy Suite + embedded cores + GUI + desktop entry
bash install.sh --check        # check only (nothing changed)
bash install.sh --tui          # menu
bash install.sh --uninstall    # remove Suite
```

clone-and-run: `git clone --depth 1 https://github.com/Maidware-Project/Maid-Suite.git && bash Maid-Suite/install.sh`.

## works with the Maid suite

Maid Suite *is* the suite front end. it stands alone as the canonical place to run Helper/AU core workflows and to install/update the other independent Maidware tools (Maid BT, Maid Runner, Maidshare). each tool remains independent and keeps its own installer, behavior, and credits.

## License

GPL-3.0-or-later — forkable and open source. See `LICENSE`.
Third-party notices and credits: `THIRD-PARTY-NOTICES.md`. Part of the
[Maidware Project](https://maidware-project.github.io/). docs live on the
[website guides](https://maidware-project.github.io/guides/).
