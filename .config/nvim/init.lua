local set = vim.opt

set.guicursor = ''
set.mouse = ''

set.expandtab = true
set.shiftwidth = 4
set.tabstop = 4

set.colorcolumn = '80'
set.number = true
set.relativenumber = true
set.scrolloff = 7

set.ignorecase = true
set.smartcase = true
set.wildignorecase = true

set.path = '**'

vim.keymap.set('n', '<leader>c<cr>',          ':-1read ~/.vim/snippets/c.snip<cr>')
vim.keymap.set('n', '<leader>java<cr>',       ':-1read ~/.vim/snippets/java.snip<cr>')
vim.keymap.set('n', '<leader>latex<cr>',      ':-1read ~/.vim/snippets/latex.snip<cr>')
vim.keymap.set('n', '<leader>make_c<cr>',     ':-1read ~/.vim/snippets/make_c.snip<cr>')
vim.keymap.set('n', '<leader>make_latex<cr>', ':-1read ~/.vim/snippets/make_latex.snip<cr>')
vim.keymap.set('n', '<leader>python<cr>',     ':-1read ~/.vim/snippets/python.snip<cr>')

vim.keymap.set('n', '<cr>', ':noh<cr><cr>')
vim.keymap.set('n', '<leader>am', ':w | !make')

local Plug = vim.fn['plug#']
vim.call('plug#begin', '~/.local/share/nvim/plugged')

Plug('neovim/nvim-lspconfig')
Plug('nvim-treesitter/nvim-treesitter', {['do'] = ':TSUpdate'})
Plug('windwp/nvim-autopairs')

vim.call('plug#end')

require 'treesitter-config'
require 'lsp-config'
require 'autopairs-config'

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
