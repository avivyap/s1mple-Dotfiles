#!/bin/bash

BAT="/org/freedesktop/UPower/devices/battery_BAT1"

battery=$(upower -i "$BAT" | awk '/percentage/ {gsub("%","",$2); print $2}')
state=$(upower -i "$BAT" | awk -F': ' '/state/ {print $2}')

# Barra de 10 bloques
filled=$((battery / 10))
empty=$((10 - filled))

bar=$(printf "%0.s=" $(seq 1 $filled))
space=$(printf "%0.s " $(seq 1 $empty))

if [ "$state" = "charging" ]; then
    status="CARGANDO"
else
    status=""
fi

echo "$status [$bar$space] ${battery}%"
