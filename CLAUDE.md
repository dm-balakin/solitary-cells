# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

`~/.config/solitary` itself, under version control: the user-wide defaults and
the cell definitions [`solitary`](https://solitary.balakin.io) reads. There is
no build and no test suite here — the only way to find out whether a change
works is to build the cell and start it. `README.md` covers the layout and the
setup; this file covers the traps.

## The two cells are copies

`cells/kvm-agents` is `cells/web-agents` plus a Go toolchain, qemu, lima and
`/dev/kvm`. It is a copy, not a layer: a cell's build context is the directory
its `Containerfile` sits in, so nothing can be shared between them.

**A change to either is a change to make to both**, unless it is one of the
things that genuinely differ. Those are, and only these:

- `cell.yaml` — `description`, the `user: cell` line, `devices:`, port 5173 for
  the docs site's dev server, three extra `network.allow` entries (`go.dev`,
  `dl.google.com`, `golang.org`), and `vm.disk` (80GiB against 40GiB) and
  `vm.memory` (6GiB against 8GiB — the sibling is the bigger one, and neither
  fits alongside the other in /dev/shm)
- `Containerfile` — the Go, qemu/lima and `useradd` blocks, and the extra
  version checks in the final `RUN`
- `README.md` — the cell it describes

`diff -r cells/web-agents cells/kvm-agents` should show those and nothing else.
Run it after touching either cell.

## Which file applies when

This decides what a change costs, and it is worth saying in the commit message:

- `cell.yaml` container settings (`build`, `command`, `secrets`, `devices`,
  `user`) and anything the `Containerfile` copies in — `solitary up` applies it,
  rebuilding the image when the `Containerfile` moved.
- `cell.yaml` machine settings (`vm`, `ports`, `network`) — only at the next
  boot. `up` warns on a running machine; the cell has to go down first.
- `cell-init.sh` — every container start. Everything in it must stay
  idempotent, and it must not clobber what the agents write: `~/.claude.json`
  holds the login and the session history, so it is merged with `jq`, and pi's
  `settings.json` and `npm/` are seeded only when absent.

## The firewall is the constraint

A cell resolves and reaches only what `network.allow` names; anything else fails
as a DNS error rather than a timeout. The image is built *inside* the machine
and behind the same firewall, so a package source missing from that list fails
the build, not the cell — when a `Containerfile` change fetches from a new host,
add the domain in the same commit. And that list is reachable by both agents, so
adding to it widens what they can reach too. Keep the trailing comment on each
entry saying who needs it.

## Versions

The `Containerfile` pins everything with an `ENV *_VERSION` near what uses it.
nvim, tmux, workmux and lima are pinned *to the host's* versions on purpose —
the point of a cell is that it works the way this machine does — so bumping one
means checking the host rather than picking the latest. Ubuntu, node, go,
golangci-lint and goreleaser are pinned to what the work needs.

## `pi/` is a snapshot

`cells/*/pi/` is a copy of `~/.pi/agent` taken by hand. It is not generated and
not linked, so never regenerate it from the host as a side effect of another
change. Inside a cell, `themes`, `extensions` and `skills` are symlinked out of
`/opt/pi` (a rebuild updates them) while `settings.json` and `npm/` are seeded
once and then belong to pi.

## Never commit

`cells/*/.env` (holds `GH_TOKEN`), `cells/*/vpn.conf` (a WireGuard private key)
and `config.yaml` are ignored, and that is the whole security story of this
repository. Do not add a file holding a credential, do not paste one into a
`cell.yaml` — `secrets:` declares a *name* and `solitary secrets` fills it in —
and do not weaken those `.gitignore` lines. When `config.yaml` gains a field,
`config.example.yaml` gains it too, with a placeholder value.

## Conventions

- Conventional Commits. No AI attribution trailers.
- Comments explain why a thing is the way it is, not what the code does — both
  `Containerfile`s and both `cell.yaml`s are written that way throughout, and
  the prose is load-bearing. Match that register.
- `cell-init.sh` is POSIX `sh` with `set -eu`, because it runs as the
  container's entry point; `statusline.sh` and `system-stats.sh` are bash, and
  `prompt.sh` is sourced rather than run. Keep each as it is.
- A cell's `README.md` describes what that cell is and how to live in it. Update
  it when behaviour it describes changes — including the "What comes from the
  host" table when a pinned version moves.
