#!/bin/bash

# ==================== CONFIGURACIÓN CENTRALIZADA ====================
set -euo pipefail

# URLs y Recursos Críticos
CAIDO_GITHUB_API="https://api.github.com/repos/caido/caido/releases/latest"
CAIDO_BASE_URL="https://caido.download/releases"
CAIDO_ICON_URL="https://cdn.brandfetch.io/idFdZwH_n_/w/500/h/500/theme/dark/logo.png?c=1bxid64Mup7aczewSAYMX&t=1764981790594"
AUR_REPO="https://aur.archlinux.org/paru-bin.git"

# Paquetes por Categoría
PKGS_VIRTUALBOX=("virtualbox" "virtualbox-host-dkms")
PKGS_VMWARE=("fuse2" "dkms" "libcanberra" "gtkmm3" "gst-plugins-base-libs" "pcsclite")
AUR_VMWARE=("vmware-keymaps" "vmware-workstation")

# Detectar usuario real
REALUSER="${SUDO_USER:-${USER}}"
if [[ $EUID -eq 0 ]]; then
    REALUSER="$(logname 2>/dev/null || whoami)"
fi
USERHOME="$(getent passwd "$REALUSER" | cut -d: -f6)"

# Colores
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; NC='\033[0m'
log_ok() { echo -e "${GREEN}[OK]${NC} $1"; }
log_msg() { echo -e "${YELLOW}[MSG]${NC} $1"; }
log_err() { echo -e "${RED}[ERR]${NC} $1" >&2; }

# Detectar kernel y headers
detect_kernel_headers() {
    local KERNEL=$(uname -r | sed 's/\([0-9]\+\.[0-9]\+\.[0-9]\+\)-\(.*\)/\2/')
    case "$KERNEL" in
        *-hardened*) echo "linux-hardened-headers" ;;
        *-zen*)      echo "linux-zen-headers" ;;
        *-lts*)      echo "linux-lts-headers" ;;
        *)           echo "linux-headers" ;;
    esac
}

KERNEL_HEADERS=$(detect_kernel_headers)
log_msg "Kernel detectado: $(uname -r) → Usando: $KERNEL_HEADERS"

check_cmd() { command -v "$1" &>/dev/null; }

# ==================== INSTALADORES (REFACTORIZADOS) ====================
install_aur_helper() {
    if check_cmd paru; then
        log_ok "paru ✅ YA INSTALADO (preferido)"
        echo "paru"
        return 0
    elif check_cmd yay; then
        log_ok "yay ✅ YA INSTALADO (alternativa)"
        echo "yay"
        return 0
    fi
    log_msg "Instalando paru..."
    cd /tmp || exit 1
    git clone "$AUR_REPO"
    cd paru-bin && makepkg -si --noconfirm
    cd - &>/dev/null
    log_ok "paru instalado"
    echo "paru"
}

# NUEVA: aur_install() → EJECUTA
aur_install() {
    local AUR_HELPER=$(install_aur_helper)
    log_msg "Instalando con $AUR_HELPER: $@"
    $AUR_HELPER -S --noconfirm "$@"
}

# VMware FIXEADO
install_vmware() {
    local TITLE="VMware Workstation"
    if check_cmd vmware; then
        log_ok "$TITLE YA INSTALADO"
        return 0
    fi
    log_msg "PREPARANDO $TITLE para kernel hardened..."
    install_aur_helper
    local PKGS_VMWARE_EXT=("${PKGS_VMWARE[@]}" "$KERNEL_HEADERS")
    sudo pacman -S --noconfirm --needed "${PKGS_VMWARE_EXT[@]}"
    aur_install "${AUR_VMWARE[@]}"
    sudo systemctl enable vmware-networks.service vmware-usbarbitrator.service
    sudo vmware-modconfig --console --install-all || true
    log_ok "$TITLE OK. Ejecuta 'vmware' para setup inicial"
}


# VirtualBox con paquetes variables
install_virtualbox() {
    local TITLE="VirtualBox"
    
    if check_cmd virtualbox && lsmod | grep -q vboxdrv && ip link show vboxnet0 &>/dev/null; then
        log_ok "$TITLE + RED ✅ YA FUNCIONANDO"
        return 0
    fi
    
    # Instala paquetes VirtualBox + headers
    local PKGS=("${PKGS_VIRTUALBOX[@]}" "$KERNEL_HEADERS")
    log_msg "Instalando: ${PKGS[*]}"
    
    if ! check_cmd virtualbox; then
        sudo pacman -S --needed --noconfirm "${PKGS[@]}"
    else
        sudo pacman -S --noconfirm virtualbox-host-dkms "$KERNEL_HEADERS"
    fi
    
    sudo dkms autoinstall --force
    sudo modprobe -r vboxnetadp vboxnetflt vboxdrv 2>/dev/null || true
    sudo modprobe vboxdrv vboxnetflt vboxnetadp
    sudo VBoxManage hostonlyif create 2>/dev/null || true
    sudo usermod -aG vboxusers "$REALUSER"
    create_vbox_service
    
    log_ok "$TITLE ✅ LISTO + AUTO-START"
}

create_vbox_service() {
    local SERVICE_FILE="/etc/systemd/system/vbox-modules.service"
    sudo systemctl stop vbox-modules.service 2>/dev/null || true
    sudo rm -f "$SERVICE_FILE"
    
    sudo tee "$SERVICE_FILE" > /dev/null << 'EOF'
[Unit]
Description=VirtualBox Kernel Modules
Before=graphical-session.target
After=network.target

[Service]
Type=oneshot
RemainAfterExit=yes
ExecStartPre=/usr/bin/dkms autoinstall --force
ExecStart=/usr/bin/modprobe vboxdrv vboxnetflt vboxnetadp
ExecStop=/usr/bin/modprobe -r vboxnetadp vboxnetflt vboxdrv
TimeoutSec=30

[Install]
WantedBy=multi-user.target
EOF

    sudo systemctl daemon-reload
    sudo systemctl enable --now vbox-modules
    log_ok "✅ vbox-modules.service CREADO + ACTIVADO"
}

install_burp() {
    local TITLE="Burp Suite Community"
    
    if [[ -x "$USERHOME/BurpSuiteCommunity/BurpSuiteCommunity" ]] || \
       command -v burp &>/dev/null || \
       pacman -Q burpsuite &>/dev/null 2>&1 || \
       find "$USERHOME" -name "*BurpSuite*" -type d | grep -q . ; then
        log_ok "Burp YA INSTALADO (detección múltiple)"
        return 0
    fi
    
    local BURP_DIR=$(find "$USERHOME" -maxdepth 3 -name "*BurpSuite*" -type d 2>/dev/null | head -1)
    if [[ "$BURP_DIR" ]]; then
        log_ok "Burp encontrado en: $BURP_DIR"
        create_burp_wrapper "$BURP_DIR/BurpSuiteCommunity"
        return 0
    fi
}

create_burp_wrapper() {
    local BURPBIN="$1"
    local WRAPPER="$USERHOME/.local/bin/burp"
    
    mkdir -p "$USERHOME/.local/bin"
    cat > "$WRAPPER" << EOF
#!/bin/bash
export _JAVA_AWT_WM_NONREPARENTING=1
export _JAVA_OPTIONS='-Dawt.toolkit.name=MToolkit -Djava.security.manager=allow'
exec "$BURPBIN" "\$@"
EOF
    chmod +x "$WRAPPER"
    log_ok "Wrapper creado: $WRAPPER"
}

# Caido con URLs variables
install_caido() {
    local DIR="$HOME/.local/share/ciber"
    local BINDIR="$HOME/bin"
    
    mkdir -p "$BINDIR" "$DIR" "$HOME/.local/bin" "$HOME/.local/share/applications" "$HOME/.local/share/icons"
    
    log_msg "Configurando icono Caido..."
    wget -q "$CAIDO_ICON_URL" -O "$HOME/.local/share/icons/caido.png"
    
    cat > "$HOME/.local/share/applications/caido.desktop" << EOF
[Desktop Entry]
Version=1.0
Name=CaiDO
Comment=Web Security Testing Proxy
Exec=$BINDIR/caido --no-sandbox
Icon=caido
Terminal=false
Type=Application
Categories=Network;Security;Hacking;
StartupWMClass=Caido
MimeType=application/x-caido;
EOF
    update-desktop-database "$HOME/.local/share/applications"
    
    if command -v caido &>/dev/null || [[ -x "$BINDIR/caido" ]]; then
        log_ok "Caido YA en PATH → Config OK"
        return 0
    fi
    
    local CAIDOVERSION=$(curl -s "$CAIDO_GITHUB_API" | grep tag_name | sed -E 's/.*"([^"]+)".*/\1/')
    local CAIDOAPPIMAGE="$BINDIR/caido-desktop-${CAIDOVERSION}-linux-x86_64.AppImage"
    
    if [[ ! -x "$CAIDOAPPIMAGE" ]]; then
        log_msg "DESCARGANDO Caido v$CAIDOVERSION..."
        rm -f "$BINDIR/caido-desktop-"*.AppImage
        wget --timeout=60 "${CAIDO_BASE_URL}/${CAIDOVERSION}/caido-desktop-${CAIDOVERSION}-linux-x86_64.AppImage" -O "$CAIDOAPPIMAGE"
        chmod +x "$CAIDOAPPIMAGE"
        echo "$CAIDOVERSION" > "$DIR/caidoversion.txt"
    else
        log_ok "Caido v$CAIDOVERSION ya descargado"
    fi
    
    ln -sf "$CAIDOAPPIMAGE" "$BINDIR/caido"
    ln -sf "$BINDIR/caido" "$HOME/.local/bin/caido"
    
    if ! grep -q ".local/bin" "$HOME/.bashrc" 2>/dev/null; then
        echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$HOME/.bashrc"
    fi
    
    log_ok "Caido OK → caido / Rofi / Menú"
}

# ==================== MAIN ====================
main() {
    log_msg "Kernel: $(uname -r) | Headers: $KERNEL_HEADERS"
    
    read -r -p "¿VMs (VirtualBox/VMware)? [y/N] " choice
    case "$choice" in [Yy]*) 
        install_virtualbox
        install_vmware
    ;; *)
        log_msg "Saltando VMs"
    esac
    
    read -r -p "¿Burp/Caido? [y/N] " choice
    case "$choice" in [Yy]*) 
        install_burp
        install_caido
    ;; *)
        log_msg "Saltando Burp/Caido"
    esac
    
    log_ok "¡LISTO! Reinicia sesión → burp, caido, virtualbox, vmware"
}

main "$@"
