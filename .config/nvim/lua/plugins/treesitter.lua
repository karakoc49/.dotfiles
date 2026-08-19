return {
    "nvim-treesitter/nvim-treesitter",
    build = ":TSUpdate",
    config = function()
        -- Modül yüklemeyi dene, başarısız olursa (status_ok = false) sessizce çık
        local status_ok, configs = pcall(require, "nvim-treesitter.configs")
        if not status_ok then
            return
        end

        configs.setup({
            ensure_installed = { "go", "javascript", "python", "c", "lua", "vim", "vimdoc", "query", "markdown", "markdown_inline" },
            sync_install = false,
            auto_install = true,
            highlight = {
                enable = true,
                additional_vim_regex_highlighting = false,
            },
            indent = {
                enable = true
            },
        })
    end
}
