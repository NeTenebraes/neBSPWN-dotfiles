#!/bin/bash
# Get the ID of the focused window. Exit if no window is focused.
win_id=$(xdotool getwindowfocus 2>/dev/null)
if [[ -z "$win_id" ]]; then
  echo " " # Imprime un espacio para limpiar el módulo
  exit 0
fi

# Get the window class and convert to lowercase
win_class=$(xprop -id "$win_id" WM_CLASS 2>/dev/null | awk -F '"' '{print $4}' | tr '[:upper:]' '[:lower:]')

# Get the window title
title=$(xprop -id "$win_id" WM_NAME 2>/dev/null | awk -F '"' '/WM_NAME/ {print $2}')

# Define icons based on window class
case "$win_class" in
    "firefox"|"librewolf"|"firefox-developer-edition")
        icon="" ;;
    "code")
        icon="" ;;
    "alacritty"|"kitty"|"st"|"gnome-terminal")
        icon="" ;;
    "nautilus"|"thunar"|"dolphin")
        icon="" ;;
    *)
        icon="" ;;
esac

if [[ -n "$title" ]]; then
  echo "$icon : ${title:0:70}"
else
  echo "$icon  "
fi