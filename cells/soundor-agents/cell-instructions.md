# What this cell adds

solitary's own skills cover how a cell works. This is what this one has on top.

## A JUCE toolchain is installed

This cell is for soundor, whose JUCE runtime builds audio plugins with CMake.
Everything it needs is already in the image — do not download JUCE or install
a compiler:

- JUCE is at `/opt/JUCE`, a path soundor finds on its own. Leave `jucePath` and
  `JUCE_DIR` unset unless a project really wants another copy.
- `cmake`, `ninja`, Clang 21 (`clang`, `clang++`, and `cc`/`c++` point at
  them), `lld`, `clangd`, `clang-format` and `clang-tidy` are on PATH.
- Builds use Clang and lld by default: `CC=clang`, `CXX=clang++`,
  `LDFLAGS=-fuse-ld=lld` and `CMAKE_GENERATOR=Ninja` are set. A build directory
  keeps the compiler and generator it was first configured with, so one made
  with anything else has to be deleted, not reconfigured. gcc is still
  installed; use it only when a task asks for it.
- JUCE's Linux libraries, webkit2gtk included, are installed, so a configure
  that fails on a missing package is worth reporting rather than working
  around.

There is no audio device and no display. A plugin can be built and its tests
run, but a Standalone cannot be opened and nothing can be listened to here.

## JUCE is licensed, and that limits what you do with it

JUCE is AGPLv3 or a commercial JUCE licence
(<https://juce.com/legal/juce-8-licence>), and you do not know which one the
user holds. So, without the user asking for it explicitly:

- Do not publish, push, export or upload the container image, or copy anything
  out of `/opt/JUCE` into a repository.
- Do not release, upload or attach a built plugin anywhere — no GitHub
  release, no artifact upload, no package. Building and testing is fine;
  shipping is the user's decision.
- Do not vendor JUCE into a project or add it as a submodule; use `/opt/JUCE`
  where it is.

If a task looks like it leads to any of these, stop and say that it touches
JUCE's licence.

## Rust is installed

Rust's latest stable is in the image, with clippy and rustfmt — do not install
rustup again. `cargo`, `rustc` and `rustup` are on PATH, and cargo reaches
crates.io.

The toolchains live in `/opt/rustup` rather than the home, so anything rustup
writes is the container's and gone at the next boot: a `rustup update`, an
added component or target, and the toolchain a project's `rust-toolchain.toml`
asks for, which is downloaded again after every restart. If a project needs one
for good, say so — it belongs in the image. `~/.cargo` is in the home, so the
registry cache and what `cargo install` puts in `~/.cargo/bin` do last. That
directory is not on PATH, so run what is in it by its path.

## A GPU is available

The cell renders on the host's GPU through a virtual one: OpenGL through virgl,
Vulkan through Venus, at `/dev/dri/renderD128`, with Mesa's drivers installed.
Rendering only — there is no CUDA and no video encoder.

Check before relying on it: `eglinfo -B -p surfaceless | grep renderer` should
name `virgl (…)`, and `vulkaninfo --summary` a `Virtio-GPU Venus (…)` device.
If either says `llvmpipe` only, this host gave the cell no GPU and everything
renders on the CPU; that is the host's setup, not something to fix from here.
A Vulkan app that picks its own device can land on llvmpipe or the host's other
GPU, since Venus lists them too.

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
