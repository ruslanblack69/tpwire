#!/bin/zsh
# Remove tpwire: unload the agent and delete installed files.
set -eu

LABEL="black.ruslan.tpwire"
BIN="$HOME/.local/bin/tpwire"
AGENT="$HOME/Library/LaunchAgents/$LABEL.plist"

launchctl bootout "gui/$(id -u)/$LABEL" 2>/dev/null || true
rm -f "$AGENT" "$BIN"

print -- "Removed agent, script, and plist."
print -- "Note: previously unpaired trackpads stay unpaired. Re-pair via System Settings if wanted."
