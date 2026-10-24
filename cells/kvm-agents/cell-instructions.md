# What this cell adds

solitary's own skills cover how a cell works. This is what this one has on top.

## Virtual machines run here

This cell is where `solitary` is developed, and `solitary` drives Lima
machines, so it can start machines of its own. Nested virtualisation is
allowed: `/dev/kvm` is real and usable, and a guest started here runs with
hardware acceleration, not emulation. It is a third level down — host, this
cell, the guest.

Everything that takes is in the image — do not install any of it:

- `limactl`, at the host's version, so it behaves the way the host's does.
- `qemu-system-x86_64` and `qemu-img`, with UEFI firmware (OVMF) for a guest to
  boot from, and the `ssh` client Lima talks to a guest over.
- A `solitary` built in a worktree here can create its machines here too.

Things to know before starting one:

- You are the user `cell`, not root, because `limactl` refuses to run as root.
  Do not reach for `sudo` to get around it.
- A guest's CPUs, memory and disk come out of this cell's: 4 CPUs, 6GiB of
  memory and 80GiB of disk, shared with you and the other agents. Lima's
  defaults assume a whole computer, so give a guest less (`--cpus`, `--memory`,
  `--disk`), run one at a time, and stop and delete it when you are done.
- A guest reaches the network through this cell's firewall, so it can fetch
  only what `network.allow` names. Lima's Ubuntu images come from `ubuntu.com`,
  which is on it; an image from anywhere else fails as a DNS error.
- Lima keeps its machines and its image cache in the home (`~/.lima`,
  `~/.cache/lima`), so they survive a restart of this cell — but a guest does
  not keep running across one. Start it again afterwards.

## Go is installed

`go`, `golangci-lint` and `goreleaser` are on PATH, each pinned to what
solitary's CI runs, so a lint or build that passes here passes there. Use the
ones installed rather than another version:

- `golangci-lint` is the linter and, as `golangci-lint fmt`, the formatter.
- `goreleaser` is what the release configuration is checked with.
- A module that asks for a newer Go downloads that toolchain itself, through
  the Go proxy, which the firewall allows.

`GOPATH` is `~/go`, in the home, so the module cache and whatever `go install`
puts in `~/go/bin` survive a restart, and `~/go/bin` is on PATH.

## A browser is installed

Playwright and its Chromium are in the image, so driving a real browser needs no
download: `playwright` is on PATH, and `PLAYWRIGHT_BROWSERS_PATH` already points
at `/opt/ms-playwright`. Use it to check what you are building — take a
screenshot, read the console, click through a page — rather than assuming a
change works.

Two things about it here:

- There is no display. Run headless, which is Playwright's default.
- The firewall applies to the browser as well: it reaches localhost and the
  names in `network.allow`, and nothing else.

A project that pins its own `playwright` reuses that Chromium when the versions
agree; when they do not, let it install its own into the project rather than
adding a browser to the image by hand.

## Node is installed

Node 24 is on PATH, installed with nvm. Both live in `/usr/local` rather than
the home, so anything written there is the container's and gone at the next
boot: another version from `nvm install`, and a package from `npm install -g`.
If a project needs either for good, say so — it belongs in the image. A
project's own `node_modules`, and npm's cache in `~/.npm`, are in the home and
last.

corepack is enabled, so pnpm and yarn come at the version a project's
`package.json` names in `packageManager`, without asking. Do not install either
with `npm install -g`.
