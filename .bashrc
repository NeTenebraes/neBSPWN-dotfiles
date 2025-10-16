#
# ~/.bashrc
#

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

alias ls='ls --color=auto'
alias grep='grep --color=auto'
PS1='[\u@\h \W]\$ '

# NeVPN & Proxy Manager command
nevpn() {
    # Source the function library to make them available in the current shell
    if [ -f "$HOME/.nevpn/nevpn.sh" ]; then
        source "$HOME/.nevpn/nevpn.sh"
    else
        echo "Error: nevpn library not found at $HOME/.nevpn/nevpn.sh"
        return 1
    fi
    # Pass all arguments to the main handler function
    nevpn_handler "$@"
}
export http_proxy="http://192.168.229.49:8228"
export https_proxy="http://192.168.229.49:8228"
