# web agents cell

A cell you drive from a terminal: tmux, nvim, and three coding agents — Claude
Code, Codex and opencode — behind a Surfshark tunnel and a firewall that refuses
everything not named in `cell.yaml`. Each tmux window's tab shows what Claude
Code in it is doing: 🤖 working, 💬 waiting for you, ✅ done. Node with corepack
is the toolchain in it; a web project's own package manager comes from its
package.json.

The sibling cells are `kvm-agents`, which is this one plus the Go toolchain and
`/dev/kvm`, and `soundor-agents`, which is this one plus soundor's JUCE
toolchain and a GPU. They are copies of this directory rather than layers on top
of it, so a change here is a change to make there too.

## Start

```bash
solitary secrets web-agents   # GH_TOKEN
solitary up web-agents
```

The VPN configuration holds a private key, so it is not in this directory. Put
yours at `cells/web-agents/vpn.conf` before the first start.

## Signing in

None of the agents ships credentials in the image. They keep them in
`/home/cell`, which is on the machine's disk and outlives the container, so this
is once per cell rather than once per start.

- **Claude Code** — run `claude` and follow the login.
- **Codex** — run `codex` and follow the login.
- **opencode** — run `opencode`, then `/connect`, and pick OpenCode Zen or
  OpenCode Go. It asks for an API key: open opencode.ai/auth on the host, copy
  the key from there and paste it in. It is kept in
  `~/.local/share/opencode/auth.json`.

## What comes from the host

The point of this cell is that it works the way your machine does, so the parts
that make it yours are pinned to the host's versions and copied from the host's
configuration:

| In the cell | Where it comes from |
| --- | --- |
| nvim + plugins, mason tools, treesitter parsers | `dm-balakin/nvim-config`, built at image build |
| tmux 3.8 | pinned, a release ahead of the host's 3.7c |
| catppuccin v2.3.2 | pinned, a release ahead of the host's v2.3.0 |
| Claude Code statusline and window-mark hooks | `statusline.sh`, `claude-settings.json` |

## Updating

Nothing in the cell updates itself. The container is started over from the image
every time the machine boots, so an update an agent downloads into it is gone by
the next boot — Claude Code's and opencode's auto-updaters are off, and gh's and
npm's version notices with them. Codex can still mention a newer release; the rebuild
is what brings it in. Update by rebuilding instead:

```sh
solitary up --rebuild web-agents
```

or `b` in `solitary dashboard`. That builds the `Containerfile` again without a
cache, so Claude Code, Codex, opencode and gh come in at their latest and everything
pinned stays where it is pinned. The home is kept; every session in the cell
ends.

## The browser

Playwright and its Chromium are in the image, in `/opt/ms-playwright` rather
than the home, so a fresh cell has a browser without downloading one. There is
no display: it runs headless, and it reaches only what `network.allow` names,
like everything else here.

All three agents are told it is there. `/opt/cell-instructions.md` is one note
about what this cell is, linked in at start as Claude Code's
`~/.claude/CLAUDE.md` and Codex's `~/.codex/AGENTS.md`; opencode reads Claude
Code's, having no `~/.config/opencode/AGENTS.md` of its own. Replace either
with a real file inside the cell and that file wins.

## The firewall

The cell only resolves and reaches the names in `cell.yaml`, so an agent's web
fetch of an arbitrary URL fails, and it fails as a DNS error rather than a
timeout. Add the domain to `network.allow` if you want it, remembering that
everything in that list is reachable by every agent here. The list is a machine
setting, so it applies at the next boot rather than at a
rebuild: `solitary down web-agents && solitary up web-agents`.
