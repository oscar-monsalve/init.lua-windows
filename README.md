# Neovim config files

Neovim configuration for Windows OS.

The repository can be cloned in:

```
C:\Users\%USERNAME%\AppData\Local\
```

Make sure to rename the cloned directory as "```nvim```".


## Install the following prerequisites

Neovim 0.11.3 or newer, Git, and the command-line utilities used by the plugins:

```console
choco install git ripgrep fd make
winget install Neovim.Neovim
```

Install [MSYS2](https://www.msys2.org/) for C and C++. The LSP discovers GCC or
Clang from `PATH` and also checks the UCRT64, MinGW64, and Clang64 environments
under `C:\msys64`. Set `MSYS2_ROOT` if MSYS2 is installed elsewhere.

Add the selected environment's `bin` directory to `PATH`, for example:

```text
C:\msys64\ucrt64\bin
```

Install Python with `venv` support for `pylsp`. Install Zig separately and keep
its minor version aligned with the ZLS version installed by Mason.

For Arduino development, install `arduino-cli`, then install the board cores and
libraries required by each sketch. The default board is `esp32:esp32:esp32`.
Override it with `ARDUINO_FQBN` or a `sketch.yaml` in the sketch directory:

```yaml
default_fqbn: arduino:avr:uno
```

After the first launch, let Mason finish installing language servers and restart
Neovim before opening source files.

## Optional path overrides

All overrides are optional. Use them when tools are not installed in a standard
location or available on `PATH`:

```powershell
$env:CC = "C:\path\to\gcc.exe"
$env:CXX = "C:\path\to\g++.exe"
$env:CLANGD_PATH = "C:\path\to\clangd.exe"
$env:CLANGD_QUERY_DRIVER = "C:/path/to/gcc.exe,C:/path/to/g++.exe"
$env:ARDUINO_LANGUAGE_SERVER_PATH = "C:\path\to\arduino-language-server.exe"
$env:ARDUINO_CLANGD_PATH = "C:\path\to\clangd.exe"
$env:ARDUINO_CLI_PATH = "C:\path\to\arduino-cli.exe"
$env:ARDUINO_CONFIG_FILE = "C:\path\to\arduino-cli.yaml"
$env:ARDUINO_FQBN = "esp32:esp32:esp32"
```

Projects with nonstandard C/C++ flags should provide `compile_commands.json`,
`compile_flags.txt`, or `.clangd`. The discovered compiler flags are only a
fallback for standalone source files.

## Other tools

Install [Windows Terminal](https://learn.microsoft.com/en-us/windows/terminal/install)
and [oh-my-posh](https://ohmyposh.dev/docs/installation/windows) if desired.

Lua interpreter:

```console
winget install "Lua for Windows"
```

Download LuaRocks, extract it, and add it to the system `PATH`:

[luarocks-3.11.1-windows-64.zip](https://luarocks.github.io/luarocks/releases/luarocks-3.11.1-windows-64.zip)

Plugin manager: [lazy.nvim](https://github.com/folke/lazy.nvim)
