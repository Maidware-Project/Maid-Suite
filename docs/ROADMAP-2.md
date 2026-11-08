# Roadmap — compositor support and phone integration

Honest, sequenced plan for the larger items. These are **not** claimed as done in a single pass; they require per-tool design, implementation, and real testing (Wayland compositors differ, and phone/ADB flows have security and device variance). **Niri/Noctila export work is out of scope (scrapped).**

## 1) Compositor support (Hyprland, Sway, i3 — and others as feasible)
**Goal:** Maid Runner and Maid BT (and, where relevant, other tools) work well outside KDE Plasma. The website remains performant across browsers.

**Approach (incremental, no Plasma regressions):**
- Detect session: `XDG_CURRENT_DESKTOP`, `XDG_SESSION_DESKTOP`, `WAYLAND_DISPLAY`, running compositor processes (best-effort).
- Build a small capability matrix per tool (launcher integration, tray/status, notifications, keybind hooks; widgets/plasmoids are KDE-specific).
- Maid BT: keep the Plasma plasmoid as KDE path; provide compositor-neutral CLI/TUI + notifications + optional status integration (e.g. Waybar/swaybar modules or simple scripts) for Hyprland/Sway/i3. Doctor reports detected session + support level.
- Maid Runner: verify launch/toggle behavior under each compositor; document/ship keybind snippets per compositor instead of assuming KDE.
- Ship per compositor behind clear “supported/partial/experimental” labels with `--check`/doctor output.

**Done when:** each target compositor has a tested path, docs, and no KDE behavior changes.

## 2) Phone integration (native feel, no-APK goal) — architecture
**Goal:** Android ↔ PC feels directly connected, combining KDE Connect, ADB/adb-over-WiFi, and local intent flows — reducing reliance on a separate APK where feasible, and evolving file/phone flows (including Maidshare’s role) carefully.

**Principles:** security-first (explicit pairing/trust, LAN-only by default, never expose services beyond the router), truthful capability reporting, and graceful fallback.

**Transport/capability matrix (to design + prototype):**
- **KDE Connect**: rich when available (commands, notifications, some device signals); keep as a first-class backend.
- **ADB / ADB over Wi-Fi**: powerful, no APK, but requires developer options/wireless debugging and careful UX; use [Tasker Permissions](https://github.com/joaomgcd/Tasker-Permissions) as reference for Tasker/ADB permission workflows (official sources only). Never run destructive ADB commands; scope narrowly.
- **Local intent/HTTP (current Maid BT pattern)**: simple LAN triggers with a token — keep, harden docs, never beyond LAN.
- **File transfer**: evaluate unifying backends (ADB push/pull, KDE Connect share, browser receive/QR) under one clear UX. “Syncthing-like” sync is a separate, opt-in track with conflict/safety rules and no silent data loss.

**Migration:** don’t break existing Maidshare/Maid BT flows; ship additive paths, then deprecate/redirect only when parity and safety are proven.

**Done when:** a documented, threat-aware design exists; a minimal vertical slice (e.g., ADB-over-WiFi device discovery + one safe action + clear setup) works on real devices with explicit consent.

## 3) Suite polish (cross-cutting)
- Maid Suite aims to be the **better unified front end** (install/update/status in one place), complementing or replacing day-to-day Maid AU usage while keeping tools’ official installers authoritative.
- Bug/glitch sweeps + update survival: idempotent installers, timestamped backups, non-destructive fixes, `--check`/dry-run everywhere.
- Easier TUI navigation everywhere: consistent number+Enter, `q` cancels/back, plain-language prompts.
