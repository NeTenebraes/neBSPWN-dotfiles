#!/bin/bash
# neBSPWN Post-Install - IDEMPOTENTE ✅
# Autor: NeTenebrae | @NeTenebraes

set -e

DOTFILES_REPO="https://github.com/NeTenebraes/neBSPWN-dotfiles.git"
DOTFILES_DIR="$HOME/.config/neBSPWN-dotfiles"  # ← CORREGIDO: repo aislado
CONFIG_SRC="$DOTFILES_DIR/Config Files"        # ← NUEVO
HOME_SRC="$DOTFILES_DIR/Home files"            # ← NUEVO
SDDM_THEME_SRC="$DOTFILES_DIR/SDDM"            # ← CORREGIDO

# Temas (cambia aquí)
THEME_GTK="catppuccin-mocha-lavender-standard+default"
THEME_ICONS="Papirus-Dark"
THEME_CURSOR="catppuccin-mocha-dark-cursors"
THEME_WM="catppuccin-mocha-lavender-standard+default"
CURSOR_SIZE="16"

SDDM_THEME_NAME="netenebrae"
SDDM_THEME_DIR="/usr/share/sddm/themes"
SDDM_THEME_DST="$SDDM_THEME_DIR/$SDDM_THEME_NAME"
SDDM_Wall="$HOME/.config/bspwm/lightdm.jpg"

# Limpiar comillas
THEME_CURSOR_CLEAN="${THEME_CURSOR//\'/}"
CURSOR_SIZE_CLEAN="${CURSOR_SIZE//\'/}"


PKGS_PACMAN=(
    # Essencials
    "git" "base-devel" "neovim" "wget" "curl" "unzip"
    "bspwm" "sxhkd" "polybar" "picom" "kitty" "rofi" "dunst"
    "feh" "scrot" "xorg" "xorg-xinit"
    "zsh" "tmux" "htop" "bat" "lsd" "sddm"
    "zsh-syntax-highlighting" "zsh-autosuggestions"
    "python" "python-pip" "nodejs" "npm"
    "firefox" "ffmpeg" "vlc" "maim" "nemo" "xclip"
    "qt5ct" "starship" "blueberry" "glib2" "libxml2"
)

PKGS_AUR=(
    "vscodium-bin" "megasync"
    "catppuccin-cursors-mocha" "papirus-icon-theme" "catppuccin-gtk-theme-mocha"
)

FONTS=(
    "ttf-jetbrains-mono-nerd"
    "ttf-font-awesome" 
    "noto-fonts-emoji" "adwaita-icon-theme"
)

echo_msg() { echo -e "\n\033[1;34m🛡️ $1\033[0m"; }
echo_ok()  { echo -e "\033[1;32m✅ $1\033[0m"; }
echo_skip(){ echo -e "\033[1;33m⏭️  $1\033[0m"; }

# 🔧 FUNCIONES IDEMPOTENTES
check_file_content() {
    local file="$1" content="$2"
    [[ -f "$file" ]] && cmp -s <(echo "$content") "$file"
}

setup_sddm() {
    echo_msg "🌀 SDDM (tema $SDDM_THEME_NAME)..."

    # 1. Copiar TODO SDDM/ -> /usr/share/sddm/themes/netenebrae
    if [[ ! -d "$SDDM_THEME_SRC" ]]; then
        echo_skip "No existe carpeta: $SDDM_THEME_SRC"
        return
    fi

    sudo mkdir -p "$SDDM_THEME_DIR"

    # Siempre sobrescribir: borrar destino y copiar limpio
    if [[ -d "$SDDM_THEME_DST" ]]; then
        sudo rm -rf "$SDDM_THEME_DST"
    fi

    sudo cp -r "$SDDM_THEME_SRC" "$SDDM_THEME_DST"
    echo_ok "Tema sobrescrito en $SDDM_THEME_DST"

    # 2. Config mínima para usarlo
    sudo mkdir -p /etc/sddm.conf.d
    local sddm_conf="/etc/sddm.conf.d/theme.conf"
    local conf_content="[Theme]
Current=$SDDM_THEME_NAME
"

    if ! sudo bash -c "cmp -s <(echo \"$conf_content\") \"$sddm_conf\" 2>/dev/null"; then
        echo "$conf_content" | sudo tee "$sddm_conf" >/dev/null
        echo_ok "SDDM configurado con tema: $SDDM_THEME_NAME"
    else
        echo_skip "Config SDDM ya usa $SDDM_THEME_NAME"
    fi
}


write_if_needed() {
    local file="$1" content="$2"
    if ! check_file_content "$file" "$content"; then
        echo "$content" > "$file"
        echo_ok "Actualizado: $file"
    else
        echo_skip "Ya OK: $file"
    fi
}

dconf_write_if_needed() {
    local key="$1" value="$2"
    if [[ "$(dconf read "$key" 2>/dev/null || echo 'NULL')" != "$value" ]]; then
        dconf write "$key" "$value"
        echo_ok "dconf: $key"
    else
        echo_skip "dconf OK: $key"
    fi
}

install_paru() {
    command -v paru >/dev/null || {
        echo_msg "PARU..."
        git clone https://aur.archlinux.org/paru.git /tmp/paru
        cd /tmp/paru && makepkg -si --noconfirm && cd - && rm -rf /tmp/paru
        echo_ok "PARU OK"
    } || echo_skip "PARU OK"
}

setup_zsh() {
    echo_msg "ZSH+Starship..."
    
    if [[ "$SHELL" != "/usr/bin/zsh" && ! "$(grep "^$USER:.*:/usr/bin/zsh$" /etc/passwd)" ]]; then
        chsh -s /usr/bin/zsh
        echo_ok "ZSH configurado (reinicia)"
    else
        echo_skip "ZSH ya shell actual"
    fi
    
    if ! command -v starship >/dev/null 2>&1; then
        curl -sS https://starship.rs/install.sh | sh
        echo_ok "Starship instalado"
    else
        echo_skip "Starship OK"
    fi
    echo_ok "ZSH listo"
}

deploy_dotfiles() {
    echo_msg "🚀 Dotfiles COMPLETOS..."
    
    # 1. Clonar repo si no existe
    [ ! -d "$DOTFILES_DIR" ] && git clone "$DOTFILES_REPO" "$DOTFILES_DIR"
    
    # 2. Config Files + Home Files (NUEVO)
    deploy_custom_files
    
    # 3. Stow tradicional (opcional, si tienes paquetes individuales)
    cd "$DOTFILES_DIR" && stow -v bspwm polybar kitty rofi zsh dunst picom sxhkd 2>/dev/null || true
    
    echo_ok "🚀 Dotfiles 100% OK"
}

deploy_custom_files() {
    echo_msg "📁 Deploy Config Files + Home Files..."

    # CONFIG FILES -> ~/.config/ (elimina y copia todo)
    if [[ -d "$CONFIG_SRC" ]]; then
        echo_msg "→ Config Files..."
        mkdir -p "$HOME/.config"
        
        shopt -s dotglob nullglob
        for item in "$CONFIG_SRC"/*; do
            [[ ! -e "$item" ]] && continue
            name="$(basename "$item")"
            target="$HOME/.config/$name"
            
            if [[ -e "$target" ]]; then
                rm -rf "$target"
                echo_ok "🗑️  Eliminado: $name"
            fi
            
            cp -rf "$item" "$target"
            echo_ok "📥 Copiado: $name → ~/.config/"
        done
        shopt -u dotglob nullglob
    else
        echo_skip "No existe: $CONFIG_SRC"
    fi

    # HOME FILES -> $HOME/ (elimina y copia todo)
    if [[ -d "$HOME_SRC" ]]; then
        echo_msg "→ Home Files..."
        
        shopt -s dotglob nullglob
        for item in "$HOME_SRC"/*; do
            [[ ! -e "$item" ]] && continue
            name="$(basename "$item")"
            target="$HOME/$name"
            
            if [[ -e "$target" ]]; then
                rm -rf "$target"
                echo_ok "🗑️  Eliminado: $name"
            fi
            
            cp -rf "$item" "$target"
            echo_ok "📥 Copiado: $name → ~/"
        done
        shopt -u dotglob nullglob
    else
        echo_skip "No existe: $HOME_SRC"
    fi
    
    echo_ok "📁 Config Files + Home Files 100% sincronizados"
}



setup_fonts() {
    echo_msg "Fuentes..."
    sudo pacman -S --needed --noconfirm "${FONTS[@]}"
    fc-cache -fv
    echo_ok "Fuentes OK"
}

setup_themes() {
    echo_msg "🎨 Temas COMPLETOS (idempotente)..."
    
    # Instalar AUR themes
    paru -S --needed --noconfirm "${PKGS_AUR[@]}"

    # 1. XResources
    local xres_content="Xcursor.theme: $THEME_CURSOR_CLEAN
Xcursor.size: $CURSOR_SIZE_CLEAN"
    write_if_needed "$HOME/.Xresources" "$xres_content"
    xrdb -merge "$HOME/.Xresources" 2>/dev/null || true

    # 2. Default cursor universal
    mkdir -p "$HOME/.icons/default"
    local default_theme="[Icon Theme]
Inherits=$THEME_CURSOR_CLEAN"
    write_if_needed "$HOME/.icons/default/index.theme" "$default_theme"

    # 3. Variables entorno PERMANENTES
    mkdir -p "$HOME/.config/environment.d"
    local env_content="XCURSOR_THEME=$THEME_CURSOR_CLEAN
XCURSOR_SIZE=$CURSOR_SIZE_CLEAN
XCURSOR_PATH=$HOME/.icons:/usr/share/icons"
    write_if_needed "$HOME/.config/environment.d/cursor.conf" "$env_content"

    # 4. GTK 3/4 (SOLO UNA VEZ)
    mkdir -p "$HOME/.config/gtk-3.0" "$HOME/.config/gtk-4.0"
    
    local gtk3_content="[Settings]
gtk-theme-name=$THEME_GTK
gtk-icon-theme-name=$THEME_ICONS
gtk-cursor-theme-name=$THEME_CURSOR_CLEAN
gtk-cursor-theme-size=$CURSOR_SIZE_CLEAN
gtk-font-name=JetBrainsMono Nerd Font 11
gtk-application-prefer-dark-theme=true
gtk-xft-antialias=1
gtk-xft-hinting=1
gtk-xft-hintstyle=hintfull
gtk-xft-rgba=rgb"
    
    local gtk4_content="[Settings]
gtk-theme-name=$THEME_GTK
gtk-icon-theme-name=$THEME_ICONS
gtk-cursor-theme-name=$THEME_CURSOR_CLEAN
gtk-cursor-theme-size=$CURSOR_SIZE_CLEAN
gtk-font-name=JetBrainsMono Nerd Font 11"
    
    write_if_needed "$HOME/.config/gtk-3.0/settings.ini" "$gtk3_content"
    write_if_needed "$HOME/.config/gtk-4.0/settings.ini" "$gtk4_content"

    # 5. QT5ct (minimal)
    mkdir -p "$HOME/.config/qt5ct"
    local qt5_content="[Appearance]
theme=kvantum
[Fonts]
font=JetBrainsMono Nerd Font,11,-1,5,50,0,0,0,0,0"
    write_if_needed "$HOME/.config/qt5ct/qt5ct.conf" "$qt5_content"

    # 6. dconf GNOME/Cinnamon/MATE (idempotente)
    local themes=(gnome cinnamon mate)
    local dconf_paths=(
        "/org/gnome/desktop/interface/"
        "/org/cinnamon/desktop/interface/"
        "/org/mate/interface/"
    )
    
    for i in "${!themes[@]}"; do
        local de="${themes[$i]}"
        local path="${dconf_paths[$i]}"
        
        dconf_write_if_needed "${path}gtk-theme" "'$THEME_GTK'"
        dconf_write_if_needed "${path}icon-theme" "'$THEME_ICONS'"
        dconf_write_if_needed "${path}cursor-theme" "'$THEME_CURSOR'"
        dconf_write_if_needed "${path}gtk-key-theme" "'Default'"
    done

    # WM themes
    dconf_write_if_needed "/org/cinnamon/desktop/wm/preferences/theme" "'$THEME_WM'"
    dconf_write_if_needed "/org/cinnamon/desktop/wm/preferences/theme-backup" "'$THEME_WM'"
    dconf_write_if_needed "/org/gnome/desktop/wm/preferences/theme" "'$THEME_WM'"

    # Extras
    dconf_write_if_needed "/org/blueberry/use-symbolic-icons" "false"
    dconf_write_if_needed "/org/gnome/desktop/interface/color-scheme" "'prefer-dark'"

    # 7. LightDM (slick-greeter)
    sudo -u lightdm dbus-launch dconf write "/x/dm/slick-greeter/cursor-theme-name" "'$THEME_CURSOR'" 2>/dev/null || true
    sudo -u lightdm dbus-launch dconf write "/x/dm/slick-greeter/icon-theme-name" "'$THEME_ICONS'" 2>/dev/null || true
    sudo -u lightdm dbus-launch dconf write "/x/dm/slick-greeter/theme-name" "'$THEME_GTK'" 2>/dev/null || true

    echo_ok "🎨 Temas 100% OK"
}

# 🚀 EJECUCIÓN
[ "$EUID" -eq 0 ] && { echo "❌ No root"; exit 1; }

echo_msg "🚀 neBSPWN Setup $(date +'%H:%M')"
sudo pacman -Syu --noconfirm
sudo pacman -S --needed --noconfirm "${PKGS_PACMAN[@]}"

setup_sddm
setup_fonts
install_paru
setup_themes
setup_zsh
deploy_dotfiles

echo_ok "🎉 ¡LISTO! Reinicia: startx"
echo "🌿 Starship + BSPWM + Kitty | @NeTenebraes 💀"
