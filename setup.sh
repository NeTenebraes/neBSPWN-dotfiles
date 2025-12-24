#!/bin/bash

# neBSPWN Post-Install - DESTRUCTIVO & LIMPIO 💀
# Autor: NeTenebrae | @NeTenebraes
# Updated: Black Hole SDDM Integration

set -e

DOTFILES_REPO="https://github.com/NeTenebraes/neBSPWN-dotfiles.git"
DOTFILES_DIR="$HOME/.config/neBSPWN-dotfiles"

# Nota: CONFIG_SRC y HOME_SRC se definen dinámicamente en deploy_dotfiles

# Temas
THEME_GTK="catppuccin-mocha-lavender-standard+default"
THEME_ICONS="Papirus-Dark"
THEME_CURSOR="catppuccin-mocha-dark-cursors"
THEME_WM="catppuccin-mocha-lavender-standard+default"
CURSOR_SIZE="16"
FONT_NAME=""

# Limpiar comillas
THEME_CURSOR_CLEAN="${THEME_CURSOR//\'/}"
CURSOR_SIZE_CLEAN="${CURSOR_SIZE//\'/}"

PKGS_PACMAN_Essencials=(
    "git" "base-devel" "neovim" "wget" "curl" "unzip" "lsd" "sddm"
    "feh" "xorg" "xorg-xinit" "nemo" "xclip" "zsh" "tmux" "htop" "bat"
    "zsh-syntax-highlighting" "zsh-autosuggestions" "python" "python-pip"
    "nodejs" "npm" "ffmpeg" "maim" "qt5ct" "qt6ct" "starship" "blueberry"
    "glib2" "libxml2" "bspwm" "sxhkd" "polybar" "picom" "rofi" "dunst" "kitty"
    "ttf-jetbrains-mono-nerd" "ttf-font-awesome" "noto-fonts-emoji" "ttf-iosevka-nerd"
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
echo_ok() { echo -e "\033[1;32m✅ $1\033[0m"; }
echo_skip(){ echo -e "\033[1;33m⏭️ $1\033[0m"; }
echo_err() { echo -e "\033[0;31m❌ $1\033[0m" >&2; }

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
    
    # EXPORTA variable global para usar en otras funciones
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

# 🌀 Función SDDM Modularizada (Integrada)
setup_sddm() {
    echo_msg "🌀 Iniciando módulo SDDM (Astronaut - Black Hole)..."

    # Variables Locales
    local THEME_DEST_NAME="netenebrae"
    local THEMES_DIR="/usr/share/sddm/themes"
    local TARGET_DIR="$THEMES_DIR/$THEME_DEST_NAME"
    local METADATA="$TARGET_DIR/metadata.desktop"
    local CLONE_DIR="${NE_TMP_REPO:-/tmp/neBSPWN-dotfiles}"
    local DATE=$(date +%s)

    # 1. Dependencias SDDM (Aseguramos que estén, aunque setup_dependencies ya instala sddm)
    # Qt6 es vital para este tema específico
    echo_msg "📦 Verificando dependencias Qt6 para SDDM..."
    sudo pacman -S --needed --noconfirm sddm qt6-svg qt6-virtualkeyboard qt6-multimedia-ffmpeg qt6-declarative 2>/dev/null || echo_skip "Deps ya instaladas"

    # 2. Localizar archivos en el repo clonado
    local source_path=""
    
    if [[ -f "$CLONE_DIR/SDDM/metadata.desktop" ]]; then
        source_path="$CLONE_DIR/SDDM"
    elif [[ -f "$CLONE_DIR/repo/SDDM/metadata.desktop" ]]; then
        source_path="$CLONE_DIR/repo/SDDM"
    else
        local found=$(find "$CLONE_DIR" -type f -name "metadata.desktop" | grep "SDDM" | head -n 1)
        if [[ -n "$found" ]]; then
            source_path=$(dirname "$found")
        else
            echo_err "❌ No se encontró la carpeta del tema SDDM en $CLONE_DIR"
            return 1
        fi
    fi

    echo_ok "Fuente encontrada: $source_path"

    # 3. Instalación Limpia
    if [[ -d "$TARGET_DIR" ]]; then
        echo_msg "♻️  Removiendo tema anterior..."
        sudo rm -fr "$TARGET_DIR"
    fi
    
    sudo mkdir -p "$TARGET_DIR"
    echo_msg "📂 Copiando archivos a $TARGET_DIR..."
    sudo cp -r "$source_path"/* "$TARGET_DIR"/

    # Fuentes
    if [[ -d "$TARGET_DIR/Fonts" ]]; then
        echo_msg "🅰️  Instalando fuentes..."
        sudo cp -r "$TARGET_DIR/Fonts"/* /usr/share/fonts/
        fc-cache -f
    fi

    # Configuración Base SDDM
    sudo mkdir -p /etc/sddm.conf.d
    echo "[Theme]
Current=$THEME_DEST_NAME" | sudo tee /etc/sddm.conf >/dev/null

    echo "[General]
InputMethod=qtvirtualkeyboard" | sudo tee /etc/sddm.conf.d/virtualkbd.conf >/dev/null

    # 4. Configurar Black Hole (Core Logic)
    if [[ ! -f "$METADATA" ]]; then
        echo_err "❌ Error crítico: metadata.desktop no encontrado tras copia."
        return 1
    fi
    
    echo_msg "⚫ Configurando variante: Black Hole"
    # Forzamos la configuración
    sudo sed -i "s|^ConfigFile=.*|ConfigFile=Themes/netenebrae.conf|" "$METADATA"
    
    # 5. Parche QML de compatibilidad (Heredado de tu script anterior por seguridad)
    local qml_file="$TARGET_DIR/Main.qml"
    if [[ -f "$qml_file" ]]; then
        # Solo aplicamos si detectamos que faltan versiones (seguro simple)
        if ! grep -q "QtQuick 2.15" "$qml_file"; then
             echo_msg "💉 Parcheando imports QML..."
             sudo sed -i 's/^import QtQuick$/import QtQuick 2.15/' "$qml_file"
             sudo sed -i 's/^import QtQuick.Layouts$/import QtQuick.Layouts 1.15/' "$qml_file"
             sudo sed -i 's/^import QtQuick.Controls$/import QtQuick.Controls 2.15/' "$qml_file"
        fi
    fi

    # 6. Habilitar Servicio
    if ! systemctl is-enabled sddm &>/dev/null; then
        echo_msg "🔌 Habilitando servicio SDDM..."
        sudo systemctl enable sddm
    fi

    echo_ok "✅ SDDM Listo (Variante Black Hole)"
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
echo_msg "   Integración SDDM Black Hole Edition"

sudo pacman -Syu --noconfirm

setup_dependecies
setup_themes
setup_zsh
deploy_dotfiles

# Ejecutamos la nueva función integrada
setup_sddm

# Limpieza final
rm -rf "$NE_TMP_REPO"

echo_ok "🎉 ¡LISTO! Reinicia: systemctl reboot"
