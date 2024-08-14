local telescope = require('telescope')

telescope.setup({
    defaults = {
        scroll_strategy = 'limit',
        layout_strategy = 'vertical',
        layout_config = {
            vertical = {
                height = 0.92,
                width = 0.9,
            };
        },
    },
    extensions = {
        fzf = {},
    }
})
telescope.load_extension('fzf')

local builtin = require('telescope.builtin')
vim.keymap.set('n', '<leader>t', builtin.builtin, {})
vim.keymap.set('n', '<leader>fd', builtin.find_files, {})
vim.keymap.set('n', '<leader>fs', builtin.lsp_document_symbols, {})
vim.keymap.set('n', '<leader>fb', builtin.buffers, {})
