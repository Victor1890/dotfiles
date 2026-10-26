# ============================================================================
# SHELL INTEGRATIONS
# ============================================================================
# iTerm2
test -e "${HOME}/.iterm2_shell_integration.zsh" && source "${HOME}/.iterm2_shell_integration.zsh"

# ---- FZF ----
# Key bindings + completion de fzf (sin el tema de colores de integrations.sh).
command -v fzf >/dev/null 2>&1 && source <(fzf --zsh)

# ---- ZOXIDE ----
# aliases.sh define `cd` → `z`, así que esto es necesario.
command -v zoxide >/dev/null 2>&1 && eval "$(zoxide init zsh)"

# ---- NVM ----
# Instalación real de esta Mac: ~/.nvm (bash usa el path XDG).
[[ -d "$HOME/.nvm" ]] && export NVM_DIR="$HOME/.nvm" || export NVM_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"

# ---- PYENV ----
export PYENV_ROOT="$HOME/.pyenv"
[[ -d "$PYENV_ROOT/bin" ]] && export PATH="$PYENV_ROOT/bin:$PATH"
command -v pyenv >/dev/null 2>&1 && eval "$(pyenv init -)"
