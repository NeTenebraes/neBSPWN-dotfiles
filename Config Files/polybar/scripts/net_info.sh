#!/bin/bash

active_index_file="$HOME/.config/polybar/scripts/active_net_index"
mkdir -p "$(dirname "$active_index_file")"

# 1. Interfaces con IPv4 global (excluye lo)
mapfile -t interfaces < <(
    ip -4 addr show | awk '/inet / && $NF != "lo" {print $NF}'
)

# Añadimos SIEMPRE una entrada virtual CENSORED al final del ciclo
interfaces+=("CENSORED")

# 2. Índice actual
if [ ! -f "$active_index_file" ]; then
    echo 0 > "$active_index_file"
fi

active_index=$(cat "$active_index_file")
if [ "$active_index" -ge "${#interfaces[@]}" ]; then
    active_index=0
    echo "$active_index" > "$active_index_file"
fi

# 3. Clicks: left = prev, right = next
case "$1" in
    prev)
        active_index=$(( (active_index - 1 + ${#interfaces[@]}) % ${#interfaces[@]} ))
        echo "$active_index" > "$active_index_file"
        exit 0
        ;;
    next)
        active_index=$(( (active_index + 1) % ${#interfaces[@]} ))
        echo "$active_index" > "$active_index_file"
        exit 0
        ;;
esac

# 4. Interfaz activa e IP
active_iface=${interfaces[$active_index]}

if [ "$active_iface" = "CENSORED" ]; then
    # Entrada virtual CENSORED sin IP real
    ip_addr="CENSORED"
    display_name="LOCAL IP"
    icon="%{T1}󰦝%{T-}"      # Skull (Nerd Font)
else
    ip_addr=$(ip -4 addr show "$active_iface" | awk '/inet / {print $2}' | cut -d'/' -f1 | head -1)
    display_name="$active_iface"

    # 5. Iconos NERD FONT (font-2 size=10)
case "$active_iface" in
    # VMware (vmnet1 / vmnet8)
    vmnet*|vmware*)
        icon="%{T1}󰝨%{T-}"      # VM / VMware
        ;;

    # VirtualBox (si algún día aparece vboxnet0, etc.)
    vboxnet*|vbox*)
        icon="%{T1}󰝨%{T-}"      # VM / VBOX
        ;;

    # USB / tethering: enp0s29u1u2 y similares (enp...u...)
    enp*u*|enp*us*|enx*|usb*)
        icon="%{T1}%{T-}"      # USB / tethering
        ;;

    # Ethernet física (enpX, ethX normales)
    eth*|enp*)
        icon="%{T1}󰈀%{T-}"      # Ethernet
        ;;

    # WiFi
    wlan*|wlp*)
        icon="%{T1}󰖩%{T-}"      # WiFi
        ;;

    # VPN / túneles
    tun*|ppp*)
        icon="%{T1}󰞉%{T-}"      # VPN
        ;;

    # CENSURED fijo
    CENSURED)
        icon="%{T1}󰳛%{T-}"      # Skull
        display_name="CENSURED"
        ;;

    # Genérico
    *)
        icon="%{T1}󰤨%{T-}"      # Señal genérica
        ;;
esac


fi

# 6. Salida para polybar
echo "%{A1:~/.config/polybar/scripts/net_info.sh prev:}${icon} %{T0}${display_name}: ${ip_addr}%{T-}%{A}%{A3:~/.config/polybar/scripts/net_info.sh next:}%{A}"
