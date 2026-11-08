#!/usr/bin/env bash
# Safe, explicit-consent ADB-over-WiFi connect helper (minimal vertical slice).
# Does ONLY: show status, and (if you explicitly provide ip:port and confirm)
# run `adb connect <ip:port>` + `adb devices`. No shell on device, no
# push/pull/install/reboot, no destructive commands. LAN-only by design;
# never expose ADB beyond your trusted network.
set -u
echo "Maid Suite - ADB over Wi-Fi (explicit consent, non-destructive)"
echo "---------------------------------------------------------------"
echo "This helper ONLY runs: adb devices / adb connect <ip:port> (you provide)."
echo "It never runs commands on the device and never transfers/installs/reboots."
echo "Use on a trusted LAN only. Enable Wireless debugging on the device first."
echo
if ! command -v adb >/dev/null 2>&1; then
  echo "adb not found. Install Android platform-tools from your distro."
  exit 1
fi
echo "Current devices:"; adb devices -l 2>&1 || true
echo
printf "Connect a device now? [y/N]: "
read -r ans || ans=""
case "${ans:-}" in y|Y|yes|YES) ;; *) echo "No changes made."; exit 0 ;; esac
printf "Enter device address (ip:port, e.g. 192.168.1.50:37123): "
read -r addr || addr=""
case "${addr:-}" in
  "" ) echo "No address provided; cancelled."; exit 0 ;;
  *[!0-9a-fA-F.:]* ) echo "Refusing: address contains unexpected characters."; exit 1 ;;
esac
printf "Confirm: run 'adb connect %s' on your trusted LAN? [y/N]: " "$addr"
read -r c2 || c2=""
case "${c2:-}" in y|Y|yes|YES) ;; *) echo "Cancelled."; exit 0 ;; esac
echo
echo "==> adb connect $addr"
adb connect "$addr" 2>&1 || true
echo
echo "==> adb devices -l"
adb devices -l 2>&1 || true
