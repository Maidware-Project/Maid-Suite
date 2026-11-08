# changelog

## unreleased

- **embedded cores (canonical):** Maid Helper and Maid AU updater cores are now bundled in `libexec/` (GPL-3.0-or-later, preserved behavior; copied from the standalone repos) and preferred by Suite — Suite is the self-contained front end for those workflows.
- **TUI flow:** selections are echoed and every action returns to the menu (`press Enter to return to menu`).
- initial release: `install.sh` (piped-fetch fallback) + `bin/maid-suite.sh` TUI
- orchestrates official installers for Maid AU, Maid Helper, Maid Runner, Maidshare, Maid BT
- adaptive MAIDWARE boot intro; clear number+Enter / `q` navigation
- doctor/status via local command markers
- GPL-3.0-or-later from birth (forkable, open source)
- roadmap notes for compositor support, KDE→Niri export, and phone-integration architecture (`docs/ROADMAP-2.md`)
