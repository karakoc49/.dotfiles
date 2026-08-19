return {
    "nvim-telescope/telescope.nvim",
    dependencies = { "nvim-lua/plenary.nvim" },
    config = function()
        local telescope = require('telescope')
        local builtin = require('telescope.builtin')
        local actions = require('telescope.actions')

        -- TELESCOPE ANA AYARLARI
        telescope.setup({
            defaults = {
                file_ignore_patterns = {
                    "%.git/", "node_modules/", "go/pkg/", "go/bin/", "%.cache/", "%.local/share/"
                },

                -- GÖRSEL DÜZEN VE ÖNİZLEME AYARLARI
                layout_strategy = "horizontal",
                layout_config = {
                    horizontal = {
                        prompt_position = "top", -- Arama çubuğu üstte dursun
                        preview_width = 0.6,     -- Ekranın %60'ı doğrudan kod önizlemesine ayrılsın
                        results_width = 0.4,
                    },
                    width = 0.90,               -- Ekranın %90'ını kaplasın (daha ferah bir görünüm)
                    height = 0.85,
                    preview_cutoff = 120,       -- Terminal çok küçülmediği sürece önizlemeyi kapatma
                },
                sorting_strategy = "ascending", -- Prompt üstte olduğu için sonuçlar yukarıdan aşağı doğru sıralansın

                -- ARAMA EKRANINDAKİ KISAYOLLAR
                mappings = {
                    i = {
                        ["<C-j>"] = actions.move_selection_next,
                        ["<C-k>"] = actions.move_selection_previous,
                        ["<C-c>"] = actions.close,
                    }
                }
            },
            pickers = {
                find_files = {
                    hidden = true,
                    previewer = true -- Önizleyicinin açık olmasını garanti altına alıyoruz
                },
                live_grep = {
                    additional_args = function() return { "--hidden" } end,
                    previewer = true -- İçerik aramasında da önizleyici kesinlikle açık
                }
            }
        })

        -- KISAYOLLAR
        -- Dosya adına göre arama
        vim.keymap.set('n', '<leader>pf', builtin.find_files, { desc = "Dosya Adı Ara" })

        -- Kodun içinde metin arama (Live Grep)
        vim.keymap.set('n', '<leader>ps', builtin.live_grep, { desc = "İçerik (Canlı) Ara" })
    end
}
