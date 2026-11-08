# changelog

## Maid Suite v1.0.0 (this release)

- **NixOS (flakes + home-manager), easy setup:** `flake.nix` with packages/apps (`default`, `#gui`), `homeManagerModules.default`/`nixosModules.default`, and `programs.maid-suite.enable`. track `main` and rebuild with `--refresh` to auto-update on every rebuild/switch.
- **NixOS-aware:** detects NixOS and gives declarative install guidance (no unmanaged `curl|bash` installers) for managed tools.
- **embedded cores (canonical):** Maid Helper and Maid AU updater cores bundled in `libexec/` (GPL-3.0-or-later, preserved behavior) and preferred by Suite - self-contained front end for those workflows.
- **TUI/GUI front end:** install/update all or selected tools (AU core, Helper core, Maid Runner, Maidshare, Maid BT), doctor/status, Suite self-update/reinstall/uninstall; arrow-key + number navigation, MAIDWARE boot intro.
- orchestrates each tool’s official installer over HTTPS (URLs shown); independent tools, no runtime coupling.
- GPL-3.0-or-later (forkable, open source).
