// Registers every discovered skill as a slash command, so `/git-commit fix typo`
// works in opencode the way it does in Claude Code. The command attaches the skill
// to the prompt (full SKILL.md text is injected) and passes the arguments as the
// prompt text. Skills come from ~/.claude/skills, ~/.agents/skills and the
// opencode skill directories.
//
// Skill discovery finishes after plugins are set up, so the list is empty (built-ins
// only) inside setup(). The plugin therefore polls briefly and reloads the command
// registry once the list stops growing.

// Commands that already exist or would shadow built-ins.
const RESERVED = new Set(["init", "review", "replay", "opencode", "report"])
const POLL_MS = 1500
const POLL_MAX = 8

const short = (text, n = 140) => {
  const s = String(text ?? "").replace(/\s+/g, " ").trim()
  return s.length > n ? s.slice(0, n - 1) + "…" : s
}

export default {
  id: "dotfiles.skill-commands",
  async setup(ctx) {
    let skills = []
    let stopped = false

    const fetchSkills = async () => {
      const listed = await ctx.skill.list()
      return (listed?.data ?? []).filter((s) => s?.id && !RESERVED.has(s.id))
    }

    await ctx.command.transform((editor) => {
      const taken = new Set()
      try {
        for (const c of editor.list()) taken.add(c.name)
      } catch { /* list() shape unknown: fall back to RESERVED only */ }

      for (const skill of skills) {
        if (taken.has(skill.id)) continue
        editor.add({
          name: skill.id,
          description: short(skill.description),
          execute: async ({ sessionID, prompt, delivery }) => {
            const args = String(prompt?.text ?? "").trim()
            await ctx.session.prompt({
              ...prompt,
              sessionID,
              text: args || `Use the ${skill.id} skill.`,
              skills: [{ id: skill.id }],
              delivery,
            })
          },
        })
      }
    })

    // Poll until the skill count is stable for two rounds, reloading commands on growth.
    ;(async () => {
      let stable = 0
      for (let i = 0; i < POLL_MAX && !stopped && stable < 2; i++) {
        await new Promise((r) => setTimeout(r, POLL_MS))
        try {
          const next = await fetchSkills()
          if (next.length !== skills.length) {
            skills = next
            stable = 0
            await ctx.command.reload()
          } else {
            stable++
          }
        } catch { /* retry on the next round */ }
      }
    })()

    return () => {
      stopped = true
    }
  },
}
