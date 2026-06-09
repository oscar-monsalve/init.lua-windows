local wrap_column = 117

local text_filetypes = {
    "markdown",
    "text",
    "plaintext",
    "gitcommit",
    "mail",
    "tex",
    "latex",
    "plaintex",
    "asciidoc",
    "rst",
    "org",
    "norg",
    "typst",
}

local text_filetype_lookup = {}

for _, ft in ipairs(text_filetypes) do
    text_filetype_lookup[ft] = true
end

return {
    "andrewferrier/wrapping.nvim",

    ft = text_filetypes,

    init = function()
        vim.filetype.add({
            extension = {
                md = "markdown",
                markdown = "markdown",
                txt = "text",
            },
            filename = {
                ["README"] = "text",
                ["COMMIT_EDITMSG"] = "gitcommit",
            },
        })
    end,

    config = function()
        local wrapping = require("wrapping")

        wrapping.setup({
            -- Do not let the plugin guess hard/soft mode.
            -- We want text files to always open with soft wrapping.
            auto_set_mode_heuristically = false,

            -- Avoid global commands/keymaps.
            create_commands = false,
            create_keymaps = false,

            -- Do not change global wrap/linebreak defaults.
            -- We will set them locally only for text buffers.
            set_nvim_opt_defaults = false,

            notify_on_switch = false,
        })

        local group = vim.api.nvim_create_augroup("TextFilesSoftWrapping", {
            clear = true,
        })

        local function is_text_file()
            return text_filetype_lookup[vim.bo.filetype] == true
        end

        local function apply_text_wrapping()
            if not is_text_file() then
                return
            end

            -- Plugin soft-wrap mode.
            wrapping.soft_wrap_mode()

            -- Same behavior as:
            -- :set wrap
            -- :set linebreak
            vim.wo.wrap = true
            vim.wo.linebreak = true
            vim.wo.breakindent = true

            -- Keep your visual guide at column 117.
            vim.wo.colorcolumn = tostring(wrap_column)

            -- Important:
            -- colorcolumn does NOT control soft wrapping.
            -- textwidth controls formatting/hard wrapping, not visual soft wrapping.
            --
            -- We set textwidth to 117 so that manual formatting with `gq`
            -- uses the same column as your colorcolumn.
            vim.bo.textwidth = wrap_column

            -- Keep it as true soft wrapping while typing:
            -- do not automatically insert hard line breaks at textwidth.
            vim.opt_local.formatoptions:remove("t")
            vim.opt_local.formatoptions:remove("c")

            -- Optional: better movement through visually wrapped lines.
            vim.keymap.set("n", "j", "gj", {
                buffer = true,
                silent = true,
                desc = "Move down by visual line",
            })

            vim.keymap.set("n", "k", "gk", {
                buffer = true,
                silent = true,
                desc = "Move up by visual line",
            })

            -- Optional manual controls.
            vim.keymap.set("n", "<leader>ws", function()
                wrapping.soft_wrap_mode()
                vim.wo.wrap = true
                vim.wo.linebreak = true
                vim.wo.breakindent = true
                vim.wo.colorcolumn = tostring(wrap_column)
                vim.bo.textwidth = wrap_column
                vim.opt_local.formatoptions:remove("t")
                vim.opt_local.formatoptions:remove("c")
            end, {
                buffer = true,
                desc = "Set soft wrap mode",
            })

            vim.keymap.set("n", "<leader>wh", function()
                wrapping.hard_wrap_mode()
                vim.bo.textwidth = wrap_column
                vim.wo.colorcolumn = tostring(wrap_column)
                vim.opt_local.formatoptions:append("t")
            end, {
                buffer = true,
                desc = "Set hard wrap mode",
            })

            vim.keymap.set("n", "<leader>wt", function()
                wrapping.toggle_wrap_mode()
                vim.wo.colorcolumn = tostring(wrap_column)
                vim.bo.textwidth = wrap_column
            end, {
                buffer = true,
                desc = "Toggle wrap mode",
            })
        end

        vim.api.nvim_create_autocmd({ "FileType", "BufWinEnter" }, {
            group = group,
            pattern = "*",
            callback = function()
                vim.schedule(apply_text_wrapping)
            end,
        })

        -- Apply immediately to the buffer that caused lazy.nvim to load the plugin.
        vim.schedule(apply_text_wrapping)
    end,
}
