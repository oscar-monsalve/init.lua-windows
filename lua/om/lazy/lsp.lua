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

        local function first_executable(paths)
            for _, path in ipairs(paths) do
                if path and path ~= "" and vim.fn.executable(path) == 1 then
                    local resolved = vim.fn.exepath(path)
                    return vim.fs.normalize(resolved ~= "" and resolved or path)
                end
            end
        end

        local function mason_executable(package, executable)
            local package_path = vim.fs.joinpath(vim.fn.stdpath("data"), "mason", "packages", package)
            local matches = vim.fn.glob(
                vim.fs.joinpath(package_path, "*", "bin", executable),
                false,
                true
            )
            table.insert(matches, vim.fs.joinpath(package_path, "bin", executable))
            table.insert(matches, vim.fs.joinpath(package_path, executable))
            table.sort(matches)

            for index = #matches, 1, -1 do
                local path = first_executable({ matches[index] })
                if path then
                    return path
                end
            end
        end

        local function discovered_compilers()
            local system_drive = vim.env.SystemDrive or "C:"
            local msys_root = vim.env.MSYS2_ROOT or vim.fs.joinpath(system_drive, "msys64")
            local candidates = {
                vim.env.CC or "",
                vim.env.CXX or "",
                "gcc",
                "g++",
                "clang",
                "clang++",
            }

            for _, environment in ipairs({ "ucrt64", "mingw64", "clang64" }) do
                for _, executable in ipairs({ "gcc.exe", "g++.exe", "clang.exe", "clang++.exe" }) do
                    table.insert(candidates, vim.fs.joinpath(msys_root, environment, "bin", executable))
                end
            end

            local compilers = {}
            local seen = {}
            for _, candidate in ipairs(candidates) do
                local path = first_executable({ candidate })
                local key = path and path:lower()
                if key and not seen[key] then
                    seen[key] = true
                    table.insert(compilers, path)
                end
            end
            return compilers
        end

        local function compiler_fallback_flags(compilers)
            local compiler = compilers[1]
            if not compiler then
                return {}
            end

            for _, candidate in ipairs(compilers) do
                if candidate:lower():match("%+%+%.exe$") then
                    compiler = candidate
                    break
                end
            end

            local flags = {}
            local target = vim.system({ compiler, "-dumpmachine" }, { text = true }):wait()
            if target.code == 0 and target.stdout then
                target.stdout = vim.trim(target.stdout)
                if target.stdout ~= "" then
                    table.insert(flags, "--target=" .. target.stdout)
                end
            end

            local includes = vim.system(
                { compiler, "-E", "-x", "c++", "-", "-v" },
                { stdin = "", text = true }
            ):wait()
            local output = (includes.stdout or "") .. "\n" .. (includes.stderr or "")
            local reading_includes = false
            for line in output:gmatch("[^\r\n]+") do
                line = vim.trim(line)
                if line == "#include <...> search starts here:" then
                    reading_includes = true
                elseif reading_includes and line == "End of search list." then
                    break
                elseif reading_includes then
                    line = line:gsub(" %(framework directory%)$", "")
                    if vim.fn.isdirectory(line) == 1 then
                        table.insert(flags, "-isystem")
                        table.insert(flags, vim.fs.normalize(line))
                    end
                end
            end
            return flags
        end

        require("luasnip.loaders.from_vscode").lazy_load()
        require("fidget").setup({})
        require("mason").setup()

        local compilers = discovered_compilers()
        local clangd_command = {
            first_executable({ vim.env.CLANGD_PATH or "", mason_executable("clangd", "clangd.exe"), "clangd" }) or "clangd",
        }
        local query_drivers = vim.env.CLANGD_QUERY_DRIVER or table.concat(compilers, ",")
        if query_drivers ~= "" then
            table.insert(clangd_command, "--query-driver=" .. query_drivers:gsub("\\", "/"))
        end

        vim.lsp.config("clangd", {
            capabilities = capabilities,
            cmd = clangd_command,
            init_options = {
                fallbackFlags = compiler_fallback_flags(compilers),
            },
            filetypes = { "c", "cpp", "objc", "objcpp", "cuda", "proto" },
        })

        vim.lsp.config("lua_ls", {
            capabilities = capabilities,
            settings = {
                Lua = {
                    diagnostics = {
                        globals = { "vim", "it", "describe", "before_each", "after_each" },
                    },
                },
            },
        })

        for _, server in ipairs({ "pylsp", "zls", "marksman" }) do
            vim.lsp.config(server, { capabilities = capabilities })
        end

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
        })

        local function arduino_tool_paths()
            local local_app_data = vim.env.LOCALAPPDATA or vim.fn.expand("~/AppData/Local")
            local tools = vim.fs.joinpath(local_app_data, "Programs", "ArduinoTools", "bin")
            local arduino_ide = vim.fs.joinpath(local_app_data, "Programs", "Arduino IDE")

            return {
                language_server = first_executable({
                    vim.env.ARDUINO_LANGUAGE_SERVER_PATH or "",
                    mason_executable("arduino-language-server", "arduino-language-server.exe"),
                    vim.fs.joinpath(tools, "arduino-language-server.exe"),
                    "arduino-language-server",
                }),
                clangd = first_executable({
                    vim.env.ARDUINO_CLANGD_PATH or "",
                    mason_executable("clangd", "clangd.exe"),
                    vim.fs.joinpath(tools, "clangd.exe"),
                    "clangd",
                }),
                cli = first_executable({
                    vim.env.ARDUINO_CLI_PATH or "",
                    vim.fs.joinpath(tools, "arduino-cli.exe"),
                    vim.fs.joinpath(arduino_ide, "arduino-cli.exe"),
                    vim.fs.joinpath(arduino_ide, "resources", "app", "lib", "backend", "resources", "arduino-cli.exe"),
                    "arduino-cli",
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
                assert(tools.language_server, "Arduino LSP: arduino-language-server is not installed")
                assert(tools.clangd, "Arduino LSP: clangd is not installed")
                assert(tools.cli, "Arduino LSP: arduino-cli is not installed; set ARDUINO_CLI_PATH or add it to PATH")

                local command = {
                    tools.language_server,
                    "-clangd", tools.clangd,
                    "-cli", tools.cli,
                    "-fqbn", sketch_fqbn(config.root_dir),
                    "-jobs", "0",
                }
                if vim.fn.filereadable(tools.cli_config) == 1 then
                    table.insert(command, "-cli-config")
                    table.insert(command, tools.cli_config)
                end

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
