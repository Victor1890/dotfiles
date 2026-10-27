# opencode

Stow package `opencode/` → `~/.config/opencode/`. Mirrors the Claude Code config
(`docs/claude-code.md`), with free models from opencode's built-in provider (no external API key or `providers`).
Picked from `opencode api model.list` by specs (no benchmarks exist). Reasoning effort goes in
the model string as `#variant`, mirroring the Claude `effort:` field.

| Tier (Claude) | Agents | Model |
|---|---|---|
| deep (opus) | plan, architecture-reviewer, security-reviewer | `beam-free#high` / `#xhigh` (1M ctx, ladder low..max) |
| second opinion | contrarian | `flint-40b-free#high` (different model than the plan it critiques) |
| mid (sonnet) | general, performance-reviewer | `deepseek-v4.1-flash-free#high` (default model) |
| mid | feedback-resolver | `glm-5.3-flash-free#high` |
| light (haiku) | explore, summarizer, title | `nemotron-3.5-lightning-free` (no variants) |

deepseek and glm only have `low`/`high`/`max`; there is no `medium`.

**v2 format required.** Guide: <https://opencode.ai/v2/docs/migrate-v1/>. v1 keys
(`permission`, `agent`, `plugin`, `autoupdate`, `small_model`, `tui.json`) are normalized in
memory but must not be used: this package only writes v2 keys.

## Installation

`scripts/bootstrap.sh` calls `ensure_opencode` (`scripts/modules/opencode.sh`) before stowing:
if opencode is missing, or is v1, it runs the v2 installer
(`curl -fsSL https://opencode.ai/v2/install | bash`, which replaces the v1 binary in
`~/.opencode/bin`). `--no-modify-path` is passed so the installer does not write to
`.zshrc`/`.bashrc` (symlinks into the repo); `path.sh` and `path.zsh` set the PATH instead.
v2 reads the same `~/.config/opencode`, so the package layout does not change.

## What is versioned

| File | Claude Code equivalent |
|---|---|
| `opencode.json` | `settings.json`: `model`, `permissions`, `policies`, `update` |
| `AGENTS.md` | global `CLAUDE.md` + caveman block. v2 only reads `AGENTS.md`, not `CLAUDE.md` |
| `agents/*.md` | `claude/.claude/agents/*.md` (all 9, same model) |
| `cli.json` | terminal theme and UI (v2 stores it globally, formerly `tui.json`) |

Skills are **not copied**: v2 discovers `~/.claude/skills/*/SKILL.md`. The reviewers still
read `~/.claude/docs/review-output.md`.

## v1 → v2 mapping used here

| Claude / v1 | v2 |
|---|---|
| `permission.bash` | `permissions` array, `action: shell` (the **last** rule wins) |
| `small_model` | `agents.title.model` |
| `autoupdate: false` | `update: "disable"` |
| agent `permission:` | `permissions:` list of `{action, resource, effect}` |
| agent `effort` | `model: opencode/<model>#<variant>` (only variants the model lists) |
| agent `temperature`, `tools` | do not exist; dropped |

## Agents

`Explore` → `explore`, `general-purpose` → `general`, `Plan` → `plan` (primary); they override
the built-ins by ID. Read-only agents have `edit` denied.

## Plugins (adapter for `claude-mods` and hooks)

opencode equivalent of the Claude hooks and `claude-mods/`. They are standalone
`plugins/*.js` files with `export default { id, setup(ctx) }` (v2 API). They are discovered
automatically (do not declare them in `plugins`: an entry there hangs startup). They were
verified end to end with `opencode run`.

| Plugin | Equivalent to | How |
|---|---|---|
| `guardrails.js` | `git-guardrails.mjs` + `guard-protected-branch.mjs` | `ctx.permission.hook("evaluate")` sets `effect = "deny"`. Imports the rules from `~/.claude/hooks/*.mjs` (single source, same tests and same `AI_GUARD_*` variables) |
| `skill-commands.js` | Claude Code's `/<skill>` | Registers every discovered skill as a command (`/git-commit`, `/tdd`, `/design-taste-frontend`…). Attaches the skill to the prompt (`skills: [{id}]`, injects the full `SKILL.md`) and passes the arguments as text. Skills appear after startup, so the plugin polls for ~12 s and reloads the commands |
| `replay.js` | `claude-mods/replay-theater` | `ctx.tool.hook("execute.before/after")` records the `write`/`edit` steps; `replay` tool and `/replay` command. No pane/band: opencode has no UI API for plugins |

Shell defense layers, outside in: `policies` (globs, hard) → `permissions` (`deny` at the end,
last rule wins) → `guardrails.js` (per-segment regex, protected branch). The plugin covers what
globs cannot see (`rm -r -f`, commits on a protected branch, edits on a protected branch).
Protected branch: `AI_GUARD_PROTECT_BRANCHES=main` in the environment **when the service
starts** (see gotchas).

Real shapes (v2.0.31, measured with a probe plugin):

- permission: `{action, resources[], effect, message?}`; `edit` carries relative paths, `shell` the command
- tool: `{tool: "write"|"edit"|"shell"|..., id, input, status, result}`;
  `write` = `{path, content}`, `edit` = `{path, oldString, newString}`
- custom tool: `ctx.tool.transform(e => e.add({name, description, parameters, execute}))`;
  `execute` returns `{content: [{type: "text", text}]}` (an `output` field without a schema fails)
- command: `ctx.command.transform(e => e.add({name, description, execute}))`
- a tool called through the `execute` tool (Code Mode) also fires the hooks

## Gotchas

- opencode runs a **background service** (`opencode serve --service`). It loads plugins and the
  environment once: after editing a plugin or changing `AI_GUARD_*`, kill it
  (`kill $(pgrep -f '[o]pencode.exe serve --service')`) and the next `opencode` relaunches it.
- The first run after relaunching leaves the service inheriting the pipe: `opencode run ... | tail`
  looks hung. Redirect to a file instead.
- `opencode run '/cmd'` does not dispatch commands (TUI only). To test them without the TUI use
  the API: `opencode api command.list` (from the project directory, after one run), then
  `opencode api session.create -d '{}'` and
  `opencode api session.command --param sessionID=<id> -d '{"name":"ponytail","text":"..."}'`;
  `opencode api session.context --param sessionID=<id>` shows the prompt with the skill attached.
- New skills show up after restarting the service (`skill-commands.js` reads them at startup).

Rest of shell: `ask`, except the allowed read list (the one from `settings.json`).

## Notes

- The caveman plugin (`plugins/caveman/`) is v1: it does not run on v2. The mode works only
  through the `AGENTS.md` block. `opencode.json` does not declare `plugins`.
- `service.json` (local password), `node_modules`, `commands/`, `skills/` and `agents/cavecrew-*`
  are managed by the caveman installer: outside the package.
- Verify: `opencode debug agents`, `opencode debug config`.
- No statusline or herdr hook.
