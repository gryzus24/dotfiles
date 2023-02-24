local set = vim.opt

set.mouse = ''
set.guicursor = ''

set.expandtab = true
set.shiftwidth = 4
set.tabstop = 8

set.number = true
set.relativenumber = false
set.scrolloff = 7
set.colorcolumn = '80'

set.incsearch = true
set.ignorecase = true
set.smartcase = true

set.path = '**'

vim.keymap.set('n', '<cr>', ':noh<cr><cr>')
--vim.keymap.set('i', '{', '{<cr>}<C-o>O')
vim.keymap.set('n', '<leader>c<cr>', ':-1read ~/.vim/snippets/c.snip<cr>4j')
vim.keymap.set('n', '<leader>java<cr>', ':-1read ~/.vim/snippets/java.snip<cr>2j')
vim.keymap.set('n', '<leader>make<cr>', ':-1read ~/.vim/snippets/make.snip<cr>')
vim.keymap.set('n', '<leader>python<cr>', ':-1read ~/.vim/snippets/python.snip<cr>4j')
vim.keymap.set('n', '<leader>latex<cr>', ':-1read ~/.vim/snippets/latex.snip<cr>15j')
vim.keymap.set('n', '<leader>latexmake<cr>', ':-1read ~/.vim/snippets/latexmake.snip<cr>15j')

vim.keymap.set('n', '<leader>am', ':w | !make')

vim.diagnostic.config({virtual_text = false})

local Plug = vim.fn['plug#']
vim.call('plug#begin', '~/.local/share/nvim/plugged')

Plug('neovim/nvim-lspconfig')
Plug('nvim-treesitter/nvim-treesitter', {['do'] = ':TSUpdate'})
Plug('nvim-treesitter/playground')

vim.call('plug#end')

require('nvim-treesitter.configs').setup {
    -- A list of parser names, or 'all'
    ensure_installed = {'c', 'java', 'python'},

    -- Install parsers synchronously (only applied to `ensure_installed`)
    sync_install = false,
    auto_install = true,

    highlight = {
        enable = true,
    },
    indent = {
        enable = false,
    },
}

-- See `:help vim.diagnostic.*` for documentation on any of the below functions
local opts = {noremap = true, silent = true}
vim.keymap.set('n', '<space>e', vim.diagnostic.open_float, opts)
vim.keymap.set('n', '[d',       vim.diagnostic.goto_prev,  opts)
vim.keymap.set('n', ']d',       vim.diagnostic.goto_next,  opts)
vim.keymap.set('n', '<space>q', vim.diagnostic.setloclist, opts)

local on_attach = function(client, bufnr)
    -- Enable completion triggered by <c-x><c-o>
    vim.api.nvim_buf_set_option(bufnr, 'omnifunc', 'v:lua.vim.lsp.omnifunc')

    -- See `:help vim.lsp.*` for documentation on any of the below functions
    local bufopts = {noremap = true, silent = true, buffer = bufnr}
    vim.keymap.set('n', 'gD', vim.lsp.buf.declaration, bufopts)
    vim.keymap.set('n', 'gd', vim.lsp.buf.definition, bufopts)
    vim.keymap.set('n', 'K', vim.lsp.buf.hover, bufopts)
    -- vim.keymap.set('n', 'gi', vim.lsp.buf.implementation, bufopts)
    vim.keymap.set('n', '<C-k>', vim.lsp.buf.signature_help, bufopts)
    vim.keymap.set('n', '<space>wa', vim.lsp.buf.add_workspace_folder, bufopts)
    vim.keymap.set('n', '<space>wr', vim.lsp.buf.remove_workspace_folder, bufopts)
    vim.keymap.set('n', '<space>wl', function()
      print(vim.inspect(vim.lsp.buf.list_workspace_folders()))
    end, bufopts)
    vim.keymap.set('n', '<space>D', vim.lsp.buf.type_definition, bufopts)
    vim.keymap.set('n', '<space>rn', vim.lsp.buf.rename, bufopts)
    vim.keymap.set('n', '<space>ca', vim.lsp.buf.code_action, bufopts)
    vim.keymap.set('n', 'gr', vim.lsp.buf.references, bufopts)
    vim.keymap.set('n', '<space>f', function() vim.lsp.buf.format {async = true} end, bufopts)
end

local lsp_flags = {
  -- This is the default in Nvim 0.7+
  debounce_text_changes = 150,
}
require('lspconfig')['pyright'].setup {
    on_attach = on_attach,
    flags = lsp_flags,
    -- Disable diagnostics completely.
    -- handlers = {
    --     ['textDocument/publishDiagnostics'] = function(...) end
    -- },
    --settings = {
    --    python = {
    --        analysis = {
    --            diagnosticSeverityOverrides = {
    --                reportMissingImports = 'none',
    --            }
    --        }
    --    }
    --}
}
require('lspconfig')['clangd'].setup {
    on_attach = on_attach,
    flags = lsp_flags,
}

vim.cmd[[colorscheme habamax]]
vim.api.nvim_set_hl(0, 'MatchParen', {cterm = {bold = true}, ctermfg = 'White'})
vim.api.nvim_set_hl(0, 'Whitespace', {link = 'ColorColumn'})
vim.api.nvim_set_hl(0, 'CurSearch', {ctermfg = 'White', ctermbg = 'Brown'})
vim.api.nvim_set_hl(0, 'Identifier', {})
vim.api.nvim_set_hl(0, 'Statement', {ctermfg = 'Yellow'})
vim.api.nvim_set_hl(0, '@operator', {})
vim.api.nvim_set_hl(0, '@type', {cterm = {italic = true}, ctermfg = 'DarkGreen'})
--vim.api.nvim_set_hl(0, '@function.call', {cterm = {italic = true}, ctermfg = 108})
vim.api.nvim_set_hl(0, '@function.call', {ctermfg = 144})
vim.api.nvim_set_hl(0, '@method.call', {ctermfg = 144})
vim.api.nvim_set_hl(0, '@punctuation.bracket', {ctermfg = 247})
vim.api.nvim_set_hl(0, '@punctuation.delimiter', {ctermfg = 247})
vim.api.nvim_set_hl(0, '@variable.builtin', {ctermfg = 'Yellow'})

vim.api.nvim_create_autocmd(
    {'BufWinEnter'},
    {pattern = '*', command = [[match Whitespace /\s\+$/]]}
)
