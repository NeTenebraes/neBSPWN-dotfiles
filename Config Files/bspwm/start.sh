#!/bin/sh

# Terminar np-applet y megasync si están corriendo
pgrep np-applet && pkill np-applet
pgrep megasync && pkill megasync
pgrep polkit-gnome-authentication-agent-1 && pkill polkit-gnome-authentication-agent-1

# Iniciar aplicaciones necesarias
pgrep nm-applet || nm-applet &
pgrep megasync || megasync &
pgrep polkit-gnome-authentication-agent-1 || /usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1 &
pgrep blueberry || blueberry &

pgrep unclutter || unclutter -idle 5 -root &

# Opcional: ssh-add si se decide cargar clave
# ssh-add ~/.ssh/id_rsa
