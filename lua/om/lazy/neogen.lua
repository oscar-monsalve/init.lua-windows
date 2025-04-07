return{
    "danymat/neogen",
    config = function ()
        require("neogen").setup({
            -- TODO: see whats better if specifying luasnip or not as snippet_engine.
            -- snippet_engine = "luasnip"
        })

        local opts = { noremap = true, silent = true }
        vim.api.nvim_set_keymap("n", "<Leader>nf", ":lua require('neogen').generate({ type = 'func' })<CR>", opts)
        vim.api.nvim_set_keymap("n", "<Leader>nt", ":lua require('neogen').generate({ type = 'type' })<CR>", opts)
        vim.api.nvim_set_keymap("n", "<Leader>nc", ":lua require('neogen').generate({ type = 'class' })<CR>", opts)
    end,
    -- version = "*"  -- Uncomment next line if you want to follow only stable versions
}
