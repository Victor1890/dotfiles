# ============================================================================
# ALIASES
# ============================================================================
# Los aliases son los de bash (una sola copia); lo propio de zsh va debajo.
[[ -r "${BASH_CONFIG_DIR}/aliases.sh" ]] && source "${BASH_CONFIG_DIR}/aliases.sh"

alias rzsh='source ~/.zshrc'
alias ezsh='nvim ~/.zshrc'

# pnpm es el gestor de paquetes JS de esta Mac
alias npm='echo "Use pnpm instead of npm."'
