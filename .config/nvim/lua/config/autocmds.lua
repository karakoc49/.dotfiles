local augroup = vim.api.nvim_create_augroup("UserAutocmds", { clear = true })

-- Yank yapılan bölgeyi kısaca vurgula
vim.api.nvim_create_autocmd("TextYankPost", {
  group = augroup,
  callback = function() vim.hl.on_yank({ timeout = 150 }) end,
})

-- Dosyayı en son bırakılan satırda aç
vim.api.nvim_create_autocmd("BufReadPost", {
  group = augroup,
  callback = function(ev)
    local mark = vim.api.nvim_buf_get_mark(ev.buf, '"')
    if mark[1] > 0 and mark[1] <= vim.api.nvim_buf_line_count(ev.buf) then
      pcall(vim.api.nvim_win_set_cursor, 0, mark)
    end
  end,
})

-- Olmayan dizine kaydederken dizini oluştur
vim.api.nvim_create_autocmd("BufWritePre", {
  group = augroup,
  callback = function(ev)
    if ev.match:match("^%w%w+://") then return end
    vim.fn.mkdir(vim.fn.fnamemodify(vim.uv.fs_realpath(ev.match) or ev.match, ":p:h"), "p")
  end,
})

-- q ile kapatılabilir yardımcı buffer'lar
vim.api.nvim_create_autocmd("FileType", {
  group = augroup,
  pattern = { "help", "qf", "man", "checkhealth", "lspinfo", "fugitive", "git" },
  callback = function(ev)
    vim.bo[ev.buf].buflisted = false
    vim.keymap.set("n", "q", "<cmd>close<CR>", { buffer = ev.buf, silent = true })
  end,
})

-- ESP-IDF / gömülü dosya tiplerini tanı
vim.filetype.add({
  filename = {
    ["sdkconfig"] = "config",
    ["sdkconfig.defaults"] = "config",
    ["CMakeLists.txt"] = "cmake",
    ["idf_component.yml"] = "yaml",
    ["dependencies.lock"] = "yaml",
  },
  pattern = {
    ["Kconfig.*"] = "kconfig",
    ["sdkconfig%..*"] = "config",
    [".*%.ld"] = "ld",
    [".*/soc/.*%.h"] = "c",
  },
  extension = {
    S = "asm", -- Xtensa assembly (.S)
    inc = "c",
  },
})

-- C dosyalarında ESP-IDF stili (4 boşluk, 120 sütun)
vim.api.nvim_create_autocmd("FileType", {
  group = augroup,
  pattern = { "c", "cpp" },
  callback = function()
    vim.bo.commentstring = "// %s"
    vim.opt_local.cindent = true
  end,
})
