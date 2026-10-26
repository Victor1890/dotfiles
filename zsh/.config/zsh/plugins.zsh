# ============================================================================
# OH MY ZSH + PLUGINS
# ============================================================================
# Oh My Zsh y los dos plugins custom no se versionan: se clonan una sola vez,
# en el primer arranque, si faltan (mismo patrón que ble.sh en bash).
# oh-my-zsh.sh ejecuta compinit, así que todo lo que dependa de compdef va en
# completion.zsh, que se carga después.

export ZSH="$HOME/.oh-my-zsh"
ZSH_CUSTOM="${ZSH_CUSTOM:-$ZSH/custom}"

_zde_ensure_clone() {
  local url="$1" dir="$2"
  [[ -d "$dir" ]] && return 0
  command -v git >/dev/null 2>&1 || return 0
  echo "[zsh] instalando ${dir:t}…" >&2
  git clone --depth 1 "$url" "$dir" >/dev/null 2>&1 \
    || echo "[zsh] fallo instalando ${dir:t}." >&2
}
_zde_ensure_clone https://github.com/ohmyzsh/ohmyzsh.git "$ZSH"
_zde_ensure_clone https://github.com/zsh-users/zsh-autosuggestions.git "$ZSH_CUSTOM/plugins/zsh-autosuggestions"
_zde_ensure_clone https://github.com/zdharma-continuum/fast-syntax-highlighting.git "$ZSH_CUSTOM/plugins/fast-syntax-highlighting"
unfunction _zde_ensure_clone

ZSH_THEME="robbyrussell"

# fast-syntax-highlighting tiene que ir ÚLTIMO entre los plugins.
plugins=(
  git
  zsh-autosuggestions
  fast-syntax-highlighting
)

[[ -r "$ZSH/oh-my-zsh.sh" ]] && source "$ZSH/oh-my-zsh.sh"
