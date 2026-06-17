require("om.set")
require("om.remap")
require("om.lazy_init")

local augroup = vim.api.nvim_create_augroup
local omGroup = augroup('omGroup', {})

local autocmd = vim.api.nvim_create_autocmd
local yank_group = augroup('HighlightYank', {})

function R(name)
    require("plenary.reload").reload_module(name)
end

vim.filetype.add({
    extension = {
        templ = 'templ',
    }
})

-- Spell checking
autocmd({ "FileType", "BufEnter" }, {
    pattern = "*",
    callback = function(opts)
        if not vim.tbl_contains({ "markdown", "txt", "env" }, vim.bo[opts.buf].filetype) then
            return
        end

        -- fixes spanish spell checking
        vim.opt_local.spelllang = { "en_us" }
        -- vim.opt.spelllang = "es"
        vim.opt_local.spell = true

        vim.opt_local.linebreak = true

        local ok, cmp = pcall(require, "cmp")
        if ok then
            cmp.setup.buffer({ enabled = false })
        end
    end,
})

autocmd('TextYankPost', {
    group = yank_group,
    pattern = '*',
    callback = function()
        vim.highlight.on_yank({
            higroup = 'IncSearch',
            timeout = 40,
        })
    end,
})

autocmd({"BufWritePre"}, {
    group = omGroup,
    pattern = "*",
    command = [[%s/\s\+$//e]],
})

autocmd('LspAttach', {
    group = omGroup,
    callback = function(e)
        local opts = { buffer = e.buf }
        vim.keymap.set("n", "gd", function() vim.lsp.buf.definition() end, opts)
        -- vim.keymap.set("n", "K", function() vim.lsp.buf.hover(vim.tbl_deep_extend("force", {}, { border = "rounded" })) end, opts)
        vim.keymap.set("n", "K", function() vim.lsp.buf.hover({ border = "rounded" }) end, opts)
        vim.keymap.set("i", "<C-h>", function() vim.lsp.buf.signature_help(vim.tbl_deep_extend("force", {}, { border = "rounded" })) end, opts)
        vim.keymap.set("n", "<leader>vws", function() vim.lsp.buf.workspace_symbol() end, opts)
        vim.keymap.set("n", "<leader>vd", function() vim.diagnostic.open_float() end, opts)
        vim.keymap.set("n", "<leader>vca", function() vim.lsp.buf.code_action() end, opts)
        vim.keymap.set("n", "<leader>vrr", function() vim.lsp.buf.references() end, opts)
        vim.keymap.set("n", "<leader>vrn", function() vim.lsp.buf.rename() end, opts)
        vim.keymap.set("n", "[d", function() vim.diagnostic.goto_next() end, opts)
        vim.keymap.set("n", "]d", function() vim.diagnostic.goto_prev() end, opts)
    end
})

-- Remove Netrw directory listing when opening nvim in directory
-- vim.g.netrw_browse_split = 0
-- vim.g.netrw_banner = 0
-- vim.g.netrw_winsize = 25
