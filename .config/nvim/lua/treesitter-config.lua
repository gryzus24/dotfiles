local langs = {
    'bash',
    'c',
    'cpp',
    'go',
    'python',
    'zig'
}
require('nvim-treesitter').install(langs):wait(15000)

vim.api.nvim_create_autocmd('FileType', {
    callback = function(ev)
        local lang = vim.treesitter.language.get_lang(ev.match)
        if vim.treesitter.language.add(lang) then
            vim.bo.indentexpr = 'v:lua.require"nvim-treesitter".indentexpr()'
            vim.treesitter.start()
        end
    end,
})
