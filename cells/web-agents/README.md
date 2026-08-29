# web agents cell

A cell you drive from a terminal: tmux and workmux running git worktrees, nvim,
and two coding agents — Claude Code and pi — behind a Surfshark tunnel and a
firewall that refuses everything not named in `cell.yaml`. Node with corepack
is the toolchain in it; a web project's own package manager comes from its
package.json.

The sibling cell is `kvm-agents`, which is this one plus the Go toolchain and
`/dev/kvm`. It is a copy of this directory rather than a layer on top of it, so
a change here is a change to make there too.

## Start

```bash
solitary secrets web-agents   # GH_TOKEN
solitary up web-agents
```

The VPN configuration holds a private key, so it is not in this directory. Put
yours at `cells/web-agents/vpn.conf` before the first start.

## Signing in

Neither agent ships credentials in the image. Both keep them in `/home/cell`,
which is on the machine's disk and outlives the container, so this is once per
cell rather than once per start.

- **Claude Code** — run `claude` and follow the login.
- **pi** — run `pi`, then `/login`, and pick ChatGPT (Codex). There is no
  browser in the cell to catch the loopback callback, so pi's headless path
  applies: open the URL on the host and paste the final redirect URL back into
  the prompt.

## What comes from the host

The point of this cell is that it works the way your machine does, so the parts
that make it yours are pinned to the host's versions and copied from the host's
configuration:

| In the cell | Where it comes from |
| --- | --- |
| nvim + plugins, mason tools, treesitter parsers | `dm-balakin/nvim-config`, built at image build |
| tmux 3.7b, catppuccin, workmux | pinned to the host's versions |
| pi settings, `focus-dark`, extensions, skills | `pi/`, copied from `~/.pi/agent` |
| Claude Code statusline and workmux hooks | `statusline.sh`, `claude-settings.json` |

`pi/` is a snapshot, not a link: when you change something under `~/.pi/agent`
on the host and want it here, copy it across and rebuild.

Inside the cell, `~/.pi/agent/themes`, `extensions` and `skills` are symlinks
into `/opt/pi`, so a rebuild updates them. `settings.json` and `npm/` are seeded
once and then yours — pi writes to both when you change a model or add a
package, and those changes survive the container being recreated.

## The firewall and pi

`pi-web-access` is installed, but the cell only resolves and reaches the names
in `cell.yaml`. Fetching an arbitrary URL fails, and it fails as a DNS error
rather than a timeout. Add the domain to `network.allow` and rebuild if you
want it, remembering that everything in that list is reachable by both agents.
