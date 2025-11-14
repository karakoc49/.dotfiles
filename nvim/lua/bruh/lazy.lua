-- Bootstrap lazy.nvim
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  local lazyrepo = "https://github.com/folke/lazy.nvim.git"
  local out = vim.fn.system({ "git", "clone", "--filter=blob:none", "--branch=stable", lazyrepo, lazypath })
  if vim.v.shell_error ~= 0 then
    vim.api.nvim_echo({
      { "Failed to clone lazy.nvim:\n", "ErrorMsg" },
      { out, "WarningMsg" },
      { "\nPress any key to exit..." },
    }, true, {})
    vim.fn.getchar()
    os.exit(1)
  end
end
vim.opt.rtp:prepend(lazypath)

-- Make sure to setup `mapleader` and `maplocalleader` before
-- loading lazy.nvim so that mappings are correct.
-- This is also a good place to setup other settings (vim.opt)
vim.g.mapleader = " "
vim.g.maplocalleader = "\\"

-- Setup lazy.nvim
-- Setup lazy.nvim
require("lazy").setup({
  spec = {

    ---------------------------------------------------------
    -- Packer’dan lazy.nvim’e dönüştürülen plugin’ler
    ---------------------------------------------------------

    -- telescope
    {
      "nvim-telescope/telescope.nvim",
      version = "0.1.8",
      dependencies = { "nvim-lua/plenary.nvim" },
    },

    -- rose-pine colorscheme
    {
      "rose-pine/neovim",
      name = "rose-pine",
      config = function()
        vim.cmd("colorscheme rose-pine")
      end,
    },

    -- Treesitter
    {
      "nvim-treesitter/nvim-treesitter",
      build = ":TSUpdate",
    },
    { "nvim-treesitter/playground" },

    -- Harpoon
    { "ThePrimeagen/harpoon" },

    -- Undotree
    { "mbbill/undotree" },

    -- vim-fugitive
    { "tpope/vim-fugitive" },

    -- Autoclose
    { "m4xshen/autoclose.nvim", config = true },

    -- Lualine
    {
      "nvim-lualine/lualine.nvim",
      dependencies = { "nvim-tree/nvim-web-devicons" },
      config = function()
        require("lualine").setup()
      end,
    },

    -- Web devicons
    { "nvim-tree/nvim-web-devicons" },

    -- File Tree
    { "nvim-tree/nvim-tree.lua",
      version = "*",
      lazy = false,
      dependencies = {
        "nvim-tree/nvim-web-devicons",
      },
      config = function()
        require("nvim-tree").setup {}
      end, },
  },

  install = { colorscheme = { "habamax" } },
  checker = { enabled = true },
})

