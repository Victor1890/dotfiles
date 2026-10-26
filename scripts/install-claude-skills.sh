#!/usr/bin/env bash
set -euo pipefail

# Installs Claude Code skills listed in packages/claude-skills.txt (user-level,
# ~/.claude/skills) and registers the claude-mods plugin. Idempotent: already
# installed skills are skipped by the skills CLI itself.

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SKILLS_LIST="${ROOT_DIR}/packages/claude-skills.txt"

log() { echo "[setup] $*"; }
exists() { command -v "$1" >/dev/null 2>&1; }

install_skills() {
  if ! exists npx; then
    log "npx not available; skipping Claude Code skills."
    return 0
  fi
  local repo
  while IFS= read -r repo; do
    [[ "${repo}" =~ ^[[:space:]]*(#|$) ]] && continue
    log "Installing skill(s) from ${repo}…"
    # -g: user-level; -a: only Claude Code; -s '*': all skills in the repo; -y: no prompts
    # stdin a /dev/null: si no, la CLI consume el stdin del bucle y solo se
    # procesa la primera línea del manifiesto.
    npx -y skills add "${repo}" -g -a claude-code -s '*' -y </dev/null \
      || log "Failed: ${repo} (continuing)."
  done < "${SKILLS_LIST}"
}

# Plugins live in each profile's own config dir, so they can't be symlinked —
# register them once per config dir. "" = default profile (~/.claude); the rest
# mirror CLAUDE_PROFILES in bootstrap.sh.
CLAUDE_PROFILES=("" work)

# Local plugin marketplace (claude-mods/, linked at ~/.claude/mods by
# link_claude_mods). settings.json only declares it; the CLI add/install makes
# the plugin available without a manual step. Per profile.
register_mods() {
  if ! exists claude; then
    log "claude CLI not available; skipping claude-mods."
    return 0
  fi
  local profile label
  for profile in "${CLAUDE_PROFILES[@]}"; do
    if [[ -n "${profile}" ]]; then
      label="${profile}"
      export CLAUDE_CONFIG_DIR="${HOME}/.claude-${profile}"
    else
      label="default"
      unset CLAUDE_CONFIG_DIR
    fi
    log "Registering claude-mods marketplace + replay-theater (${label})…"
    claude plugin marketplace add "${HOME}/.claude/mods" \
      && claude plugin install replay-theater@dotfiles-mods \
      || log "Failed to register claude-mods for ${label} (continuing)."
  done
  unset CLAUDE_CONFIG_DIR
}

install_skills
register_mods
log "Claude Code skills/mods done."
