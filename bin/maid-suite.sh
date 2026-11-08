#!/usr/bin/env bash
# Maid Suite - unified TUI to install/update/check the Maidware tools.
# Orchestrates each tool's OFFICIAL installer (fetched over HTTPS). No secrets stored.
set -u

RAW_BASE="https://raw.githubusercontent.com/Maidware-Project"
# registry: id|label|repo|marker_commands(space-sep, any = installed)
TOOLS=(
  "au|Maid AU (updates)|Maid-AU|update-all.sh"
  "helper|Maid Helper|Maid-Helper|maid-helper"
  "runner|Maid Runner|Maid-Runner|maid-runner"
  "share|Maidshare|Maidshare|maidshare"
  "bt|Maid BT (Bluetooth)|Maid-BT|bluetooth-toggle.sh"
)

B="\033[1m"; D="\033[2m"; R="\033[0m"; G="\033[32m"; Y="\033[33m"; C="\033[36m"
hr() { printf '%*s\n' "${COLUMNS:-80}" '' | tr ' ' '-'; }
say() { printf '  %b==>%b %s\n' "$C" "$R" "$*"; }
warn() { printf '  %b!!%b %s\n' "$Y" "$R" "$*" >&2; }
ok() { printf '  %bok%b %s\n' "$G" "$R" "$*"; }
pause() { printf '\n  %bpress Enter to continue%b' "$D" "$R"; read -r _ || true; }

term_size() {
  local sz
  sz="$(stty size 2>/dev/null </dev/tty)" || sz="${LINES:-24} ${COLUMNS:-80}"
  ROWS="${sz%% *}"; COLS="${sz##* }"
  [ "${ROWS:-0}" -ge 4 ] 2>/dev/null || ROWS=24
  [ "${COLS:-0}" -ge 20 ] 2>/dev/null || COLS=80
}

maidware_boot() {
  [ -t 0 ] && [ -t 1 ] || return 0
  case "${TERM:-}" in ""|dumb|linux) return 0 ;; esac
  [ -z "${NO_COLOR:-}" ] || return 0
  [ "${MAID_FAST:-0}" = "1" ] && return 0
  term_size
  [ "$COLS" -ge 34 ] || return 0; [ "$ROWS" -ge 8 ] || return 0
  local -a letters=(M A I D W A R E)
  local -a rots=('|' '/' '-' $'\\')
  local -a pal=("\033[94m" "\033[96m" "\033[92m" "\033[93m" "\033[95m")
  local n slot pad
  n=${#letters[@]}; [ "${n:-0}" -ge 1 ] 2>/dev/null || return 0
  slot=3
  pad=$(( (COLS - n*slot)/2 )); [ "$pad" -ge 0 ] || pad=0
  local -a reveal=()
  local i
  for ((i=0;i<n;i++)); do reveal[i]=$((2+i)); done
  local total wordrow f col glyph startcol
  total=$((reveal[n-1]+2))
  wordrow=$((ROWS/2 - 2))
  printf '\033[?25l\033[0m'
  for ((f=0; f<total; f++)); do
    printf '\033[%d;1H\033[2K' "$wordrow"
    for ((i=0;i<n;i++)); do
      col=$(( pad + i*slot + 1 ))
      if [ "$f" -ge "${reveal[i]}" ]; then
        glyph="$(printf "${pal[$(( (f+n-i) % ${#pal[@]} ))]}")"
        printf '\033[%d;%dH%s%s\033[0m' "$wordrow" "$col" "$glyph" "${letters[i]}"
      elif [ "$f" -lt $(( reveal[i]-2 )) ]; then
        [ "$f" -gt 0 ] && printf '\033[%d;%dH\033[2m%s\033[0m' "$wordrow" "$col" "${rots[$(( (f+i)%${#rots[@]} ))]}"
      else
        startcol=1; [ $((i%2)) -eq 0 ] || startcol=$COLS
        [ "$f" -eq $((reveal[i]-2)) ] && col=$startcol || col=$(( (col+startcol)/2 ))
        glyph="$(printf "${pal[$(( (f+i) % ${#pal[@]} ))]}")"
        printf '\033[%d;%dH%s%s\033[0m' "$wordrow" "$col" "$glyph" "${letters[i]}"
      fi
    done
    local k=""; read -t 0.07 -n 1 -s k 2>/dev/null || true
    if [ -n "${k:-}" ] && [ "$k" != $'\004' ] && [ "$k" != $'\000' ]; then break; fi
  done
  local word=""; for ((i=0;i<n;i++)); do word="$word ${letters[i]} "; done
  printf '\033[%d;1H\033[2K%*s\033[1;97m%s\033[0m' "$wordrow" "$pad" '' "$word"
  printf '\033[%d;1H\033[2K%*s\033[2mMaid Suite - install / update the whole set\033[0m' "$((wordrow+1))" "$(( (COLS-38)/2 ))" ''
  sleep 0.4
  printf '\033[?25h\033[0m\033[2J\033[H'
}

tool_field() { # idx field(1=id 2=label 3=repo 4=markers)
  local rec="${TOOLS[$1]}"
  echo "$rec" | cut -d'|' -f"$2"
}

is_installed() {
  local markers="$1" m
  for m in $markers; do
    command -v "$m" >/dev/null 2>&1 && return 0
    [ -x "$HOME/.local/bin/$m" ] && return 0
  done
  return 1
}

status_line() {
  local i=0 label markers
  for rec in "${TOOLS[@]}"; do
    label="$(echo "$rec" | cut -d'|' -f2)"
    markers="$(echo "$rec" | cut -d'|' -f4)"
    if is_installed "$markers"; then ok "$label"; else printf '  %b..%b %s %b(not detected)%b\n' "$D" "$R" "$label" "$D" "$R"; fi
    i=$((i+1))
  done
}

pick_tools() {
  # prints selected indices, one per line; empty = cancelled
  local i=0 label markers mark
  echo >&2; echo "  Select tools (examples: 1 3 5  or  1,3,5  or  a = all, q = back):" >&2
  for rec in "${TOOLS[@]}"; do
    i=$((i+1))
    label="$(echo "$rec" | cut -d'|' -f2)"
    markers="$(echo "$rec" | cut -d'|' -f4)"
    mark=" "; is_installed "$markers" && mark="*"
    printf '   %b%d%b) [%s] %s\n' "$B" "$i" "$R" "$mark" "$label" >&2
  done
  printf '  %b>%b ' "$B" "$R" >&2
  local ans; read -r ans || return 0
  case "${ans:-}" in q|Q|back|cancel|"") return 0 ;; a|A|all) for ((i=0;i<${#TOOLS[@]};i++)); do echo "$i"; done; return 0 ;; esac
  # parse numbers
  ans="$(echo "$ans" | tr ',' ' ')"
  local n
  for n in $ans; do
    if [[ "$n" =~ ^[0-9]+$ ]] && [ "$n" -ge 1 ] && [ "$n" -le "${#TOOLS[@]}" ]; then
      echo $((n-1))
    fi
  done
}

run_installer() {
  local repo="$1" label="$2" mode="$3" # mode: install|update (informational)
  local url="$RAW_BASE/$repo/main/install.sh"
  say "$mode: $label (official installer)"
  printf '    %s\n' "$url"
  if ! command -v curl >/dev/null 2>&1; then warn "curl not found; cannot fetch $label"; return 1; fi
  local tmp; tmp="$(mktemp /tmp/maid-suite.XXXXXX.sh)"
  if ! curl -fsSL "$url" -o "$tmp"; then
    warn "fetch failed for $label ($url)"; rm -f "$tmp"; return 1
  fi
  # In a non-interactive Suite session, avoid surprise sudo: pass
  # --no-packages so the child stays safe (you can rerun it with
  # --packages later). In an interactive tty, run it normally.
  local args=()
  if [ ! -t 0 ]; then args+=(--no-packages); fi
  bash "$tmp" "${args[@]}"
  local rc=$?
  rm -f "$tmp"
  [ "$rc" -eq 0 ] && ok "$label done" || warn "$label exited $rc (review output above)"
  return "$rc"
}

do_install() { # $1 = install|update
  local mode="$1" idx
  while IFS= read -r idx; do
    [ -z "$idx" ] && continue
    run_installer "$(tool_field "$idx" 3)" "$(tool_field "$idx" 2)" "$mode"
    echo
  done < <(pick_tools)
  pause
}

menu() {
  term_size
  printf '\n%bMaid Suite%b %b(Helper + AU + the whole set, one place)%b\n' "$B" "$R" "$D" "$R"
  hr
  printf '  %btype a number and press Enter · %bq%b cancels/back%b\n\n' "$D" "$B" "$D" "$R"
  printf '  %b1%b) install/update %ball%b tools (recommended)\n' "$B" "$R" "$B" "$R"
  printf '  %b2%b) install/update %bselected%b tools\n' "$B" "$R" "$B" "$R"
  printf '  %b3%b) system %bcheck/fix%b (Maid Helper, if installed)\n' "$B" "$R" "$B" "$R"
  printf '  %b4%b) run %bMaid AU%b updater (update-all.sh, if installed)\n' "$B" "$R" "$B" "$R"
  printf '  %b5%b) doctor / status (what’s detected)\n' "$B" "$R"
  printf '  %b6%b) about + KDE Plasma / desktop options\n' "$B" "$R"
  printf '  %bq%b) quit\n\n' "$B" "$R"
  printf '  %b>%b ' "$B" "$R"
}

run_if_present() { # cmd label
  local cmd="$1" label="$2"
  if command -v "$cmd" >/dev/null 2>&1; then
    say "running $label ($cmd)"
    "$cmd"
    return $?
  elif [ -x "$HOME/.local/bin/$cmd" ]; then
    say "running $label ($HOME/.local/bin/$cmd)"
    "$HOME/.local/bin/$cmd"
    return $?
  else
    warn "$label is not installed here. Use option 1 or 2 to install it via Suite."
    return 1
  fi
}

maidware_boot

while true; do
  menu
  read -r choice || { echo; exit 0; }
  case "${choice:-}" in
    1)
      echo; for rec in "${TOOLS[@]}"; do
        run_installer "$(echo "$rec"|cut -d'|' -f3)" "$(echo "$rec"|cut -d'|' -f2)" "install/update"; echo
      done
      pause ;;
    2) do_install "install/update" ;;
    3)
      echo
      if command -v maid-helper >/dev/null 2>&1 || [ -x "$HOME/.local/bin/maid-helper" ]; then
        say "Maid Helper: runs its own checks/fixes (it will ask before changes)."
        run_if_present "maid-helper" "Maid Helper" || true
      else
        warn "Maid Helper not detected. Install it now via Suite? (y/N)"
        read -r yn || yn=""; case "$yn" in [Yy]*) run_installer "Maid-Helper" "Maid Helper" "install" ;; esac
      fi
      pause ;;
    4)
      echo
      if command -v update-all.sh >/dev/null 2>&1 || [ -x "$HOME/.local/bin/update-all.sh" ]; then
        say "Maid AU (update-all.sh): running its updater flow."
        run_if_present "update-all.sh" "Maid AU updater" || true
      else
        warn "Maid AU (update-all.sh) not detected. Suite option 1/2 can install/update everything in one place."
      fi
      pause ;;
    5) echo; hr; status_line; hr; pause ;;
    6)
      echo
      say "One place for Helper + AU style workflows + install/update of the whole Maidware set."
      say "KDE Plasma / desktops: installer adds a menu entry (maid-suite.desktop). Launch from your app menu or run: maid-suite"
      say "Safe: official installers fetched over HTTPS, URLs shown. Non-interactive runs pass --no-packages to child installers."
      say "Roadmap (compositor support, phone integration): docs/ROADMAP-2.md"
      pause ;;
    q|Q|quit|exit|"") echo "  bye!"; exit 0 ;;
    *) warn "choose 1-6 or q" ;;
  esac
done
