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

## Plugins (adaptador de `claude-mods` y hooks)

Equivalente opencode de los hooks de Claude y de `claude-mods/`. Son archivos sueltos
`plugins/*.js` con `export default { id, setup(ctx) }` (API v2). Se descubren solos
(no declarar en `plugins`: una entrada ahí cuelga el arranque). Se verificaron de punta a punta
con `opencode run`.

| Plugin | Equivale a | Cómo |
|---|---|---|
| `guardrails.js` | `git-guardrails.mjs` + `guard-protected-branch.mjs` | `ctx.permission.hook("evaluate")` pone `effect = "deny"`. Importa las reglas de `~/.claude/hooks/*.mjs` (una sola fuente, mismos tests y mismas variables `AI_GUARD_*`) |
| `replay.js` | `claude-mods/replay-theater` | `ctx.tool.hook("execute.before/after")` registra los pasos de `write`/`edit`; tool `replay` y comando `/replay`. Sin pane/banda: opencode no tiene API de UI para plugins |

Capas de defensa para shell, de fuera hacia dentro: `policies` (globs, duro) → `permissions`
(`deny` al final, gana la última) → `guardrails.js` (regex por segmento, rama protegida).
El plugin cubre lo que los globs no ven (`rm -r -f`, commit en rama protegida, edits en rama
protegida). Rama protegida: `AI_GUARD_PROTECT_BRANCHES=main` en el entorno **al arrancar el
servicio** (ver trampas).

Shapes reales (v2.0.31, medidos con un plugin sonda):

- permiso: `{action, resources[], effect, message?}`; `edit` trae rutas relativas, `shell` el comando
- tool: `{tool: "write"|"edit"|"shell"|..., id, input, status, result}`;
  `write` = `{path, content}`, `edit` = `{path, oldString, newString}`
- tool propia: `ctx.tool.transform(e => e.add({name, description, parameters, execute}))`;
  `execute` devuelve `{content: [{type: "text", text}]}` (un campo `output` sin schema falla)
- comando: `ctx.command.transform(e => e.add({name, description, execute}))`
- un tool llamado vía el tool `execute` (Code Mode) también dispara los hooks

## Trampas

- opencode corre un **servicio en segundo plano** (`opencode serve --service`). Carga los plugins
  y el entorno una sola vez: tras editar un plugin o cambiar `AI_GUARD_*`, mátalo
  (`kill $(pgrep -f '[o]pencode.exe serve --service')`) y el próximo `opencode` lo relanza.
- La primera ejecución tras relanzarlo deja el servicio heredando el pipe: `opencode run ... | tail`
  parece colgado. Redirige a un archivo.
- `opencode run '/cmd'` no despacha comandos de plugin (solo la TUI): se probaron vía tool.

Resto de shell: `ask`, salvo la lista de lectura permitida (la de `settings.json`).

## Notas

- El plugin de caveman (`plugins/caveman/`) es v1: no corre en v2. El modo funciona solo por el
  bloque de `AGENTS.md`. `opencode.json` no declara `plugins`.
- `service.json` (password local), `node_modules`, `commands/`, `skills/` y `agents/cavecrew-*`
  los gestiona el instalador de caveman: fuera del paquete.
- Verificar: `opencode debug agents`, `opencode debug config`.
- Sin statusline ni hook de herdr.
