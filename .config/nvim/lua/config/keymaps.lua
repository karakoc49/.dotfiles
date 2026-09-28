vim.g.mapleader = " "
vim.g.maplocalleader = "\\" -- vimtex/latex için ayrı localleader

local map = vim.keymap.set

-- Visual: satır taşı
map("v", "J", ":m '>+1<CR>gv=gv", { desc = "Seçimi aşağı taşı" })
map("v", "K", ":m '<-2<CR>gv=gv", { desc = "Seçimi yukarı taşı" })

-- Yapıştırırken yank register'ı bozulmasın
map("x", "<leader>p", '"_dP', { desc = "Register'ı bozmadan yapıştır" })

-- Girinti sonrası seçimi koru
map("v", "<", "<gv")
map("v", ">", ">gv")

-- Pencere gezinme (harpoon <C-h/j/k/l>'yi aldığı için <leader>w ile)
map("n", "<leader>wh", "<C-w>h", { desc = "Sol pencere" })
map("n", "<leader>wj", "<C-w>j", { desc = "Alt pencere" })
map("n", "<leader>wk", "<C-w>k", { desc = "Üst pencere" })
map("n", "<leader>wl", "<C-w>l", { desc = "Sağ pencere" })
map("n", "<leader>wv", "<C-w>v", { desc = "Dikey böl" })
map("n", "<leader>ws", "<C-w>s", { desc = "Yatay böl" })
map("n", "<leader>wq", "<C-w>q", { desc = "Pencereyi kapat" })

-- Quickfix: derleyici hataları arasında gezinme (C geliştirmede kritik)
map("n", "<C-q>", function()
  local open = vim.iter(vim.fn.getwininfo()):any(function(w) return w.quickfix == 1 end)
  vim.cmd(open and "cclose" or "copen")
end, { desc = "Quickfix aç/kapat" })
map("n", "]q", "<cmd>cnext<CR>zz", { desc = "Sonraki quickfix girdisi" })
map("n", "[q", "<cmd>cprev<CR>zz", { desc = "Önceki quickfix girdisi" })

-- Arama/atlama sonrası imleci ortala
map("n", "<C-d>", "<C-d>zz")
map("n", "<C-u>", "<C-u>zz")
map("n", "n", "nzzzv")
map("n", "N", "Nzzzv")

-- Terminal modundan çıkış
map("t", "<Esc><Esc>", "<C-\\><C-n>", { desc = "Terminal normal moda geç" })

-- Arama vurgusunu / float'ları temizle
map("n", "<Esc>", "<cmd>nohlsearch<CR>", { desc = "Aramayı temizle" })
