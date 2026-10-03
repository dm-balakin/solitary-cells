# soundor agents cell

A cell for [soundor](https://github.com/soundor/soundor): tmux and workmux
running git worktrees, nvim, and two coding agents — Claude Code and pi — behind
a Surfshark tunnel and a firewall that refuses everything not named in
`cell.yaml`. It is `web-agents` plus what soundor's JUCE runtime builds a plugin
with: cmake, ninja, Clang and lld, JUCE's Linux libraries and JUCE itself.

It is a copy of `web-agents` rather than a layer on top of it, like `kvm-agents`
is, so a change to one of the three is a change to make in the others too.

> [!IMPORTANT]
> **JUCE is not free software you can do anything with.** It is AGPLv3 or a
> commercial JUCE licence, and building this cell puts it in the image. Never
> publish the image, and never ship a plugin built here without meeting the
> licence you use JUCE under. Read [the licence](#the-licence) before the first
> `up`.

## Start

```bash
solitary secrets soundor-agents   # GH_TOKEN
solitary up soundor-agents
```

The VPN configuration holds a private key, so it is not in this directory. Put
yours at `cells/soundor-agents/vpn.conf` before the first start.

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

## Updating

Nothing in the cell updates itself. The container is started over from the image
every time the machine boots, so an update an agent downloads into it is gone by
the next boot — Claude Code's auto-updater is off, and pi's, gh's and npm's
version notices with it. Update by rebuilding instead:

```sh
solitary up --rebuild soundor-agents
```

or `b` in `solitary dashboard`. That builds the `Containerfile` again without a
cache, so Claude Code and gh come in at their latest and everything pinned stays
where it is pinned. The home is kept; every session in the cell ends.

## JUCE

JUCE 8.0.14 — the host's version — is cloned into `/opt/JUCE` at build. That is
one of the well-known paths soundor's JUCE runtime searches on Linux, so
`soundor doctor` finds it with no `jucePath` and no `JUCE_DIR`. soundor never
downloads JUCE itself because its license asks to be accepted; putting it in
this image is that acceptance. To move to another version, change
`JUCE_VERSION` in the `Containerfile` and rebuild.

### The licence

JUCE is **not** free to use however you like. It is dual-licensed:

- **AGPLv3** — anything you distribute that is built with JUCE has to be AGPLv3
  too, with its full source published.
- **JUCE's commercial licence** (Starter, Indie, Pro) — closed source is
  allowed, within the tier's terms; Starter is free up to a revenue limit.

The terms are at <https://juce.com/legal/juce-8-licence>, and they are the
authority, not this summary. Running `solitary up soundor-agents` builds JUCE
into the image, so **you are using JUCE under one of these from the first
build**. What that rules out here:

- **Do not publish the image.** No `podman push`, no saving it out and handing
  it over. It contains JUCE's source, and passing it on is redistributing JUCE.
  The image only ever lives on this cell's machine — keep it that way.
- **Do not ship a plugin built in this cell** — not a VST3, not a Standalone,
  not a test build sent to a friend — unless it meets the licence you chose:
  AGPLv3 source published, or a commercial JUCE licence that covers it. Nothing
  in the cell checks this; it is on you.
- **Sharing this directory is fine.** The `Containerfile` holds a `git clone`
  command, not JUCE. Whoever builds it downloads JUCE from JUCE's own repository
  and accepts the licence for themselves — so point them at this section.

The agents are told the same in `/opt/cell-instructions.md`: they build with
JUCE but do not package, publish or upload what it produces.

cmake defaults to ninja here (`CMAKE_GENERATOR=Ninja`), and to Clang and lld
(`CC=clang`, `CXX=clang++`, `LDFLAGS=-fuse-ld=lld`), since soundor names
neither a generator nor a compiler. `cc` and `c++` point at Clang too, so
`soundor doctor` reports the compiler that is actually used. A build directory
keeps the generator and compiler it was first configured with, so one made
under Makefiles or gcc has to be deleted rather than reused.

The LLVM tools are all version 18: `clang`, `lld`, `clangd`, `clang-format`
and `clang-tidy`. gcc stays installed because Clang uses its C++ standard
library and glibc headers, and it is there for anything that asks for `gcc` or
`g++` by name.

A plugin builds, but nothing in the cell can play it: there is no audio device
and no display, so a Standalone has nothing to open. Build here; listen on the
host.

The machine is the same 4 CPUs and 6GiB as `web-agents`. A machine's memory is
a file on the host's `/dev/shm`, which holds 7.7GiB, so this cell does not fit
alongside either sibling: bring the other one down first.

## The browser

Playwright and its Chromium are in the image, in `/opt/ms-playwright` rather
than the home, so a fresh cell has a browser without downloading one. There is
no display: it runs headless, and it reaches only what `network.allow` names,
like everything else here.

Both agents are told it is there. `/opt/cell-instructions.md` is one note about
what this cell is, linked in at start as Claude Code's `~/.claude/CLAUDE.md` and
pi's `~/.pi/agent/AGENTS.md`; replace either with a real file inside the cell
and that file wins.

## The firewall and pi

`pi-web-access` is installed, but the cell only resolves and reaches the names
in `cell.yaml`. Fetching an arbitrary URL fails, and it fails as a DNS error
rather than a timeout. Add the domain to `network.allow` and rebuild if you
want it, remembering that everything in that list is reachable by both agents.
