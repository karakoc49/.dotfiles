return {
  "mfussenegger/nvim-dap",
  dependencies = {
    "rcarriga/nvim-dap-ui",
    "nvim-neotest/nvim-nio",
    "theHamsta/nvim-dap-virtual-text",
    "leoluz/nvim-dap-go",
    "mfussenegger/nvim-dap-python",
  },
  keys = {
    { "<F5>",       function() require("dap").continue() end,          desc = "DAP: Devam / Baslat" },
    { "<F10>",      function() require("dap").step_over() end,         desc = "DAP: Step over" },
    { "<F11>",      function() require("dap").step_into() end,         desc = "DAP: Step into" },
    { "<S-F11>",    function() require("dap").step_out() end,          desc = "DAP: Step out" },
    { "<leader>db", function() require("dap").toggle_breakpoint() end, desc = "DAP: Breakpoint" },
    {
      "<leader>dB",
      function() require("dap").set_breakpoint(vim.fn.input("Kosul: ")) end,
      desc = "DAP: Kosullu breakpoint",
    },
    { "<leader>du", function() require("dapui").toggle() end,      desc = "DAP: UI ac/kapat" },
    { "<leader>dr", function() require("dap").repl.toggle() end,   desc = "DAP: REPL" },
    { "<leader>dx", function() require("dap").terminate() end,     desc = "DAP: Sonlandir" },
    { "<leader>dc", function() require("dap").run_to_cursor() end, desc = "DAP: Imlece kadar cal" },
  },
  config = function()
    local dap, dapui = require("dap"), require("dapui")
    local esp = require("config.esp")

    dapui.setup()
    require("nvim-dap-virtual-text").setup({})

    -- <F12> terminallerde cakisiyor; step out'u <S-F11>'e aldik (keys tablosunda).
    vim.fn.sign_define("DapBreakpoint", { text = "", texthl = "DiagnosticSignError" })
    vim.fn.sign_define("DapStopped", { text = "", texthl = "DiagnosticSignWarn", linehl = "Visual" })

    ---------------------------------------------------------------------------
    -- Adaptorler
    ---------------------------------------------------------------------------
    pcall(function() require("dap-go").setup() end)
    pcall(function() require("dap-python").setup("python3") end)

    -- Host tarafi (unit test / simulasyon) icin sistem GDB'si.
    -- GDB 14+ dahili DAP sunucusu barindirir; ayri bir adaptor kurmaya gerek yok.
    dap.adapters.gdb = {
      type = "executable",
      command = "gdb",
      args = { "--interpreter=dap", "--eval-command", "set print pretty on" },
    }

    -- ESP32 hedefi: Espressif'in xtensa/riscv GDB'si, OpenOCD'ye remote baglanir.
    local esp_gdb = esp.gdb()
    if esp_gdb then
      dap.adapters.esp = {
        type = "executable",
        command = esp_gdb,
        args = { "--interpreter=dap", "--eval-command", "set print pretty on" },
      }
    end

    ---------------------------------------------------------------------------
    -- Konfigurasyonlar
    ---------------------------------------------------------------------------
    --- build/<proje>.elf dosyasini otomatik bul.
    local function elf_path()
      local root = esp.project_root() or vim.fn.getcwd()
      local hits = vim.fn.glob(root .. "/build/*.elf", false, true)
      if #hits == 1 then return hits[1] end
      return vim.fn.input("ELF yolu: ", root .. "/build/", "file")
    end

    dap.configurations.c = {
      {
        name = "ESP32: OpenOCD'ye baglan (3333)",
        type = "esp",
        request = "attach",
        program = elf_path,
        target = "localhost:3333",
        cwd = "${workspaceFolder}",
        stopAtBeginningOfMainSubprogram = false,
      },
      {
        name = "ESP32: Flash + app_main'de dur",
        type = "esp",
        request = "attach",
        program = elf_path,
        target = "localhost:3333",
        cwd = "${workspaceFolder}",
        stopAtBeginningOfMainSubprogram = true,
      },
      {
        name = "Host: yerel calistirilabilir (gdb)",
        type = "gdb",
        request = "launch",
        program = function()
          return vim.fn.input("Calistirilabilir yol: ", vim.fn.getcwd() .. "/", "file")
        end,
        cwd = "${workspaceFolder}",
        stopAtBeginningOfMainSubprogram = false,
      },
    }
    dap.configurations.cpp = dap.configurations.c

    ---------------------------------------------------------------------------
    -- UI otomasyonu
    ---------------------------------------------------------------------------
    dap.listeners.before.attach.dapui_config = function() dapui.open() end
    dap.listeners.before.launch.dapui_config = function() dapui.open() end
    dap.listeners.before.event_terminated.dapui_config = function() dapui.close() end
    dap.listeners.before.event_exited.dapui_config = function() dapui.close() end
  end,
}
