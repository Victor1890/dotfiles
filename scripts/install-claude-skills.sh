#!/usr/bin/env bash
set -euo pipefail

# Installs Claude Code skills listed in packages/claude-skills.txt (user-level,
# ~/.claude/skills). Idempotent: already
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

install_skills
log "Claude Code skills done."
