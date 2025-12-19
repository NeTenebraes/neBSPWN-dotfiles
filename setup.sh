#!/bin/bash
# neBSPWN Post-Install - SIN ERRORES
# Autor: NeTenebrae

set -e

DOTFILES_REPO="https://github.com/NeTenebraes/neBSPWN-dotfiles.git"
DOTFILES_DIR="$HOME/Github/neBSPWN-dotfiles"

PKGS_PACMAN=(
    "git" "base-devel" "neovim" "wget" "curl" "unzip" "stow"
    "bspwm" "sxhkd" "polybar" "picom" "kitty" "rofi" "dunst"
    "lightdm" "lightdm-gtk-greeter"
    "feh" "scrot" "xorg" "xorg-xinit"
    "zsh" "tmux" "htop" "bat" "lsd" 
    "zsh-syntax-highlighting" "zsh-autosuggestions"
    "python" "python-pip" "nodejs" "npm"
    "firefox" "ffmpeg" "vlc"
    "qt5ct" "kvantum"
    "starship"
)

PKGS_AUR=(
    "vscodium-bin"
)

FONTS=(
    "ttf-jetbrains-mono-nerd"
    "ttf-font-awesome" "ttf-font-awesome"
    "noto-fonts-emoji" "adwaita-icon-theme"
)

echo_msg() { echo -e "\n\033[1;34m🛡️ $1\033[0m"; }
echo_ok()  { echo -e "\033[1;32m✅ $1\033[0m"; }

install_paru() {
    command -v paru >/dev/null || {
        echo_msg "PARU..."
        git clone https://aur.archlinux.org/paru.git /tmp/paru
        cd /tmp/paru && makepkg -si --noconfirm && cd - && rm -rf /tmp/paru
        echo_ok "PARU OK"
    }
}

setup_zsh() {
    echo_msg "ZSH+Starship..."
    chsh -s /usr/bin/zsh
    
    cat > "$HOME/.zshrc" << 'EOF'
eval "\$(starship init zsh)"
source /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
source /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh
export PATH="\$HOME/.local/bin:\$PATH"
alias ll='lsd -la'
alias dotfiles='cd ~/Github/neBSPWN-dotfiles'
EOF
    echo_ok "ZSH OK"
}

deploy_dotfiles() {
    [ ! -d "$DOTFILES_DIR" ] && git clone "$DOTFILES_REPO" "$DOTFILES_DIR"
    cd "$DOTFILES_DIR" && stow bspwm polybar kitty rofi zsh dunst picom sxhkd 2>/dev/null || true
    echo_ok "Dotfiles OK"
}

setup_fonts() {
    echo_msg "Fuentes..."
    sudo pacman -S --needed --noconfirm "${FONTS[@]}"
    fc-cache -fv
    echo_ok "Fuentes OK"
}

setup_themes() {
    echo_msg "Temas básicos..."
    paru -S --needed --noconfirm "${PKGS_AUR[@]}"
    
    # GTK básico oscuro
    mkdir -p "$HOME/.config/gtk-3.0"
    echo "gtk-application-prefer-dark-theme=1" > "$HOME/.config/gtk-3.0/settings.ini"
    
    # QT Kvantum
    mkdir -p "$HOME/.config/qt5ct"
    echo "[Appearance]" > "$HOME/.config/qt5ct/qt5ct.conf"
    echo "theme=kvantum" >> "$HOME/.config/qt5ct/qt5ct.conf"
    echo_ok "Temas OK"
}

# EXEC
[ "$EUID" -eq 0 ] && { echo "No root"; exit 1; }

echo_msg "🚀 neBSPWN Setup"
sudo pacman -Syu --noconfirm
sudo pacman -S --needed --noconfirm "${PKGS_PACMAN[@]}"
setup_fonts
install_paru
setup_themes
setup_zsh
deploy_dotfiles

echo_ok "¡LISTO! Reinicia: startx"
echo "🌿 Starship + BSPWM + Kitty | @NeTenebraes"
