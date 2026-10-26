# ============================================================================
# PACKAGE MANAGERS (Homebrew)
# ============================================================================
[[ -x /opt/homebrew/bin/brew ]] && eval "$(/opt/homebrew/bin/brew shellenv)"

# ============================================================================
# PATH
# ============================================================================
# Rutas de esta Mac (no las del path.sh de bash, pensado para Linux/XDG).

# User-local binaries
[[ -d "$HOME/.local/bin" ]] && export PATH="$HOME/.local/bin:$PATH"
[[ -d "$HOME/bin" ]] && export PATH="$HOME/bin:$PATH"

# pnpm (en macOS vive en ~/Library/pnpm)
export PNPM_HOME="$HOME/Library/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME/bin:"*) ;;
  *) export PATH="$PNPM_HOME/bin:$PATH" ;;
esac

# bun
export BUN_INSTALL="$HOME/.bun"
[[ -d "$BUN_INSTALL" ]] && export PATH="$BUN_INSTALL/bin:$PATH"

# PHP 8.2 (Homebrew)
[[ -d /opt/homebrew/opt/php@8.2 ]] && export PATH="/opt/homebrew/opt/php@8.2/bin:/opt/homebrew/opt/php@8.2/sbin:$PATH"

# CLIs instaladas fuera de brew
[[ -d "$HOME/.lmstudio/bin" ]] && export PATH="$PATH:$HOME/.lmstudio/bin"                             # LM Studio (lms)
[[ -d "$HOME/.opencode/bin" ]] && export PATH="$HOME/.opencode/bin:$PATH"                             # opencode
[[ -d "$HOME/.antigravity-ide/antigravity-ide/bin" ]] && export PATH="$HOME/.antigravity-ide/antigravity-ide/bin:$PATH"  # Antigravity IDE
[[ -r "$HOME/.local/bin/env" ]] && . "$HOME/.local/bin/env"
