-- Common Lisp development (SBCL) via nvlime — a SLIME-like environment built on the
-- Swank protocol (REPL, eval/compile-and-load, inspector, condition/restart debugger,
-- cross-reference, trace). nvlime is archived upstream but the Swank protocol is stable;
-- the commit is pinned in lazy-lock.
--
-- First-run server setup and usage are documented in the chat / :help nvlime-start-up.
-- Buffer-local commands use nvlime's own `\` leader in Lisp buffers, e.g.:
--   \rr  start the SBCL server from nvim and connect      \cc  connect to a running server
--   \ss  eval sexp    \ii  interactive eval    \rf  compile+load file    \dd  describe
--   \ww  close nvlime windows    \? or <F1>  help
return {
  {
    'cage433/nvlime',
    dependencies = { 'monkoose/parsley' },
    ft = { 'lisp' },
    init = function()
      -- Place nvlime's output/REPL pane by terminal orientation, mirroring the
      -- toggle_split rule (see init.lua): side (right) when landscape-ish,
      -- bottom when portrait. nvlime reads this once when it loads, so it
      -- reflects the orientation at nvim startup (restart to re-evaluate).
      local position = (vim.o.columns > vim.o.lines * 3.0) and 'right' or 'bottom'
      vim.g.nvlime_config = vim.tbl_deep_extend('force', vim.g.nvlime_config or {}, {
        main_window = { position = position },
      })
    end,
  },

  -- Structural (paredit) editing — slurp/barf/wrap/etc. Lisp is painful without it.
  {
    'julienvincent/nvim-paredit',
    ft = { 'lisp', 'scheme', 'clojure', 'fennel', 'racket' },
    config = function()
      require('nvim-paredit').setup()
    end,
  },
}
