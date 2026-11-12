#!/usr/bin/env bash
# Backend: Void Linux (xbps). Sourced by update-all.sh - not run directly.
# Provides: pm_name, pm_check, pm_update. Uses $SUDO, $TMP, log(), UPDATED.
# shellcheck disable=SC2034  # cross-file state: read by update-all.sh after sourcing
PM_PROBE="xbps-install --version"
pm_name() { echo "xbps"; }

pm_check() {
  ZYPPER_N=0; PACKMAN_N=0; SYS_HIT=0
  if $SUDO xbps-install -Sun >"$TMP" 2>&1; then
    # xbps-install -Sun lists packages to update; no updates usually means empty/no relevant lines
    ZYPPER_N=$(grep -cE '^[A-Za-z0-9]' "$TMP" || true)
    ZYPPER_N=${ZYPPER_N:-0}
    if [ "$ZYPPER_N" -eq 0 ]; then
      log "check: xbps: nothing to do."
    else
      UPDATED=1
      if grep -qiE "^linux[0-9.-]*|^linux[[:space:]]|systemd|dbus|glibc|udev|dracut" "$TMP"; then SYS_HIT=1; fi
      log "check: xbps: ${ZYPPER_N} package(s) available."
    fi
  else
    cat "$TMP"; log "check: xbps dry-run FAILED"; return 1
  fi
  EXTRA_N=0
  return 0
}

pm_update() {
  echo "--- xbps-install -Su ---"
  SNAP_PRE_ID=$(snap_pre "xbps")
  if [ -z "$SNAP_PRE_ID" ]; then
    if [ "$REQUIRE_SNAP" = "1" ]; then
      echo "ABORT: --require-snapshot and pre-snapshot failed."
      log "strict abort: no pre-snapshot."
      exit 2
    fi
    say "safety: pre-update snapshot FAILED - continuing without rollback (--require-snapshot aborts instead)."
  fi
  # sync repos and update system
  if $SUDO xbps-install -Suy >"$TMP" 2>&1; then
    cat "$TMP"
    if grep -qiE "updat|install|remov" "$TMP"; then
      UPDATED=1
      if grep -qiE "linux[0-9.-]*|linux-lts|systemd|dbus|glibc|udev|dracut" "$TMP"; then IMPORTANT=1; fi
      grep -iE "updat|install|remov" "$TMP" >> "$LOG" || true
    else
      log "xbps: nothing to do."
    fi
  else
    cat "$TMP"; log "xbps: FAILED"
    grep -iE "error|failed|warning" "$TMP" >> "$LOG" || true
    return 1
  fi
  snap_post "xbps"
  SNAP_POST_ID=$(snap_last)
  if [ -n "$SNAP_PRE_ID" ] && [ -n "$SNAP_POST_ID" ] && [ "$SNAP_PRE_ID" != "timeshift" ]; then
    SNAP_INFO="snapshots #$SNAP_PRE_ID -> #$SNAP_POST_ID (rollback: sudo snapper -c root rollback <pre#>)"
    log "safety: $SNAP_INFO"
  elif [ "$SNAP_PRE_ID" = "timeshift" ]; then
    SNAP_INFO="timeshift snapshot taken (restore: timeshift --restore)"
    log "safety: $SNAP_INFO"
  fi
  return 0
}
