return {
  "folke/which-key.nvim",
  event = "VeryLazy",
  opts = {
    preset = "helix",
    spec = {
      { "<leader>e", group = "ESP-IDF" },
      { "<leader>d", group = "Debug" },
      { "<leader>g", group = "Git" },
      { "<leader>l", group = "LaTeX" },
      { "<leader>p", group = "Bul / Gezin" },
      { "<leader>t", group = "Terminal" },
      { "<leader>u", group = "Ac/Kapat" },
      { "<leader>v", group = "LSP" },
      { "<leader>w", group = "Pencere" },
    },
  },
  keys = {
    { "<leader>?", function() require("which-key").show({ global = false }) end, desc = "Buffer kisayollari" },
  },
}
