return {
  "nvim-telescope/telescope.nvim",
  cmd = "Telescope",
  dependencies = {
    "nvim-lua/plenary.nvim",
    { "nvim-telescope/telescope-fzf-native.nvim", build = "make" }, -- C ile derlenen hizli siralayici
    "nvim-telescope/telescope-ui-select.nvim",                      -- vim.ui.select -> telescope (code action menuleri)
  },
  keys = {
    { "<leader>pf", "<cmd>Telescope find_files<CR>",                desc = "Dosya ara" },
    { "<leader>ps", "<cmd>Telescope live_grep<CR>",                 desc = "Icerik ara (live grep)" },
    { "<leader>pw", "<cmd>Telescope grep_string<CR>",               desc = "Imlecteki kelimeyi ara" },
    { "<leader>pb", "<cmd>Telescope buffers<CR>",                   desc = "Acik buffer'lar" },
    { "<leader>ph", "<cmd>Telescope help_tags<CR>",                 desc = "Yardim konulari" },
    { "<leader>pk", "<cmd>Telescope keymaps<CR>",                   desc = "Kisayollar" },
    { "<leader>pr", "<cmd>Telescope resume<CR>",                    desc = "Son aramaya don" },
    { "<leader>pd", "<cmd>Telescope diagnostics<CR>",               desc = "Tum diagnostikler" },
    { "<leader>pq", "<cmd>Telescope quickfix<CR>",                  desc = "Quickfix listesi" },
    { "<leader>po", "<cmd>Telescope lsp_document_symbols<CR>",      desc = "Dosyadaki semboller" },
    { "<leader>pS", "<cmd>Telescope lsp_dynamic_workspace_symbols<CR>", desc = "Proje sembolleri" },
    {
      "<leader>pe",
      function()
        local idf = require("config.esp").idf_path()
        if not idf then return vim.notify("ESP-IDF bulunamadi", vim.log.levels.ERROR) end
        require("telescope.builtin").live_grep({ cwd = idf .. "/components", prompt_title = "ESP-IDF components" })
      end,
      desc = "ESP-IDF kaynaginda ara",
    },
  },
  config = function()
    local telescope = require("telescope")
    local actions = require("telescope.actions")

    telescope.setup({
      defaults = {
        file_ignore_patterns = {
          "%.git/", "node_modules/", "%.cache/", "%.local/share/",
          -- ESP-IDF: derleme ciktilari ve ikili dosyalar arama sonuclarini bogar
          "/build/", "managed_components/", "%.o$", "%.d$", "%.elf$", "%.bin$", "%.map$", "%.a$",
        },
        layout_strategy = "horizontal",
        layout_config = {
          prompt_position = "top",
          horizontal = { preview_width = 0.6, results_width = 0.4 },
          width = 0.90,
          height = 0.85,
          preview_cutoff = 120,
        },
        sorting_strategy = "ascending",
        path_display = { "truncate" },
        mappings = {
          i = {
            ["<C-j>"] = actions.move_selection_next,
            ["<C-k>"] = actions.move_selection_previous,
            ["<C-c>"] = actions.close,
            ["<C-q>"] = actions.smart_send_to_qflist + actions.open_qflist, -- sonuclari quickfix'e at
            ["<C-u>"] = false, -- prompt'u temizlemek yerine onizlemeyi kaydir
          },
        },
      },
      pickers = {
        find_files = { hidden = true },
        live_grep = { additional_args = function() return { "--hidden" } end },
      },
      extensions = {
        fzf = { fuzzy = true, override_generic_sorter = true, override_file_sorter = true },
        ["ui-select"] = { require("telescope.themes").get_dropdown({}) },
      },
    })

    pcall(telescope.load_extension, "fzf")
    pcall(telescope.load_extension, "ui-select")
  end,
}
