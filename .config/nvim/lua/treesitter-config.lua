require('nvim-treesitter.configs').setup({
    ensure_installed = {'c', 'python', 'zig'},
    -- ignore_install = {},
    highlight = {
    	enable = true,
    },
    indent = {
        enable = true,
        disable = {'python'},
    },
    incremental_selection = {
        enable = true,
        keymaps = {
          init_selection = '<C-n>',
          node_incremental = '<C-n>',
          scope_incremental = '<C-s>',
          node_decremental = '<C-p>',
        },
    },
})
