local vim = vim
local set = vim.opt

set.fsync = false
set.lazyredraw = true
set.mouse = ''
set.showcmd = false
set.termguicolors = false

set.expandtab = true
set.shiftwidth = 4
set.tabstop = 8

set.colorcolumn = '80'
set.number = true
set.relativenumber = true
set.scrolloff = 7

set.ignorecase = true
set.smartcase = true
set.wildignorecase = true

set.completeopt = 'menu'

set.path = '**'
set.grepprg = 'git grep -n'

function set_snippet(name)
    vim.keymap.set(
        'n',
        '<leader>'..name..'<cr>', '<cmd>-1read ~/.vim/snippets/'..name..'.snip<cr>'
    )
end

set_snippet('c')
set_snippet('java')
set_snippet('latex')
set_snippet('make_c')
set_snippet('make_latex')
set_snippet('python')

function tfeedkeys(s)
    w = vim.api.nvim_replace_termcodes(s, true, false, true)
    vim.api.nvim_feedkeys(w, 'n', false)
end

-- nm_*: must be called in normal mode
-- *_im: returns in insert mode
function nm_newline_check_close_bracket_im()
    opening = {'{', '[', '('}
    closing = {'}', ']', ')'}

    line = vim.api.nvim_get_current_line()
    lastch = line:sub(#line, #line)

    vim.api.nvim_feedkeys('o', 'n', false)
    for i = 1, #opening do
        if opening[i] == lastch then
            tfeedkeys(closing[i]..'<c-o>O')
            return
        end
    end
end

vim.keymap.set('n', '<leader>am', ':w | !make')
vim.keymap.set('n', '<cr>', '<cmd>noh<cr><cr>')
vim.keymap.set('n', '<esc>', '<cmd>noh<cr>')
vim.keymap.set('n', 'S', '"_S<left><right>')
vim.keymap.set('n', '<c-.>', '<c-w>4>')
vim.keymap.set('n', '<c-,>', '<c-w>4<')
vim.keymap.set('n', '<c-m>', '<c-w>2+')
vim.keymap.set('n', '<c-b>', '<c-w>2-')
vim.keymap.set('n', '<tab>', '<cmd>cnext<cr>')
vim.keymap.set('n', '<S-tab>', '<cmd>cprev<cr>')
vim.keymap.set('i', '<cr>',
    function()
        col = vim.api.nvim_win_get_cursor(0)[2]
        line = vim.api.nvim_get_current_line()

        -- cursor at eol and not whitespace-only line
        if col >= #line and #line:match('%s*') < #line then
            -- satisfy the calling convention :^)
            tfeedkeys('<esc>')
            nm_newline_check_close_bracket_im()
        else
            tfeedkeys('<cr>')
        end
    end
)
vim.keymap.set('v', '<bs>', '"_x')
vim.keymap.set('v', '<space>s', '"zy:%s/<c-r>z//g<left><left>')
vim.keymap.set('v', 'H', 'dhPgvhoho')
vim.keymap.set('v', 'L', 'dpgvlolo')
vim.keymap.set('s', 'h', '<esc>"_xf<space>pF<space>;gh')
vim.keymap.set('s', 'l', 'l<space><esc>hr<space>f<space>;"_xF<space>gh')

local Plug = vim.fn['plug#']
vim.call('plug#begin', '~/.local/share/nvim/plugged')
Plug('neovim/nvim-lspconfig')
Plug('nvim-treesitter/nvim-treesitter', {['do'] = ':TSUpdate'})
Plug('nvim-treesitter/nvim-treesitter-context')
Plug('nvim-lua/plenary.nvim')
Plug('nvim-telescope/telescope.nvim', {['tag'] = '0.1.x'})
Plug('nvim-telescope/telescope-fzf-native.nvim', {['do'] = 'make'})
vim.call('plug#end')

require('lspconfig').util.default_config.on_init = function(client, _)
  client.server_capabilities.semanticTokensProvider = nil
end

require 'treesitter-config'
require 'lsp-config'
require 'telescope-config'

require('treesitter-context').setup({
    enable = false,
    multiline_threshold = 1
})

function simple_colorscheme()
    vim.cmd.colorscheme('default')

    local set_hl = vim.api.nvim_set_hl
    set_hl(0, 'Function',      {})
    set_hl(0, 'Identifier',    {})
    set_hl(0, 'Special',       {})
    set_hl(0, '@type',         {cterm = {italic = true}, ctermfg = 'DarkGreen'})
    set_hl(0, 'Constant',      {cterm = {bold = true}})
    set_hl(0, 'MatchParen',    {cterm = {bold = true}, ctermfg = 'White'})
    set_hl(0, 'Comment',       {ctermfg = 'DarkGray'})
    set_hl(0, 'CurSearch',     {ctermfg = 'White', ctermbg = 'Brown'})
    set_hl(0, 'Statement',     {ctermfg = 'Yellow'})
    set_hl(0, 'Whitespace',    {ctermbg = 'DarkGray'})
    set_hl(0, '@type.builtin', {link = '@type'})
    set_hl(0, 'ColorColumn',   {link = 'Whitespace'})
    set_hl(0, 'LineNr',        {link = 'Comment'})
end

function complex_colorscheme()
    vim.cmd.colorscheme('habamax')

    local set_hl = vim.api.nvim_set_hl
    set_hl(0, 'Normal',                {})
    set_hl(0, 'Identifier',            {})
    set_hl(0, 'Operator',              {})
    set_hl(0, 'Statement',             {ctermfg = 'Yellow'})
    set_hl(0, 'Delimiter',             {ctermfg = 247})
    set_hl(0, 'MatchParen',            {cterm = {bold = true}, ctermfg = 'White'})
    set_hl(0, 'CurSearch',             {ctermfg = 'White', ctermbg = 'Brown'})

    -- More specific
    set_hl(0, '@function.call',        {ctermfg = 144})
    set_hl(0, '@type',                 {cterm = {italic = true}, ctermfg = 'DarkGreen'})
    set_hl(0, '@variable.builtin',     {ctermfg = 138})

    -- Less specific
    set_hl(0, '@type.builtin' ,        {link = '@type'})
    set_hl(0, '@lsp.type.type' ,       {link = '@type'})
    set_hl(0, '@function.method.call', {link = '@function.call'})
    set_hl(0, '@method.call',          {link = '@function.call'})

    -- Fixups
    set_hl(0, 'Whitespace',            {link = 'ColorColumn'})
    set_hl(0, '@keyword.type',         {link = 'Keyword'})
    set_hl(0, '@operator',             {link = 'Operator'})
end

complex_colorscheme()

vim.api.nvim_create_autocmd(
    {'BufWinEnter'},
    {pattern = '*', command = [[match Whitespace /\s\+$/]]}
)
