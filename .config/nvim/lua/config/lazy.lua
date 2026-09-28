local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  local lazyrepo = "https://github.com/folke/lazy.nvim.git"
  local out = vim.fn.system({ "git", "clone", "--filter=blob:none", "--branch=stable", lazyrepo, lazypath })
  if vim.v.shell_error ~= 0 then
    vim.api.nvim_echo({
      { "lazy.nvim klonlanamadi:\n", "ErrorMsg" },
      { out,                         "WarningMsg" },
      { "\nCikmak icin bir tusa bas..." },
    }, true, {})
    vim.fn.getchar()
    os.exit(1)
  end
end
vim.opt.rtp:prepend(lazypath)

require("lazy").setup({
  spec = { { import = "plugins" } },
  install = { colorscheme = { "rose-pine", "habamax" } },
  -- Guncelleme kontrolu her aciliste ag istegi yapiyordu; haftalik yeter.
  checker = { enabled = true, notify = false, frequency = 604800 },
  change_detection = { enabled = true, notify = false },
  performance = {
    rtp = {
      -- Kullanilmayan yerlesik eklentileri kapat (acilis suresi)
      disabled_plugins = {
        -- matchit/matchparen KAPATILMADI: C'de % ile ayrac ve #if/#endif atlamasi lazim.
        "gzip", "tarPlugin", "zipPlugin", "tohtml", "tutor", "rplugin", "netrwPlugin",
      },
    },
  },
})
