/**
 * Marks the tmux window pi runs in with what it is doing, through the image's
 * agent-status script — the same marks Claude Code's hooks set.
 *
 * pi has no event for waiting on a permission, so it only ever shows working
 * and done; the mark goes when pi exits.
 */

import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";

export default function (pi: ExtensionAPI) {
  function setStatus(status: string) {
    pi.exec("agent-status", [status]).catch(() => {});
  }

  pi.on("agent_start", async () => {
    setStatus("working");
  });

  pi.on("agent_end", async () => {
    setStatus("done");
  });

  pi.on("session_shutdown", async () => {
    setStatus("clear");
  });
}
