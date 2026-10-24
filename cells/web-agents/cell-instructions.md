# What this cell adds

solitary's own skills cover how a cell works. This is what this one has on top.

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
