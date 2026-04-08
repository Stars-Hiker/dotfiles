-- INSTALL
-- lazy.nvim setup
local lazy = {}

function lazy.install(path)
  if not vim.loop.fs_stat(path) then
    print('Installing lazy.nvim....')
    vim.fn.system({
      'git',
      'clone',
      '--filter=blob:none',
      'https://github.com/folke/lazy.nvim.git',
      '--branch=stable', -- latest stable release
      path,
    })
  end
end

function lazy.setup(plugins)
  if vim.g.plugins_ready then
    return
  end

  -- Install lazy.nvim if not present
  lazy.install(lazy.path)

  -- Prepend the lazy.nvim path to 'runtimepath'
  vim.opt.rtp:prepend(lazy.path)

  -- Setup the plugin manager with the plugins list
  require('lazy').setup(plugins, lazy.opts)
  
  -- Mark plugins as ready
  vim.g.plugins_ready = true
end

-- Define the installation path for lazy.nvim
lazy.path = vim.fn.stdpath('data') .. '/lazy/lazy.nvim'
-- Setup options for lazy.nvim (can be empty for now)
lazy.opts = {}

-- Call lazy.setup with the list of plugins to install
lazy.setup({
  -- Example: List of plugins you want to install
--  {'folke/tokyonight.nvim'},
  {'morhetz/gruvbox'},
  {'nvim-lualine/lualine.nvim'},
	{'nvim-treesitter/nvim-treesitter', run = ':TSUpdate'},
  {'hrsh7th/nvim-cmp'},
	{'nvim-telescope/telescope.nvim', requires = {{'nvim-lua/plenary.nvim'}}},

	-- Add other plugins here
})

vim.g.gruvbox_contrast_dark = 'hard'  -- Optional: Adjust contrast
vim.opt.background = 'dark'
-- Themes
vim.opt.termguicolors = true
-- vim.cmd.colorscheme('tokyonight') 
vim.cmd.colorscheme('gruvbox')


-- CONFIGURATION

-- Useful options
vim.opt.number = true
vim.opt.mouse = 'a'
vim.opt.ignorecase = true
vim.opt.smartcase = true
vim.opt.hlsearch = false
vim.opt.wrap = true
vim.opt.breakindent = true
vim.opt.tabstop = 2
vim.opt.shiftwidth = 2
vim.opt.expandtab = false
vim.opt.clipboard = "unnamedplus"

-- Keybindings
vim.g.mapleader = ' '
vim.keymap.set('n', '<leader>w', '<cmd>write<cr>', {desc = 'Save'})
vim.keymap.set({'n', 'x'}, 'gy', '"+y')
vim.keymap.set({'n', 'x'}, 'gp', '"+p')
vim.keymap.set({'n', 'x'}, 'x', '"_x')
vim.keymap.set({'n', 'x'}, 'X', '"_d')
vim.keymap.set('n', '<leader>a', ':keepjumps normal! ggVG<cr>')
vim.keymap.set('n', '<F2>', '<cmd>Lexplore<cr>')
vim.keymap.set('n', '<space><space>', '<F2>', {remap = true})

-- Reload Config
vim.api.nvim_create_user_command('ReloadConfig', 'source $MYVIMRC', {})
vim.keymap.set('n', '<space>r', '<cmd>ReloadConfig<cr>')


-- Status Line
require('lualine').setup()

--Highlight yank with yy
vim.api.nvim_create_autocmd('TextYankPost', {
  group = augroup,
  desc = 'Highlight on yank',
  callback = function(event)
    vim.highlight.on_yank({higroup = 'Visual', timeout = 200})
  end
})	
