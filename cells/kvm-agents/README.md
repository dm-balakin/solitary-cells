# kvm agents cell

Where `solitary` is developed. `web-agents` with three things added: the Go
toolchain it is built with — Go, golangci-lint, goreleaser — `/dev/kvm`, passed
in with `devices:`, and qemu and lima to use it with.

Everything else is the same cell, browser included, and the directories —
these two and `soundor-agents`, a third copy with JUCE in it — are copies
rather than one shared context: a cell's build context is the directory its Containerfile sits
in, so a change made to one has to be made to the others by hand.

## The device

The host allows nested virtualisation and the machine's kernel has the node, so
`/dev/kvm` inside the cell is real: a guest started here is a third level under
the host and the cell. `up` hands the node to the machine's user at every
start, which is what makes it openable from inside a rootless container.

qemu and lima are in the image, pinned to the host's lima version, so a
`solitary` built in a worktree here can create a machine here: host, cell,
guest. That is also why this cell names a `user:` where its siblings do not —
limactl refuses to run as root, and a cell is root in its container until the
definition says otherwise, so work here happens as `cell`. The guest's memory
and disk come out of this cell's, which is why it asks for 80GiB of disk where
its siblings ask for 40. The memory is the same 6GiB on all three.

That is also the one thing to watch on the host: a machine's memory is a file
on `/dev/shm`, which holds 7.6GiB, so no two of the three cells fit at once.
Bring one down before another comes up.

The nested machine reaches the network through this cell's firewall, so what a
guest can fetch is what `network.allow` names — `ubuntu.com` is in it, which is
where lima gets its image.

## Start

```bash
solitary secrets kvm-agents   # GH_TOKEN
solitary up kvm-agents
```

The VPN configuration holds a private key, so it is not in this directory. Put
yours at `cells/kvm-agents/vpn.conf` before the first start.

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
| go, golangci-lint, goreleaser | pinned in the `Containerfile` |
| /dev/kvm | the machine's own node, passed in by `devices:` |
| Claude Code statusline and window-mark hooks | `statusline.sh`, `claude-settings.json` |
| Codex's and opencode's window marks | `codex-config.toml`, `opencode/plugins/agent-status.js` |

## Updating

Nothing in the cell updates itself. The container is started over from the image
every time the machine boots, so an update an agent downloads into it is gone by
the next boot — Claude Code's and opencode's auto-updaters are off, and gh's and
npm's version notices with them. Codex can still mention a newer release; the rebuild
is what brings it in. Update by rebuilding instead:

```sh
solitary up --rebuild kvm-agents
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
rebuild: `solitary down kvm-agents && solitary up kvm-agents`.
