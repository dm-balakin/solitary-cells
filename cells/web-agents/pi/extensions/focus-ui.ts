import { basename } from "node:path";
import {
  CustomEditor,
  type ExtensionAPI,
  type ExtensionContext,
  type KeybindingsManager,
} from "@earendil-works/pi-coding-agent";
import {
  truncateToWidth,
  visibleWidth,
  type EditorTheme,
  type TUI,
} from "@earendil-works/pi-tui";

const UI_NAME = "focus-ui";

function formatPercent(value: number | null): string {
  return value === null ? "?" : `${Math.round(value)}%`;
}

function fitSides(left: string, right: string, width: number): string {
  if (width <= 0) return "";

  const rightWidth = visibleWidth(right);
  if (rightWidth >= width) return truncateToWidth(right, width);

  const leftWidth = Math.max(0, width - rightWidth - 1);
  const fittedLeft = truncateToWidth(left, leftWidth);
  const gap = " ".repeat(Math.max(1, width - visibleWidth(fittedLeft) - rightWidth));
  return truncateToWidth(fittedLeft + gap + right, width);
}

class FocusEditor extends CustomEditor {
  constructor(
    tui: TUI,
    theme: EditorTheme,
    keybindings: KeybindingsManager,
    private readonly label: () => string,
  ) {
    super(tui, theme, keybindings, { paddingX: 1 });
  }

  override render(width: number): string[] {
    if (width < 6) return super.render(width);

    const innerWidth = width - 2;
    const lines = super.render(innerWidth);
    if (lines.length > 0 && innerWidth >= 16) {
      const label = this.label();
      const labelWidth = visibleWidth(label);
      const first = lines[0] ?? "";
      const leftWidth = Math.max(3, innerWidth - labelWidth - 3);
      const left = truncateToWidth(first, leftWidth, "");
      const remaining = Math.max(0, innerWidth - visibleWidth(left) - labelWidth);
      lines[0] = left + label + this.borderColor("─".repeat(remaining));
    }

    return lines.map((line) => ` ${truncateToWidth(line, innerWidth, "")} `);
  }
}

export default function focusUi(pi: ExtensionAPI) {
  let enabled = true;
  let clearScreen: (() => void) | undefined;

  const restore = (ctx: ExtensionContext) => {
    ctx.ui.setHeader(undefined);
    ctx.ui.setEditorComponent(undefined);
    ctx.ui.setFooter(undefined);
    ctx.ui.setWorkingIndicator();
    ctx.ui.setToolsExpanded(false);
    clearScreen?.();
  };

  const apply = (ctx: ExtensionContext) => {
    if (ctx.mode !== "tui") return;

    ctx.ui.setToolsExpanded(false);
    ctx.ui.setWorkingIndicator({
      frames: [
        ctx.ui.theme.fg("dim", "·"),
        ctx.ui.theme.fg("muted", "•"),
        ctx.ui.theme.fg("accent", "●"),
        ctx.ui.theme.fg("muted", "•"),
      ],
      intervalMs: 120,
    });

    ctx.ui.setHeader((tui, theme) => {
      clearScreen = () => {
        tui.terminal.clearScreen();
        tui.requestRender(true);
      };
      clearScreen();

      return {
        invalidate() {},
        render(width: number): string[] {
          const project = basename(ctx.cwd) || ctx.cwd;
          const session = pi.getSessionName();
          const left = theme.fg("accent", theme.bold(`  ${project}`));
          const right = theme.fg("dim", session ? `${session}  ` : "focus mode  ");
          const innerWidth = Math.max(1, width - 2);
          const top = ` ${fitSides(left, right, innerWidth)} `;

          // Fill an empty session so the editor begins at the bottom. As the
          // transcript grows these rows naturally scroll out of the viewport.
          const fillerRows = Math.max(1, tui.terminal.rows - 8);
          return [top, ...Array.from({ length: fillerRows }, () => "")];
        },
      };
    });

    ctx.ui.setEditorComponent((tui, theme, keybindings) =>
      new FocusEditor(tui, theme, keybindings, () => {
        const model = ctx.model?.name || ctx.model?.id || "no model";
        const thinking = ctx.thinkingLevel === "off" ? "" : ` · ${ctx.thinkingLevel}`;
        return (
          " " +
          ctx.ui.theme.fg("accent", model) +
          ctx.ui.theme.fg("dim", thinking) +
          " "
        );
      }),
    );

    ctx.ui.setFooter((tui, theme, footerData) => {
      const unsubscribe = footerData.onBranchChange(() => tui.requestRender());

      return {
        dispose: unsubscribe,
        invalidate() {},
        render(width: number): string[] {
          const project = basename(ctx.cwd) || ctx.cwd;
          const branch = footerData.getGitBranch();
          const leftBase = branch ? `${project}  ${branch}` : project;

          const statuses = [...footerData.getExtensionStatuses().entries()]
            .filter(([key, value]) => key !== UI_NAME && value.trim().length > 0)
            .slice(0, 2)
            .map(([, value]) => value)
            .join("  ·  ");

          const usage = ctx.getContextUsage();
          const context = usage ? formatPercent(usage.percent) : "?";
          const contextLabel = `ctx ${context}`;
          const right =
            usage?.percent !== null && usage?.percent !== undefined && usage.percent >= 90
              ? theme.fg("error", contextLabel)
              : usage?.percent !== null && usage?.percent !== undefined && usage.percent >= 70
                ? theme.fg("warning", contextLabel)
                : theme.fg("dim", contextLabel);

          let left = theme.fg("muted", leftBase);
          if (statuses) left += theme.fg("dim", `  ·  ${statuses}`);
          const innerWidth = Math.max(1, width - 2);

          return [` ${fitSides(left, right, innerWidth)} `];
        },
      };
    });

    ctx.ui.setTitle(`pi · ${basename(ctx.cwd) || ctx.cwd}`);
  };

  pi.on("session_start", (_event, ctx) => {
    if (enabled) apply(ctx);
  });

  pi.on("session_shutdown", (event, _ctx) => {
    if (event.reason === "quit") clearScreen?.();
  });

  pi.registerCommand("focus-ui", {
    description: "Toggle the local fullscreen focus interface",
    handler: async (args, ctx) => {
      const value = args.trim().toLowerCase();
      if (value && !["on", "off", "toggle", "status"].includes(value)) {
        ctx.ui.notify("Usage: /focus-ui [on|off|toggle|status]", "error");
        return;
      }

      if (value === "status") {
        ctx.ui.notify(`Focus UI is ${enabled ? "on" : "off"}`, "info");
        return;
      }

      enabled = value === "on" ? true : value === "off" ? false : !enabled;
      if (enabled) apply(ctx);
      else restore(ctx);
      ctx.ui.notify(`Focus UI ${enabled ? "enabled" : "disabled"}`, "info");
    },
  });
}
