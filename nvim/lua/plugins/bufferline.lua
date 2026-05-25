return {
    'akinsho/bufferline.nvim',
    version = "*",
    dependencies = 'nvim-tree/nvim-web-devicons',
    config = function()
        require("bufferline").setup {}

        -- Sekmeler arası geçiş için genel kısayollar
        vim.keymap.set('n', '<Tab>', '<cmd>BufferLineCycleNext<cr>',
            { noremap = true, silent = true, desc = "Sonraki Sekme" })
        vim.keymap.set('n', '<S-Tab>', '<cmd>BufferLineCyclePrev<cr>',
            { noremap = true, silent = true, desc = "Önceki Sekme" })

        -- MEVCUT SEKMEYİ KAPATMA (Close Buffer)
        vim.keymap.set("n", "<leader>c", "<cmd>bdelete<cr>", { desc = "Mevcut Sekmeyi Kapat" })
    end
}
