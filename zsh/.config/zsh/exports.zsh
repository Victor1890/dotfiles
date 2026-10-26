# ============================================================================
# EXPORTS
# ============================================================================
# Shim: las variables de entorno son las mismas que en bash (locale, EDITOR,
# colores de ls/man, fzf). Ver bash/.config/bash/exports.sh.
[[ -r "${BASH_CONFIG_DIR}/exports.sh" ]] && source "${BASH_CONFIG_DIR}/exports.sh"
