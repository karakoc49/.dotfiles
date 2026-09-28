-- ESP-IDF komutlari (:IdfBuild, :IdfFlash, ...) ve <leader>e kisayollari.
local esp = require("config.esp")

-- Uzun sureli terminaller (monitor, openocd) yeniden kullanilsin.
local terms = {}
local function run_term(key, cmd, opts)
  opts = opts or {}
  if terms[key] and terms[key]:is_open() then terms[key]:close() end
  local Terminal = require("toggleterm.terminal").Terminal -- toggleterm ilk kullanimda yuklensin
  terms[key] = Terminal:new({
    cmd = cmd,
    dir = esp.project_root() or vim.fn.getcwd(),
    direction = opts.direction or "horizontal",
    close_on_exit = false,
    hidden = true,
    on_open = function() vim.cmd("startinsert") end,
  })
  terms[key]:toggle()
end

--- idf.py <args>'i ESP-IDF ortami kaynaklanmis bir terminalde calistirir.
local function idf(args, opts)
  local cmd = esp.idf_cmd(args)
  if not cmd then return end
  run_term("idf", vim.o.shell .. " -c " .. vim.fn.shellescape(cmd), opts)
end

--- build sonrasi compile_commands.json'i proje kokune linkler ki
--- clangd (root'ta arar) hemen bulsun.
local function link_compile_commands()
  local root = esp.project_root()
  if not root then return end
  local src, dst = root .. "/build/compile_commands.json", root .. "/compile_commands.json"
  if vim.uv.fs_stat(src) and not vim.uv.fs_stat(dst) then
    vim.uv.fs_symlink(src, dst)
    vim.notify("compile_commands.json proje kokune baglandi", vim.log.levels.INFO)
  end
end

local cmds = {
  IdfBuild      = { "build", "Derle" },
  IdfFlash      = { "flash", "Flash'la" },
  IdfMonitor    = { "monitor", "Seri monitor" },
  IdfFlashMon   = { "flash monitor", "Flash + monitor" },
  IdfMenuconfig = { "menuconfig", "menuconfig" },
  IdfClean      = { "fullclean", "Tam temizlik" },
  IdfSize       = { "size-components", "Bellek kullanimi" },
  IdfReconfig   = { "reconfigure", "CMake yeniden yapilandir" },
}
for name, spec in pairs(cmds) do
  vim.api.nvim_create_user_command(name, function()
    idf(spec[1], { direction = spec[1]:match("menuconfig") and "float" or "horizontal" })
    if spec[1] == "build" then vim.defer_fn(link_compile_commands, 3000) end
  end, { desc = "ESP-IDF: " .. spec[2] })
end

vim.api.nvim_create_user_command("IdfSetTarget", function(a)
  idf("set-target " .. (a.args ~= "" and a.args or "esp32s3"))
end, { nargs = "?", desc = "ESP-IDF: hedef cip sec" })

vim.api.nvim_create_user_command("IdfOpenOCD", function()
  local bin, scripts = esp.openocd(), esp.openocd_scripts()
  if not bin then
    return vim.notify("OpenOCD bulunamadi (~/.espressif/tools/openocd-esp32)", vim.log.levels.ERROR)
  end
  local target = esp.target()
  run_term("openocd", string.format(
    "%s -s %s -f board/%s-builtin.cfg", vim.fn.shellescape(bin), vim.fn.shellescape(scripts), target))
end, { desc = "ESP-IDF: OpenOCD baslat (JTAG, port 3333)" })

vim.api.nvim_create_user_command("IdfInfo", function()
  vim.notify(table.concat({
    "IDF_PATH  : " .. (esp.idf_path() or "BULUNAMADI"),
    "Hedef     : " .. esp.target(),
    "Proje kok : " .. (esp.project_root() or "-"),
    "clangd    : " .. (esp.clangd() or "BULUNAMADI"),
    "gdb       : " .. (esp.gdb() or "BULUNAMADI"),
    "openocd   : " .. (esp.openocd() or "BULUNAMADI"),
  }, "\n"), vim.log.levels.INFO, { title = "ESP-IDF" })
end, { desc = "ESP-IDF: ortam ozeti" })


vim.api.nvim_create_user_command("IdfClangdInit", function()
  local root = esp.project_root()
  if not root then return vim.notify("Proje koku bulunamadi", vim.log.levels.ERROR) end
  local dst = root .. "/.clangd"
  if vim.uv.fs_stat(dst) then
    return vim.notify(".clangd zaten var: " .. dst, vim.log.levels.WARN)
  end
  local src = vim.fn.stdpath("config") .. "/templates/clangd-esp32s3"
  local body = table.concat(vim.fn.readfile(src), "\n")
  -- GCC builtin header dizinlerini bu makineye gore doldur (bkz. esp.gcc_builtin_includes)
  local adds = {}
  for _, dir in ipairs(esp.gcc_builtin_includes()) do
    table.insert(adds, "    - -isystem" .. dir)
  end
  body = body:gsub("#__GCC_BUILTIN_INCLUDES__", table.concat(adds, "\n"), 1)
  vim.fn.writefile(vim.split(body, "\n"), dst)
  vim.notify(".clangd olusturuldu: " .. dst .. "\nNeovim'i yeniden baslatin ki clangd yeni ayari okusun", vim.log.levels.INFO)
end, { desc = "ESP-IDF: projeye .clangd sablonu koy" })

-- Kisayollar
local map = vim.keymap.set
map("n", "<leader>eb", "<cmd>IdfBuild<CR>", { desc = "ESP: Derle" })
map("n", "<leader>ef", "<cmd>IdfFlash<CR>", { desc = "ESP: Flash" })
map("n", "<leader>em", "<cmd>IdfMonitor<CR>", { desc = "ESP: Monitor" })
map("n", "<leader>ea", "<cmd>IdfFlashMon<CR>", { desc = "ESP: Flash + Monitor" })
map("n", "<leader>ec", "<cmd>IdfMenuconfig<CR>", { desc = "ESP: menuconfig" })
map("n", "<leader>es", "<cmd>IdfSize<CR>", { desc = "ESP: Bellek kullanimi" })
map("n", "<leader>eo", "<cmd>IdfOpenOCD<CR>", { desc = "ESP: OpenOCD baslat" })
map("n", "<leader>ei", "<cmd>IdfInfo<CR>", { desc = "ESP: Ortam ozeti" })
map("n", "<leader>ex", "<cmd>IdfClean<CR>", { desc = "ESP: Tam temizlik" })
map("n", "<leader>ed", "<cmd>IdfClangdInit<CR>", { desc = "ESP: .clangd olustur" })
