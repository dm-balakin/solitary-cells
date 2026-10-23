# solitary cells

My [`solitary`](https://solitary.balakin.io) configuration: the user-wide
defaults and the two cell definitions I work in. `solitary` reads all of this
from `~/.config/solitary`, so this repository *is* that directory — clone it
there rather than somewhere else and symlinking.

```sh
git clone https://github.com/dm-balakin/solitary-cells.git ~/.config/solitary
```

Nothing here is secret. What is — the tokens, the VPN credential — stays on the
machine and is named in `.gitignore`; see [Secrets](#secrets) below.

## The cells

| Cell | What it is |
| --- | --- |
| [`web-agents`](cells/web-agents) | Claude Code, Codex and opencode in tmux, with nvim and node |
| [`kvm-agents`](cells/kvm-agents) | `web-agents` plus the Go toolchain, qemu, lima and `/dev/kvm` — where `solitary` itself is developed |
| [`soundor-agents`](cells/soundor-agents) | `web-agents` plus what [soundor](https://github.com/soundor/soundor) builds a plugin with — cmake, ninja, Clang, lld and JUCE — and the host's GPU to render with |

Each has its own README with what it holds, how to sign the agents in and what
it can reach. The other two are copies of the first rather than layers on top
of it: a cell's build context is the directory its `Containerfile` sits in, so
there is no way to share one. A change to one is a change to make to all three.

All three are built on `ubuntu:24.04`, run behind a Surfshark tunnel, and
resolve and reach only the domains their `cell.yaml` names — an unlisted host
does not resolve at all. The versions that make a cell feel like this machine
(nvim, tmux, lima) are pinned in the `Containerfile` to the host's.

## Setting up a machine

```sh
cp config.example.yaml config.yaml     # then put your git identity in it
cp /path/to/wireguard.conf cells/web-agents/vpn.conf
solitary secrets web-agents            # GH_TOKEN
solitary up web-agents
```

`config.yaml` is the user-wide defaults every cell inherits — currently just the
name and email cells commit as. It is ignored rather than committed because it
is per machine; `config.example.yaml` is the template, and the two should move
together.

The VPN configuration is a Surfshark WireGuard file with its `DNS` line removed:
these cells resolve through `network.resolvers` in their own `cell.yaml`, and a
`DNS` line in the tunnel would race it.

## Layout

```
config.example.yaml         the template for the ignored config.yaml
cells/<name>/
  cell.yaml                 the cell: image, secrets, ports, network, vm
  Containerfile             the image, built inside the machine
  cell-init.sh              runs at every container start, over the cell's home
  README.md                 what this cell is
  prompt.sh tmux.conf system-stats.sh statusline.sh claude-settings.json
  nvim-bootstrap.lua        the shell, tmux and editor the cell comes up in
  agent-status              marks a tmux window with what Claude Code is doing
```

## Secrets

Three things never enter this repository, and `.gitignore` holds the line for
each:

- `cells/*/.env` — written by `solitary secrets`, holds `GH_TOKEN` itself. A
  cell's `cell.yaml` declares the *name*; only declared names are passed in.
- `cells/*/vpn.conf` — a WireGuard private key. Yours, not the cell's.
- `config.yaml` — user-wide and per machine.

Nothing else in here is sensitive: `cell.yaml` names secrets without holding
them, and the agents' credentials are written inside the cell, on the machine's
disk, and never reach the host.
