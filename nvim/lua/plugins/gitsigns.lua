return {
    "lewis6991/gitsigns.nvim",
    config = function()
        require('gitsigns').setup({
            -- 1. Satır içi blame özelliğini aç
            current_line_blame = true,

            -- 2. Görünüm ve gecikme ayarları
            current_line_blame_opts = {
                virt_text = true,
                virt_text_pos = 'eol', -- Satırın hemen bittiği yere yaz
                delay = 300,           -- 300ms gecikme
                ignore_whitespace = false,
            },

            -- 3. Yazı formatı: Yazar, Tarih • Hash • Mesaj
            current_line_blame_formatter = ' 󰊢 <author>, <author_time:%Y-%m-%d> • <abbrev_sha> • <summary>',
        })

        -- İsteğe bağlı: Tek tuşla aç/kapat kısayolu
        vim.keymap.set('n', '<leader>gb', function()
            require('gitsigns').toggle_current_line_blame()
        end, { desc = "Git Blame (Inline) Aç/Kapat" })
    end
}
