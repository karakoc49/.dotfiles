#!/bin/sh

# Bluetooth servisi çalışıyor mu?
if [ $(systemctl is-active bluetooth) != "active" ]; then
    echo "%{F#707880}" # Servis kapalıysa gri ikon
else
    # Bağlı cihaz var mı?
    if [ $(bluetoothctl show | grep "Powered: yes" | wc -l) -eq 0 ]; then
        echo "%{F#707880}" # Güç kapalı
    else
        # Bağlı cihazın ismini alalım
        if [ $(echo info | bluetoothctl | grep 'Device' | wc -l) -eq 1 ]; then
            DEVICE=$(echo info | bluetoothctl | grep 'Name' | cut -d ' ' -f 2-)
            echo "%{F#2193ff} $DEVICE" # Mavi ikon + Cihaz adı
        else
            echo "%{F#ffffff}" # Açık ama bağlı değil (Beyaz)
        fi
    fi
fi
