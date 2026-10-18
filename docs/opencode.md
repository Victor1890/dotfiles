# opencode

Paquete Stow `opencode/` → `~/.config/opencode/`. Espejo de la config de Claude Code
(`docs/claude-code.md`), con un único modelo para todo: `opencode/mimo-v2.6-flash-free`
(MiMo-V2.6-Flash vía el proveedor integrado de opencode; sin API key externa ni `providers`).

**Formato v2 obligatorio.** Guía: <https://opencode.ai/v2/docs/migrate-v1/>. Claves v1
(`permission`, `agent`, `plugin`, `autoupdate`, `small_model`, `tui.json`) se normalizan en
memoria pero no se deben usar: este paquete solo escribe claves v2.

## Qué se versiona

| Archivo | Equivale en Claude Code |
|---|---|
| `opencode.json` | `settings.json`: `model`, `permissions`, `policies`, `mcp`, `update` |
| `AGENTS.md` | `CLAUDE.md` global + bloque caveman. v2 solo lee `AGENTS.md`, no `CLAUDE.md` |
| `agents/*.md` | `claude/.claude/agents/*.md` (los 9, mismo modelo) |
| `cli.json` | tema y UI del terminal (v2 lo guarda global, antes `tui.json`) |

Los skills **no se copian**: v2 descubre `~/.claude/skills/*/SKILL.md`. Los reviewers siguen
leyendo `~/.claude/docs/review-output.md`.

## Mapa v1 → v2 usado aquí

| Claude / v1 | v2 |
|---|---|
| `permission.bash` | `permissions` array, `action: shell` (gana la **última** regla) |
| `small_model` | `agents.title.model` |
| `autoupdate: false` | `update: "disable"` |
| `mcp.<n>` + `enabled` | `mcp.servers.<n>` + `disabled` |
| agente `permission:` | `permissions:` lista de `{action, resource, effect}` |
| agente `temperature`, `effort`, `tools` | no existen; se descartan |

## Agentes

`Explore` → `explore`, `general-purpose` → `general`, `Plan` → `plan` (primary); sobrescriben
los integrados por ID. Los de solo lectura llevan `edit` denegado.

## Guardrails

Los hooks de Claude (`git-guardrails.mjs`, `guard-protected-branch.mjs`) **no se portan**:
los plugins v1 no corren en v2 y la API de plugins v2 no documenta intercepción de tools.
En su lugar, `policies` con `tool.use` y `shell:<glob>` deniega (duro, sin prompt, no se
puede reabrir desde un proyecto) las reglas SAFETY: `rm -rf`, `git reset --hard`,
`git clean -f`, force-push, `git branch -D`, `git reflog expire`, `git checkout .`,
`git restore .`. Los mismos globs aparecen como `deny` en `permissions`. Más burdo que el regex
por segmento: no distingue `main` de otra rama y no hay guard de rama protegida.

Resto de shell: `ask`, salvo la lista de lectura permitida (la de `settings.json`).

## Notas

- El plugin de caveman (`plugins/caveman/`) es v1: no corre en v2. El modo funciona solo por el
  bloque de `AGENTS.md`. Por eso `opencode.json` no declara `plugins`.
- `service.json` (password local), `node_modules`, `commands/`, `skills/` y `agents/cavecrew-*`
  los gestiona el instalador de caveman: fuera del paquete.
- Verificar: `opencode debug agents`, `opencode debug config`.
- Sin statusline ni hook de herdr.
