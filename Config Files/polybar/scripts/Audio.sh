#!/usr/bin/env bash

SINK="@DEFAULT_SINK@"

get_volume() {
    pactl get-sink-volume "$SINK" \
      | awk -F'/' 'NR==1{gsub(/ /,"",$2); gsub(/%/,"",$2); print $2}'
}

get_mute() {
    pactl get-sink-mute "$SINK" | awk '{print $2}'
}

print_status() {
    vol=$(get_volume)
    mute=$(get_mute)

    # Iconos estilo JetBrains/Material
    ICON_MUTED="" 
    ICON_LOW=""
    ICON_HIGH=""

    # Si no hay volumen (error)
    if [ -z "$vol" ]; then
        echo "%{F#C62828}$ICON_MUTED  [  MUTED   ]  0%%{F-}"
        exit 0
    fi

    # Limitar el volumen real a 150
    [ "$vol" -gt 150 ] && vol=150
    [ "$vol" -lt 0 ] && vol=0

    # Estado Mute: Icono JetBrains y barra con texto "MUTED"
    if [ "$mute" = "yes" ] || [ "$vol" -eq 0 ]; then
        echo "%{F#C62828}$ICON_MUTED  [  MUTED   ]  0%%{F-}"

        exit 0
    fi

    # Icono según volumen
    if [ "$vol" -lt 34 ]; then
        icon=$ICON_LOW
    else
        icon=$ICON_HIGH
    fi

    # LÓGICA DE LA BARRA (10 bloques exactos)
    # Solo será 10 si vol >= 100. Si es 99, será 9.
    filled=$((vol / 10))
    
    # Asegurar que no exceda 10 bloques aunque el vol sea 150
    [ "$filled" -gt 10 ] && filled=10
    [ "$filled" -lt 0 ] && filled=0
    
    empty=$((10 - filled))

    # Construcción de la barra
    bar=""
    for i in $(seq 1 $filled); do bar="${bar}█"; done
    for i in $(seq 1 $empty); do bar="${bar}░"; done

    # Color según volumen REAL (Cambia DESPUÉS de 100)
if [ "$vol" -le 100 ]; then
    color="#F5F5F5" # blanco suave (hasta el 100%)
elif [ "$vol" -le 130 ]; then
    color="#FF8A65" # naranja acorde al tema
else
    color="#C62828" # rojo máximo
fi


    # Formato final con un solo % visual
    echo "%{F$color}$icon  [$bar] ${vol}%%{F-}"
}

case "$1" in
    --inc)
        pactl set-sink-mute "$SINK" 0
        pactl set-sink-volume "$SINK" +5%
        print_status
        ;;
    --dec)
        pactl set-sink-mute "$SINK" 0
        pactl set-sink-volume "$SINK" -5%
        print_status
        ;;
    --toggle-mute)
        pactl set-sink-mute "$SINK" toggle
        print_status
        ;;
    *)
        print_status
        ;;
esac