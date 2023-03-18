local npairs = require('nvim-autopairs')
local Rule = require('nvim-autopairs.rule')

npairs.setup({})
npairs.clear_rules()
npairs.add_rules {
    Rule('{', '}')
        :end_wise(function() return true end)
}
