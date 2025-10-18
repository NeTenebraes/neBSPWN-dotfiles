#!/bin/bash

# Define los iconos que usas
ICON_CONNECTED="直"
ICON_DISCONNECTED="睊"
ICON_WIFI=""
ICON_ETHERNET=""

# 1. Obtener la interfaz que está "conectada" (no necesariamente "up", sino "activada" por NM)
# Excluye interfaces loopback (lo)
INTERFACE=$(nmcli -t -f DEVICE,STATE dev | grep "conectado" | grep -v "lo" | head -n 1 | cut -d ':' -f 1)

# 2. Si hay una interfaz activa, obtener el tipo de conexión y el nombre
if [ -n "$INTERFACE" ]; then
    # Obtener el tipo de conexión (wifi, ethernet)
    TYPE=$(nmcli -t -f TYPE,DEVICE dev | grep "^$INTERFACE" | cut -d ':' -f 1)

    # Definir el icono basado en el tipo
    case "$TYPE" in
        wifi)
            FINAL_ICON="$ICON_WIFI"
            # Si es Wi-Fi, intenta obtener el SSID (nombre de la red)
            SSID=$(nmcli -t -f NAME con show --active | head -n 1)
            FINAL_TEXT="${SSID}"
            ;;
        ethernet)
            FINAL_ICON="$ICON_ETHERNET"
            FINAL_TEXT="Ethernet"
            ;;
        *)
            # Para otros tipos (VPN, etc.)
            FINAL_ICON="$ICON_CONNECTED"
            FINAL_TEXT="${INTERFACE}"
            ;;
    esac
    
    # Formato final con el icono de estado de tu config original
    echo "直 $FINAL_ICON $FINAL_TEXT"
else
    # Si no hay interfaces conectadas
    echo "$ICON_DISCONNECTED"
fi