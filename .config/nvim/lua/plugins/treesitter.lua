-- NOT: nvim-treesitter `main` dalinda. Eski `nvim-treesitter.configs` API'si YOK.
-- Bu dosya main dal API'si (setup/install + vim.treesitter.start) ile yazildi.
return {
  {
    "nvim-treesitter/nvim-treesitter",
    branch = "main",
    lazy = false, -- main dal lazy-load DESTEKLEMIYOR
    build = ":TSUpdate",
    config = function()
      local ts = require("nvim-treesitter")
      ts.setup({ install_dir = vim.fn.stdpath("data") .. "/site" })

      local parsers = {
        -- gomulu / ESP-IDF
        "c", "cpp", "asm", "cmake", "make", "kconfig", "linkerscript", "devicetree",
        -- config & veri
        "json", "yaml", "toml", "ini", "bash", "python",
        -- editor & git
        "lua", "luadoc", "vim", "vimdoc", "query", "regex", "diff", "gitcommit", "gitignore",
        -- dokuman
        "markdown", "markdown_inline", "latex", "bibtex",
        -- diger
        "go", "gomod", "javascript",
      }

      -- Kurulu olmayanlari arka planda kur (kurulu olanlar icin no-op)
      ts.install(parsers)

      -- Highlight + indent'i filetype bazinda ac (main dalda otomatik degil)
      vim.api.nvim_create_autocmd("FileType", {
        group = vim.api.nvim_create_augroup("TSStart", { clear = true }),
        callback = function(ev)
          local lang = vim.treesitter.language.get_lang(ev.match)
          if not lang or not vim.treesitter.language.add(lang) then return end
          vim.treesitter.start(ev.buf, lang)
          vim.bo[ev.buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
        end,
      })
    end,
  },

  -- C icin fonksiyon/parametre text object'leri: vaf, dif, ]f, [f ...
  {
    "nvim-treesitter/nvim-treesitter-textobjects",
    branch = "main",
    dependencies = { "nvim-treesitter/nvim-treesitter" },
    event = "VeryLazy",
    config = function()
      require("nvim-treesitter-textobjects").setup({
        select = { lookahead = true },
        move = { set_jumps = true },
      })

      local sel = require("nvim-treesitter-textobjects.select")
      local move = require("nvim-treesitter-textobjects.move")
      local map = vim.keymap.set

      for key, query in pairs({
        ["af"] = "@function.outer",
        ["if"] = "@function.inner",
        ["ac"] = "@class.outer",
        ["ic"] = "@class.inner",
        ["aa"] = "@parameter.outer",
        ["ia"] = "@parameter.inner",
        ["ab"] = "@block.outer",
        ["ib"] = "@block.inner",
        ["a/"] = "@comment.outer",
      }) do
        map({ "x", "o" }, key, function() sel.select_textobject(query, "textobjects") end,
          { desc = "TS " .. query })
      end

      map({ "n", "x", "o" }, "]f", function() move.goto_next_start("@function.outer", "textobjects") end,
        { desc = "Sonraki fonksiyon" })
      map({ "n", "x", "o" }, "[f", function() move.goto_previous_start("@function.outer", "textobjects") end,
        { desc = "Onceki fonksiyon" })
    end,
  },
}
