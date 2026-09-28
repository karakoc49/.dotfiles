-- ESP-IDF ortamini kesfeden yardimci modul.
-- Tek kaynak: burada bulunan yollar hem LSP (esp-clangd) hem DAP (openocd + xtensa gdb)
-- hem de idf.py komutlari tarafindan kullanilir.
local M = {}

local ESPRESSIF = vim.env.IDF_TOOLS_PATH or (vim.env.HOME .. "/.espressif")

-- ~/.espressif/tools/<tool>/<surum>/... altindaki ilk eslesen dosyayi bulur.
local function find(tool, glob)
  local hits = vim.fn.glob(ESPRESSIF .. "/tools/" .. tool .. "/*/" .. glob, false, true)
  table.sort(hits)
  return hits[#hits] -- en yeni surum
end

--- ESP-IDF kaynak agacinin yolu.
function M.idf_path()
  if vim.env.IDF_PATH and vim.uv.fs_stat(vim.env.IDF_PATH .. "/export.sh") then
    return vim.env.IDF_PATH
  end
  local env = ESPRESSIF .. "/idf-env.json"
  local fd = io.open(env, "r")
  if fd then
    local ok, data = pcall(vim.json.decode, fd:read("*a"))
    fd:close()
    if ok and data.idfInstalled then
      for _, info in pairs(data.idfInstalled) do
        if info.path and vim.uv.fs_stat(info.path .. "/export.sh") then return info.path end
      end
    end
  end
  return nil
end

--- Espressif'in xtensa/riscv destekli clangd fork'u (mainline clangd xtensa bilmez).
function M.clangd() return find("esp-clangd", "esp-clangd/bin/clangd") end

--- Hedefe ozel GDB, orn. xtensa-esp32s3-elf-gdb (RISC-V hedeflerde riscv32-esp-elf-gdb).
function M.gdb(target)
  target = target or M.target()
  -- esp32c*/h*/p* RISC-V cekirdekli, geri kalani Xtensa.
  if target:match("^esp32[chp]") then
    return find("riscv32-esp-elf-gdb", "riscv32-esp-elf-gdb/bin/riscv32-esp-elf-gdb")
  end
  return find("xtensa-esp-elf-gdb", "xtensa-esp-elf-gdb/bin/xtensa-" .. target .. "-elf-gdb")
end

function M.openocd() return find("openocd-esp32", "openocd-esp32/bin/openocd") end

function M.openocd_scripts()
  local bin = M.openocd()
  return bin and vim.fs.normalize(vim.fs.dirname(bin) .. "/../share/openocd/scripts") or nil
end

--- Derleyicinin bin dizini (clangd --query-driver icin gerekli).
function M.toolchain_bins()
  local out = {}
  for _, t in ipairs({ "xtensa-esp-elf", "riscv32-esp-elf" }) do
    local gcc = find(t, t .. "/bin/*-gcc")
    if gcc then table.insert(out, vim.fs.dirname(gcc) .. "/*") end
  end
  return out
end

--- GCC'nin builtin header dizini (stddef.h, stdarg.h, stdint.h ...).
--- Espressif'in esp-clangd dagitimi yalnizca bin/ iceriyor; kendi
--- lib/clang/<N>/include resource dizini YOK. Bu yuzden builtin header'lari
--- GCC'den odunc almak gerekiyor, yoksa her dosyada "stddef.h not found" cikar.
function M.gcc_builtin_includes()
  local out = {}
  for _, t in ipairs({ "xtensa-esp-elf", "riscv32-esp-elf" }) do
    local hit = find(t, t .. "/lib/gcc/" .. t .. "/*/include")
    if hit then table.insert(out, hit) end
  end
  return out
end

--- Proje kokunu bul: CMakeLists.txt + sdkconfig ya da .git iceren en yakin dizin.
function M.project_root(bufnr)
  local start = vim.api.nvim_buf_get_name(bufnr or 0)
  if start == "" then start = vim.fn.getcwd() end
  return vim.fs.root(start, { "sdkconfig", "sdkconfig.defaults", "CMakeLists.txt", ".git" })
end

--- sdkconfig'ten aktif hedefi oku, yoksa esp32s3 varsay.
function M.target()
  local root = M.project_root()
  if root then
    local fd = io.open(root .. "/sdkconfig", "r")
    if fd then
      for line in fd:lines() do
        local t = line:match('^CONFIG_IDF_TARGET="(.-)"')
        if t then fd:close() return t end
      end
      fd:close()
    end
  end
  return vim.g.idf_target or "esp32s3"
end

--- idf.py'yi dogru ortam degiskenleriyle calistiran shell komutu uretir.
function M.idf_cmd(args)
  local idf = M.idf_path()
  if not idf then
    vim.notify("ESP-IDF bulunamadi (IDF_PATH bos, idf-env.json okunamadi)", vim.log.levels.ERROR)
    return nil
  end
  return string.format("set -e; . %q >/dev/null 2>&1; idf.py %s", idf .. "/export.sh", args)
end

return M
