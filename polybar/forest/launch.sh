#!/usr/bin/env bash

# Add this script to your wm startup file.

DIR="$HOME/.config/polybar/forest"

# Terminate already running bar instances
killall -q polybar

# Wait until the processes have been shut down
echo "Esperando que Polybar termine..."
while pgrep -u "$UID" -x polybar >/dev/null; do sleep 1; done

notify-send "$(xrandr -q | grep -w connected)"

if xrandr -q | grep -q '^DP-1 connected'; then
  notify-send "DP-1 conectado. Lanzando Polybar principal..."
  polybar main -c "$DIR"/config.ini &
fi

if xrandr -q | grep -q '^HDMI-1 connected'; then
  notify-send "Lanzando Polybar secundario..."
  polybar secondary -c "$DIR"/config.ini &
fi

if xrandr -q | grep -q '^DP-2 connected'; then
  notify-send "DP-2 conectado. Lanzando Polybar terciario..."
  polybar terciary -c "$DIR"/config.ini &
fi