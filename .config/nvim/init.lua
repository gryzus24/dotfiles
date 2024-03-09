local set = vim.opt

set.fsync = false
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

local Plug = vim.fn['plug#']
vim.call('plug#begin', '~/.local/share/nvim/plugged')
Plug('neovim/nvim-lspconfig')
Plug('nvim-treesitter/nvim-treesitter', {['do'] = ':TSUpdate'})
Plug('nvim-treesitter/nvim-treesitter-context')
Plug('numToStr/Comment.nvim')
vim.call('plug#end')

require 'treesitter-config'
require 'lsp-config'

require('treesitter-context').setup({
    enable = false,
    multiline_threshold = 1
})
require('Comment').setup({
    mappings = {
        extra = false
    }
})

vim.cmd.colorscheme('habamax')
vim.api.nvim_set_hl(0, 'Normal', {})
vim.api.nvim_set_hl(0, 'MatchParen', {cterm = {bold = true}, ctermfg = 'White'})
vim.api.nvim_set_hl(0, 'Whitespace', {link = 'ColorColumn'})
vim.api.nvim_set_hl(0, 'CurSearch', {ctermfg = 'White', ctermbg = 'Brown'})
vim.api.nvim_set_hl(0, 'Identifier', {})
vim.api.nvim_set_hl(0, 'Statement', {ctermfg = 'Yellow'})
vim.api.nvim_set_hl(0, '@operator', {})
vim.api.nvim_set_hl(0, '@type', {cterm = {italic = true}, ctermfg = 'DarkGreen'})
--vim.api.nvim_set_hl(0, '@function.call', {cterm = {italic = true}, ctermfg = 108})
vim.api.nvim_set_hl(0, '@variable.builtin', {ctermfg = 138})
vim.api.nvim_set_hl(0, '@function.call', {ctermfg = 144})
vim.api.nvim_set_hl(0, '@method.call', {ctermfg = 144})
vim.api.nvim_set_hl(0, '@punctuation.bracket', {ctermfg = 247})
vim.api.nvim_set_hl(0, '@punctuation.delimiter', {ctermfg = 247})

vim.api.nvim_create_autocmd(
    {'BufWinEnter'},
    {pattern = '*', command = [[match Whitespace /\s\+$/]]}
)
