#!/bin/bash
# neBSPWN Post-Install - SIN ERRORES
# Autor: NeTenebrae

set -e

DOTFILES_REPO="https://github.com/NeTenebraes/neBSPWN-dotfiles.git"
DOTFILES_DIR="$HOME/Github/neBSPWN-dotfiles"
# Temas (cámbialos aquí)
THEME_GTK="'catppuccin-mocha-lavender-standard+default'"
THEME_ICONS="'Papirus-Dark'"
THEME_CURSOR="'catppuccin-mocha-dark-cursors'"
THEME_WM="'catppuccin-mocha-lavender-standard+default'"
CURSOR_SIZE="'16'"
# Agrega ESTAS 2 variables al inicio (después de las existentes)
THEME_CURSOR_CLEAN="${THEME_CURSOR//\'/}"  # Quita comillas simples
CURSOR_SIZE_CLEAN="${CURSOR_SIZE//\'/}"    # Quita comillas simples
WALLPAPER_PATH="$HOME/.config/bspwm/lightdm.jpg"


PKGS_PACMAN=(
    "git" "base-devel" "neovim" "wget" "curl" "unzip" "stow"
    "bspwm" "sxhkd" "polybar" "picom" "kitty" "rofi" "dunst"
    "feh" "scrot" "xorg" "xorg-xinit"
    "zsh" "tmux" "htop" "bat" "lsd" 
    "zsh-syntax-highlighting" "zsh-autosuggestions"
    "python" "python-pip" "nodejs" "npm"
    "firefox" "ffmpeg" "vlc" "maim" "nemo" "xclip"
    "qt5ct" 
    "starship" "blueberry" "glib2" "glib2-devel" "libxml2"
)

PKGS_AUR=(
    "vscodium-bin" "megasync-bin"
    "catppuccin-cursors-mocha" "papirus-icon-theme" "catppuccin-gtk-theme-mocha"
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
    
    # Verificar si ZSH ya es el shell actual
    if [ "$SHELL" = "/usr/bin/zsh" ] || grep -q "^$USER:.*:/usr/bin/zsh$" /etc/passwd; then
        echo_ok "ZSH ya configurado (shell actual)"
    else
        echo "🔄 Cambiando shell a ZSH..."
        chsh -s /usr/bin/zsh
        echo_ok "ZSH configurado (reinicia sesión)"
    fi
    
    # Verificar e instalar Starship si no existe
    if ! command -v starship >/dev/null 2>&1; then
        echo "🚀 Instalando Starship..."
        curl -sS https://starship.rs/install.sh | sh
        echo_ok "Starship instalado"
    else
        echo_ok "Starship OK"
    fi
    
    # Configurar ZSH con plugins (después de stow)
    echo_ok "ZSH+Starship listo"
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

    # === 1. XRESOURCES (BSPWM/NÚCLEO X11) ===
    echo "🔹 XResources (BSPWM)..."
    cat >> "$HOME/.Xresources" << EOF
Xcursor.theme: $THEME_CURSOR_CLEAN
Xcursor.size: $CURSOR_SIZE_CLEAN
EOF
    xrdb -merge "$HOME/.Xresources"
    echo_ok "XResources OK"

    # === 2. DEFAULT CURSOR (UNIVERSAL) ===
    gsettings set org.gnome.desktop.interface cursor-size "$CURSOR_SIZE_CLEAN" 2>/dev/null || true
    echo "🔹 Default Cursor..."
    mkdir -p "$HOME/.icons/default"
    cat > "$HOME/.icons/default/index.theme" << EOF
[Icon Theme]
Inherits=$THEME_CURSOR_CLEAN
EOF
    echo_ok "Default OK"

    # === 3. VARIABLES ENTORNO (PERMANENTE) ===
    echo "🔹 Variables..."
    mkdir -p "$HOME/.config/environment.d"
    cat > "$HOME/.config/environment.d/cursor.conf" << EOF
XCURSOR_THEME=$THEME_CURSOR_CLEAN
XCURSOR_SIZE=$CURSOR_SIZE_CLEAN
XCURSOR_PATH=$HOME/.icons:/usr/share/icons
EOF

# === GTK 3/4 CONFIGS (REEMPLAZA COMPLETO) ===
echo "Configurando GTK 3/4..."
mkdir -p "$HOME/.config/gtk-3.0" "$HOME/.config/gtk-4.0"

cat > "$HOME/.config/gtk-3.0/settings.ini" << EOF
[Settings]
gtk-theme-name=${THEME_GTK//\'/}
gtk-icon-theme-name=${THEME_ICONS//\'/}
gtk-cursor-theme-name=$THEME_CURSOR_CLEAN
gtk-cursor-theme-size=$CURSOR_SIZE_CLEAN
gtk-font-name=JetBrainsMono Nerd Font 11
gtk-application-prefer-dark-theme=true
gtk-xft-antialias=1
gtk-xft-hinting=1
gtk-xft-hintstyle=hintfull
gtk-xft-rgba=rgb
EOF

# GTK4 - CON VARIABLES (igual)
cat > "$HOME/.config/gtk-4.0/settings.ini" << EOF
[Settings]
gtk-theme-name=${THEME_GTK//\'/}
gtk-icon-theme-name=${THEME_ICONS//\'/}
gtk-cursor-theme-name=$THEME_CURSOR_CLEAN
gtk-cursor-theme-size=$CURSOR_SIZE_CLEAN
gtk-font-name=JetBrainsMono Nerd Font 11
EOF


echo_ok "GTK 3/4 OK"

    # === 5. QT Kvantum ===
    echo "🔹 QT5..."
    mkdir -p "$HOME/.config/qt5ct"
    cat > "$HOME/.config/qt5ct/qt5ct.conf" << EOF
[Appearance]
theme=kvantum
[Fonts]
font=JetBrainsMono Nerd Font,11,-1,5,50,0,0,0,0,0
EOF
    echo_ok "QT OK"

    dconf write /org/blueberry/use-symbolic-icons false
    dconf write /org/gnome/desktop/interface/color-scheme "'prefer-dark'"

    # QT Kvantum
    mkdir -p "$HOME/.config/qt5ct"
    {
        echo "[Appearance]"
        echo "theme=kvantum"
    } > "$HOME/.config/qt5ct/qt5ct.conf"

    # Slick-greeter (usuario lightdm)
    sudo -u lightdm dbus-launch dconf write /x/dm/slick-greeter/cursor-theme-name "$THEME_CURSOR"
    sudo -u lightdm dbus-launch dconf write /x/dm/slick-greeter/icon-theme-name "$THEME_ICONS"
    sudo -u lightdm dbus-launch dconf write /x/dm/slick-greeter/theme-name "$THEME_GTK"

    # GNOME interface
    dconf write /org/gnome/desktop/interface/gtk-theme "$THEME_GTK"
    dconf write /org/gnome/desktop/interface/icon-theme "$THEME_ICONS"
    dconf write /org/gnome/desktop/interface/cursor-theme "$THEME_CURSOR"
    dconf write /org/gnome/desktop/interface/gtk-key-theme "'Default'"

    # Cinnamon interface
    dconf write /org/cinnamon/desktop/interface/gtk-theme "$THEME_GTK"
    dconf write /org/cinnamon/desktop/interface/icon-theme "$THEME_ICONS"
    dconf write /org/cinnamon/desktop/interface/cursor-theme "$THEME_CURSOR"
    dconf write /org/cinnamon/desktop/interface/gtk-key-theme "'Default'"

    # Cinnamon / GNOME WM
    dconf write /org/cinnamon/desktop/wm/preferences/theme "$THEME_WM"
    dconf write /org/cinnamon/desktop/wm/preferences/theme-backup "$THEME_WM"
    dconf write /org/gnome/desktop/wm/preferences/theme "$THEME_WM"

    # MATE (si aplica)
    dconf write /org/mate/interface/gtk-theme "$THEME_GTK"
    dconf write /org/mate/interface/icon-theme "$THEME_ICONS"
    dconf write /org/mate/interface/cursor-theme "$THEME_CURSOR"
    dconf write /org/mate/interface/gtk-key-theme "'Default'"

    # Backups de Cinnamon
    dconf write /org/cinnamon/desktop/interface/gtk-theme-backup "$THEME_GTK"
    dconf write /org/cinnamon/desktop/interface/icon-theme-backup "$THEME_ICONS"

    # GNOME key theme (igual en todos)
    dconf write /org/gnome/desktop/interface/gtk-key-theme "'Default'"

    # MATE interface
    dconf write /org/mate/interface/gtk-theme "$THEME_GTK"
    dconf write /org/mate/interface/icon-theme "$THEME_ICONS"
    dconf write /org/mate/interface/gtk-key-theme "'Default'"

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
