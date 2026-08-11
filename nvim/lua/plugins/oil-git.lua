return {
    'malewicz1337/oil-git.nvim',
    dependencies = { "stevearc/oil.nvim" },
    opts = {
        show_file_highlights = true,
        show_directory_highlights = false,
        show_ignored_files = true,
    },
    config = function()
        -- Oil'i başlat ve varsayılan dosya gezgini (netrw'nin katili) yap
        require("oil").setup({
            default_file_explorer = true, -- Bu ayar netrw'yi otomatik olarak tamamen öldürür
            columns = {
                "icon",
                -- İleride istersen buraya "permissions", "size" gibi detaylar da ekleyebilirsin
            },
            view_options = {
                -- Başında nokta olan gizli dosyaları (dotfiles) varsayılan olarak göster
                show_hidden = true,
            },
            -- Oil içindeki varsayılan kullanışlı kısayollar
            keymaps = {
                ["g?"] = "actions.show_help",
                ["<CR>"] = "actions.select",
                ["q"] = "actions.close",
                ["-"] = "actions.parent",
                ["_"] = "actions.open_cwd",
                ["`"] = "actions.cd",
                ["~"] = "actions.tcd",
                ["gs"] = "actions.change_sort",
                ["gx"] = "actions.open_external",
                ["g."] = "actions.toggle_hidden",
            },
        })

        -- Senin klasik <leader>pv kısayolun
        vim.keymap.set("n", "<leader>pv", "<CMD>Oil<CR>", { desc = "Oil dosya gezginini aç" })
    end
}
