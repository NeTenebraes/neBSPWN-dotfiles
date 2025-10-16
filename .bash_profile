#
# ~/.bash_profile
#

[[ -f ~/.bashrc ]] && . ~/.bashrc

# Load .bashrc if it exists for interactive shells
if [ -f ~/.bashrc ]; then
    source ~/.bashrc
fi
