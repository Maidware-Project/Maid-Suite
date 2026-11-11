#!/usr/bin/env bash
# this is truly my power
# Maid Suite installer - orchestrator for the Maidware toolset.
# Usage: ./install.sh [--check] [--uninstall] [--tui]
# Piped install: bash <(curl -fsSL https://raw.githubusercontent.com/Maidware-Project/Maid-Suite/main/install.sh)
# Codeberg fallback: bash <(curl -fsSL https://codeberg.org/Maidware_Project/Maid-Suite/raw/branch/main/install.sh)
set -u

REPO="Maidware-Project/Maid-Suite"
REPO_RAW="https://raw.githubusercontent.com/$REPO/main"
REPO_RAW_CODEBERG="https://codeberg.org/Maidware_Project/Maid-Suite/raw/branch/main"

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
    LATEST_TAG="$(curl -fsSL "https://api.github.com/repos/$REPO/releases/latest" 2>/dev/null | sed -n 's/.*"tag_name"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -n 1)"
    _fetched=0
    _urls=()
    if [ -n "$LATEST_TAG" ]; then
      _urls+=("https://codeload.github.com/$REPO/tar.gz/refs/tags/$LATEST_TAG")
      _urls+=("https://codeberg.org/Maidware_Project/Maid-Suite/archive/${LATEST_TAG}.tar.gz")
    fi
    _urls+=("https://codeload.github.com/$REPO/tar.gz/refs/heads/main")
    _urls+=("https://codeberg.org/Maidware_Project/Maid-Suite/archive/main.tar.gz")
    for _tar_url in "${_urls[@]}"; do
      if curl -fsSL "$_tar_url" | tar -xz -C "$FETCH_TMP" 2>/dev/null; then
        PKGDIR="$(find "$FETCH_TMP" -mindepth 1 -maxdepth 1 -type d | head -n 1)"
        if [ -f "$PKGDIR/bin/maid-suite.sh" ]; then _fetched=1; break; fi
        rm -rf "$FETCH_TMP"/* 2>/dev/null || true
      fi
    done
    [ "$_fetched" = "1" ] || { echo "fetch failed (tried GitHub and Codeberg)" >&2; exit 1; }
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
session_env_line() {
  local de="${XDG_CURRENT_DESKTOP:-}" sess="${XDG_SESSION_DESKTOP:-}" dses="${DESKTOP_SESSION:-}"
  local label="unknown"
  case "$de $sess $dses" in
    *[Pp]lasma*|*[Kk][Dd][Ee]*) label="KDE Plasma" ;;
    *[Gg][Nn][Oo][Mm][Ee]*) label="GNOME" ;;
    *[Xx][Ff][Cc][Ee]*) label="XFCE" ;;
    *[Mm][Aa][Tt][Ee]*) label="MATE" ;;
    *[Cc]innamon*) label="Cinnamon" ;;
    *[Ll][Xx][Qq]t*) label="LXQt" ;;
    *[Hh]yprland*) label="Hyprland" ;;
    *[Ss]way*) label="Sway" ;;
    *[Ii]3*) label="i3" ;;
    *) [ -n "${de:-}${sess:-}${dses:-}" ] && label="$de" || label="unknown" ;;
  esac
  if command -v pgrep >/dev/null 2>&1; then
    pgrep -x gpuishell >/dev/null 2>&1 && label="$label (+ GPUIShell/gpuishell)"
    pgrep -x horizon >/dev/null 2>&1 && label="$label (+ Event Horizon)"
  fi
  echo "Session: $label | XDG_CURRENT_DESKTOP=${de:-n/a} | DESKTOP_SESSION=${dses:-n/a} | WAYLAND=${WAYLAND_DISPLAY:+yes}${WAYLAND_DISPLAY:-no} | X11=${DISPLAY:+yes}${DISPLAY:-no}"
}
distro_env_line() {
  if [ -r /etc/os-release ]; then
    # shellcheck disable=SC1091
    . /etc/os-release
    echo "Distro: ${PRETTY_NAME:-${NAME:-unknown}} (id=${ID:-?}${ID_LIKE:+ like=${ID_LIKE}})"
  elif [ "$(uname -s 2>/dev/null)" = "Linux" ]; then
    echo "Distro: Linux (unidentified)"
  else
    echo "Distro: $(uname -s 2>/dev/null || echo unknown)"
  fi
}

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
say "$(session_env_line)"
say "$(distro_env_line)"
say "installed maid-suite (TUI) + maid-suite-gui (native Qt/KDE Plasma GUI) -> $BINDIR"
say "app menu entry -> $APPS/maid-suite.desktop"
say "launch: maid-suite   (unified install/update/status for the Maidware tools)"

if [ "$TUI" = "1" ]; then
  exec "$BINDIR/maid-suite"
fi
exit 0
