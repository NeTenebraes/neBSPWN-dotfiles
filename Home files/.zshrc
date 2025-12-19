# Historial básico
HISTFILE=~/.zsh_history
HISTSIZE=10000
SAVEHIST=10000
setopt SHARE_HISTORY HIST_IGNORE_DUPS

# Completado
autoload -U compinit
compinit
zstyle ':completion:*' menu select
setopt completealiases

# =================================================================
# SHORTCUTS DE TECLADO (EMACS MODE) - TODO MANTENIDO
# =================================================================
TRAPWINCH() { zle && zle reset-prompt }

bindkey '^[[1;5D' backward-word    # Ctrl+←
bindkey '^[[5D'   backward-word
bindkey '^[[1;5C' forward-word     # Ctrl+→
bindkey '^[[5C'   forward-word
bindkey '^A' beginning-of-line     # Ctrl+A
bindkey '^E' end-of-line           # Ctrl+E
bindkey '^K' kill-line             # Ctrl+K
bindkey '^U' backward-kill-line    # Ctrl+U
bindkey '^W' backward-kill-word    # Ctrl+W
bindkey '^Y' yank                  # Ctrl+Y
bindkey '\ed' kill-word            # Alt+D
bindkey '^R' history-incremental-search-backward  # Ctrl+R
bindkey '^X^X' exchange-point-and-mark            # Ctrl+X Ctrl+X
bindkey '^L' clear-screen          # Ctrl+L

# STARSHIP
eval "$(starship init zsh)"
