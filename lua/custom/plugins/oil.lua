return {
  {
    'stevearc/oil.nvim',
    opts = {
      default_file_explorer = true,
    },
    dependencies = { { 'nvim-tree/nvim-web-devicons', lazy = true } },
    keys = {
      { '-', '<cmd>Oil<cr>', desc = 'Open parent directory' },
    },
  },
}
