#!/usr/bin/env bash

# ~/.ssh/config içindeki tanımlı host isimlerini çek (wildcard '*' hariç)
HOST=$(awk '/^Host / && !/\*/ {print $2}' ~/.ssh/config | rofi -dmenu -p "SSH Sunucuları")

# Seçim yapıldıysa Alacritty içinde ssh oturumu başlat
if [ -n "$HOST" ]; then
    alacritty -e ssh "$HOST"
fi
