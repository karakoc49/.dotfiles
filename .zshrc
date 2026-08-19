# ==========================================
# TUŞ BAĞLAMALARI (KEYBINDINGS)
# ==========================================
# Zsh'ın standart tuş haritasını garantile
bindkey -e

# Home Tuşu (Farklı terminal emülatörleri için alternatif kodlar)
bindkey '^[[H' beginning-of-line
bindkey '^[[1~' beginning-of-line
bindkey '^[OH' beginning-of-line

# End Tuşu
bindkey '^[[F' end-of-line
bindkey '^[[4~' end-of-line
bindkey '^[OF' end-of-line

# Delete Tuşu (Büyük ihtimalle bu da bozuktur, hazır el atmışken düzeltelim)
bindkey '^[[3~' delete-char

# Ctrl + Sol/Sağ Ok ile kelime kelime atlama (Vibe coding için şarttır)
bindkey '^[[1;5C' forward-word
bindkey '^[[1;5D' backward-word

# ==========================================
# ÇEVRE DEĞİŞKENLERİ
# ==========================================
export PATH="$PATH:/usr/local/go/bin"
export PATH="$(python -c 'import site; print(site.USER_BASE + "/bin")'):$PATH"
export SUDO_EDITOR="nvim"
export EDITOR="nvim"

# pyenv
export PYENV_ROOT="$HOME/.pyenv"
[[ -d $PYENV_ROOT/bin ]] && export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init -)"

# ==========================================
# GEÇMİŞ (HISTORY) AYARLARI
# ==========================================
HISTFILE=~/.zsh_history
HISTSIZE=10000
SAVEHIST=10000
setopt appendhistory
setopt sharehistory # Farklı terminal pencereleri arasında geçmişi anında paylaşır

# ==========================================
# KISAYOLLAR (ALIASES)
# ==========================================
# ls yerine çok daha hızlı ve ikonlu eza
alias ls='eza -al --color=always --group-directories-first --icons=always'
alias ll='eza -l --color=always --icons=always'
alias tree='eza --tree --icons=always'

alias cat='bat --style="plain"'
alias vim='nvim'
alias python='python3'
alias idf=". ~/esp/esp-idf/export.sh"
# ==========================================
# MODERN ARAÇLARIN BAŞLATILMASI
# ==========================================
# Zoxide (Akıllı cd)
eval "$(zoxide init zsh)"

# Starship Prompt
eval "$(starship init zsh)"

# ==========================================
# ZSH EKLENTİLERİ (FEDORA LINUX YOLLARI)
# ==========================================
# 1. Otomatik Tamamlama (Sen yazarken silik renkte geçmişi önerir, sağ ok ile kabul edersin)
source /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh

# 2. Sözdizimi Renklendirme (Komut doğruysa yeşil, yanlışsa kırmızı yanar)
# ÖNEMLİ: syntax-highlighting Zsh'ta her zaman en sona yazılmalıdır!
source /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

# Initialize Zsh command completion
autoload -Uz compinit && compinit

