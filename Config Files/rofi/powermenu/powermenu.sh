#!/usr/bin/env bash

# 1. Iconos y Nombres
op_power="󰐥"
op_reboot="󰜉"
op_suspend="󰤄"
op_lock="󰌾"
op_logout="󰍃"
op_cancel="󰅖"

# 2. Cálculos de pantalla (Resolución dinámica)
read -r width height <<< "$(xdpyinfo | grep dimensions | awk '{print $2}' | tr 'x' ' ')"

# --- AJUSTE DE TAMAÑO GRANDE ---
btn_size=250   # Antes era 180
spacing=50
cols=3
rows=2

# Centrado exacto recalculado para botones grandes
menu_w=$(( (btn_size * cols) + (spacing * (cols - 1)) ))
menu_h=$(( (btn_size * rows) + spacing + 100 ))
pad_h=$(( (width - menu_w) / 2 ))
pad_v=$(( (height - menu_h) / 2 ))

# 3. Creación del Tema
theme_path="$HOME/.config/rofi/powermenu/theme.rasi"
mkdir -p "$(dirname "$theme_path")"

cat <<EOF > "$theme_path"
* {
    bg: rgba(5, 5, 5, 0.95);
    btn: rgba(25, 20, 20, 0.8);
    accent: rgba(217, 4, 41, 1.0);
    fg: rgba(255, 255, 255, 0.6);
}

window {
    fullscreen: true;
    background-color: @bg;
    padding: ${pad_v}px ${pad_h}px;
}

mainbox {
    background-color: transparent;
    children: [ inputbar, listview ];
}

inputbar {
    margin: 0px 0px 60px 0px;
    children: [ prompt ];
    background-color: transparent;
}

prompt {
    background-color: transparent;
    text-color: white;
    font: "JetBrainsMono Nerd Font Bold 45";
    width: 100%;
    horizontal-align: 0.5;
}

listview {
    background-color: transparent;
    columns: $cols;
    lines: $rows;
    spacing: ${spacing}px;
    fixed-height: true;
    fixed-columns: true;
}

element {
    background-color: @btn;
    text-color: @fg;
    border-radius: 35px; /* Bordes más redondeados para botones grandes */
    padding: 0px;
}

element selected {
    background-color: @accent;
    text-color: white;
}

element-text {
    font: "JetBrainsMono Nerd Font 110"; /* Fuente más grande para el botón grande */
    background-color: transparent;
    text-color: inherit;
    horizontal-align: 0.5;
    vertical-align: 0.5;
    /* Ajuste de margen para centrado vertical con el nuevo tamaño */
    margin: 60px 0px 60px 0px; 
}
EOF

# 4. Ejecución y Lógica
options="$op_power\n$op_reboot\n$op_suspend\n$op_lock\n$op_logout\n$op_cancel"

chosen="$(echo -e "$options" | rofi -dmenu -theme "$theme_path" -p "POWER MENU")"

case "$chosen" in
    "$op_power")   systemctl poweroff ;;
    "$op_reboot")  systemctl reboot ;;
    "$op_suspend") systemctl suspend ;;
    "$op_lock")    betterlockscreen -l ;;
    "$op_logout")  bspc quit ;;
    *)             exit 0 ;;
esac