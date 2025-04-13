vim.lsp.set_log_level('OFF')
vim.diagnostic.config({signs = false})

local conf = require('lspconfig')
conf['clangd'].setup({})
conf['csharp_ls'].setup({})
conf['pyright'].setup({})
conf['ts_ls'].setup({})
conf['zls'].setup({})

vim.keymap.set('n', '<space>e', vim.diagnostic.open_float)
vim.keymap.set('n', '[d',       vim.diagnostic.goto_prev)
vim.keymap.set('n', ']d',       vim.diagnostic.goto_next)
vim.keymap.set('n', '<space>q', vim.diagnostic.setloclist)

vim.api.nvim_create_autocmd('LspAttach', {
  group = vim.api.nvim_create_augroup('UserLspConfig', {}),
  callback = function(ev)
    local opts = {buffer = ev.buf}
    vim.keymap.set('n', 'gd',       vim.lsp.buf.definition, opts)
    vim.keymap.set('n', 'gD',       vim.lsp.buf.type_definition, opts)
    vim.keymap.set('n', 'gi',       vim.lsp.buf.implementation, opts)
    vim.keymap.set('n', 'gr',       vim.lsp.buf.references, {buffer = ev.buf, nowait = true})
    vim.keymap.set('n', '<c-s>',    vim.lsp.buf.signature_help, opts)
    vim.keymap.set('n', '<space>D', vim.lsp.buf.declaration, opts)
    vim.keymap.set({'n', 'v'}, '<space>rn', vim.lsp.buf.rename, opts)
    vim.keymap.set({'n', 'v'}, '<space>ca', vim.lsp.buf.code_action, opts)
    vim.keymap.set('n', '<space>wa', vim.lsp.buf.add_workspace_folder, opts)
    vim.keymap.set('n', '<space>wr', vim.lsp.buf.remove_workspace_folder, opts)
    vim.keymap.set('n', '<space>wl', function()
      print(vim.inspect(vim.lsp.buf.list_workspace_folders()))
    end, opts)
    vim.keymap.set('n', '<space>f',  function()
      vim.lsp.buf.format({async = true})
    end, opts)
  end,
})
