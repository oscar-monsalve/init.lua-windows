-- Local leader
vim.g.maplocalleader = ","

return {
    "lervag/vimtex",

    init = function()

        -- PDF viewer
        vim.g["vimtex_view_general_viewer"] = "SumatraPDF"
        vim.g["vimtex_view_general_options"] = "-reuse-instance -forward-search @tex @line @pdf"

        -- Deactivate quickfix window
        vim.g["vimtex_quickfix_mode"] = 0

        -- Auto Indent
        vim.g["vimtex_indent_enabled"] = 0

        -- Syntax highlighting
        vim.g["vimtex_syntax_enabled"] = 1

        -- Ignore things
        vim.g["vimtex_log_ignore"] = ({
            "Underfull",
            "Overfull",
            "specifier changed to",
            "Token not allowed in a PDF string",
        })

        -- Compiler
        vim.g.vimtex_compiler_method = "latexmk"

    end
}
