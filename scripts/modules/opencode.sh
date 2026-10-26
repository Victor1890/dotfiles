#!/usr/bin/env bash
# opencode v2 is the official version for this config (opencode/ uses v2 keys,
# which v1 rejects). The v2 installer works the same on every OS and replaces
# the v1 binary in ~/.opencode/bin. --no-modify-path: the installer must not
# touch .zshrc/.bashrc (they are symlinks into the repo); path.sh / path.zsh
# already set the PATH. See docs/opencode.md.
opencode_major() {
  opencode --version 2>/dev/null | grep -oE '[0-9]+' | head -n 1
}

ensure_opencode() {
  if exists opencode && [[ "$(opencode_major)" -ge 2 ]] 2>/dev/null; then
    return 0
  fi
  if exists opencode; then
    log "opencode v1 detected; upgrading to v2…"
  else
    log "opencode not found; installing v2…"
  fi
  local tmp; tmp="$(mktemp)"
  if curl -fsSL -o "${tmp}" https://opencode.ai/v2/install; then
    bash "${tmp}" --no-modify-path || log "Failed to install opencode v2."
  else
    log "Could not download the opencode v2 installer."
  fi
  rm -f "${tmp}"
}
