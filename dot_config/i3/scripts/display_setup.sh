#!/bin/bash

# 1. Önce autorandr ile kayıtlı bir profil var mı bak (Ev, Ofis vs.)
if autorandr --change; then
    echo ">> Kayıtlı profil yüklendi."
    # Polybar/Wallpaper yenilemek gerekebilir
    ~/.config/polybar/launch.sh &
    nitrogen --restore &
    exit 0
fi

# 2. Kayıtlı profil yoksa (veya VM ise) manuel tarama yap
echo ">> Bilinmeyen ekran, otomatik ayarlanıyor..."

# Bağlı olan ekranları diziye al
screens=($(xrandr | grep " connected" | cut -d ' ' -f1))

if [ ${#screens[@]} -eq 0 ]; then
    echo "Hiçbir ekran bulunamadı!"
    exit 1
fi

# İlk ekranı (Primary) ayarla
primary="${screens[0]}"
cmd="xrandr --output $primary --auto --primary"

# Varsa diğer ekranları bir öncekinin sağına ekle (--right-of)
# Bu sayede ekranlar üst üste binmez (mirror olmaz)
for ((i=1; i<${#screens[@]}; i++)); do
    prev="${screens[$((i-1))]}"
    curr="${screens[$i]}"
    cmd="$cmd --output $curr --auto --right-of $prev"
done

echo "Çalıştırılıyor: $cmd"
$cmd

# Wallpaper ve Bar'ı yeniden tetikle
~/.config/polybar/launch.sh &
nitrogen --restore &