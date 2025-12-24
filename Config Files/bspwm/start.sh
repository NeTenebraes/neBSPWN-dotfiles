#!/bin/sh

# Terminar np-applet y megasync si están corriendo
pgrep np-applet && pkill np-applet
pgrep megasync && pkill megasync
pgrep polkit-gnome-authentication-agent-1 && pkill polkit-gnome-authentication-agent-1

# Iniciar aplicaciones necesarias
pgrep nm-applet || nm-applet &
pgrep megasync || megasync &
pgrep polkit-gnome-authentication-agent-1 || /usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1 &
pgrep blueberry-tray || blueberry-tray &

pgrep unclutter || unclutter -idle 5 -root &

killall -q conky

(sleep 3 && conky -c /home/netenebrae/.config/conky/conky.conf) &
