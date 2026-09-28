-- ESP-IDF is akisi: idf.py komutlari, seri monitor, OpenOCD ve compile_commands.json.
-- Neovim'den cikmadan build/flash/monitor dongusu.
return {
  {
    "akinsho/toggleterm.nvim",
    version = "*",
    keys = {
      { "<C-\\>",     "<cmd>ToggleTerm direction=float<CR>", desc = "Terminal (float)" },
      { "<leader>tt", "<cmd>ToggleTerm direction=horizontal<CR>", desc = "Terminal (alt)" },
    },
    cmd = { "ToggleTerm", "TermExec" },
    opts = {
      size = function(term)
        return term.direction == "horizontal" and 18 or vim.o.columns * 0.4
      end,
      open_mapping = nil,
      shade_terminals = false,
      float_opts = { border = "rounded" },
    },
  },

  {
    "folke/which-key.nvim", -- <leader>e grubunu ESP komutlarina ayiriyoruz
    optional = true,
    opts = {
      spec = { { "<leader>e", group = "ESP-IDF" } },
    },
  },
}
