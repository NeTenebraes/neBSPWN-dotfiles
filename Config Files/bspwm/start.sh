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
# Al final de bspwmrc (aún más seguro)
pgrep xautolock || xautolock -time 5 -locker "betterlockscreen -l" &


# 3. Configuración de pantalla (Evita suspensión, apaga a la hora)
xset s off               # Desactiva el protector de pantalla clásico
xset -dpms               # Resetea DPMS
xset dpms 0 0 3600 &     # 0 standby, 0 suspend, 3600 (1 hora) para OFF total