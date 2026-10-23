// Marks the tmux window opencode runs in, the same way Claude Code's and
// Codex's hooks do: 🤖 while it works, 💬 when it waits for a permission or an
// answer, ✅ when the session goes idle. The mark goes when opencode exits.
//
// Loaded from /etc/opencode, which OPENCODE_CONFIG_DIR names in the image, so
// it comes with the image and a ~/.config/opencode in the cell's home is still
// read alongside it.
import { spawn, spawnSync } from "node:child_process";

const mark = (status) => {
  spawn("agent-status", [status], { stdio: "ignore" }).on("error", () => {});
};

export const AgentStatus = async () => {
  process.on("exit", () => {
    spawnSync("agent-status", ["clear"], { stdio: "ignore" });
  });

  return {
    event: async ({ event }) => {
      switch (event.type) {
        case "session.status":
          if (event.properties?.status?.type === "busy") mark("working");
          break;
        case "permission.asked":
        case "question.asked":
          mark("waiting");
          break;
        case "permission.replied":
        case "question.replied":
        case "question.rejected":
          mark("working");
          break;
        case "session.idle":
          mark("done");
          break;
      }
    },
  };
};
