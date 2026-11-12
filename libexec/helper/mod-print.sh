#!/usr/bin/env bash
# Doctor: printing (CUPS off, no driverless discovery, HP missing drivers).
# Detect: CUPS scheduler running + enabled. Fix: install + enable CUPS (and
# avahi for driverless network printers). HP printers get an hplip note.
# Test page is printed as a command for you, never auto-printed (paper!).
# Usage: mod-print.sh check|fix. rc: 0 healthy/fixed, 2 needs attention.
set -u
here="$(cd "$(dirname "$0")" && pwd)"
# shellcheck disable=SC1090,SC1091
. "$here/lib.sh"
# standalone-safe: dispatcher exports PM, direct runs detect it
: "${PM:=$(detect_pm)}"

MODE="${1:-check}"

print_ok() {
  have lpstat || return 1
  lpstat -r 2>/dev/null | grep -qi "scheduler is running" || return 1
  if have systemctl; then
    systemctl is-enabled cups.service cups.socket cups.path 2>/dev/null | grep -q enabled || return 1
  elif have rc-status; then
    rc-status default 2>/dev/null | grep -qE 'cups|cupsd' || rc-service cupsd status >/dev/null 2>&1 || return 1
  elif have sv; then
    sv status cupsd >/dev/null 2>&1 || sv status cups >/dev/null 2>&1 || return 1
  fi
  return 0
}

if print_ok; then
  lpstat -p 2>/dev/null | head -n 3
  # lpstat's raw "no system default destination" reads like an error on a
  # fresh box; it just means no printer has been set up yet
  if lpstat -d 2>/dev/null | grep -q "no system default"; then
    echo "note - no default printer set up (the print settings can add one)"
  else
    lpstat -d 2>/dev/null
  fi
  echo "ok - CUPS running and enabled"
  exit 0
fi
echo "NEEDS FIX - CUPS not running/enabled"
lpstat -p 2>/dev/null | head -n 5 || true
[ "$MODE" = "fix" ] || exit 2

ensure_sudo || exit 1
case "$PM" in
  zypper) install_pkgs zypper cups cups-filters avahi || true ;;
  dnf) install_pkgs dnf cups cups-filters avahi || true ;;
  pacman) install_pkgs pacman cups cups-filters avahi || true ;;
  apt) install_pkgs apt cups cups-filters avahi-daemon || true ;;
  xbps) install_pkgs xbps cups cups-filters avahi || true ;;
  *) echo "unsupported distro for printing"; exit 1 ;;
esac

if have systemctl; then
  sudo systemctl enable --now cups.service 2>&1 | tail -n 1 || true
  if have avahi-daemon || have avahi-browse; then
    sudo systemctl enable --now avahi-daemon.service 2>&1 | tail -n 1 || true
  fi
elif have rc-update && have rc-service; then
  sudo rc-update add cupsd default 2>&1 | tail -n 1 || true
  sudo rc-service cupsd start 2>&1 | tail -n 1 || true
  if have avahi-daemon || have avahi-browse; then
    sudo rc-update add avahi-daemon default 2>&1 | tail -n 1 || true
    sudo rc-service avahi-daemon start 2>&1 | tail -n 1 || true
  fi
elif have sv; then
  echo "note: runit detected - enable/start CUPS (and avahi-daemon if needed) via your service links, e.g.:"
  echo "  sudo ln -s /etc/sv/cupsd /var/service/  (path varies by distro)"
else
  echo "note: could not detect a supported init/service manager to enable CUPS automatically."
  echo "      start/enable CUPS (and avahi-daemon for network discovery) using your init system."
fi
echo "note: HP printer? needs hplip too: sudo <pm> install hplip, then run hp-setup"

if print_ok; then
  echo "ok - CUPS running now"
  echo "print a test page yourself when ready: lp -d <printer> /usr/share/cups/data/testprint"
else
  echo "FAILED - CUPS still down (see lines above)"
  exit 1
fi
