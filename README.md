# Neovim config files

Neovim configuration for Windows OS.

The repository can be cloned in:

```
C:\Users\%USERNAME%\AppData\Local\
```

Make sure to rename the cloned directory as "```nvim```".


## Install the following pre-requisites:

- Packages:

```console
choco install git ripgrep fd make
```

- Install [MSYS2 Windows](https://www.msys2.org/):

    Make sure to add to PATH as ```C:\msys64\mingw64\bin\``` or ```C:\msys64\ucrt64\bin```.

- Install [Windows terminal](https://learn.microsoft.com/en-us/windows/terminal/install)

- Install [oh-my-posh shell](https://ohmyposh.dev/docs/installation/windows)


## Installing Neovim:

```console
winget install Neovim.Neovim
```

- lua interpreter:

```console
 winget install "Lua for Windows"
```

- Download luarocks, extract and add to SYSTEM PATH:

[luarocks-3.11.1-windows-64.zip](https://luarocks.github.io/luarocks/releases/),

- Package manager: [lazy.nvim](https://github.com/folke/lazy.nvim)
