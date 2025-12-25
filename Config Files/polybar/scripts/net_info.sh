#!/bin/bash

active_index_file="$HOME/.config/polybar/scripts/active_net_index"
mkdir -p "$(dirname "$active_index_file")"

# 1. Interfaces con IPv4 global (excluye lo)
mapfile -t interfaces < <(
  ip -4 addr show | awk '/inet / && $NF != "lo" {print $NF}'
)

# Si no hay interfaces
if [ "${#interfaces[@]}" -eq 0 ]; then
  echo "  Sin IP"
  exit 0
fi

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
    ;;
  next)
    active_index=$(( (active_index + 1) % ${#interfaces[@]} ))
    echo "$active_index" > "$active_index_file"
    ;;
esac

# 4. Interfaz activa e IP
active_iface=${interfaces[$active_index]}
ip_addr=$(ip -4 addr show "$active_iface" | awk '/inet / {print $2}' | cut -d'/' -f1 | head -1)

# 5. Iconos por tipo de interfaz
case "$active_iface" in
  wlan*|wlp*)           icon=""  ; name="Wi-Fi" ;;
  enx*|enp*us*|usb*)    icon=""  ; name="USB"   ;;  # USB / adapters
  vboxnet*|vbox*)       icon=""  ; name="VBOX"  ;;  # VirtualBox host-only
  eth*|enp*)            icon=""  ; name="ETH"   ;;
  tun*|ppp*)            icon=""  ; name="VPN"   ;;
  *)                    icon=""  ; name="NET"   ;;
esac



echo "$icon $name: $ip_addr"
