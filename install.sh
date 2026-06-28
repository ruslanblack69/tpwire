#!/bin/zsh
# Install tpwire: copy the script, optionally pin the trackpad by MAC,
# render the LaunchAgent, and load it. Safe to re-run: an existing config
# is left untouched and the agent is cleanly reloaded.
set -eu

LABEL="black.ruslan.tpwire"
BIN_DIR="$HOME/.local/bin"
BIN="$BIN_DIR/tpwire"
AGENT_DIR="$HOME/Library/LaunchAgents"
AGENT="$AGENT_DIR/$LABEL.plist"
LOG="$HOME/Library/Logs/tpwire.log"
CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/tpwire"
CONFIG="$CONFIG_DIR/config"
SRC="$(cd "$(dirname "$0")" && pwd)"

find_blueutil() {
  local c
  for c in \
    "$(command -v blueutil 2>/dev/null || true)" \
    /opt/homebrew/bin/blueutil \
    /usr/local/bin/blueutil
  do
    [ -n "${c:-}" ] && [ -x "$c" ] && { print -r -- "$c"; return 0; }
  done
  return 1
}

BLUEUTIL="$(find_blueutil)" || {
  print -u2 -- "blueutil not found. Install it first: brew install blueutil"
  exit 127
}

# Optionally pin to the trackpad's (stable) Bluetooth MAC. Skipped entirely
# if a config already exists, so a re-install never clobbers your address.
configure_mac() {
  if [ -f "$CONFIG" ]; then
    print -- "Config exists, keeping it: $CONFIG"
    grep -E '^[[:space:]]*TPWIRE_MAC' "$CONFIG" 2>/dev/null || true
    return 0
  fi

  printf 'Pin the trackpad by its Bluetooth MAC (recommended)? [Y/n] '
  local ans mac; read -r ans || ans=""
  case "$ans" in [Nn]*) print -- "OK, tpwire will match by name."; return 0;; esac

  mac="$("$BLUEUTIL" --paired \
        | grep -i 'Magic Trackpad' \
        | grep -oiE '([0-9a-f]{2}-){5}[0-9a-f]{2}' \
        | head -1)"
  if [ -z "$mac" ]; then
    print -- "No paired 'Magic Trackpad' found (connect/pair it first to auto-detect)."
    printf 'Enter MAC manually (xx-xx-xx-xx-xx-xx), or leave empty to match by name: '
    read -r mac || mac=""
    [ -z "$mac" ] && { print -- "OK, tpwire will match by name."; return 0; }
  fi

  mac="${mac//:/-}"; mac="${mac:l}"
  if ! print -r -- "$mac" | grep -qE '^([0-9a-f]{2}-){5}[0-9a-f]{2}$'; then
    print -u2 -- "Invalid MAC '$mac'; tpwire will match by name."
    return 0
  fi

  mkdir -p "$CONFIG_DIR"
  print -- "TPWIRE_MAC=$mac" > "$CONFIG"
  print -- "Wrote $CONFIG (TPWIRE_MAC=$mac)"
}

mkdir -p "$BIN_DIR" "$AGENT_DIR"
install -m 0755 "$SRC/bin/tpwire" "$BIN"

configure_mac

sed -e "s#__TPWIRE_BIN__#$BIN#g" \
    -e "s#__LOG__#$LOG#g" \
    "$SRC/launchd/$LABEL.plist.template" > "$AGENT"

launchctl bootout "gui/$(id -u)/$LABEL" 2>/dev/null || true
launchctl bootstrap "gui/$(id -u)" "$AGENT"

print -- "Installed. Agent: $LABEL"
print -- "Script:  $BIN"
if [ -f "$CONFIG" ]; then
  print -- "Config:  $CONFIG ($(grep -E '^[[:space:]]*TPWIRE_MAC' "$CONFIG" | head -1))"
else
  print -- "Config:  none — matching the trackpad by name"
fi
print -- "Log:     $LOG"
