#!/bin/bash

if [ "$#" -ne 3 ]; then
    echo "Uso: $0 expand|contract north|east|south|west tamaño"
    exit 1
fi

motion=$1
direction=$2
size=$3

if [ "$motion" = "expand" ]; then
    case "$direction" in
        north) bspc node -z top 0 -"$size" ;;
        east)  bspc node -z right "$size" 0 ;;
        south) bspc node -z bottom 0 "$size" ;;
        west)  bspc node -z left -"$size" 0 ;;
        *) echo "Dirección inválida: $direction"; exit 1 ;;
    esac
elif [ "$motion" = "contract" ]; then
    case "$direction" in
        north) bspc node -z top 0 "$size" ;;
        east)  bspc node -z right -"$size" 0 ;;
        south) bspc node -z bottom 0 -"$size" ;;
        west)  bspc node -z left "$size" 0 ;;
        *) echo "Dirección inválida: $direction"; exit 1 ;;
    esac
else
    echo "Acción inválida: $motion (usa expand|contract)"
    exit 1
fi
