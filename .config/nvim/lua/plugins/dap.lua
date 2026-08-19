return {
    "mfussenegger/nvim-dap",
    dependencies = {
        "rcarriga/nvim-dap-ui",
        "nvim-neotest/nvim-nio",
        "leoluz/nvim-dap-go",           -- Go için eklendi
        "mfussenegger/nvim-dap-python", -- Python için eklendi
    },
    config = function()
        local dap, dapui = require("dap"), require("dapui")
        dapui.setup()

        -- Adaptör Kurulumları
        require("dap-go").setup()
        -- Sistemindeki global python veya sanal ortamdaki debugpy'ı otomatik yakalar
        require("dap-python").setup("python")

        -- C/C++ için (GDB altyapısı)
        dap.configurations.cpp = {
            {
                name = 'Launch file',
                type = 'cppbg',
                request = 'launch',
                program = function()
                    return vim.fn.input('Path to executable: ', vim.fn.getcwd() .. '/', 'file')
                end,
                cwd = '${workspaceRoot}',
                stopAtEntry = false,
            },
        }
        dap.configurations.c = dap.configurations.cpp

        dap.listeners.before.attach.dapui_config = function() dapui.open() end
        dap.listeners.before.launch.dapui_config = function() dapui.open() end
        dap.listeners.after.event_terminated.dapui_config = function() dapui.close() end
        dap.listeners.after.event_exited.dapui_config = function() dapui.close() end

        -- Mevcut kısayolların
        vim.keymap.set('n', '<F5>', function() require('dap').continue() end)
        vim.keymap.set('n', '<F10>', function() require('dap').step_over() end)
        vim.keymap.set('n', '<F11>', function() require('dap').step_into() end)
        vim.keymap.set('n', '<F12>', function() require('dap').step_out() end)
        vim.keymap.set('n', '<leader>b', function() require('dap').toggle_breakpoint() end)
    end
}
