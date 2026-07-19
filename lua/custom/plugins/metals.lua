-- Scala language server (Metals) plus test/debug running via nvim-dap.
--
-- Metals attaches as a normal LSP client, so the generic LspAttach keymaps in
-- init.lua are active in Scala buffers automatically:
--   grd  goto definition        grr  find references      gri  goto implementation
--   grt  goto type definition   gW   project symbol search  gO  document symbols
--   grn  rename                 gra  code action           K   hover docs
--
-- Running tests: Metals emits "test" / "run" code lenses (via nvim-dap). Put the
-- cursor on the class (or a single test method) line and press <leader>dt.
--   <leader>dt  run the test/main under the cursor
--   <leader>dc  start/continue (also shows a picker of Scala run/test targets)
--   <leader>db  toggle breakpoint          <leader>du  toggle the debug UI
--   <leader>do/di/dO  step over/into/out   <leader>dr  terminate
return {
  {
    'scalameta/nvim-metals',
    dependencies = {
      'nvim-lua/plenary.nvim',
      'mfussenegger/nvim-dap',
      { 'rcarriga/nvim-dap-ui', dependencies = { 'nvim-neotest/nvim-nio' } },
    },
    ft = { 'scala', 'sbt' },
    opts = function()
      local metals_config = require('metals').bare_config()

      metals_config.settings = {
        -- Run Metals/Bloop on the same JDK 25 the rest of the toolchain uses (shell,
        -- sbt, IntelliJ's BSP all use 25.0.3-zulu). Matching JDKs keeps a single
        -- consistent Zinc incremental cache, avoiding recompiles when switching tools.
        javaHome = vim.fn.expand '~/.sdkman/candidates/java/25.0.3-zulu',
        -- Inline hints that are commonly useful in Scala.
        showImplicitArguments = true,
        showInferredType = true,
      }

      -- Use blink.cmp's capabilities so autocompletion works in Scala buffers.
      metals_config.capabilities = require('blink.cmp').get_lsp_capabilities()

      metals_config.on_attach = function(_, bufnr)
        -- Register Metals' DAP configurations so run/test code lenses launch via nvim-dap.
        require('metals').setup_dap()
        -- Run the test/main code lens under the cursor.
        vim.keymap.set('n', '<leader>dt', vim.lsp.codelens.run, { buffer = bufnr, desc = 'Debug: Run [T]est/main under cursor' })
      end

      return metals_config
    end,
    config = function(self, metals_config)
      -- nvim-dap + dap-ui: auto-open the debug UI when a run/test session starts.
      -- Intentionally do NOT auto-close on finish, so test output/results stay
      -- visible after the run. Dismiss the panel yourself with <leader>du.
      local dap = require 'dap'
      local dapui = require 'dapui'
      dapui.setup()
      dap.listeners.after.event_initialized['dapui_config'] = function() dapui.open() end

      -- Debug controls (global; only fire once a session is running).
      vim.keymap.set('n', '<leader>dc', dap.continue, { desc = 'Debug: Start/[C]ontinue' })
      vim.keymap.set('n', '<leader>db', dap.toggle_breakpoint, { desc = 'Debug: Toggle [B]reakpoint' })
      vim.keymap.set('n', '<leader>do', dap.step_over, { desc = 'Debug: Step [O]ver' })
      vim.keymap.set('n', '<leader>di', dap.step_into, { desc = 'Debug: Step [I]nto' })
      vim.keymap.set('n', '<leader>dO', dap.step_out, { desc = 'Debug: Step Out' })
      vim.keymap.set('n', '<leader>dr', dap.terminate, { desc = 'Debug: Te[r]minate' })
      vim.keymap.set('n', '<leader>du', dapui.toggle, { desc = 'Debug: Toggle [U]I' })
      -- Evaluate the expression under the cursor (normal) or the visual selection.
      vim.keymap.set({ 'n', 'v' }, '<leader>de', function() dapui.eval() end, { desc = 'Debug: [E]valuate expression' })

      -- Label the <leader>d group in which-key, if present.
      local ok, wk = pcall(require, 'which-key')
      if ok then wk.add { { '<leader>d', group = '[D]ebug/Test' } } end

      -- Attach Metals on Scala files.
      local group = vim.api.nvim_create_augroup('nvim-metals', { clear = true })
      vim.api.nvim_create_autocmd('FileType', {
        pattern = self.ft,
        group = group,
        callback = function()
          require('metals').initialize_or_attach(metals_config)
        end,
      })

      -- Keep the test/run code lenses refreshed as you move around Scala buffers.
      vim.api.nvim_create_autocmd({ 'BufEnter', 'CursorHold', 'InsertLeave' }, {
        group = group,
        pattern = { '*.scala', '*.sbt' },
        callback = function() pcall(vim.lsp.codelens.refresh, { bufnr = 0 }) end,
      })
    end,
  },
}
