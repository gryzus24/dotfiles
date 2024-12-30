require('nvim-treesitter.configs').setup({
    ensure_installed = {'c', 'cpp', 'python', 'zig'},
    highlight = {
    	enable = true,
    },
    indent = {
        enable = false,
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
