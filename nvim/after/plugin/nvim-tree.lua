local ok, nvimtree = pcall(require, "nvim-tree")
if not ok then
  return
end

nvimtree.setup({
  hijack_netrw = false,
  disable_netrw = false,

  sync_root_with_cwd = true,
  respect_buf_cwd = true,

  view = {
    width = 30,
    side = "left",
  },

  renderer = {
    highlight_git = true,
    highlight_opened_files = "all",
  },
})

-- Mevcut dosyanın dizininde açan toggle
vim.keymap.set("n", "<C-n>", function()
  require("nvim-tree.api").tree.toggle({ find_file = true, focus = true })
end, { noremap = true, silent = true })

-- Rose-pine uyumlu görünüm
vim.api.nvim_set_hl(0, "NvimTreeNormal", { bg = "none" })
vim.api.nvim_set_hl(0, "NvimTreeNormalNC", { bg = "none" })
vim.api.nvim_set_hl(0, "NvimTreeEndOfBuffer", { bg = "none" })

