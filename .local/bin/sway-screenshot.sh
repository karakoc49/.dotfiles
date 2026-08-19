#!/bin/bash

# Rofi menüsü
OPTIONS="1. 🔲 Alan Seç\n2. 🖥️ Tüm Ekran\n3. 🪟 Pencere Seç\n4. ⏱️ Alan Seç (Seçtikten Sonra 3 sn)\n5. ⏱️ Tüm Ekran (3 sn Gecikmeli)\n6. ⏱️ Pencere Seç (Seçtikten Sonra 3 sn)"

CHOSEN=$(echo -e "$OPTIONS" | rofi -dmenu -i -p "Ekran Görüntüsü:" -lines 6)

# Kullanıcı ESC'ye basıp menüden çıkarsa iptal et
if [ -z "$CHOSEN" ]; then
    exit 0
fi

# Tarih damgalı dosya yolu
FILE="$HOME/Pictures/Screenshot_$(date +%Y-%m-%d-%H%M%S).png"

case "$CHOSEN" in
    "1."*) # Alan Seç (Anında)
        GEOM=$(slurp)
        [ -n "$GEOM" ] && grim -g "$GEOM" "$FILE"
        ;;
    "2."*) # Tüm Ekran (Anında)
        grim "$FILE"
        ;;
    "3."*) # Pencere Seç (Anında)
        WINDOW=$(swaymsg -t get_tree | jq -r '.. | select(.pid? and .visible?) | .rect | "\(.x),\(.y) \(.width)x\(.height)"' | slurp)
        [ -n "$WINDOW" ] && grim -g "$WINDOW" "$FILE"
        ;;
    "4."*) # Alan Seç (Önce Seç -> Sonra 3 sn Bekle -> Çek)
        GEOM=$(slurp)
        if [ -n "$GEOM" ]; then
            sleep 3
            grim -g "$GEOM" "$FILE"
        fi
        ;;
    "5."*) # Tüm Ekran (3 sn Bekle -> Çek)
        sleep 3
        grim "$FILE"
        ;;
    "6."*) # Pencere Seç (Önce Pencereyi Seç -> Sonra 3 sn Bekle -> Çek)
        WINDOW=$(swaymsg -t get_tree | jq -r '.. | select(.pid? and .visible?) | .rect | "\(.x),\(.y) \(.width)x\(.height)"' | slurp)
        if [ -n "$WINDOW" ]; then
            sleep 3
            grim -g "$WINDOW" "$FILE"
        fi
        ;;
esac

# Eğer dosya başarıyla oluşturulduysa ÇİFT PANO sistemini tetikle
if [ -f "$FILE" ]; then
    # 1. Normal Panoya (Ctrl+V) pikselleri kopyala -> Slack, Discord, Chrome
    wl-copy < "$FILE"
    
    # 2. Birincil Panoya (Primary Selection) dosya yolunu metin olarak kopyala -> Terminal, Claude Code
    echo -n "$FILE" | wl-copy -p
    
    notify-send "📸 Ekran Görüntüsü Alındı" "Resim Ctrl+V'ye, dosya yolu Orta Tuş'a kopyalandı." -i "$FILE"
fi
