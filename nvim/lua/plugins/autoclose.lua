return {
    "windwp/nvim-autopairs",
    event = "InsertEnter",
    dependencies = { "hrsh7th/nvim-cmp" }, -- Otomatik tamamlama entegrasyonu için
    config = function()
        local autopairs = require("nvim-autopairs")

        autopairs.setup({
            check_ts = true,                          -- Treesitter entegrasyonunu aç (Akıllı mod)
            ts_config = {
                lua = { "string" },                   -- Lua string'leri içinde çiftleme yapma
                go = { "string" },                    -- Go string'leri içinde çiftleme yapma
            },
            disable_filetype = { "TelescopePrompt" }, -- Arama yaparken parantez kapatmaya çalışmasın
        })

        -- 1. EN KRAL ÖZELLİK: nvim-cmp Entegrasyonu
        -- Bir fonksiyon onaylandığında otomatik olarak yanına parantez () koyar.
        local cmp_autopairs = require("nvim-autopairs.completion.cmp")
        local cmp = require("cmp")
        cmp.event:on("confirm_done", cmp_autopairs.on_confirm_done())

        -- 2. LaTeX / VimTeX Kuralını Koruyoruz
        -- Eski konfigürasyonundaki $$ mantığı bozulmasın diye sadece tex ve latex dosyalarında çalışacak $ kuralı:
        local Rule = require('nvim-autopairs.rule')
        autopairs.add_rules({
            Rule("$", "$", { "tex", "latex" })
        })
    end
}
