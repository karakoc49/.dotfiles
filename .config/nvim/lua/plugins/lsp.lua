return {
    "neovim/nvim-lspconfig",
    dependencies = {
        "williamboman/mason.nvim",
        "williamboman/mason-lspconfig.nvim",
        "hrsh7th/cmp-nvim-lsp",
        "hrsh7th/cmp-buffer",
        "hrsh7th/cmp-path",
        "hrsh7th/cmp-cmdline",
        "hrsh7th/nvim-cmp",
        "L3MON4D3/LuaSnip",
        "saadparwaiz1/cmp_luasnip",
        "j-hui/fidget.nvim",
        "onsails/lspkind.nvim",
    },
    config = function()
        require("fidget").setup({})
        require("mason").setup()
        require("mason-lspconfig").setup({
            ensure_installed = {
                "lua_ls",
                "gopls",
                "clangd",
                "pyright",
            },
            handlers = {
                function(server_name)
                    require("lspconfig")[server_name].setup {}
                end,

                ["lua_ls"] = function()
                    local lspconfig = require("lspconfig")
                    lspconfig.lua_ls.setup {
                        settings = {
                            Lua = {
                                diagnostics = {
                                    globals = { "vim" }
                                }
                            }
                        }
                    }
                end,
            }
        })

        -- ==========================================
        --  YENİ: ANLIK HATA GÖSTERİMİ (DIAGNOSTICS)
        -- ==========================================
        vim.diagnostic.config({
            virtual_text = {
                prefix = '●',
                spacing = 4,
                source = "if_many",
                -- İŞTE SİHİRLİ DOKUNUŞ: Sağ taraftaki yazıları SADECE 'ERROR' için gösterir.
                -- Warning (Uyarı), Hint (İpucu) ve Info (Bilgi) seviyeleri sağda metin olarak çıkmaz.
                severity = vim.diagnostic.severity.ERROR,
            },

            -- Uyarıları (Warning) sol tarafta sadece ufak bir ikon veya altı çizili olarak bırakıyoruz.
            -- Böylece ekranın kirlenmez ama nerede <leader>vd yapman gerektiğini bilirsin.
            signs = true,
            underline = true,

            update_in_insert = true,
            severity_sort = true,
        })

        local cmp = require('cmp')
        local cmp_select = { behavior = cmp.SelectBehavior.Select }

        cmp.setup({
            snippet = {
                expand = function(args)
                    require('luasnip').lsp_expand(args.body)
                end,
            },
            mapping = cmp.mapping.preset.insert({
                ['<C-p>'] = cmp.mapping.select_prev_item(cmp_select),
                ['<C-n>'] = cmp.mapping.select_next_item(cmp_select),
                ['<C-Space>'] = cmp.mapping.complete(),
                ['<CR>'] = cmp.mapping.confirm({ select = true }),
                ['<Tab>'] = cmp.mapping(function(fallback)
                    local luasnip = require('luasnip')
                    if cmp.visible() then
                        cmp.select_next_item()
                    elseif luasnip.expand_or_jumpable() then
                        luasnip.expand_or_jump()
                    else
                        fallback()
                    end
                end, { 'i', 's' }),
                ['<S-Tab>'] = cmp.mapping(function(fallback)
                    local luasnip = require('luasnip')
                    if cmp.visible() then
                        cmp.select_prev_item()
                    elseif luasnip.jumpable(-1) then
                        luasnip.jump(-1)
                    else
                        fallback()
                    end
                end, { 'i', 's' }),
            }),
            sources = cmp.config.sources({
                { name = 'nvim_lsp' },
                { name = 'luasnip' },
            }, {
                { name = 'buffer' },
            }),
            formatting = {
                format = require('lspkind').cmp_format({
                    mode = 'symbol_text',
                    maxwidth = 50,
                    ellipsis_char = '...',
                })
            },
        })

        vim.api.nvim_create_autocmd('LspAttach', {
            group = vim.api.nvim_create_augroup('UserLspConfig', {}),
            callback = function(ev)
                local opts = { buffer = ev.buf }
                vim.keymap.set('n', 'gd', function() vim.lsp.buf.definition() end, opts)
                vim.keymap.set('n', 'K', function() vim.lsp.buf.hover() end, opts)
                vim.keymap.set('n', '<leader>vws', function() vim.lsp.buf.workspace_symbol() end, opts)
                vim.keymap.set('n', '<leader>vd', function() vim.diagnostic.open_float() end, opts)
                vim.keymap.set('n', '[d', function() vim.diagnostic.goto_next() end, opts)
                vim.keymap.set('n', ']d', function() vim.diagnostic.goto_prev() end, opts)
                vim.keymap.set('n', '<leader>vca', function() vim.lsp.buf.code_action() end, opts)
                vim.keymap.set('n', '<leader>vrr', function() vim.lsp.buf.references() end, opts)
                vim.keymap.set('n', '<leader>vrn', function() vim.lsp.buf.rename() end, opts)
            end,
        })
    end
}
