// opencode v2 adapter of the Claude Code guardrail hooks (claude/.claude/hooks/).
// The rules stay in the shared .mjs files (single source of truth, shared tests);
// this only maps them onto the v2 permission "evaluate" hook, which can turn an
// allow/ask into deny. Same env switches: AI_GUARD_PROTECT_BRANCHES,
// AI_GUARD_ENABLE, AI_GUARD_DISABLE.
import { execSync } from "node:child_process"
import { homedir } from "node:os"
import path from "node:path"
import { pathToFileURL } from "node:url"

const load = (name) => import(pathToFileURL(path.join(homedir(), ".claude", "hooks", name)).href)

export default {
  id: "dotfiles.guardrails",
  async setup(ctx) {
    const [git, branchGuard] = await Promise.all([
      load("git-guardrails.mjs"),
      load("guard-protected-branch.mjs"),
    ])
    const dir = ctx.location.directory
    const sh = (cmd) => {
      try {
        return execSync(cmd, { cwd: dir, encoding: "utf8", timeout: 2000 }).trim()
      } catch {
        return null
      }
    }

    await ctx.permission.hook("evaluate", (event) => {
      let reason
      if (event.action === "shell") {
        for (const cmd of event.resources ?? []) {
          const needsBranch = git.protectedBranches().length && /git\s+commit/.test(cmd)
          reason = git.evaluate(cmd, needsBranch ? sh("git branch --show-current") : null)
          if (reason) break
        }
      } else if (event.action === "edit" && branchGuard.protectedBranches().length) {
        const root = sh("git rev-parse --show-toplevel") ?? dir
        const branch = sh("git branch --show-current")
        for (const file of event.resources ?? []) {
          reason = branchGuard.evaluate(path.resolve(dir, file), branch, root)
          if (reason) break
        }
      }
      if (reason) {
        event.effect = "deny"
        event.message = reason
      }
    })
  },
}
