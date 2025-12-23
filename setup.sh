#!/bin/bash
# neBSPWN Post-Install - DESTRUCTIVO & LIMPIO 💀
# Autor: NeTenebrae | @NeTenebraes

set -e

DOTFILES_REPO="https://github.com/NeTenebraes/neBSPWN-dotfiles.git"
DOTFILES_DIR="$HOME/.config/neBSPWN-dotfiles"
# Nota: CONFIG_SRC y HOME_SRC se definen dinámicamente en deploy_dotfiles

# Temas (cambia aquí)
THEME_GTK="catppuccin-mocha-lavender-standard+default"
THEME_ICONS="Papirus-Dark"
THEME_CURSOR="catppuccin-mocha-dark-cursors"
THEME_WM="catppuccin-mocha-lavender-standard+default"
CURSOR_SIZE="16"
FONT_NAME=""

SDDM_THEME_NAME="netenebrae"
SDDM_THEME_DIR="/usr/share/sddm/themes"
SDDM_THEME_DST="$SDDM_THEME_DIR/$SDDM_THEME_NAME"
SDDM_Wall="$HOME/.config/bspwm/lightdm.jpg"

# Limpiar comillas
THEME_CURSOR_CLEAN="${THEME_CURSOR//\'/}"
CURSOR_SIZE_CLEAN="${CURSOR_SIZE//\'/}"

PKGS_PACMAN_Essencials=(
    "git" "base-devel" "neovim" "wget" "curl" "unzip" "lsd" "sddm" 
    "feh" "xorg" "xorg-xinit" "nemo" "xclip" "zsh" "tmux" "htop" "bat" 
    "zsh-syntax-highlighting" "zsh-autosuggestions" "python" "python-pip" 
    "nodejs" "npm" "ffmpeg" "maim" "qt5ct" "starship" "blueberry" 
    "glib2" "libxml2" "bspwm" "sxhkd" "polybar" "picom" "rofi" "dunst" "kitty"
    "ttf-jetbrains-mono-nerd" "ttf-font-awesome" "noto-fonts-emoji" 
    "adwaita-icon-theme"
)

PKGS_PACMAN_optionals=(
    "firefox" "vlc" "obsidian"   
)

PKGS_AUR=(
    "vscodium-bin" "megasync"
    "catppuccin-cursors-mocha" "papirus-icon-theme" "catppuccin-gtk-theme-mocha"
)

echo_msg() { echo -e "\n\033[1;34m🛡️ $1\033[0m"; }
echo_ok()  { echo -e "\033[1;32m✅ $1\033[0m"; }
echo_skip(){ echo -e "\033[1;33m⏭️  $1\033[0m"; }

# Funciones Helper
check_file_content() {
    local file="$1" content="$2"
    [[ -f "$file" ]] && cmp -s <(echo "$content") "$file"
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

setup_dependecies() {
    command -v paru >/dev/null || {
        echo_msg "PARU..."
        # URL FIX
        git clone https://aur.archlinux.org/paru.git /tmp/paru
        cd /tmp/paru && makepkg -si --noconfirm && cd - && rm -rf /tmp/paru
        echo_ok "PARU OK"
    } || echo_skip "PARU OK"

    sudo pacman -S --needed --noconfirm "${PKGS_PACMAN_Essencials[@]}"
    sudo pacman -S --needed --noconfirm "${PKGS_PACMAN_optionals[@]}"
    paru -S --needed "${PKGS_AUR[@]}"
    fc-cache -fv
    
    # 🔥 CLONE ÚNICO AQUÍ
    echo_msg "📥 CLONANDO REPO DOTFILES..."
    local tmp_repo="/tmp/neBSPWN-dotfiles"
    [[ -d "$tmp_repo" ]] && rm -rf "$tmp_repo"
    git clone "$DOTFILES_REPO" "$tmp_repo"
    echo_ok "✅ Repo clonado → $tmp_repo"
    
    # EXPORTA variable global
    export NE_TMP_REPO="$tmp_repo"
    echo_ok "Fuentes + Repo OK"
}

setup_themes() {
    echo_msg "🎨 Temas COMPLETOS (idempotente)..."
    
    local xres_content="Xcursor.theme: $THEME_CURSOR_CLEAN
Xcursor.size: $CURSOR_SIZE_CLEAN"
    write_if_needed "$HOME/.Xresources" "$xres_content"
    xrdb -merge "$HOME/.Xresources" 2>/dev/null || true

    # Default cursor universal
    mkdir -p "$HOME/.icons/default"
    local default_theme="[Icon Theme]
Inherits=$THEME_CURSOR_CLEAN"
    write_if_needed "$HOME/.icons/default/index.theme" "$default_theme"

    # Variables entorno PERMANENTES
    mkdir -p "$HOME/.config/environment.d"
    local env_content="XCURSOR_THEME=$THEME_CURSOR_CLEAN
XCURSOR_SIZE=$CURSOR_SIZE_CLEAN
XCURSOR_PATH=$HOME/.icons:/usr/share/icons"
    write_if_needed "$HOME/.config/environment.d/cursor.conf" "$env_content"

    # GTK 3/4
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

    # dconf GNOME/Cinnamon/MATE
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

    # LightDM (slick-greeter)
    sudo -u lightdm dbus-launch dconf write "/x/dm/slick-greeter/cursor-theme-name" "'$THEME_CURSOR'" 2>/dev/null || true
    sudo -u lightdm dbus-launch dconf write "/x/dm/slick-greeter/icon-theme-name" "'$THEME_ICONS'" 2>/dev/null || true
    sudo -u lightdm dbus-launch dconf write "/x/dm/slick-greeter/theme-name" "'$THEME_GTK'" 2>/dev/null || true

    echo_ok "🎨 Temas 100% OK"
}

setup_sddm() {
    echo_msg "🌀 SDDM (tema $SDDM_THEME_NAME)..."

    local tmp_repo="${NE_TMP_REPO:-/tmp/neBSPWN-dotfiles}"
    local sddm_src="$tmp_repo/SDDM"
    local sddm_dst="/usr/share/sddm/themes/$SDDM_THEME_NAME"
    local sddm_conf_dir="/etc/sddm.conf.d"

    # 1. Validación
    if [[ ! -d "$sddm_src" ]]; then
        echo_skip "❌ No existe carpeta SDDM en repo ($sddm_src)"
        return 1
    fi

    # 2. Dependencias (Vitales para este tema)
    echo_msg "📦 Verificando dependencias SDDM..."
    sudo pacman -S --needed --noconfirm sddm qt6-svg qt6-virtualkeyboard qt6-multimedia-ffmpeg qt6-declarative
    
    # 3. Instalación Limpia
    if [[ -d "$sddm_dst" ]]; then
        echo_msg "💣 Borrando tema anterior..."
        sudo rm -rf "$sddm_dst"
    fi
    sudo mkdir -p "$sddm_dst"

    echo_msg "📂 Instalando archivos..."
    sudo cp -r "$sddm_src"/* "$sddm_dst/"
    
    # 4. Configuración de Variante (MEJORADO)
    # En lugar de mover archivos, buscamos el config correcto y apuntamos el metadata ahí.
    local theme_config="Themes/netenebrae.conf" # Tu config ideal
    
    # Si no existe tu config, busca cualquiera disponible en Themes/
    if [[ ! -f "$sddm_dst/$theme_config" ]]; then
        local found_conf=$(find "$sddm_dst/Themes" -name "*.conf" -type f -printf "%f\n" 2>/dev/null | head -n 1)
        if [[ -n "$found_conf" ]]; then
            theme_config="Themes/$found_conf"
            echo_msg "⚠️ Config 'netenebrae.conf' no encontrada, usando '$found_conf'"
        else
             # Si no hay carpeta Themes, asumimos theme.conf en raíz (estructura antigua)
             theme_config="theme.conf"
        fi
    fi

    # Parchear metadata.desktop para usar esa variante
    local meta_file="$sddm_dst/metadata.desktop"
    if [[ -f "$meta_file" ]]; then
        sudo sed -i "s|^ConfigFile=.*|ConfigFile=$theme_config|" "$meta_file"
        echo_ok "✅ Metadata configurado: ConfigFile=$theme_config"
    fi

    # 5. Parche QML (El de siempre)
    echo_msg "💉 Parcheando versiones en Main.qml..."
    local qml_file="$sddm_dst/Main.qml"
    if [[ -f "$qml_file" ]]; then
        sudo sed -i 's/^import QtQuick$/import QtQuick 2.15/' "$qml_file"
        sudo sed -i 's/^import QtQuick.Layouts$/import QtQuick.Layouts 1.15/' "$qml_file"
        sudo sed -i 's/^import QtQuick.Controls$/import QtQuick.Controls 2.15/' "$qml_file"
        sudo sed -i 's/^import QtGraphicalEffects$/import QtGraphicalEffects 1.15/' "$qml_file"
        sudo sed -i 's/^import QtMultimedia$/import QtMultimedia 5.15/' "$qml_file"
        echo_ok "✅ QML parcheado"
    fi

    # 6. Permisos y Config Sistema
    sudo chown -R root:root "$sddm_dst"

    echo_msg "⚙️  Configurando /etc/sddm.conf..."
    sudo mkdir -p "$sddm_conf_dir"
    echo "[Theme]
Current=$SDDM_THEME_NAME" | sudo tee "$sddm_conf_dir/theme.conf" >/dev/null

    echo "[General]
InputMethod=qtvirtualkeyboard" | sudo tee "$sddm_conf_dir/virtualkbd.conf" >/dev/null

    # 7. Fuentes
    if [[ -d "$sddm_dst/Fonts" ]]; then
        echo_msg "🅰️  Instalando fuentes..."
        sudo cp -r "$sddm_dst/Fonts"/* /usr/share/fonts/ 2>/dev/null || true
        fc-cache -f
    fi

    if ! systemctl is-enabled sddm &>/dev/null; then
        echo_msg "🔌 Habilitando servicio SDDM..."
        sudo systemctl enable sddm
    fi

    echo_ok "✅ SDDM Listo (Variante: $theme_config)"
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
        # URL FIX
        curl -sS https://starship.rs/install.sh | sh
        echo_ok "Starship instalado"
    else
        echo_skip "Starship OK"
    fi
    echo_ok "ZSH listo"
}

deploy_dotfiles() {
    echo_msg "🚀 Deploy dotfiles DESTRUCTIVO..."
    
    local tmp_repo="${NE_TMP_REPO:-/tmp/neBSPWN-dotfiles}"
    local config_src="$tmp_repo/Config Files"
    local home_src="$tmp_repo/Home files"
    
    # CONFIG FILES -> ~/.config/ (BORRA Y REEMPLAZA)
    if [[ -d "$config_src" ]]; then
        echo_msg "📁 Config Files → ~/.config/"
        mkdir -p "$HOME/.config"
        
        shopt -s dotglob nullglob
        for item in "$config_src"/*; do
            [[ ! -e "$item" ]] && continue
            local name="$(basename "$item")"
            local target="$HOME/.config/$name"
            
            if [[ -e "$target" ]]; then
                # 💥 DESTRUCTIVO
                rm -rf "$target"
                echo_msg "🔥 Borrado: $name"
            fi
            
            cp -rf "$item" "$target"
            echo_ok "📥 Instalado: $name"
        done
        shopt -u dotglob nullglob
    fi
    
    # HOME FILES -> ~/ (BORRA Y REEMPLAZA)
    if [[ -d "$home_src" ]]; then
        echo_msg "🏠 Home Files → ~/"
        
        shopt -s dotglob nullglob
        for item in "$home_src"/*; do
            [[ ! -e "$item" ]] && continue
            local name="$(basename "$item")"
            local target="$HOME/$name"
            
            if [[ -e "$target" ]]; then
                # 💥 DESTRUCTIVO
                rm -rf "$target"
                echo_msg "🔥 Borrado: $name"
            fi
            
            cp -rf "$item" "$target"
            echo_ok "📥 Instalado: $name"
        done
        shopt -u dotglob nullglob
    fi
    
    echo_ok "🚀 Dotfiles 100% Sincronizados (Modo Dios)"
}

# 🚀 EJECUCIÓN
[ "$EUID" -eq 0 ] && { echo "❌ No root"; exit 1; }

echo_msg "🚀 neBSPWN Setup DESTRUCTIVO $(date +'%H:%M')"
sudo pacman -Syu --noconfirm

setup_dependecies
setup_themes
setup_zsh
deploy_dotfiles
setup_sddm

# Limpieza final del repo
rm -rf "$NE_TMP_REPO"

echo_ok "🎉 ¡LISTO! Reinicia: startx"
