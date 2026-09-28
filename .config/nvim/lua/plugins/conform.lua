return {
  "stevearc/conform.nvim",
  event = { "BufWritePre" },
  cmd = { "ConformInfo" },
  keys = {
    {
      "<leader>f",
      function() require("conform").format({ async = true, lsp_format = "fallback" }) end,
      mode = { "n", "v" },
      desc = "Buffer'i formatla",
    },
    {
      "<leader>uf",
      function()
        vim.g.disable_autoformat = not vim.g.disable_autoformat
        vim.notify("Kaydederken format: " .. (vim.g.disable_autoformat and "KAPALI" or "ACIK"))
      end,
      desc = "Kaydederken formatlamayi ac/kapat",
    },
  },
  opts = {
    formatters_by_ft = {
      lua = { "stylua" },
      go = { "goimports", "gofmt" },
      python = { "ruff_format" },
      c = { "clang-format" },
      cpp = { "clang-format" },
      sh = { "shfmt" },
      json = { "jq" },
      -- Formatter yoksa sessizce LSP'ye dus, hata basma
      ["_"] = { lsp_format = "fallback" },
    },
    -- ESP-IDF .clang-format dosyasi projede yoksa IDF stiline yakin varsayilan
    formatters = {
      ["clang-format"] = {
        prepend_args = function(_, ctx)
          if vim.fs.root(ctx.filename, { ".clang-format" }) then return {} end
          return { "--style={BasedOnStyle: Google, IndentWidth: 4, ColumnLimit: 120, SortIncludes: false}" }
        end,
      },
    },
    format_on_save = function(bufnr)
      -- Kaydederken formatlama kapaliysa veya IDF'in kendi kaynak agacindaysak dokunma
      if vim.g.disable_autoformat or vim.b[bufnr].disable_autoformat then return end
      local name = vim.api.nvim_buf_get_name(bufnr)
      if name:match("/build/") or name:match("/managed_components/") or name:match("/esp%-idf/") then
        return
      end
      return { timeout_ms = 1000, lsp_format = "fallback" }
    end,
  },
}
