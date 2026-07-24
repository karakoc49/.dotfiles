#!/usr/bin/env bash

# Seçenekler
op1="🔒 Lock"
op2="💤 Sleep"
op3="🌙 Hibernate"
op4="🚪 Logout"
op5="🔄 Restart"
op6="🛑 Shutdown"

options="$op1\n$op2\n$op3\n$op4\n$op5\n$op6"

# Rofi Menüsünü Tetikle
chosen=$(echo -e "$options" | rofi -dmenu -i -p "Sistem Eylemi:" -theme-str 'window {width: 300px; height: 280px;}')

case $chosen in
    $op1)
        gtklock -d
        ;;
    $op2)
        systemctl suspend
        ;;
    $op3)
        systemctl hibernate
        ;;
    $op4)
        swaymsg exit
        ;;
    $op5)
        systemctl reboot
        ;;
    $op6)
        systemctl poweroff
        ;;
esac
