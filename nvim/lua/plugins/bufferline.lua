return {
    'akinsho/bufferline.nvim',
    version = "*",
    dependencies = 'nvim-tree/nvim-web-devicons',
    config = function()
        require("bufferline").setup {}
        -- Sekmeler arası geçiş için kısayollar
        vim.keymap.set("n", "<Tab>", "<cmd>BufferLineCycleNext<cr>")
        vim.keymap.set("n", "<S-Tab>", "<cmd>BufferLineCyclePrev<cr>")

        -- MEVCUT SEKMEYİ KAPATMA (Close Buffer)
        -- Space + c kombinasyonu o anki sekmeyi kapatır
        vim.keymap.set("n", "<leader>c", "<cmd>bdelete<cr>", { desc = "Mevcut Sekmeyi Kapat" })
    end
}
