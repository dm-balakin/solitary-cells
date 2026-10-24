# AGENTS.md

This file provides guidance to coding agents working with code in this
repository.

## What this is

`~/.config/solitary` itself, under version control: the user-wide defaults and
the cell definitions [`solitary`](https://solitary.balakin.io) reads. There is
no build and no test suite here — the only way to find out whether a change
works is to build the cell and start it. `README.md` covers the layout and the
setup; this file covers the traps.

## The cells are copies

There are three, and `cells/web-agents` is the one the other two are copied
from. `cells/kvm-agents` is `cells/web-agents` plus a Go toolchain, qemu, lima
and `/dev/kvm`. It is a copy, not a layer: a cell's build context is the
directory its `Containerfile` sits in, so nothing can be shared between them.

**A change to either is a change to make to both**, unless it is one of the
things that genuinely differ. Those are, and only these:

- `cell.yaml` — `description`, the `user: cell` line, `devices:`, four extra
  `network.allow` entries (`go.dev`, `dl.google.com`, `golang.org`,
  `solitary.balakin.io`), and `vm.disk` (80GiB against 40GiB) with the
  sentence above `vm:` that says why. Neither the memory nor port 5173 is one
  of these any more: every cell forwards 5173 and asks for 6GiB, since no two
  fit alongside each other in /dev/shm and web-agents crashed at 7
- `Containerfile` — the Go, qemu/lima and `useradd` blocks, the comment on the
  `cell-instructions.md` `COPY`, and the extra version checks in the final
  `RUN`
- `cell-instructions.md` — the virtual machines and Go sections
- `README.md` — the cell it describes

`diff -r cells/web-agents cells/kvm-agents` should show those and nothing else.
Run it after touching either cell.

`cells/soundor-agents` is `cells/web-agents` plus what soundor builds a plugin
with and a GPU. A change to web-agents is a change to make to it too, bar what
genuinely differs:

- `cell.yaml` — `description`, the JUCE licence comment, `gpu: true`, and the
  three Skia entries in `network.allow` (`skia.googlesource.com`,
  `chromium.googlesource.com`, `chrome-infra-packages.appspot.com`) and the
  two for Rust (`crates.io`, `rust-lang.org`)
- `Containerfile` — the `FROM` line and the comment above it (Ubuntu 24.04,
  which soundor supports and prebuilds its engine on, against web-agents'
  26.04), the tmux comment that names 24.04's 3.4, the cmake/LLVM/JUCE-libraries
  block, the Clang and lld defaults, the JUCE clone, the Mesa block, the Rust block, the comment on the
  `cell-instructions.md` `COPY`, and their checks in the final `RUN`
- `cell-instructions.md` — the JUCE, licence, Rust and GPU sections
- `README.md` — the cell it describes

`diff -r cells/web-agents cells/soundor-agents` should show those and nothing
else.

## Which file applies when

This decides what a change costs, and it is worth saying in the commit message:

- `cell.yaml` container settings (`build`, `command`, `secrets`, `devices`,
  `user`) and anything the `Containerfile` copies in — `solitary up` applies it,
  rebuilding the image when the `Containerfile` moved.
- `cell.yaml` machine settings (`vm`, `ports`, `network`, `gpu`) — only at the
  next boot. `up` warns on a running machine; the cell has to go down first.
- `cell-init.sh` — every container start. Everything in it must stay
  idempotent, and it must not clobber what the agents write: `~/.claude.json`
  holds the login and the session history, so it is merged with `jq`, and a
  real file where it would link the cell note is left alone.

## The firewall is the constraint

A cell resolves and reaches only what `network.allow` names; anything else fails
as a DNS error rather than a timeout. The image is built *inside* the machine
and behind the same firewall, so a package source missing from that list fails
the build, not the cell — when a `Containerfile` change fetches from a new host,
add the domain in the same commit. And that list is reachable by every agent, so
adding to it widens what they can reach too. Keep the trailing comment on each
entry saying who needs it.

## Versions

The `Containerfile` pins everything with an `ENV *_VERSION` near what uses it.
nvim, tree-sitter, lima and JUCE are pinned *to the host's* versions on purpose
— the point of a cell is that it works the way this machine does — so bumping
one means checking the host rather than picking the latest. tmux is pinned too,
but to its latest release, ahead of the host's packages. Ubuntu and node are
pinned to what the work needs, and go, golangci-lint and goreleaser to what
solitary's own CI runs — `go.mod`, `verify.yml` and the release workflow. Not
pinned at all are the agents (Claude Code, Codex and opencode), Playwright and
soundor-agents' Rust stable toolchain: each build takes their latest, and none
of them updates itself.

## Never commit

`cells/*/.env` (holds `GH_TOKEN`), `cells/*/vpn.conf` (a WireGuard private key)
and `config.yaml` are ignored, and that is the whole security story of this
repository. Do not add a file holding a credential, do not paste one into a
`cell.yaml` — `secrets:` declares a *name* and `solitary secrets` fills it in —
and do not weaken those `.gitignore` lines. When `config.yaml` gains a field,
`config.example.yaml` gains it too, with a placeholder value.

## Conventions

- Conventional Commits. No AI attribution trailers.
- No branches and no pull requests: commit on `main` and push `main`. This
  directory is the live configuration `solitary` reads, so a commit sitting on
  a branch is a change the cells are already running without anyone having
  agreed to it.
- Comments explain why a thing is the way it is, not what the code does — both
  `Containerfile`s and both `cell.yaml`s are written that way throughout, and
  the prose is load-bearing. Match that register.
- `cell-init.sh` is POSIX `sh` with `set -eu`, because it runs as the
  container's entry point; `statusline.sh` and `system-stats.sh` are bash, and
  `prompt.sh` is sourced rather than run. Keep each as it is.
- A cell's `README.md` describes what that cell is and how to live in it. Update
  it when behaviour it describes changes — including the "What comes from the
  host" table when a pinned version moves.
