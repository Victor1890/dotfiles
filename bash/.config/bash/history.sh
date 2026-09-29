# ============================================================================
# HISTORY CONFIGURATION
# ============================================================================
# "sharehistory" no tiene equivalente 1:1 en bash: se imita compartiendo el
# historial en vivo entre sesiones vía PROMPT_COMMAND.

HISTSIZE=5000
HISTFILE="$HOME/.bash_history"
HISTFILESIZE=$HISTSIZE
HISTTIMEFORMAT="[%F %T] "

# ignorespace: no guarda líneas que empiezan con espacio (hist_ignore_space)
# ignoredups:  no guarda duplicados consecutivos
# erasedups:   al guardar una línea, borra duplicados anteriores (≈ hist_ignore_all_dups)
HISTCONTROL=ignorespace:ignoredups:erasedups

shopt -s histappend   # appendhistory: no pisa el archivo al salir
shopt -s cmdhist       # un comando multilínea = una entrada de historial

# sharehistory: comparte el historial en vivo entre sesiones abiertas a la vez
PROMPT_COMMAND="history -a; history -c; history -r${PROMPT_COMMAND:+; $PROMPT_COMMAND}"
