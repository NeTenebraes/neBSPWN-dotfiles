# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# Archivo de historial y tamaño
HISTFILE=~/.zsh_history
HISTSIZE=10000
SAVEHIST=10000

# Opciones recomendadas
setopt INC_APPEND_HISTORY       # Guarda cada comando al ejecutarlo
setopt SHARE_HISTORY            # Comparte historial entre terminales
setopt HIST_IGNORE_DUPS         # Evita duplicados
setopt HIST_REDUCE_BLANKS       # Ignora líneas vacías

# Created by newuser for 5.9
source /opt/powerlevel10k/powerlevel10k.zsh-theme
source /opt/powerlevel10k/powerlevel10k.zsh-theme

# Sistema de autocompletado nativo
autoload -U compinit
compinit

# Muestra menú de sugerencias al presionar dos veces TAB
zstyle ':completion:*' menu select

# Permitir autocompletar alias
setopt completealiases

ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=#ff5555'



# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

# MANUAL
alias ll='lsd -lh --group-dirs=first'
alias la='lsd -a --group-dirs=first'
alias l='lsd --group-dirs=first'
alias lla='lsd -lha --group-dirs=first'
alias ls='lsd --group-dirs=first'
alias cat='bat'
alias ncat='/bin/cat'

# =================================================================
# ATRIBUTOS DE EDICIÓN Y NAVEGACIÓN (EMACS MODE)
# Se recomienda usar estos bindings para mejorar la productividad.
#
# Para listar todos los atajos de tu shell actual, usa: bindkey
# =================================================================

# ---------------------------------------------------------------
# 1. NAVEGACIÓN RÁPIDA (Word Jumps)
# ---------------------------------------------------------------

# Mover el cursor una palabra hacia atrás (Ctrl + Flecha Izquierda)
# NOTA: La secuencia ^[[1;5D es la más común, pero puede variar.
# La secuencia ^[[5D es otra alternativa común.
bindkey '^[[1;5D' backward-word
bindkey '^[[5D'   backward-word

# Mover el cursor una palabra hacia adelante (Ctrl + Flecha Derecha)
# Se asume que la secuencia para la derecha es ^[[1;5C (o ^[[5C)
bindkey '^[[1;5C' forward-word
bindkey '^[[5C'   forward-word


# ---------------------------------------------------------------
# 2. ATAJOS DE EDICIÓN Y MANIPULACIÓN DE LÍNEA
# ---------------------------------------------------------------

# Ir al inicio de la línea (Ctrl + A)
bindkey '^A' beginning-of-line
# Ir al final de la línea (Ctrl + E)
bindkey '^E' end-of-line
# Cortar desde el cursor hasta el final de la línea (Ctrl + K)
bindkey '^K' kill-line
# Cortar desde el cursor hasta el inicio de la línea (Ctrl + U)
bindkey '^U' backward-kill-line
# Eliminar la palabra anterior (Ctrl + W)
bindkey '^W' backward-kill-word
# Pegar el texto cortado (Ctrl + Y - 'Yank')
bindkey '^Y' yank
# Eliminar el carácter delante del cursor (Alt + D)
bindkey '\ed' kill-word

# ---------------------------------------------------------------
# 3. ATAJOS DE HISTORIAL Y UTILIDAD
# ---------------------------------------------------------------

# Búsqueda incremental en el historial (Ctrl + R - Reverse Search)
# Esta es una de las funciones más útiles.
bindkey '^R' history-incremental-search-backward

# Alternar entre el cursor actual y la posición anterior (Ctrl + X, Ctrl + X)
# Útil para copiar y pegar entre dos puntos.
bindkey '^X^X' exchange-point-and-mark

# Limpiar la pantalla de la terminal (Ctrl + L)
bindkey '^L' clear-screen

[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh
