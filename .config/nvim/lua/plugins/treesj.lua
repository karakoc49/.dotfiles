return {
    "Wansmer/treesj",
    dependencies = { "nvim-treesitter/nvim-treesitter" }, -- Mevcut treesitter altyapını kullanır
    keys = {
        { "<leader>m", desc = "Split/Join Blok Dönüştürücü (Expand/Shrink)" },
    },
    config = function()
        local treesj = require("treesj")

        treesj.setup({
            use_default_keymaps = false, -- Kendi kısayolumuzu tanımlayacağız
            max_join_length = 150,       -- Tek satıra indirgerken izin verilen max karakter
        })

        -- Space + m tuşuna basarak bloğu genişlet (expand) veya daralt (shrink)
        vim.keymap.set("n", "<leader>m", treesj.toggle)
    end,
}
