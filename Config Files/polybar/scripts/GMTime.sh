#!/usr/bin/env bash

STATE_FILE="$HOME/.cache/polybar-time-mode"

# Estado por defecto: "gmt"
[ ! -f "$STATE_FILE" ] && echo "gmt" > "$STATE_FILE"

if [ "$1" = "--toggle" ]; then
    mode=$(cat "$STATE_FILE")
    [ "$mode" = "gmt" ] && echo "ampm" > "$STATE_FILE" || echo "gmt" > "$STATE_FILE"
    exit 0
fi

mode=$(cat "$STATE_FILE")

ICON=""  # Reloj (JetBrainsMono Nerd Font)

if [ "$mode" = "gmt" ]; then
    # Dec 25 -   20:43:00 [GMT-5]
    date +"%b %e - $ICON %H:%M:%S [GMT%:z]"\
      | sed 's/GMT\([+-]\)\([0-9][0-9]\):[0-9][0-9]/GMT\1\2/'
else
    # Dec 25 -   08:43:00 PM
    date +"%b %e - $ICON  %I:%M:%S %p"
fi
