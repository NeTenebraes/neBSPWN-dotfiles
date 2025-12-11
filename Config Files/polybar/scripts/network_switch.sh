#!/bin/bash

# --- Configuración ---
# Archivo para guardar el índice de la interfaz activa
active_index_file="$HOME/.config/polybar/scripts/active_net_index"

# --- Lógica del script ---
# Crear el directorio si no existe
mkdir -p "$(dirname "$active_index_file")"

# Detectar todas las interfaces de red relevantes
interfaces=($(ip -o link show | awk -F': ' '{print $2}' | grep -E '^(enp|eth|wlan|wlp|wlx|usb|usb0|virbr|vnet|vmnet|tun|tap|ppp|docker|br-|vboxnet|vmw)'))

# Si no hay interfaces, mostrar un mensaje corto y salir
if [ ${#interfaces[@]} -eq 0 ]; then
    echo " --"
    exit 0
fi

# Crear archivo de índice si no existe
if [ ! -f "$active_index_file" ]; then
    echo 0 > "$active_index_file"
fi

# Leer y validar el índice activo
active_index=$(cat "$active_index_file")
if ! [[ "$active_index" =~ ^[0-9]+$ ]] || [ "$active_index" -ge "${#interfaces[@]}" ]; then
    active_index=0
    echo "$active_index" > "$active_index_file"
fi

# Cambiar de interfaz al recibir el argumento 'toggle'
if [[ "$1" == "toggle" ]]; then
    active_index=$(( (active_index + 1) % ${#interfaces[@]} ))
    echo "$active_index" > "$active_index_file"
fi

# Obtener la interfaz activa y su IP
active_iface=${interfaces[$active_index]}
ip_addr=$(ip -4 addr show "$active_iface" 2>/dev/null | grep -oP '(?<=inet\s)\d+(\.\d+){3}')

# Función para obtener un nombre corto y su número
get_short_name() {
    local iface_name="$1"
    local base_name
    local num

    # Extraer el número del final del nombre de la interfaz (ej: de "tun0" extrae "0")
    if [[ "$iface_name" =~ ([0-9]+)$ ]]; then
        num=${BASH_REMATCH[1]}
    else
        num=""
    fi

    # Determinar el nombre base según el tipo de interfaz
    if [[ "$iface_name" == enp* && ${#iface_name} -gt 6 ]]; then
        base_name="USB"
    else
        case "$iface_name" in
            docker*|br-*) base_name="Docker" ;;
            vboxnet*) base_name="vbox" ;;
            vmw*|vmnet*) base_name="vmware" ;;
            virbr*) base_name="VM" ;;
            tun*|tap*|ppp*) base_name="VPN" ;;
            wlan*|wlp*|wlx*) base_name="Wi-Fi" ;;
            enp*|eth*) base_name="ETH" ;;
            *) base_name="???" ;;
        esac
    fi

    # Si se encontró un número, añadirlo entre paréntesis
    if [ -n "$num" ]; then
        echo "$base_name($num)"
    else
        echo "$base_name"
    fi
}

# Función para obtener el ícono según el nombre corto (sin el número)
get_icon() {
    # Eliminar el número entre paréntesis para encontrar el ícono correcto
    local base_name=$(echo "$1" | sed -E 's/\([0-9]+\)//')

    case "$base_name" in
        "USB") echo "" ;;
        "Docker") echo "" ;;
        "vbox") echo "" ;;
        "vmware") echo "" ;;
        "VM") echo "" ;;
        "VPN") echo "" ;;
        "Wi-Fi") echo "" ;;
        "ETH") echo "" ;;
        *) echo "" ;;
    esac
}

# Obtener el nombre formateado y el ícono
short_name=$(get_short_name "$active_iface")
icon=$(get_icon "$short_name")

# Mostrar la salida final para Polybar
if [ -n "$ip_addr" ]; then
    echo "$icon $short_name: $ip_addr"
else
    echo "$icon $short_name: (sin IP)"
fi
