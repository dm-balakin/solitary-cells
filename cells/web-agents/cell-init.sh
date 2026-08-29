#!/bin/sh
# Runs at container start, before the cell settles into its long-running
# command. Everything here is idempotent: it runs again on every start.
#
# This exists because both agents read their configuration from the cell's home
# — a directory on the machine, mounted over whatever the image put there, so
# the build cannot write it. The image ships the intent under /opt and this
# applies it at start instead.
set -eu

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

# pi's mcp adapter reads the tool-agnostic ~/.config/mcp/mcp.json, so the same
# server is declared there rather than taught to pi separately. This file is
# ours alone — nothing else writes it — so it is replaced outright.
mkdir -p "$HOME/.config/mcp"
cat > "$HOME/.config/mcp/mcp.json" <<'JSON'
{
  "mcpServers": {
    "context7": {
      "type": "http",
      "url": "https://mcp.context7.com/mcp"
    }
  }
}
JSON

# --- pi's agent directory ----------------------------------------------------
#
# ~/.pi/agent holds two kinds of thing. What the image owns — the theme, the
# extensions, the skills — is symlinked, so rebuilding the cell with a new
# version of the config is enough to update it. What pi itself writes — the
# login, the sessions, the settings it edits when you change a theme or a model
# from inside — is seeded once and then left alone.
agent="$HOME/.pi/agent"
mkdir -p "$agent"

for dir in themes extensions skills; do
	# Only ever replace our own symlink. A real directory here is something
	# put there by hand inside the cell, and it wins.
	if [ ! -e "$agent/$dir" ] || [ -L "$agent/$dir" ]; then
		ln -sfn "/opt/pi/$dir" "$agent/$dir"
	fi
done

[ -e "$agent/settings.json" ] || cp /opt/pi/settings.json "$agent/settings.json"

# The packages, copied rather than linked: pi installs into this directory when
# you add one from inside the cell, and that should survive the container being
# recreated.
[ -e "$agent/npm" ] || cp -a /opt/pi/npm "$agent/npm"
