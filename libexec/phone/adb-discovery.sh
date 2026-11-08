#!/usr/bin/env bash
# EXPERIMENTAL / READ-ONLY: ADB device discovery (no pairing, no control, no installs).
set -u
say() { printf '  %s\n' "$*"; }
say "ADB device discovery (read-only) — shows connected/authorized devices only."
say "No changes made. For wireless debugging/permissions workflows, see official Android/ADB docs and Tasker Permissions guidance."
echo
if ! command -v adb >/dev/null 2>&1; then
  say "adb not found (install Android platform-tools if you want to try this)."
  exit 0
fi
adb start-server >/dev/null 2>&1 || true
adb devices -l 2>&1 || true
echo
say "Tip: this is a discovery slice for the phone-integration roadmap (no APK goal). It never runs shell commands on devices."
