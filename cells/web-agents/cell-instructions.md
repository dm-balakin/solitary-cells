# This is a cell

A `solitary` cell: a container on its own machine, with a home that outlives it
and a firewall that refuses every name `cell.yaml` does not list. An unlisted
host fails to resolve rather than to time out, so a DNS error usually means the
firewall and not the network.

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
