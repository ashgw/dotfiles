let mapleader =","

" Auto setup all the plugins on first lauch
if ! filereadable(system('echo -n "${XDG_CONFIG_HOME:-$HOME/.config}/nvim/autoload/plug.vim"'))
    echo "Downloading junegunn/vim-plug to manage plugins..."
    silent !mkdir -p ${XDG_CONFIG_HOME:-$HOME/.config}/nvim/autoload/
    silent !curl "https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim" > ${XDG_CONFIG_HOME:-$HOME/.config}/nvim/autoload/plug.vim
    autocmd VimEnter * PlugInstall
endif

map ,, :keepp /<++><CR>ca<
imap ,, <esc>:keepp /<++><CR>ca<

"Basics"
set shell=/bin/zsh
set encoding=UTF-8
set number
set relativenumber
set autoindent
set shiftwidth=4
set smarttab
set title
set bg=light
set go=a
set mouse=a
set nohlsearch
set clipboard+=unnamedplus
set noshowmode
set noruler
set laststatus=0
set noshowcmd
set nocompatible
nnoremap c "_c
filetype plugin on
syntax on

"All the plugins
call plug#begin(system('echo -n "${XDG_CONFIG_HOME:-$HOME/.config}/nvim/plugged"'))
" Themes
Plug 'Mofiqul/dracula.nvim'
Plug 'catppuccin/nvim', { 'as': 'catppuccin' }
" helpers
Plug 'tpope/vim-surround'
Plug 'preservim/nerdtree'
Plug 'junegunn/goyo.vim'
Plug 'jreybert/vimagit'
Plug 'vimwiki/vimwiki'
Plug 'vim-airline/vim-airline'
Plug 'tpope/vim-commentary'

" JS ecosystem setup
Plug 'ap/vim-css-color'
Plug 'pangloss/vim-javascript'    " JavaScript support
Plug 'leafgarland/typescript-vim' " TypeScript syntax
Plug 'maxmellon/vim-jsx-pretty'   " JS and JSX syntax
Plug 'jparise/vim-graphql'
Plug 'neoclide/coc.nvim', {'branch': 'release'}


" Navigation
Plug 'jlanzarotta/bufexplorer'
" Remap keys for applying codeAction to the current line.
nmap <leader>ac  <Plug>(coc-codeaction)
" Apply AutoFix to problem on the current line.
nmap <leader>qf  <Plug>(coc-fix-current)

" GoTo code navigation.
nmap <silent> gd <Plug>(coc-definition)
nmap <silent> gy <Plug>(coc-type-definition)
nmap <silent> gi <Plug>(coc-implementation)
nmap <silent> gr <Plug>(coc-references)

" Custom navigation with Ctrl
nnoremap <C-d> <Plug>(coc-definition)
nnoremap <C-a> <C-o>

" CoC extensions
let g:coc_global_extensions = ['coc-tsserver', 'coc-python', 'coc-rust-analyzer', 'coc-go', 'coc-docker']

nnoremap <silent><leader>1 :source ~/.config/nvim/init.vim \| :PlugInstall<CR>

" JS ECO done

" more useful pluuugs 🌿
let g:kite_supported_languages = ['python', 'javascript']

" nerd toggle needs to show hidden files
let NERDTreeShowHidden=1

" Themes
Plug 'folke/tokyonight.nvim'
Plug 'morhetz/gruvbox'
"
Plug 'rust-lang/rust.vim'
Plug 'cespare/vim-toml', {'branch': 'main'}
Plug 'stephpy/vim-yaml'
Plug 'rust-lang/rust.vim'
Plug 'plasticboy/vim-markdown'

Plug 'vim-airline/vim-airline'
Plug 'vim-airline/vim-airline-themes'
Plug 'ryanoasis/vim-devicons'
Plug 'scrooloose/nerdcommenter'
Plug 'sheerun/vim-polyglot'
Plug 'jiangmiao/auto-pairs'
Plug 'neoclide/coc.nvim', {'branch': 'release'}
Plug 'tpope/vim-fugitive'
Plug 'davidhalter/jedi-vim'
Plug 'vim-scripts/indentpython.vim'
Plug 'Xuyuanp/nerdtree-git-plugin'
Plug 'tiagofumo/vim-nerdtree-syntax-highlight'
Plug 'PhilRunninger/nerdtree-visual-selection'
Plug 'SirVer/ultisnips' | Plug 'honza/vim-snippets'
Plug 'scrooloose/nerdtree', { 'on':  'NERDTreeToggle' }
Plug 'tpope/vim-fireplace', { 'for': 'clojure' }
Plug 'junegunn/fzf', { 'do': { -> fzf#install() } }
Plug 'junegunn/fzf.vim'

" Others
Plug 'nvim-treesitter/nvim-treesitter', {'do': ':TSUpdate'}

" One more
Plug 'wbthomason/packer.nvim'
Plug 'svrana/neosolarized.nvim'
Plug 'nvim-lualine/lualine.nvim'
Plug 'onsails/lspkind-nvim'
Plug 'L3MON4D3/LuaSnip'
Plug 'hrsh7th/cmp-nvim-lsp'
Plug 'hrsh7th/cmp-buffer'
Plug 'hrsh7th/nvim-cmp'
Plug 'neovim/nvim-lspconfig'
Plug 'jose-elias-alvarez/null-ls.nvim'
Plug 'MunifTanjim/prettier.nvim'
Plug 'williamboman/mason.nvim'
Plug 'williamboman/mason-lspconfig.nvim'
Plug 'glepnir/lspsaga.nvim'
Plug 'nvim-treesitter/nvim-treesitter'
Plug 'kyazdani42/nvim-web-devicons'
Plug 'nvim-telescope/telescope.nvim'
Plug 'nvim-telescope/telescope-file-browser.nvim'
Plug 'windwp/nvim-autopairs'
Plug 'windwp/nvim-ts-autotag'
Plug 'norcalli/nvim-colorizer.lua'
Plug 'akinsho/nvim-bufferline.lua'
Plug 'lewis6991/gitsigns.nvim'
Plug 'dinhhuy258/git.nvim'
Plug 'folke/zen-mode.nvim'
Plug 'iamcco/markdown-preview.nvim'
Plug 'kyazdani42/nvim-web-devicons' " For fancy icons
Plug 'nvim-lualine/lualine.nvim'

let g:bargreybars_auto=0
let g:airline_solorized_bg='dark'
let g:airline_powerline_fonts=1
let g:airline#extension#tabline#left_sep=' '
let g:airline#extension#tabline#left_alt_sep='|'
let g:airline#extension#tabline#formatter='unique_tail'
let NERDTreeQuitOnOpen=1

" for all themes @see https://github.com/vim-airline/vim-airline/commit/d7fd8ca649e441b3865551a325b10504cdf0711b
let g:airline_theme = 'onedark'

let g:WebDevIconsUnicodeDecorateFolderNodes = 1
let g:WebDevIconsUnicodeDecorateFolderNodeDefaultSymbol = '#'
let g:WebDevIconsUnicodeDecorateFileNodesExtensionSymbols = {}
let g:WebDevIconsUnicodeDecorateFileNodesExtensionSymbols['nerdtree'] = '#'

call plug#end()


""""""""""""""""""""""""
"""""""""" SCRIPTS  """"
" basically make the theme go hard
lua << EOF
require("catppuccin").setup({
  flavour = "mocha", -- latte, frappe, macchiato, mocha
  integrations = {
    bufferline = true,
    treesitter = true,
    coc_nvim = true,
    nvimtree = true,
    native_lsp = {
      enabled = true,
    }
  }
})
vim.cmd.colorscheme "catppuccin"
EOF

" === Enable bufferline.nvim tab bar ===
lua << EOF
require("bufferline").setup({
  options = {
    mode = "buffers",
    diagnostics = "nvim_lsp",
    separator_style = "slant",
    show_close_icon = false,
    show_buffer_close_icons = false,
    always_show_bufferline = true,
  },
})
EOF

" configure treesetter modern syntax highliting
lua << EOF
require'nvim-treesitter.configs'.setup {
  ensure_installed = {
    "typescript",
    "tsx",
    "javascript",
    "json",
    "html",
    "css",
    "lua",
    "vim",
    "bash"
  },
  highlight = {
    enable = true,
    additional_vim_regex_highlighting = false,
  },
}
EOF

""""""""""""""""""""

" Enable autocompletion:
set wildmode=longest,list,full

" Spell-check set to <leader>o, 'o' for 'orthography':
map <leader>o :setlocal spell! spelllang=en_us<CR>

" Splits open to the right != default left.
set splitbelow splitright

" Nerd tree
map <leader>n :NERDTreeToggle<CR>
autocmd bufenter * if (winnr("$") == 1 && exists("b:NERDTree") && b:NERDTree.isTabTree()) | q | endif
if has('nvim')
    let NERDTreeBookmarksFile = stdpath('data') . '/NERDTreeBookmarks'
else
    let NERDTreeBookmarksFile = '~/.vim' . '/NERDTreeBookmarks'
endif

" vimling:
nm <leader>d :call ToggleDeadKeys()<CR>
imap <leader>d <esc>:call ToggleDeadKeys()<CR>a
nm <leader>i :call ToggleIPA()<CR>
imap <leader>i <esc>:call ToggleIPA()<CR>a
nm <leader>q :call ToggleProse()<CR>

" vim-airline
if !exists('g:airline_symbols')
    let g:airline_symbols = {}
endif
let g:airline_symbols.colnr = ' C:'
let g:airline_symbols.linenr = ' L:'
let g:airline_symbols.maxlinenr = '☰ '

" Shortcutting split navigation, saving a keypress:
map <C-h> <C-w>h
map <C-j> <C-w>j
map <C-k> <C-w>k
map <C-l> <C-w>l

" Tab-like buffer navigation (bufferline)
nnoremap <silent> <Tab> :BufferLineCycleNext<CR>
nnoremap <silent> <S-Tab> :BufferLineCyclePrev<CR>
nnoremap <silent> <C-x> :bd<CR> " close current buffer
nnoremap <leader>bl :ls<CR>:b<Space>

" Check file in shellcheck:
map <leader>s :!clear && shellcheck -x %<CR>

" Replace all is aliased to S.
nnoremap S :%s//g<Left><Left>

" Automatically deletes all trailing whitespace and newlines at end of file on save. & reset cursor position
autocmd BufWritePre * let currPos = getpos(".")
autocmd BufWritePre * %s/\s\+$//e
autocmd BufWritePre * %s/\n\+\%$//e
autocmd BufWritePre *.[ch] %s/\%$/\r/e " add trailing newline for ANSI C standard
autocmd BufWritePre *neomutt* %s/^--$/-- /e " dash-dash-space signature delimiter in emails
autocmd BufWritePre * cal cursor(currPos[1], currPos[2])

" Turns off highlighting on the bits of code that are changed, so the line that is changed is highlighted but the actual text that has changed stands out on the line and is readable.
if &diff
    highlight! link DiffText MatchParen
endif

" Function for toggling the bottom statusbar:
let s:hidden_all = 0
function! ToggleHiddenAll()
    if s:hidden_all  == 0
        let s:hidden_all = 1
        set noshowmode
        set noruler
        set laststatus=0
        set noshowcmd
    else
        let s:hidden_all = 0
        set showmode
        set ruler
        set laststatus=2
        set showcmd
    endif
endfunction

nnoremap <leader>h :call ToggleHiddenAll()<CR>

" default theme for now
" colorscheme catppuccin-mocha
" colorscheme dracula
"             tokyonight-night, tokyonight-sorm
"
" colorscheme catppuccin-mocha

" ===============================
" == CoC Autocomplete Mappings ==
" ===============================

" Trigger completion menu manually (like VSCode ctrl+space)
inoremap <silent><expr> <C-Space> coc#refresh()

" Use Tab for next suggestion and Shift-Tab for previous
inoremap <silent><expr> <Tab> pumvisible() ? "\<C-n>" : "\<Tab>"
inoremap <silent><expr> <S-Tab> pumvisible() ? "\<C-p>" : "\<S-Tab>"

" Accept suggestion with Enter
inoremap <silent><expr> <CR> pumvisible() ? coc#pum#confirm() : "\<CR>"

" use fuzzy finder inside vim
cnoreabbrev ff FZF!

" Transparent BG
hi normal guibg=NONE
