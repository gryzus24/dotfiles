local vim = vim
local set = vim.opt

set.fsync = false
set.lazyredraw = true
set.mouse = ''
set.showcmd = false

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

function set_snippet(name)
    vim.keymap.set(
        'n',
        '<leader>'..name..'<cr>', '<cmd>read ~/.vim/snippets/'..name..'.snip<cr>'
    )
end

set_snippet('c')
set_snippet('java')
set_snippet('latex')
set_snippet('make_c')
set_snippet('make_latex')
set_snippet('python')

vim.keymap.set('n', '<leader>am', ':w | !make')
vim.keymap.set('n', '<cr>', '<cmd>noh<cr><cr>')
vim.keymap.set('n', '<esc>', '<cmd>noh<cr>')
vim.keymap.set('n', 'S', '"_S<left><right>')
vim.keymap.set('n', '<c-.>', '<c-w>4>')
vim.keymap.set('n', '<c-,>', '<c-w>4<')
vim.keymap.set('n', '<c-m>', '<c-w>2+')
vim.keymap.set('n', '<c-b>', '<c-w>2-')
vim.keymap.set('n', '<c-1>', '<cmd>cprev<cr>')
vim.keymap.set('n', '<c-2>', '<cmd>cnext<cr>')
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
vim.keymap.set('t', '<c-j>', '<c-\\><c-n>')

set.rtp:prepend(vim.fn.stdpath('data') .. '/lazy/lazy.nvim')
require('lazy').setup({
    spec = {
        {'neovim/nvim-lspconfig'},
        {
            'nvim-telescope/telescope-fzf-native.nvim',
            build = 'make',
        },
        {
            'nvim-telescope/telescope.nvim',
            tag = '0.1.8',
            branch = '0.1.x',
            dependencies = {'nvim-lua/plenary.nvim'},
        },
        {'nvim-treesitter/nvim-treesitter'},
  },
  checker = {enabled = false},
})

require 'lsp-config'
require 'telescope-config'
require 'treesitter-config'

function acolors()
    set.termguicolors = false

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

function bcolors()
    set.termguicolors = false

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

function ccolors()
    set.termguicolors = true

    vim.cmd.colorscheme('habamax')
    local set_hl = vim.api.nvim_set_hl

    local ign = '#988f81'

    -- Green
    -- local fg = '#d9dbba'
    -- local bg = '#0b1009'
    -- local ws = '#1b2019'

    -- Mono
    local fg = '#d0d8c8'
    local bg = '#0d0d0d'
    local ws = '#1a0d0d'

    set_hl(0, 'Normal',                {fg = fg, bg = bg})

    -- override
    set_hl(0, 'Directory',             {fg = fg})
    set_hl(0, 'Identifier',            {fg = fg})
    set_hl(0, '@module',               {fg = fg})

    -- yield
    set_hl(0, 'Constant',              {})
    set_hl(0, 'Special',               {fg = fg})
    set_hl(0, 'PreProc',               {})
    set_hl(0, '@label',                {})

    set_hl(0, 'Function',              {fg = '#5cb9ff', bold = true})
    set_hl(0, '@function.call',        {fg = '#b5c3e2', bold = true})
    set_hl(0, '@function.method.call', {link = '@function.call'})
    set_hl(0, '@function.builtin',     {link = '@function.call'})

    set_hl(0, '@number',               {fg = '#5cb9ff'})
    set_hl(0, '@number.float',         {link = '@number'})
    set_hl(0, '@boolean',              {link = '@number'})

    set_hl(0, 'String',                {fg = '#ecbe7b'})
    set_hl(0, '@character',            {link = 'String'})
    set_hl(0, '@string.escape',        {fg = '#fbd85f'})

    set_hl(0, 'MatchParen',            {fg = 'White', bold = true})
    set_hl(0, 'Operator',              {fg = '#a8a095'})
    set_hl(0, 'Statement',             {fg = '#beec7b'})

    set_hl(0, 'Type',                  {fg = '#b5c3e2', italic = true})
    set_hl(0, '@type.builtin',         {link = 'Type'})

    set_hl(0, '@constant.builtin',     {fg = '#7effa3'})
    set_hl(0, '@keyword.conditional.ternary', {link = 'Operator'})
    set_hl(0, '@keyword.directive',    {link = 'Type'})
    set_hl(0, '@keyword.import',       {link = 'Keyword'})
    set_hl(0, '@keyword.type',         {link = 'Keyword'})

    set_hl(0, 'Whitespace',            {bg = ws})
    set_hl(0, 'ColorColumn',           {link = 'Whitespace'})
    set_hl(0, 'CurSearch',             {fg = 'White', bg = 'Brown'})
    set_hl(0, 'Comment',               {fg = ign, italic = true})
    set_hl(0, 'LineNr',                {fg = ign})

    set_hl(0, '@lsp.type.class',       {fg = '#ec7bbe', bold = true, italic = true});
    set_hl(0, '@lsp.type.enumMember',  {});
    set_hl(0, '@lsp.type.errorTag',    {});
    set_hl(0, '@lsp.type.function',    {});
    set_hl(0, '@lsp.type.macro',       {});
    set_hl(0, '@lsp.type.method',      {});
    set_hl(0, '@lsp.type.string',      {});
    set_hl(0, '@lsp.type.type',        {});
    set_hl(0, '@lsp.type.variable',    {});
    set_hl(0, '@lsp.typemod.label.declaration', {link = '@string.escape'});
end

ccolors()

vim.api.nvim_create_autocmd(
    {'BufWinEnter'},
    {pattern = '*', command = [[match Whitespace /\s\+$/]]}
)

if vim.g.neovide then
    set.mouse = 'a'
    vim.g.neovide_cursor_animation_length = 0
    vim.g.neovide_cursor_antialiasing = 0
    vim.g.neovide_cursor_trail_size = 0
    vim.g.neovide_position_animation_length = 0
    vim.g.neovide_scroll_animation_length = 0.1

    vim.keymap.set('n', '<cs-v>', '"+P')
    vim.keymap.set('i', '<cs-v>', '<space><esc>v"+Pa')
    vim.keymap.set('c', '<cs-v>', '<c-r>+')
    vim.keymap.set('v', '<cs-c>', '"+ygv')
end
