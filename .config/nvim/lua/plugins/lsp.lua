return {
  "neovim/nvim-lspconfig",
  event = { "BufReadPre", "BufNewFile" },
  dependencies = {
    { "mason-org/mason.nvim", opts = {} },
    "mason-org/mason-lspconfig.nvim",
    "hrsh7th/cmp-nvim-lsp",
    "hrsh7th/cmp-buffer",
    "hrsh7th/cmp-path",
    "hrsh7th/cmp-cmdline",
    "hrsh7th/nvim-cmp",
    "L3MON4D3/LuaSnip",
    "saadparwaiz1/cmp_luasnip",
    "rafamadriz/friendly-snippets",
    { "j-hui/fidget.nvim", opts = {} },
    "onsails/lspkind.nvim",
  },
  config = function()
    local esp = require("config.esp")

    ---------------------------------------------------------------------------
    -- 1) Tum sunuculara ortak ayar (nvim 0.11+ vim.lsp.config API'si).
    --    Onemli: cmp capabilities'i burada veriyoruz; mason-lspconfig v2
    --    sunuculari otomatik `vim.lsp.enable` ettigi icin eski
    --    `lspconfig[server].setup{}` cagrisi artik calismiyor.
    ---------------------------------------------------------------------------
    vim.lsp.config("*", {
      capabilities = require("cmp_nvim_lsp").default_capabilities(),
    })

    ---------------------------------------------------------------------------
    -- 2) clangd: Espressif fork'u varsa onu kullan.
    --    Mainline clangd xtensa target'ini ve -mlongcalls gibi bayraklari
    --    tanimadigi icin ESP-IDF projelerinde her satiri hataya boyar.
    ---------------------------------------------------------------------------
    local clangd_bin = esp.clangd() or vim.fn.exepath("clangd")
    local clangd_cmd = { clangd_bin ~= "" and clangd_bin or "clangd" }
    vim.list_extend(clangd_cmd, {
      "--background-index",
      "--clang-tidy",
      "--header-insertion=never", -- IDF baslik yollari uzun; otomatik ekleme cogu zaman yanlis
      "--completion-style=detailed",
      "--function-arg-placeholders",
      "--pch-storage=memory",
      "--offset-encoding=utf-16",
    })
    -- clangd'nin derleyiciyi sorgulayip builtin include yollarini ogrenmesi icin sart.
    -- Hem Espressif cross-derleyicileri hem de host gcc (IDF disi C dosyalari icin).
    local drivers = esp.toolchain_bins()
    vim.list_extend(drivers, { "/usr/bin/*gcc*", "/usr/bin/*g++*", "/usr/bin/cc", "/usr/bin/c++" })
    table.insert(clangd_cmd, "--query-driver=" .. table.concat(drivers, ","))

    vim.lsp.config("clangd", {
      cmd = clangd_cmd,
      filetypes = { "c", "cpp", "objc", "objcpp" },
      root_markers = { ".clangd", "compile_commands.json", "sdkconfig", "CMakeLists.txt", ".git" },
      init_options = { fallbackFlags = { "-std=gnu17" } },
    })

    vim.lsp.config("lua_ls", {
      settings = {
        Lua = {
          runtime = { version = "LuaJIT" },
          diagnostics = { globals = { "vim" } },
          workspace = { library = vim.api.nvim_get_runtime_file("", true), checkThirdParty = false },
          telemetry = { enable = false },
        },
      },
    })

    require("mason-lspconfig").setup({
      ensure_installed = { "lua_ls", "cmake", "neocmake", "pyright", "bashls" },
      -- clangd'yi mason'dan KURMUYORUZ: esp-clangd zaten ~/.espressif altinda.
      automatic_enable = { exclude = { "clangd" } },
    })
    vim.lsp.enable("clangd") -- kendi tanimimizla elle etkinlestir

    ---------------------------------------------------------------------------
    -- 3) Diagnostics
    ---------------------------------------------------------------------------
    vim.diagnostic.config({
      virtual_text = { prefix = "●", spacing = 4, source = "if_many" },
      signs = {
        text = {
          [vim.diagnostic.severity.ERROR] = " ",
          [vim.diagnostic.severity.WARN] = " ",
          [vim.diagnostic.severity.INFO] = " ",
          [vim.diagnostic.severity.HINT] = " ",
        },
      },
      underline = true,
      update_in_insert = false, -- true iken clangd buyuk IDF projelerinde yaziyi takar
      severity_sort = true,
      float = { border = "rounded", source = true },
    })

    ---------------------------------------------------------------------------
    -- 4) cmp
    ---------------------------------------------------------------------------
    require("luasnip.loaders.from_vscode").lazy_load()
    local cmp = require("cmp")
    local luasnip = require("luasnip")
    local cmp_select = { behavior = cmp.SelectBehavior.Select }

    cmp.setup({
      snippet = { expand = function(args) luasnip.lsp_expand(args.body) end },
      window = { completion = cmp.config.window.bordered(), documentation = cmp.config.window.bordered() },
      mapping = cmp.mapping.preset.insert({
        ["<C-p>"] = cmp.mapping.select_prev_item(cmp_select),
        ["<C-n>"] = cmp.mapping.select_next_item(cmp_select),
        ["<C-b>"] = cmp.mapping.scroll_docs(-4),
        ["<C-f>"] = cmp.mapping.scroll_docs(4),
        ["<C-Space>"] = cmp.mapping.complete(),
        ["<C-e>"] = cmp.mapping.abort(),
        -- select=false: hicbir sey secili degilken <CR> gercek satir sonu olsun
        ["<CR>"] = cmp.mapping.confirm({ select = false }),
        ["<Tab>"] = cmp.mapping(function(fallback)
          if cmp.visible() then cmp.select_next_item()
          elseif luasnip.locally_jumpable(1) then luasnip.jump(1)
          else fallback() end
        end, { "i", "s" }),
        ["<S-Tab>"] = cmp.mapping(function(fallback)
          if cmp.visible() then cmp.select_prev_item()
          elseif luasnip.locally_jumpable(-1) then luasnip.jump(-1)
          else fallback() end
        end, { "i", "s" }),
      }),
      sources = cmp.config.sources(
        { { name = "nvim_lsp" }, { name = "luasnip" }, { name = "path" } },
        { { name = "buffer" } }
      ),
      formatting = {
        format = require("lspkind").cmp_format({ mode = "symbol_text", maxwidth = 50, ellipsis_char = "..." }),
      },
    })

    cmp.setup.cmdline("/", { mapping = cmp.mapping.preset.cmdline(), sources = { { name = "buffer" } } })
    cmp.setup.cmdline(":", {
      mapping = cmp.mapping.preset.cmdline(),
      sources = cmp.config.sources({ { name = "path" } }, { { name = "cmdline" } }),
    })

    ---------------------------------------------------------------------------
    -- 5) LSP kisayollari
    ---------------------------------------------------------------------------
    vim.api.nvim_create_autocmd("LspAttach", {
      group = vim.api.nvim_create_augroup("UserLspConfig", { clear = true }),
      callback = function(ev)
        local function m(mode, lhs, rhs, desc)
          vim.keymap.set(mode, lhs, rhs, { buffer = ev.buf, desc = "LSP: " .. desc })
        end

        m("n", "gd", vim.lsp.buf.definition, "Tanima git")
        m("n", "gD", vim.lsp.buf.declaration, "Bildirime git")
        m("n", "gi", vim.lsp.buf.implementation, "Gerceklestirime git")
        m("n", "gy", vim.lsp.buf.type_definition, "Tip tanimina git")
        m("n", "K", vim.lsp.buf.hover, "Hover dokumantasyon")
        m({ "i", "n" }, "<C-s>", vim.lsp.buf.signature_help, "Imza yardimi")
        m("n", "<leader>vws", vim.lsp.buf.workspace_symbol, "Workspace sembol")
        m("n", "<leader>vd", vim.diagnostic.open_float, "Satir diagnostigi")
        m({ "n", "v" }, "<leader>vca", vim.lsp.buf.code_action, "Code action")
        m("n", "<leader>vrr", vim.lsp.buf.references, "Referanslar")
        m("n", "<leader>vrn", vim.lsp.buf.rename, "Yeniden adlandir")

        -- DUZELTME: eskiden [d ileri, ]d geri gidiyordu (ters bagliydi).
        m("n", "]d", function() vim.diagnostic.jump({ count = 1, float = true }) end, "Sonraki diagnostik")
        m("n", "[d", function() vim.diagnostic.jump({ count = -1, float = true }) end, "Onceki diagnostik")
        m("n", "]e", function()
          vim.diagnostic.jump({ count = 1, severity = vim.diagnostic.severity.ERROR, float = true })
        end, "Sonraki hata")
        m("n", "[e", function()
          vim.diagnostic.jump({ count = -1, severity = vim.diagnostic.severity.ERROR, float = true })
        end, "Onceki hata")

        -- clangd'ye ozel: .c <-> .h gecisi
        local client = vim.lsp.get_client_by_id(ev.data.client_id)
        if client and client.name == "clangd" then
          m("n", "<leader>o", "<cmd>LspClangdSwitchSourceHeader<CR>", "Kaynak/baslik gecisi")
        end

        -- Inlay hint destekleyen sunucular icin ac/kapat
        if client and client:supports_method("textDocument/inlayHint") then
          m("n", "<leader>vh", function()
            vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled({ bufnr = ev.buf }), { bufnr = ev.buf })
          end, "Inlay hint ac/kapat")
        end
      end,
    })
  end,
}
