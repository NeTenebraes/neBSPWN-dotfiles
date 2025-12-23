#!/bin/bash

## SDDM Astronaut Theme Installer (Custom Repo Edition)
## Source: NeTenebraes/neBSPWN-dotfiles
## Refactored for NeTenebrae - Forces Black Hole from custom path

set -euo pipefail

# Variables Actualizadas
readonly USER_REPO="https://github.com/NeTenebraes/neBSPWN-dotfiles.git"
readonly REPO_NAME="neBSPWN-dotfiles"
readonly THEME_DEST_NAME="sddm-astronaut-theme" # Nombre que espera SDDM en /usr/share/themes
readonly THEMES_DIR="/usr/share/sddm/themes"
readonly CLONE_DIR="$HOME/$REPO_NAME"
readonly TARGET_DIR="$THEMES_DIR/$THEME_DEST_NAME"
readonly METADATA="$TARGET_DIR/metadata.desktop"
readonly DATE=$(date +%s)

# Colores
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

info() { echo -e "${GREEN}[+] $1${NC}"; }
warn() { echo -e "${YELLOW}[!] $1${NC}"; }
error() { echo -e "${RED}[X] $1${NC}" >&2; }

# 1. Instalar Dependencias (Igual que antes)
install_deps() {
    info "Verificando dependencias..."
    local mgr=$(for m in pacman xbps-install dnf zypper apt; do command -v $m &>/dev/null && { echo $m; break; }; done)
    
    [[ -z "$mgr" ]] && { error "Gestor de paquetes no encontrado"; return 1; }

    case $mgr in
        pacman) sudo pacman --needed -S sddm qt6-svg qt6-virtualkeyboard qt6-multimedia-ffmpeg ;;
        xbps-install) sudo xbps-install -y sddm qt6-svg qt6-virtualkeyboard qt6-multimedia ;;
        dnf) sudo dnf install -y sddm qt6-qtsvg qt6-qtvirtualkeyboard qt6-qtmultimedia ;;
        zypper) sudo zypper install -y sddm libQt6Svg6 qt6-virtualkeyboard qt6-multimedia ;;
        apt) sudo apt update && sudo apt install -y sddm qt6-svg-dev qml6-module-qtquick-virtualkeyboard qt6-multimedia-dev ;;
    esac
    info "Dependencias OK."
}

# 2. Clonar TU repositorio de Dotfiles
clone_repo() {
    if [[ -d "$CLONE_DIR" ]]; then
        warn "Repo local detectado. Actualizando..."
        cd "$CLONE_DIR"
        git pull --force
        cd ..
    else
        info "Clonando $USER_REPO..."
        git clone --depth 1 "$USER_REPO" "$CLONE_DIR"
    fi
}

# 3. Instalar archivos desde la carpeta SDDM del repo
install_files() {
    # Buscamos la carpeta que contiene el tema dentro de tu repo
    # Probamos rutas comunes: raíz del repo/SDDM o raíz del repo/repo/SDDM
    local source_path=""
    
    if [[ -f "$CLONE_DIR/SDDM/metadata.desktop" ]]; then
        source_path="$CLONE_DIR/SDDM"
    elif [[ -f "$CLONE_DIR/repo/SDDM/metadata.desktop" ]]; then
        source_path="$CLONE_DIR/repo/SDDM"
    else
        # Búsqueda profunda si la estructura no es obvia
        local found=$(find "$CLONE_DIR" -type f -name "metadata.desktop" | grep "SDDM" | head -n 1)
        if [[ -n "$found" ]]; then
            source_path=$(dirname "$found")
        else
            error "No se encontró la carpeta del tema SDDM (metadata.desktop) dentro de $CLONE_DIR"
            return 1
        fi
    fi

    info "Fuente del tema encontrada en: $source_path"

    # Backup si ya existe el tema instalado en sistema
    if [[ -d "$TARGET_DIR" ]]; then
        warn "Backup de instalación anterior en /usr/share..."
        sudo mv "$TARGET_DIR" "${TARGET_DIR}_backup_$DATE"
    fi
    
    sudo mkdir -p "$TARGET_DIR"
    info "Instalando archivos en $TARGET_DIR..."
    sudo cp -r "$source_path"/* "$TARGET_DIR"/

    # Instalar fuentes si existen
    if [[ -d "$TARGET_DIR/Fonts" ]]; then
        info "Instalando fuentes..."
        sudo cp -r "$TARGET_DIR/Fonts"/* /usr/share/fonts/
    fi

    # Configurar sddm.conf
    echo "[Theme]
Current=$THEME_DEST_NAME" | sudo tee /etc/sddm.conf >/dev/null

    sudo mkdir -p /etc/sddm.conf.d
    echo "[General]
InputMethod=qtvirtualkeyboard" | sudo tee /etc/sddm.conf.d/virtualkbd.conf >/dev/null
}

# 4. Configurar Black Hole
configure_black_hole() {
    [[ ! -f "$METADATA" ]] && { error "metadata.desktop no encontrado tras la copia"; return 1; }
    
    info "Configurando variante: Black Hole"
    # Forzamos el config file
    sudo sed -i "s|^ConfigFile=.*|ConfigFile=Themes/black_hole.conf|" "$METADATA"
    
    info "Configuración aplicada."
}

# 5. Habilitar servicio
enable_sddm() {
    if command -v systemctl &>/dev/null; then
        info "Habilitando servicio sddm..."
        sudo systemctl disable display-manager.service 2>/dev/null || true
        sudo systemctl enable sddm.service
    else
        warn "systemctl no disponible (¿Usas runit/openrc?). Habilita sddm manualmente."
    fi
}

main() {
    [[ $EUID -eq 0 ]] && { error "Ejecuta como usuario normal (no root)."; exit 1; }
    
    echo "------------------------------------------------"
    echo "  SDDM Installer | NeBSPWN Dotfiles Edition     "
    echo "------------------------------------------------"
    
    install_deps
    clone_repo
    install_files
    configure_black_hole
    enable_sddm

    echo "------------------------------------------------"
    info "Instalación completada [web:1]."
    warn "Reinicia o prueba con: sddm-greeter-qt6 --test-mode --theme $TARGET_DIR"
    echo "------------------------------------------------"
}

main "$@"
