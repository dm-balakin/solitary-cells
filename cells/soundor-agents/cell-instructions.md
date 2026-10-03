# This is a cell

A `solitary` cell: a container on its own machine, with a home that outlives it
and a firewall that refuses every name `cell.yaml` does not list. An unlisted
host fails to resolve rather than to time out, so a DNS error usually means the
firewall and not the network.

## A JUCE toolchain is installed

This cell is for soundor, whose JUCE runtime builds audio plugins with CMake.
Everything it needs is already in the image — do not download JUCE or install
a compiler:

- JUCE is at `/opt/JUCE`, a path soundor finds on its own. Leave `jucePath` and
  `JUCE_DIR` unset unless a project really wants another copy.
- `cmake`, `ninja`, `g++` (as `c++`), `clangd` and `clang-format` are on PATH.
  `CMAKE_GENERATOR` is `Ninja`; a build directory configured with another
  generator has to be deleted, not reconfigured.
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
