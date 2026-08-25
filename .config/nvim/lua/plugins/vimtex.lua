return {
  "lervag/vimtex",
  lazy = false, -- LaTeX dosyası açınca değil, direkt yüklensin (daha stabil)
  init = function()
    -- VimTeX ayarları (VimScript değişkenleri)
    -- PDF görüntüleyici olarak Zathura'yı seçiyoruz
    vim.g.vimtex_view_method = "zathura"

    -- Derleme motoru (latexmk kullanır, en iyisidir)
    vim.g.vimtex_compiler_method = "latexmk"

    -- Hata vermesin diye map leader ayarı (genelde space'dir ama garanti olsun)
    -- vim.g.mapleader = " "
  end,
  config = function()
    vim.keymap.set("n", "<leader>ll", "<cmd>VimtexCompile<CR>", { desc = "VimTeX Compile" })
    vim.keymap.set("n", "<leader>lv", "<cmd>VimtexView<CR>", { desc = "VimTeX View PDF" })
    vim.keymap.set("n", "<leader>lk", "<cmd>VimtexStop<CR>", { desc = "VimTeX Stop" })
    vim.keymap.set("n", "<leader>lc", "<cmd>VimtexClean<CR>", { desc = "VimTeX Clean Junk Files" })
  end,
}
