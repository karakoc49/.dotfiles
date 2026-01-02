#!/bin/bash
set -e

echo ">>> Arch Linux Setup Başlatılıyor..."

# 1. Temel gereksinimleri kur
echo ">>> Git ve Ansible kuruluyor..."
sudo pacman -Sy --noconfirm git ansible

# 2. Hedef dizin (Chezmoi varsayılanı)
DEST_DIR="$HOME/.local/share/chezmoi"

# 3. Repoyu doğru yere koy
if [ -d "$DEST_DIR" ]; then
    echo ">>> Repo zaten var, güncelleniyor..."
    cd "$DEST_DIR" && git pull
else
    echo ">>> Repo klonlanıyor..."
    # AŞAĞIDAKİ SATIRIN YORUMUNU KALDIR VE REPO ADRESİNİ YAZ:
    git clone https://github.com/karakoc49/.dotfiles.git "$DEST_DIR"
    
    # EĞER ŞU AN "ansible" BRANCH'İNDEYSEN VE MAIN'E MERGE ETMEYECEKSEN:
    cd "$DEST_DIR" && git checkout ansible
fi

# 4. Playbook'u çalıştır
echo ">>> Ansible Playbook çalıştırılıyor..."
ansible-playbook ansible/local.yml --ask-become-pass

echo ">>> Kurulum Bitti! Lütfen oturumu kapatıp açın."