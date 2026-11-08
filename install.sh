#!/usr/bin/env bash
# Maid Suite installer - orchestrator for the Maidware toolset.
# Usage: ./install.sh [--check] [--uninstall] [--tui]
# Piped install: bash <(curl -fsSL https://raw.githubusercontent.com/Maidware-Project/Maid-Suite/main/install.sh)
set -u

REPO_RAW="https://raw.githubusercontent.com/Maidware-Project/Maid-Suite/main"

# piped-fetch fallback: when run as a stream (no local tree), fetch the repo
SCRIPT_PATH="${BASH_SOURCE[0]:-$0}"
PKGDIR="$(cd "$(dirname "$SCRIPT_PATH")" 2>/dev/null && pwd)" || PKGDIR=""
PIPED=0
FETCH_TMP=""
cleanup() { [ -n "$FETCH_TMP" ] && rm -rf "$FETCH_TMP"; }
trap cleanup EXIT

if [ ! -f "$PKGDIR/bin/maid-suite.sh" ]; then
  if command -v curl >/dev/null 2>&1; then
    FETCH_TMP="$(mktemp -d /tmp/maidsuite-fetch.XXXXXX)"
    curl -fsSL "https://codeload.github.com/Maidware-Project/Maid-Suite/tar.gz/refs/heads/main" \
      | tar -xz -C "$FETCH_TMP" || { echo "fetch failed" >&2; exit 1; }
    PKGDIR="$(find "$FETCH_TMP" -mindepth 1 -maxdepth 1 -type d -name 'Maid-Suite-*' | head -n 1)"
    [ -f "$PKGDIR/bin/maid-suite.sh" ] || { echo "downloaded tree looks wrong" >&2; exit 1; }
    # stdin is the user's tty in process substitution - never trust [ -t 0 ] alone
    PIPED=1
  else
    echo "need curl to fetch Maid Suite, or clone the repo and run ./install.sh" >&2
    exit 1
  fi
fi

CHECK=0; UNINST=0; TUI=0
for a in "$@"; do
  case "$a" in
    --check) CHECK=1 ;;
    --uninstall) UNINST=1 ;;
    --tui) TUI=1 ;;
  esac
done

BINDIR="$HOME/.local/bin"
SHARE="$HOME/.local/share/maid-suite"
APPS="$HOME/.local/share/applications"
mkdir -p "$BINDIR" "$SHARE" "$APPS"

say() { echo "==> $*"; }

if [ "$UNINST" = "1" ]; then
  [ "$CHECK" = "1" ] && { echo "would remove $BINDIR/maid-suite $SHARE $APPS/maid-suite.desktop"; exit 0; }
  rm -f "$BINDIR/maid-suite" "$APPS/maid-suite.desktop"
  rm -rf "$SHARE"
  say "Maid Suite removed (the tools it installed remain; uninstall them individually if you want)"
  exit 0
fi

if [ "$CHECK" = "1" ]; then
  echo "COPY $BINDIR/maid-suite $BINDIR/maid-suite-gui"
  echo "COPY $APPS/maid-suite.desktop (KDE Plasma / app menu)"
  echo "COPY $SHARE (docs, libexec, gui)"
  echo "==> (check only, nothing changed)"
  exit 0
fi

install -m 0755 "$PKGDIR/bin/maid-suite.sh" "$BINDIR/maid-suite"
[ -f "$PKGDIR/bin/maid-suite-gui" ] && install -m 0755 "$PKGDIR/bin/maid-suite-gui" "$BINDIR/maid-suite-gui"
[ -f "$PKGDIR/desktop/maid-suite.desktop" ] && install -m 0644 "$PKGDIR/desktop/maid-suite.desktop" "$APPS/maid-suite.desktop"
mkdir -p "$SHARE/libexec" "$SHARE/gui"
if [ -d "$PKGDIR/libexec" ]; then
  cp -rf "$PKGDIR/libexec/." "$SHARE/libexec/" 2>/dev/null || true
  chmod -R u+rwX,go+rX "$SHARE/libexec" 2>/dev/null || true
  find "$SHARE/libexec" -type f \( -name '*.sh' -o -name 'maid-*' -o -name 'update-all.sh' \) -exec chmod 0755 {} + 2>/dev/null || true
fi
[ -d "$PKGDIR/gui" ] && cp -rf "$PKGDIR/gui/." "$SHARE/gui/" 2>/dev/null || true
cp -f "$PKGDIR/README.md" "$PKGDIR/CHANGELOG.md" "$SHARE/" 2>/dev/null || true
[ -d "$PKGDIR/docs" ] && cp -rf "$PKGDIR/docs" "$SHARE/" 2>/dev/null || true
say "installed maid-suite (TUI) + maid-suite-gui (native Qt/KDE Plasma GUI) -> $BINDIR"
say "app menu entry -> $APPS/maid-suite.desktop"
say "launch: maid-suite   (unified install/update/status for the Maidware tools)"

if [ "$TUI" = "1" ]; then
  exec "$BINDIR/maid-suite"
fi
exit 0
