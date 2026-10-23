#!/bin/sh
# Runs at container start, before the cell settles into its long-running
# command. Everything here is idempotent: it runs again on every start.
#
# This exists because the agents read their configuration from the cell's home
# — a directory on the machine, mounted over whatever the image put there, so
# the build cannot write it. The image ships the intent under /opt and this
# applies it at start instead.
set -eu

# --- the user this runs as ----------------------------------------------------
#
# A cell that names a user still starts its command as root: solitary maps that
# user onto the machine's and leaves the process itself root, so that a cell
# which hands out a session has something to hand it out with. Everything below
# writes into the home, which belongs to that user — as root it leaves files the
# user cannot read, and ~/.claude.json is one of them, so Claude Code loses its
# login and its history on every start.
#
# So hand the script to whoever owns the home and let it run again as them.
# setpriv rather than su because the home's owner is identified by uid here and
# the environment, HOME included, is already the right one. In a cell with no
# user of its own the home is root's and this does nothing.
if [ "$(id -u)" = 0 ]; then
	home_uid=$(stat -c %u "$HOME")
	if [ "$home_uid" != 0 ]; then
		exec setpriv --reuid "$home_uid" --regid "$(stat -c %g "$HOME")" \
			--clear-groups "$0" "$@"
	fi
fi

# --- MCP servers -------------------------------------------------------------
#
# Claude Code reads them from ~/.claude.json. Merged rather than written: the
# same file holds the login and the session history, and neither survives being
# overwritten.
claude_config="$HOME/.claude.json"
[ -f "$claude_config" ] || echo '{}' > "$claude_config"

tmp=$(mktemp)
if jq '.mcpServers.context7 = {
	"type": "http",
	"url": "https://mcp.context7.com/mcp"
}' "$claude_config" > "$tmp"; then
	mv "$tmp" "$claude_config"
else
	rm -f "$tmp"
	echo "cell-init: could not add the context7 MCP server for claude" >&2
fi
