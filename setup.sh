#!/bin/bash

# Autor: NeTenebrae | @NeTenebraes
# Updated: Black Hole SDDM Integration

set -e

DOTFILES_REPO="https://github.com/NeTenebraes/neBSPWN-dotfiles.git"
DOTFILES_DIR="$HOME/.config/neBSPWN-dotfiles"
# Nota: CONFIG_SRC y HOME_SRC se definen dinámicamente en deploy_dotfiles

# Temas
THEME_DEFAULT="catppuccin-mocha-mauve-standard+default"
THEME_CURSOR="catppuccin-mocha-dark-cursors"
THEME_ICONS="Papirus-Dark"
CURSOR_SIZE="16"
THEME_FONT="JetBrainsMono Nerd Font 11"

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
    "kvantum" "kvantum-qt5" "xdg-desktop-portal" "xdg-desktop-portal-gtk" "qt5ct" "qt6ct"
)

PKGS_PACMAN_optionals=(
    "firefox" "vlc" "obsidian"
)

PKGS_AUR=(
    "catppuccin-cursors-mocha" "papirus-icon-theme" "catppuccin-gtk-theme-mocha"
)

PKGS_AUR_Optionals=(
    "vscodium-bin" "megasync"
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
    # 1. PARU (Obligatorio - Si no existe se compila)
    command -v paru >/dev/null || {
        echo_msg "Instalando PARU..."
        # URL FIX
        git clone https://aur.archlinux.org/paru.git /tmp/paru
        cd /tmp/paru && makepkg -si --noconfirm && cd - && rm -rf /tmp/paru
        echo_ok "PARU Instalado"
    } || echo_skip "PARU ya estaba instalado"

    # 2. Dependencias Esenciales Pacman (Obligatorio)
    echo_msg "📦 Instalando dependencias esenciales (Pacman)..."
    sudo pacman -S --needed --noconfirm "${PKGS_PACMAN_Essencials[@]}"

    # 3. Dependencias Opcionales Pacman (Interactivo)
    echo -e "\n¿Deseas instalar las dependencias opcionales de Pacman? (y/N)"
    echo -e "   (Incluye: ${PKGS_PACMAN_optionals[*]})"
    read -r -p " > " response_pacman
    if [[ "$response_pacman" =~ ^([yY][eE][sS]|[yY])$ ]]; then
        echo_msg "📦 Instalando opcionales (Pacman)..."
        sudo pacman -S --needed --noconfirm "${PKGS_PACMAN_optionals[@]}"
        echo_ok "Opcionales Pacman instaladas"
    else
        echo_skip "Saltando opcionales Pacman"
    fi

    # 4. Paquetes AUR Esenciales (Obligatorio)
    echo_msg "📦 Instalando paquetes AUR esenciales..."
    paru -S --needed --noconfirm "${PKGS_AUR[@]}"

    # 5. Paquetes AUR Opcionales (Interactivo - NUEVO)
    echo -e "\n¿Deseas instalar las dependencias opcionales de AUR? (y/N)"
    echo -e "   (Incluye: ${PKGS_AUR_Optionals[*]})"
    read -r -p " > " response_aur
    if [[ "$response_aur" =~ ^([yY][eE][sS]|[yY])$ ]]; then
        echo_msg "📦 Instalando opcionales (AUR)..."
        paru -S --needed --noconfirm "${PKGS_AUR_Optionals[@]}"
        echo_ok "Opcionales AUR instaladas"
    else
        echo_skip "Saltando opcionales AUR"
    fi

    # 6. Cache de fuentes
    fc-cache -fv

    # 7. Clonado del Repo
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
    echo_msg "🎨 Temas COMPLETOS..."
    
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

    # GTK 3/4 (CORREGIDO: Faltaban el signo = y el valor correcto)
    mkdir -p "$HOME/.config/gtk-3.0" "$HOME/.config/gtk-4.0"
    
    local gtk3_content="[Settings]
gtk-theme-name=$THEME_DEFAULT
gtk-icon-theme-name=$THEME_ICONS
gtk-cursor-theme-name=$THEME_CURSOR_CLEAN
gtk-cursor-theme-size=$CURSOR_SIZE_CLEAN
gtk-font-name=$THEME_FONT
gtk-application-prefer-dark-theme=true
gtk-xft-antialias=1
gtk-xft-hinting=1
gtk-xft-hintstyle=hintfull
gtk-xft-rgba=rgb"

    local gtk4_content="[Settings]
gtk-theme-name=$THEME_DEFAULT
gtk-icon-theme-name=$THEME_ICONS
gtk-cursor-theme-name=$THEME_CURSOR_CLEAN
gtk-cursor-theme-size=$CURSOR_SIZE_CLEAN
gtk-font-name=$THEME_FONT"

    write_if_needed "$HOME/.config/gtk-3.0/settings.ini" "$gtk3_content"
    write_if_needed "$HOME/.config/gtk-4.0/settings.ini" "$gtk4_content"

    # dconf GNOME/Cinnamon/MATE (CORREGIDO: Comillas GVariant)
    local themes=(gnome cinnamon mate)
    local dconf_paths=(
        "/org/gnome/desktop/interface/"
        "/org/cinnamon/desktop/interface/"
        "/org/mate/interface/"
    )

    for i in "${!themes[@]}"; do
        local de="${themes[$i]}"
        local path="${dconf_paths[$i]}"
        
        # GVariant requiere que las cadenas estén entre comillas simples DENTRO de las dobles
        # EJEMPLO CORRECTO: "'valor'"
        
        dconf_write_if_needed "${path}gtk-theme" "'$THEME_DEFAULT'"
        dconf_write_if_needed "${path}icon-theme" "'$THEME_ICONS'"
        dconf_write_if_needed "${path}cursor-theme" "'$THEME_CURSOR'"
        dconf_write_if_needed "${path}gtk-key-theme" "'Default'"
    done

    # WM themes (CORREGIDO)
    dconf_write_if_needed "/org/cinnamon/desktop/wm/preferences/theme" "'$THEME_DEFAULT'"
    dconf_write_if_needed "/org/cinnamon/desktop/wm/preferences/theme-backup" "'$THEME_DEFAULT'"
    dconf_write_if_needed "/org/gnome/desktop/wm/preferences/theme" "'$THEME_DEFAULT'"

    # Extras
    dconf_write_if_needed "/org/blueberry/use-symbolic-icons" "false"
    dconf_write_if_needed "/org/gnome/desktop/interface/color-scheme" "'prefer-dark'"

    # LightDM (slick-greeter) (CORREGIDO)
    sudo -u lightdm dbus-launch dconf write "/x/dm/slick-greeter/cursor-theme-name" "'$THEME_CURSOR'" 2>/dev/null || true
    sudo -u lightdm dbus-launch dconf write "/x/dm/slick-greeter/icon-theme-name" "'$THEME_ICONS'" 2>/dev/null || true
    sudo -u lightdm dbus-launch dconf write "/x/dm/slick-greeter/theme-name" "'$THEME_DEFAULT'" 2>/dev/null || true

    # Iconos Rojos (Papirus)
    wget -qO- https://git.io/papirus-folders-install | sh
    papirus-folders -C red --theme Papirus-Dark

    echo_ok "🎨 Temas 100% OK"
}

setup_dns() {
    echo_msg "🌐 CONFIGURACIÓN DNS"
    echo -e "\nSelecciona tu proveedor DNS preferido:"
    echo "  1) Cloudflare (1.1.1.1) - [Recomendado: Velocidad/Privacidad]"
    echo "  2) Quad9      (9.9.9.9) - [Bloqueo de Malware]"
    echo "  3) Google     (8.8.8.8) - [Estándar]"
    echo "  4) Automático (ISP)     - [Por defecto de tu proveedor]"
    echo "  5) Saltar configuración"
    
    read -r -p " > " dns_choice

    local target_ips=""
    local provider_name=""

    case "$dns_choice" in
        1) target_ips="1.1.1.1 1.0.0.1"; provider_name="Cloudflare" ;;
        2) target_ips="9.9.9.9 149.112.112.112"; provider_name="Quad9" ;;
        3) target_ips="8.8.8.8 8.8.4.4"; provider_name="Google" ;;
        4) target_ips="auto"; provider_name="ISP (Auto)" ;;
        *) echo_skip "Saltando configuración DNS"; return 0 ;;
    esac

    # Detectar conexión
    if ! command -v nmcli >/dev/null; then
        echo_err "NetworkManager no encontrado."
        return 1
    fi

    local active_conn
    active_conn=$(nmcli -t -f NAME connection show --active | head -n1)

    if [[ -z "$active_conn" ]]; then
        echo_skip "No hay conexión activa. Conéctate a internet primero."
        return 0
    fi

    echo_msg "Aplicando $provider_name en conexión: '$active_conn'..."

    # Aplicar cambios
    if [[ "$target_ips" == "auto" ]]; then
        nmcli con mod "$active_conn" ipv4.ignore-auto-dns no
        nmcli con mod "$active_conn" ipv4.dns ""
    else
        nmcli con mod "$active_conn" ipv4.ignore-auto-dns yes
        nmcli con mod "$active_conn" ipv4.dns "$target_ips"
    fi

    # Fix para /etc/resolv.conf en Arch
    if [[ -L "/etc/resolv.conf" ]]; then
        sudo rm -f /etc/resolv.conf
        sudo systemctl restart NetworkManager
        sleep 2
        echo_ok "Enlace resolv.conf corregido."
    else
        nmcli con up "$active_conn" >/dev/null 2>&1
    fi
    
    echo_ok "DNS configurado exitosamente: $provider_name"
}

# 🌀 Función SDDM Modularizada (Integrada)
setup_sddm() {
    echo_msg "🌀 Iniciando módulo SDDM..."

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

    echo_ok "✅ SDDM Listo"
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
    echo_msg "🚀 Deploy dotfiles DESTRUCTIVO..."
    local tmp_repo="${NE_TMP_REPO:-/tmp/neBSPWN-dotfiles}"
    local config_src="$tmp_repo/Config Files"
    local home_src="$tmp_repo/Home files"

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

setup_qt() {
    echo_msg "🎨 Configurando entorno Qt (BSPWM + Wayland/X11 Hybrid)..."

    # 2. Configurar Variables de Entorno en BSPWM
    # Inyectamos configuración robusta al inicio de bspwmrc para asegurar que carguen antes que las apps
    local bspwm_config="$HOME/.config/bspwm/bspwmrc"
    
    # Creamos el archivo si no existe (raro si ya corriste deploy_dotfiles, pero preventivo)
    if [[ ! -f "$bspwm_config" ]]; then
        mkdir -p "$(dirname "$bspwm_config")"
        touch "$bspwm_config"
        echo "#!/bin/sh" > "$bspwm_config"
        chmod +x "$bspwm_config"
    fi

    # Lógica de inyección inteligente (Idempotente)
    # Solo añadimos si NO detectamos la configuración específica
    if ! grep -q "QT_STYLE_OVERRIDE=kvantum" "$bspwm_config"; then
        echo_msg "🔧 Inyectando variables Qt en bspwmrc..."
        
        local temp_bspwm=$(mktemp)
        
        # Mantener shebang
        head -n 1 "$bspwm_config" > "$temp_bspwm"
        
        # Bloque de configuración Qt
        cat <<EOF >> "$temp_bspwm"

# --- QT/THEME FIX (Auto-generated by neBSPWN) ---
# Fuerza XCB para evitar bordes rotos en BSPWM y Kvantum para unificar temas
export QT_QPA_PLATFORM=xcb
export QT_STYLE_OVERRIDE=kvantum
export QT_QPA_PLATFORMTHEME=qt5ct
# Iniciar Portals necesarios para Qt6
(sleep 1; /usr/lib/xdg-desktop-portal &)
(sleep 1; /usr/lib/xdg-desktop-portal-gtk &)
# ------------------------------------------------
EOF
        
        # Añadir resto del archivo original (saltando shebang)
        tail -n +2 "$bspwm_config" >> "$temp_bspwm"
        
        # Reemplazar atómicamente
        cat "$temp_bspwm" > "$bspwm_config"
        rm "$temp_bspwm"
        
        echo_ok "Variables inyectadas en bspwmrc"
    else
        echo_skip "Variables Qt ya presentes en bspwmrc"
    fi

    # 3. Configurar Kvantum (Tema Oscuro por defecto)
    # Evita tener que abrir kvantummanager manualmente
    local kvantum_config_dir="$HOME/.config/Kvantum"
    local kvantum_config_file="$kvantum_config_dir/kvantum.kvconfig"
    
    if [[ ! -f "$kvantum_config_file" ]]; then
        echo_msg "🌑 Configurando tema Kvantum por defecto (KvArcDark)..."
        mkdir -p "$kvantum_config_dir"
        
        # Configuración mínima válida para Kvantum
        cat <<EOF > "$kvantum_config_file"
[General]
theme=KvArcDark

[Applications]
keepassxc=KvArcDark
EOF
        echo_ok "Kvantum configurado con KvArcDark"
    else
        echo_skip "Configuración Kvantum ya existe"
    fi

    # 4. Iniciar servicios de Portal (Run-time fix para la sesión actual)
    if ! pgrep -f "xdg-desktop-portal" >/dev/null; then
        echo_msg "🔌 Iniciando Portals (Sesión actual)..."
        /usr/lib/xdg-desktop-portal & disown
        /usr/lib/xdg-desktop-portal-gtk & disown
    fi

    echo_ok "✅ Entorno Qt completado"
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
setup_qt
setup_sddm
setup_dns

# Limpieza final
rm -rf "$NE_TMP_REPO"

echo_ok "🎉 ¡LISTO! Reinicia: systemctl reboot"
