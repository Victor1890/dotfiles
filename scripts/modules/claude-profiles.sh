#!/usr/bin/env bash
# Perfiles extra de Claude Code (config dirs aparte para otras cuentas). El
# perfil por defecto es ~/.claude y lo enlaza stow; estos replican la misma
# config compartida vía symlink. Ver docs/claude-code.md.
CLAUDE_PROFILES=(work)

link_claude_profiles() {
  local p dir agent
  for p in "${CLAUDE_PROFILES[@]}"; do
    dir="${HOME}/.claude-${p}"
    log "Linking shared Claude config into ${dir}…"
    mkdir -p "${dir}/agents"
    ln -sfn "${ROOT_DIR}/claude/.claude/settings.json" "${dir}/settings.json"
    ln -sfn "${ROOT_DIR}/claude/.claude/CLAUDE.md" "${dir}/CLAUDE.md"
    for agent in "${ROOT_DIR}"/claude/.claude/agents/*.md; do
      [[ -e "${agent}" ]] || continue
      ln -sfn "${agent}" "${dir}/agents/$(basename "${agent}")"
    done
    # Las skills reales viven en el perfil por defecto (ahí las instala
    # `npx skills add -g`); los perfiles extra las comparten por symlink.
    if [[ -d "${dir}/skills" && ! -L "${dir}/skills" ]]; then
      log "WARNING: ${dir}/skills is a real directory; move it to ~/.claude/skills and re-run."
    else
      ln -sfn "${HOME}/.claude/skills" "${dir}/skills"
    fi
  done
}

# Marketplace local de plugins (claude-mods/). settings.json lo referencia por
# una ruta estable (~/.claude/mods) para no hardcodear dónde está clonado el repo.
link_claude_mods() {
  log "Linking claude-mods plugin marketplace at ${HOME}/.claude/mods…"
  mkdir -p "${HOME}/.claude"
  ln -sfn "${ROOT_DIR}/claude-mods" "${HOME}/.claude/mods"
}
