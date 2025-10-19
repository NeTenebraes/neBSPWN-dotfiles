#!/bin/bash

chosen=$(echo -e " Power Off\n Reboot\n Suspend\n Lock" | rofi -dmenu -i -p "Power Action:")

case "$chosen" in
    " Power Off")
        ans=$(echo -e "No\nYes" | rofi -dmenu -i -p "Are you sure you want to power off?")
        if [ "$ans" == "Yes" ]; then
            systemctl poweroff
        fi
        ;;
    " Reboot")
        ans=$(echo -e "No\nYes" | rofi -dmenu -i -p "Are you sure you want to reboot?")
        if [ "$ans" == "Yes" ]; then
            systemctl reboot
        fi
        ;;
    " Suspend")
        systemctl suspend
        ;;
    " Lock")
        i3lock
        ;;
esac