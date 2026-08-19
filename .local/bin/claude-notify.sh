#!/usr/bin/env bash

TITLE="Claude Code"
MSG="${1:-Islem tamamlandi!}"
SOUND="${2:-bell.oga}"

# DBus ve Wayland/Ses ortam değişkenlerini garantiye alalım
export XDG_RUNTIME_DIR="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"
export DBUS_SESSION_BUS_ADDRESS="${DBUS_SESSION_BUS_ADDRESS:-unix:path=$XDG_RUNTIME_DIR/bus}"

# 1. Mako Bildirimi Gönder
notify-send -a "Claude Code" -t 5000 -i utilities-terminal "$TITLE" "$MSG"

# 2. Ses Çal (Arka planda çalması için & eklendi)
SOUND_PATH="/usr/share/sounds/freedesktop/stereo/$SOUND"
if [ -f "$SOUND_PATH" ]; then
    pw-play "$SOUND_PATH" >/dev/null 2>&1 &
fi

# 3. İlgili Alacritty Penceresini Bul ve Waybar'da Kırmızı Yap (Urgent)
curr=$PPID
while [ -n "$curr" ] && [ "$curr" -gt 1 ]; do
    if ps -p "$curr" -o comm= 2>/dev/null | grep -qi "alacritty"; then
        swaymsg "[pid=$curr] urgent enable" >/dev/null 2>&1
        break
    fi
    curr=$(ps -p "$curr" -o ppid= 2>/dev/null | tr -d ' ')
done
