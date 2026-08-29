# kvm agents cell

Where `solitary` is developed. `web-agents` with three things added: the Go
toolchain it is built with — Go, golangci-lint, goreleaser — `/dev/kvm`, passed
in with `devices:`, and qemu and lima to use it with.

Everything else is the same cell, and the two directories are copies rather
than one shared context: a cell's build context is the directory its
Containerfile sits in, so a change made to one has to be made to the other by
hand.

## The device

The host allows nested virtualisation and the machine's kernel has the node, so
`/dev/kvm` inside the cell is real: a guest started here is a third level under
the host and the cell. `up` hands the node to the machine's user at every
start, which is what makes it openable from inside a rootless container.

qemu and lima are in the image, pinned to the host's lima version, so a
`solitary` built in a worktree here can create a machine here: host, cell,
guest. That is also why this cell names a `user:` where its sibling does not —
limactl refuses to run as root, and a cell is root in its container until the
definition says otherwise, so work here happens as `cell`. The guest's memory and disk come out of this cell's, which is why it
asks for 6GiB and 80GiB where its sibling asks for 7 and 40.

That is also the one thing to watch on the host: a guest's memory is a file on
`/dev/shm`, which holds 7.7GiB, so this cell and `web-agents` do not both fit
at once. Bring one down before the other comes up.

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
| go, golangci-lint, goreleaser | pinned in the `Containerfile` |
| /dev/kvm | the machine's own node, passed in by `devices:` |
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
