-- This file can be loaded by calling `lua require('plugins')` from your init.vim

-- Only required if you have packer configured as `opt`


return require('packer').startup(function(use)
  -- Packer can manage itself
  use 'wbthomason/packer.nvim'

  use("folke/tokyonight.nvim")

  use({
      'rose-pine/neovim',
      as = 'rose-pine',
  })

  use('nvim-treesitter/nvim-treesitter', {run = ':TSUpdate'})

  use {
      'nvim-telescope/telescope.nvim', tag = '0.1.5',
      -- or                            , branch = '0.1.x',
      requires = { {'nvim-lua/plenary.nvim'} }
  }

  use {
      "ThePrimeagen/harpoon",
      branch = "harpoon2",
  }

  use{'ThePrimeagen/vim-be-good'}

  use {'lervag/vimtex'}

  use {
	  'VonHeikemen/lsp-zero.nvim',
	  branch = 'v3.x',
	  requires = {
		  --- Uncomment these if you want to manage LSP servers from neovim
		  {'williamboman/mason.nvim'},
		  {'williamboman/mason-lspconfig.nvim'},

		  -- LSP Support
		  {'neovim/nvim-lspconfig'},

		  -- Autocompletion
		  {'hrsh7th/nvim-cmp'},
		  {'hrsh7th/cmp-buffer'},
		  {'hrsh7th/cmp-path'},
		  {'hrsh7th/cmp-nvim-lsp'},
		  {'hrsh7th/cmp-nvim-lua'},

		  -- Snippets
          {'saadparwaiz1/cmp_luasnip'},
          {'L3MON4D3/LuaSnip'},
          {'rafamadriz/friendly-snippets'},
	  }
  }

  use({
      "epwalsh/obsidian.nvim",
      tag = "*",  -- recommended, use latest release instead of latest commit
      requires = {
          -- Required.
          "nvim-lua/plenary.nvim",

          -- see below for full list of optional dependencies
      }
  })

end)
