#!/usr/bin/env bash
#
# omarchy-course-verify — read-only health check for the Stevinator free
# Omarchy course (https://stevinator.com/courses/omarchy).
#
# Every check below mirrors a real item from the course's own Module 0
# Checkpoint and later modules. Nothing here modifies your system: every
# command is a read-only inspection (status, version, --dry-run style
# queries). Review this file before running it — that's the whole point.
#
# Usage:
#   ./verify.sh            # run all checks
#   ./verify.sh --module 0 # run only Module 0's checks (Installation/Firmware/etc.)
#
set -u

PASS=0
FAIL=0
SKIP=0

ok()   { printf '\033[32m\xe2\x9c\x93\033[0m %s\n' "$1"; PASS=$((PASS+1)); }
bad()  { printf '\033[31m\xe2\x9c\x97\033[0m %s\n' "$1"; FAIL=$((FAIL+1)); }
skip() { printf '\033[90m-\033[0m %s (skipped: %s)\n' "$1" "$2"; SKIP=$((SKIP+1)); }
section() { printf '\n\033[1m%s\033[0m\n' "$1"; }

have() { command -v "$1" >/dev/null 2>&1; }

section "Installation"
if have omarchy; then
	if omarchy version >/dev/null 2>&1; then
		ok "Omarchy installed — $(omarchy version 2>/dev/null | head -n1)"
	else
		bad "omarchy command found but 'omarchy version' failed"
	fi
else
	bad "omarchy command not found on PATH"
fi

section "Firmware"
if have bootctl; then
	bootctl_out=$(bootctl status 2>&1)
	loader=$(printf '%s\n' "$bootctl_out" | grep -m1 'Product:' | sed 's/^ *Product: *//')
	if [ -n "$loader" ]; then
		if printf '%s\n' "$bootctl_out" | grep -qi 'permission denied'; then
			ok "Bootloader detected: $loader (partial report — run 'sudo bootctl status' yourself for the full one)"
		else
			ok "Bootloader detected: $loader (full report)"
		fi
	else
		bad "Could not read any bootloader info from 'bootctl status'"
	fi
else
	skip "Bootloader check" "bootctl not found"
fi

section "Omarchy desktop"
if have hyprctl; then
	ok "Hyprland/hyprctl available"
else
	bad "hyprctl not found — Hyprland may not be running"
fi

section "Hardware — network"
if have omarchy && omarchy network status >/dev/null 2>&1; then
	ok "Network status reachable via 'omarchy network status'"
elif have nmcli && nmcli -t -f STATE general status 2>/dev/null | grep -q connected; then
	ok "Network connected (via nmcli)"
else
	bad "No network connection detected"
fi

section "Hardware — audio"
if have pactl && pactl info >/dev/null 2>&1; then
	ok "Audio subsystem reachable (pactl info)"
else
	skip "Audio check" "pactl not available or PipeWire/PulseAudio not running"
fi

section "Hardware — Bluetooth"
if have bluetoothctl; then
	if bluetoothctl show >/dev/null 2>&1; then
		ok "Bluetooth controller present"
	else
		skip "Bluetooth check" "no controller found"
	fi
else
	skip "Bluetooth check" "bluetoothctl not found"
fi

section "Hardware — display"
if have hyprctl && hyprctl monitors all >/dev/null 2>&1; then
	ok "Display info reachable ('hyprctl monitors all')"
else
	skip "Display check" "hyprctl not available or no active session"
fi

section "Development — Git"
if have git; then
	if git config --get user.name >/dev/null 2>&1 && git config --get user.email >/dev/null 2>&1; then
		ok "Git installed and configured ($(git config --get user.name))"
	else
		bad "Git installed but user.name/user.email not configured"
	fi
else
	bad "git not found"
fi

section "Development — GitHub CLI"
if have gh; then
	if gh auth status >/dev/null 2>&1; then
		ok "GitHub CLI authenticated"
	else
		bad "gh installed but not authenticated — run 'gh auth login'"
	fi
else
	bad "gh (GitHub CLI) not found"
fi

section "Development — mise"
if have mise; then
	ok "mise installed — $(mise --version 2>/dev/null)"
else
	bad "mise not found"
fi

section "System health"
if have systemctl; then
	failed_system=$(systemctl --failed --no-legend 2>/dev/null | wc -l)
	failed_user=$(systemctl --user --failed --no-legend 2>/dev/null | wc -l)
	if [ "$failed_system" -eq 0 ] && [ "$failed_user" -eq 0 ]; then
		ok "0 failed systemd units (system + user)"
	else
		bad "$failed_system failed system unit(s), $failed_user failed user unit(s) — see 'systemctl --failed'"
	fi
else
	skip "systemd health check" "systemctl not found"
fi

section "Recovery"
if have omarchy-snapshot || have snapper; then
	ok "Snapshot tooling present"
else
	skip "Snapshot check" "no known snapshot tool found on PATH"
fi

echo
printf 'Summary: \033[32m%d passed\033[0m, \033[31m%d failed\033[0m, %d skipped\n' "$PASS" "$FAIL" "$SKIP"
[ "$FAIL" -eq 0 ]
