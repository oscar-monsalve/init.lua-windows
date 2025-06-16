# Neovim config files

Neovim configuration for Windows OS.

- Package manager: [lazy.nvim](https://github.com/folke/lazy.nvim)

The repository can be cloned and neovim will configure automatically. The following are the prerequisites:

- git:
```console
choco install git
```

- ripgrep:
```console
choco install ripgrep
```

- fd:
```console
choco install fd
```

- make:
```console
choco install make
```

- MSYS2 [MSYS2 windows install](https://www.msys2.org/) (install gcc compiler for windows and add to PATH -> C:\msys64\mingw64\bin\ or C:\msys64\ucrt64\bin).

- Install shell [oh-my-posh shell](https://ohmyposh.dev/docs/installation/windows)

- Windows terminal [Windows terminal](https://learn.microsoft.com/en-us/windows/terminal/install)

- neovim:
```console
winget install Neovim.Neovim
```

- lua interpreter:
```console
 winget install "Lua for Windows"
```

- Download [luarocks-3.11.1-windows-64.zip](https://luarocks.github.io/luarocks/releases/), extract and add to SYSTEM PATH.
