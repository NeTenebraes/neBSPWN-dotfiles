# Historial básico
HISTFILE=~/.zsh_history
HISTSIZE=10000
SAVEHIST=10000
setopt SHARE_HISTORY HIST_IGNORE_DUPS HIST_IGNORE_SPACE
source /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=242' 
# ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=52'


# Completado PRO
autoload -U compinit
compinit
zstyle ':completion:*' menu select list-colors ''
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}' 'r:|[._-]=* r:|=*' 'l:|=* r:|=*'
setopt COMPLETE_ALIASES

# FZF + ZSH
export TERM=xterm-256color
export FZF_DEFAULT_OPTS='--height 40% --layout=reverse --border'

# =================================================================
# SHORTCUTS DE TECLADO (FIX Ctrl+Espacio)
# =================================================================
TRAPWINCH() { zle && zle reset-prompt }

# FIX SUPR + BACKSPACE
bindkey '^[[3~' delete-char          # Supr
bindkey '^H'   backward-delete-char  # Backspace

# NAVEGACIÓN WORD
bindkey '^[[1;5D' backward-word      # Ctrl+←
bindkey '^[[5D'   backward-word      # Option+←  
bindkey '^[[1;5C' forward-word       # Ctrl+→
bindkey '^[[5C'   forward-word       # Option+→

# BÁSICOS EMACS
bindkey '^A' beginning-of-line       # Ctrl+A
bindkey '^E' end-of-line             # Ctrl+E
bindkey '^K' kill-line               # Ctrl+K
bindkey '^U' backward-kill-line      # Ctrl+U
bindkey '^W' backward-kill-word      # Ctrl+W
bindkey '^Y' yank                    # Ctrl+Y
bindkey '\ed' kill-word              # Alt+D

# HISTORIAL
bindkey '^R' history-incremental-search-backward  # Ctrl+R
bindkey '^S' history-incremental-search-forward   # Ctrl+S
bindkey '^[[A' up-line-or-history                  # ↑
bindkey '^[[B' down-line-or-history                # ↓

# SELECCIÓN + MARK
bindkey '^X^X' exchange-point-and-mark             # Ctrl+X Ctrl+X
bindkey '^G' cancel                                # Ctrl+G

# PANTALLA
bindkey '^L' clear-screen                          # Ctrl+L

# FZF (SIN Ctrl+Espacio)
bindkey '^T' fzf-file-widget                       # Ctrl+T archivos
bindkey '^G^F' fzf-history-widget                  # Ctrl+G Ctrl+F historial  
bindkey '^[e' fzf-cd-widget                        # Alt+E directorios

# STARSHIP
eval "$(starship init zsh)"