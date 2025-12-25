#!/usr/bin/env bash

STATE_FILE="$HOME/.cache/polybar_powermenu_state"

# Detectar distro -> icono (puedes cambiar el de Arch por otro)
if [ -f /etc/os-release ]; then
  . /etc/os-release
  case "$ID" in
    arch)   icon="󰣇" ;;
    ubuntu) icon="" ;;
    debian) icon="" ;;
    fedora) icon="" ;;
    kali)   icon="" ;;
    *)      icon="" ;;
  esac
else
  icon=""
fi

case "$1" in
  click)
    # Guarda timestamp del click
    date +%s > "$STATE_FILE"
    # Lanza rofi sin bloquear
    setsid /home/netenebrae/.config/rofi/powermenu/powermenu.sh >/dev/null 2>&1 &
    ;;

  status|*)
    now=$(date +%s)
    if [ -f "$STATE_FILE" ]; then
      last=$(cat "$STATE_FILE" 2>/dev/null || echo 0)
    else
      last=0
    fi

    # Si el último click fue hace <= 2 segundos -> rojo
    if [ "$((now - last))" -le 2 ]; then
      echo "%{T3}%{F#ff5555} ${icon} %{F-}%{T-}"
    else
      echo "%{T3}%{F#ffffff} ${icon} %{F-}%{T-}"
    fi
    ;;
esac
