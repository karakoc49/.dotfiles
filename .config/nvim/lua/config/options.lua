local opt = vim.opt

-- Satır numaraları
opt.number = true
opt.relativenumber = true
opt.signcolumn = "yes" -- diagnostic/gitsigns ikonları gelince metin kaymasın

-- Girinti (vim-sleuth dosyaya göre override eder)
opt.tabstop = 4
opt.softtabstop = 4
opt.shiftwidth = 4
opt.expandtab = true
opt.smartindent = true
opt.breakindent = true

-- Arama
opt.hlsearch = false
opt.incsearch = true
opt.ignorecase = true
opt.smartcase = true -- büyük harf yazınca case-sensitive'e döner

-- Görünüm
opt.termguicolors = true
opt.scrolloff = 8
opt.sidescrolloff = 8
opt.colorcolumn = "120" -- ESP-IDF kod stili 120 sütun
opt.cursorline = true
opt.wrap = false
opt.laststatus = 3 -- tek global statusline (split'lerde daha temiz)
opt.splitright = true
opt.splitbelow = true
opt.pumheight = 12
opt.list = true
opt.listchars = { tab = "» ", trail = "·", nbsp = "␣" }
opt.fillchars = { eob = " " }
opt.winborder = "rounded" -- nvim 0.11+: tüm float'lara çerçeve

-- Kalıcı undo (undotree eklentisi ancak bununla anlamlı olur)
opt.undofile = true
opt.undodir = vim.fn.stdpath("state") .. "/undo"
opt.swapfile = false
opt.backup = false

-- Davranış
opt.clipboard = "unnamedplus"
opt.mouse = "a"
opt.updatetime = 250 -- CursorHold / gitsigns / LSP daha hızlı tepki versin
opt.timeoutlen = 400 -- which-key popup'ı çabuk açılsın
opt.confirm = true   -- kaydedilmemiş buffer'da :q sorsun, hata vermesin
opt.completeopt = { "menu", "menuone", "noselect" }
opt.grepprg = "rg --vimgrep --smart-case"
opt.grepformat = "%f:%l:%c:%m"

-- ESP-IDF build klasörleri dosya aramalarını kirletmesin
opt.wildignore:append({ "*/build/*", "*/managed_components/*", "*.o", "*.elf", "*.bin", "*.map" })

-- Netrw'yi tamamen devre dışı bırak (oil.nvim kullanılıyor)
vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1
