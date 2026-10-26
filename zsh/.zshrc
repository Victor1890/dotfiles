# ============================================================================
# ZSH CONFIG — entry point (macOS)
# ============================================================================
# Espejo de bash/.bashrc: loader delgado + módulos bajo ~/.config/zsh/ (ver
# docs/shell-and-dotfiles.md). zsh solo lee .zshrc en shells interactivas.

ZSH_CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/zsh"
# aliases, functions y exports son los de bash (una sola copia); ver los shims.
BASH_CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/bash"

zsh_modules=(
  exports       # shim: exports de bash (locale, EDITOR, colores, fzf)
  path          # Homebrew + PATH
  plugins       # Oh My Zsh (tema + plugins); hace compinit
  completion    # completions que deben ir DESPUÉS de compinit (bun, nvm)
  history       # opciones de historial
  aliases       # shim: aliases de bash + los propios de zsh
  functions     # shim: funciones de bash
  integrations  # fzf, zoxide, nvm, pyenv, iTerm2
)

for _mod in "${zsh_modules[@]}"; do
  [[ -r "${ZSH_CONFIG_DIR}/${_mod}.zsh" ]] && source "${ZSH_CONFIG_DIR}/${_mod}.zsh"
done
unset _mod zsh_modules
