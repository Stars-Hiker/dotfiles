set number
set relativenumber
set tabstop=4               " number of columns occupied by a tab
set softtabstop=4           " see multiple spaces as tabstops so <BS> does the right thing
set expandtab               " converts tabs to white space
set shiftwidth=4            " width for autoindents
set autoindent              " indent a new line the same amount as the line just typed
set wildmode=longest,list   " get bash-like tab completions
set cc=80                  " set an 80 column border for good coding style
filetype plugin indent on   "allow auto-indenting depending on file type
syntax on                   " syntax highlighting
set mouse=a                 " enable mouse click
set clipboard=unnamedplus   " using system clipboard
filetype plugin on
set cursorline              " highlight current cursorline

nmap <F6> :NERDTreeToggle<CR>

call plug#begin('~/.config/nvim/plugged')
 Plug 'morhetz/gruvbox'
 "Plug 'kepano/flexoki-neovim', { 'as': 'flexoki' }
 "Plug 'jacoborus/tender.vim', { 'as': 'tender' }
 "Plug 'rebelot/kanagawa.nvim'
 "Plug 'folke/tokyonight.nvim'
 "Plug 'dracula/vim', { 'as': 'dracula' }
 "Plug 'bluz71/vim-moonfly-colors', { 'as': 'moonfly' }
 Plug 'preservim/nerdtree'
 Plug 'preservim/nerdcommenter'
 Plug 'ryanoasis/vim-devicons'
 Plug 'SirVer/ultisnips'
 Plug 'honza/vim-snippets'
 Plug 'mhinz/vim-startify'
 Plug 'neoclide/coc.nvim', {'branch': 'release'}
 Plug 'vim-airline/vim-airline'
 "Plug 'junegunn/fzf', { 'do': { -> fzf#install() } }
 "Plug 'nanotee/zoxide.vim'
call plug#end()

"Tender
"if (has("termguicolors"))
" set termguicolors
"endif

let g:gruvbox_contrast_dark = 'hard'
"colorscheme flexoki-dark 
"let g:gruvbox_colorterm = 1
colorscheme gruvbox
"colorscheme moonfly
"colorscheme tokyonight

" set airline theme
"let g:airline_theme = 'tender'
" set lighline theme inside lightline config
"let g:lightline = { 'colorscheme': 'tender' }

"syntax enable
"colorscheme tender

"set background=dark
