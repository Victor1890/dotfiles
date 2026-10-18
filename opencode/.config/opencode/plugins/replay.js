// opencode v2 adapter of claude-mods/replay-theater (Anthropic sample mod,
// Apache-2.0, see claude-mods/replay-theater/VENDORED.md). The Claude version draws
// a pane and a band; opencode plugins have no UI API, so this records the same
// edit steps and exposes them as a `replay` tool plus a `/replay` command that
// asks the model to call it. Recording only reads files; it never blocks an edit.
import { existsSync, readFileSync } from "node:fs"
import path from "node:path"

const MAX_DIFF_LINES = 12
const MAX_LCS_LINES = 400
const MARK = "[replay]"

const splitLines = (text) => {
  if (!text) return []
  const lines = String(text).split("\n")
  if (lines.length > 1 && lines[lines.length - 1] === "") lines.pop()
  return lines
}

// Small inputs get an LCS diff so unchanged lines show as context; large ones
// fall back to all-removed then all-added.
function diffLines(oldText, newText) {
  const a = splitLines(oldText)
  const b = splitLines(newText)
  if (a.length > MAX_LCS_LINES || b.length > MAX_LCS_LINES) {
    return [...a.map((t) => ({ op: "-", t })), ...b.map((t) => ({ op: "+", t }))]
  }
  const n = a.length, m = b.length
  const dp = Array.from({ length: n + 1 }, () => new Array(m + 1).fill(0))
  for (let i = n - 1; i >= 0; i--)
    for (let j = m - 1; j >= 0; j--)
      dp[i][j] = a[i] === b[j] ? dp[i + 1][j + 1] + 1 : Math.max(dp[i + 1][j], dp[i][j + 1])
  const out = []
  let i = 0, j = 0
  while (i < n && j < m) {
    if (a[i] === b[j]) { out.push({ op: " ", t: a[i] }); i++; j++ }
    else if (dp[i + 1][j] >= dp[i][j + 1]) out.push({ op: "-", t: a[i++] })
    else out.push({ op: "+", t: b[j++] })
  }
  while (i < n) out.push({ op: "-", t: a[i++] })
  while (j < m) out.push({ op: "+", t: b[j++] })
  return trimContext(out)
}

// Keep one line of context around each change.
function trimContext(lines) {
  if (!lines.some((l) => l.op !== " ")) return lines.slice(0, MAX_DIFF_LINES)
  const keep = lines.map((l, k) =>
    l.op !== " " || (lines[k - 1]?.op && lines[k - 1].op !== " ") || (lines[k + 1]?.op && lines[k + 1].op !== " "))
  const out = []
  let skipped = false
  lines.forEach((l, k) => {
    if (keep[k]) { if (skipped && out.length) out.push({ op: "~", t: "..." }); out.push(l); skipped = false }
    else skipped = true
  })
  return out
}

const render = (steps) =>
  steps.map((s, k) => {
    const shown = s.diff.slice(0, MAX_DIFF_LINES)
    const body = shown.map((l) => `${l.op === "~" ? " " : l.op} ${l.t}`).join("\n")
    const more = s.diff.length > MAX_DIFF_LINES ? `\n  ... ${s.diff.length - MAX_DIFF_LINES} more lines` : ""
    return `step ${k + 1}/${steps.length}  ${s.file}  (${s.tool}${s.note ? ", " + s.note : ""})\n${body || "  (no line changes)"}${more}`
  }).join("\n\n")

export default {
  id: "dotfiles.replay",
  async setup(ctx) {
    const dir = ctx.location.directory
    const abs = (p) => path.resolve(dir, p)
    const rel = (p) => path.relative(dir, abs(p)) || p
    const state = { pending: [], replay: [] }
    const inflight = new Map()

    // A new user prompt closes the previous turn: its edits become the replay.
    await ctx.session.hook("prompt", (e) => {
      if (String(e.prompt?.text ?? "").includes(MARK)) return
      if (state.pending.length) {
        state.replay = state.pending
        state.pending = []
      }
    })

    await ctx.tool.hook("execute.before", (e) => {
      try {
        const i = e.input ?? {}
        if (e.tool === "edit" && i.path) {
          inflight.set(e.id, { tool: "edit", file: rel(i.path), diff: diffLines(i.oldString, i.newString), note: i.replaceAll ? "replace all" : "" })
        } else if (e.tool === "write" && i.path) {
          const existed = existsSync(abs(i.path))
          const before = existed ? readFileSync(abs(i.path), "utf8") : ""
          inflight.set(e.id, { tool: "write", file: rel(i.path), diff: diffLines(before, i.content), note: existed ? "rewrite" : "new file" })
        }
      } catch { /* recording must never stop the edit */ }
    })

    await ctx.tool.hook("execute.after", (e) => {
      const step = inflight.get(e.id)
      if (!step) return
      inflight.delete(e.id)
      if (e.status === "completed") state.pending.push(step)
    })

    const steps = () => (state.pending.length ? state.pending : state.replay)

    await ctx.tool.transform((editor) => {
      editor.add({
        name: "replay",
        description: "Show the file edits made in the last turn, one diff per step. Call it when the user asks to replay or review recent edits.",
        parameters: { type: "object", properties: {} },
        execute: async () => {
          const s = steps()
          return { content: [{ type: "text", text: s.length ? render(s) : "No edits recorded in the last turn." }] }
        },
      })
    })

    await ctx.command.transform((editor) => {
      editor.add({
        name: "replay",
        description: "Step through the last turn's file edits (replay-theater)",
        execute: async ({ sessionID, prompt, delivery }) => {
          await ctx.session.prompt({
            ...prompt,
            sessionID,
            text: `${MARK} Call the replay tool and show its output verbatim, then summarise what each step changed in one line.`,
            delivery,
          })
        },
      })
    })
  },
}
