return {
    "neovim/nvim-lspconfig",
    dependencies = {
        "williamboman/mason.nvim",
        "williamboman/mason-lspconfig.nvim",
        "hrsh7th/cmp-nvim-lsp",
        "hrsh7th/cmp-buffer",
        "hrsh7th/cmp-path",
        "hrsh7th/cmp-cmdline",
        "hrsh7th/nvim-cmp",
        "L3MON4D3/LuaSnip",
        "saadparwaiz1/cmp_luasnip",
        "rafamadriz/friendly-snippets",
        "j-hui/fidget.nvim",
    },

    config = function()
        vim.filetype.add({
            extension = {
                ino = "arduino",
            },
        })

        local cmp = require('cmp')
        local cmp_lsp = require("cmp_nvim_lsp")
        local capabilities = vim.tbl_deep_extend(
            "force",
            {},
            vim.lsp.protocol.make_client_capabilities(),
            cmp_lsp.default_capabilities())

        require("luasnip.loaders.from_vscode").lazy_load()
        require("fidget").setup({})
        require("mason").setup()
        require("mason-lspconfig").setup({
            ensure_installed = {
                "pylsp",
                "zls",
                "marksman",
                "clangd",
                "arduino_language_server",
                "lua_ls",
                -- "texlab",
                -- "rust_analyzer",
            },

            automatic_enable = {
                exclude = { "arduino_language_server" },
            },

            handlers = {
                function(server_name) -- default handler (optional)

                    require("lspconfig")[server_name].setup {
                        capabilities = capabilities
                    }
                end,

                ["lua_ls"] = function()
                    local lspconfig = require("lspconfig")
                    lspconfig.lua_ls.setup {
                        capabilities = capabilities,
                        settings = {
                            Lua = {
                                diagnostics = {
                                    globals = { "vim", "it", "describe", "before_each", "after_each" },
                                }
                            }
                        }
                    }
                end,

                ["clangd"] = function()
                    local lspconfig = require('lspconfig')
                    lspconfig.clangd.setup{
                        capabilities = capabilities,
                        cmd = {'clangd', '--query-driver=C:/msys64/mingw64/bin/g++.exe'},
                        filetypes = { "c", "cpp", "h", "hpp", "inl", "objc", "objcpp", "cuda", "proto" }
                    }
                end,



            }
        })

        local function first_executable(paths)
            for _, path in ipairs(paths) do
                if path ~= "" and vim.fn.executable(path) == 1 then
                    return path
                end
            end
            return paths[#paths]
        end

        local function arduino_tool_paths()
            local local_app_data = vim.env.LOCALAPPDATA or vim.fn.expand("~/AppData/Local")
            local tools = vim.fs.joinpath(local_app_data, "Programs", "ArduinoTools", "bin")
            local mason = vim.fs.joinpath(vim.fn.stdpath("data"), "mason", "packages")
            local mason_clangd = vim.fn.glob(
                vim.fs.joinpath(mason, "clangd", "clangd_*", "bin", "clangd.exe"),
                false,
                true
            )[1] or ""

            return {
                language_server = first_executable({
                    vim.fs.joinpath(tools, "arduino-language-server.exe"),
                    vim.fs.joinpath(mason, "arduino-language-server", "arduino-language-server.exe"),
                    vim.fn.exepath("arduino-language-server"),
                }),
                clangd = first_executable({
                    vim.env.ARDUINO_CLANGD_PATH or "",
                    vim.fs.joinpath(tools, "clangd.exe"),
                    mason_clangd,
                    vim.fn.exepath("clangd"),
                }),
                cli = first_executable({
                    vim.fs.joinpath(tools, "arduino-cli.exe"),
                    vim.fn.exepath("arduino-cli"),
                }),
                cli_config = vim.env.ARDUINO_CONFIG_FILE
                    or vim.fs.joinpath(local_app_data, "Arduino15", "arduino-cli.yaml"),
            }
        end

        local function sketch_fqbn(root_dir)
            local config_path = vim.fs.joinpath(root_dir, "sketch.yaml")
            if vim.fn.filereadable(config_path) == 1 then
                for _, line in ipairs(vim.fn.readfile(config_path)) do
                    local fqbn = line:match([[^%s*default_fqbn:%s*["']?([^%s"'#]+)]])
                    if fqbn then
                        return fqbn
                    end
                end
            end

            return vim.env.ARDUINO_FQBN or "esp32:esp32:esp32"
        end

        local arduino_restart_pending = false

        local function is_arduino_sync_error(code, err)
            local message = type(err) == "table" and type(err.error) == "table"
                and tostring(err.error.message)
                or tostring(err)

            return code == vim.lsp.rpc.client_errors.INVALID_SERVER_MESSAGE
                and message:find("trying to get preamble for non-added document", 1, true) ~= nil
        end

        local function restart_arduino_lsp()
            if arduino_restart_pending then
                return
            end
            arduino_restart_pending = true
            vim.notify("Arduino LSP lost synchronization; restarting it.", vim.log.levels.WARN)
            vim.schedule(function()
                local buffers = {}
                for _, client in ipairs(vim.lsp.get_clients({ name = "arduino_language_server" })) do
                    for bufnr in pairs(client.attached_buffers) do
                        buffers[bufnr] = true
                    end
                end
                vim.lsp.enable("arduino_language_server", false)
                vim.defer_fn(function()
                    vim.lsp.enable("arduino_language_server", true)
                    for bufnr in pairs(buffers) do
                        if vim.api.nvim_buf_is_valid(bufnr) and vim.bo[bufnr].filetype == "arduino" then
                            local config = vim.deepcopy(vim.lsp.config.arduino_language_server)
                            config.root_dir = vim.fs.dirname(vim.api.nvim_buf_get_name(bufnr))
                            vim.lsp.start(config, { bufnr = bufnr })
                        end
                    end
                    arduino_restart_pending = false
                end, 500)
            end)
        end

        vim.lsp.config("arduino_language_server", {
            capabilities = vim.tbl_deep_extend("force", {}, capabilities, {
                textDocument = { semanticTokens = vim.NIL },
                workspace = { semanticTokens = vim.NIL },
            }),
            root_dir = function(bufnr, on_dir)
                local path = vim.api.nvim_buf_get_name(bufnr)
                if path ~= "" then
                    on_dir(vim.fs.dirname(path))
                end
            end,
            workspace_required = true,
            -- Batched incremental changes can desynchronize Arduino LS's .ino-to-.cpp mapper.
            flags = {
                debounce_text_changes = 0,
            },
            cmd = function(dispatchers, config)
                local tools = arduino_tool_paths()
                local command = {
                    tools.language_server,
                    "-clangd", tools.clangd,
                    "-cli", tools.cli,
                    "-cli-config", tools.cli_config,
                    "-fqbn", sketch_fqbn(config.root_dir),
                    "-jobs", "0",
                }

                local suppress_exit = false
                local rpc_dispatchers = vim.tbl_extend("force", {}, dispatchers, {
                    on_error = function(code, err)
                        if is_arduino_sync_error(code, err) then
                            suppress_exit = true
                            restart_arduino_lsp()
                            return
                        end
                        dispatchers.on_error(code, err)
                    end,
                    on_exit = function(code, signal)
                        if suppress_exit then
                            dispatchers.on_exit(0, signal)
                            return
                        end
                        dispatchers.on_exit(code, signal)
                    end,
                })

                return vim.lsp.rpc.start(command, rpc_dispatchers)
            end,
        })
        vim.lsp.enable("arduino_language_server")

        local cmp_select = { behavior = cmp.SelectBehavior.Select }

        cmp.setup({
            snippet = {
                expand = function(args)
                    require('luasnip').lsp_expand(args.body) -- For `luasnip` users.
                end,
            },
            window = {
                -- completion = cmp.config.window.bordered(),
                documentation = cmp.config.window.bordered(),
            },
            mapping = cmp.mapping.preset.insert({
                ['<C-p>'] = cmp.mapping.select_prev_item(cmp_select),
                ['<C-n>'] = cmp.mapping.select_next_item(cmp_select),
                ['<Tab>'] = cmp.mapping.confirm({ select = true }),
                ["<C-Space>"] = cmp.mapping.complete(),
            }),
            sources = cmp.config.sources({
                { name = 'nvim_lsp' },
                { name = 'luasnip' }, -- For luasnip users.
            }, {
                { name = 'buffer' },
            })
        })

        vim.diagnostic.config({
            virtual_text = true,
            update_in_insert = false,
            float = {
                focusable = true,
                style = "minimal",
                border = "rounded",
                source = "always",
                header = "",
                prefix = "",
            },
        })
    end
}
