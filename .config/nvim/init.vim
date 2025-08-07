let mapleader = ","

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
Plug 'pangloss/vim-javascript'
Plug 'pantharshit00/vim-prisma'
Plug 'leafgarland/typescript-vim'
Plug 'maxmellon/vim-jsx-pretty'
Plug 'jparise/vim-graphql'
Plug 'neoclide/coc.nvim', {'branch': 'release'}

" Navigation
Plug 'jlanzarotta/bufexplorer'
nmap <leader>ac  <Plug>(coc-codeaction)
nmap <leader>qf  <Plug>(coc-fix-current)
nmap <silent> gd <Plug>(coc-definition)
nmap <silent> gy <Plug>(coc-type-definition)
nmap <silent> gi <Plug>(coc-implementation)
nmap <silent> gr <Plug>(coc-references)
nnoremap <C-d> <Plug>(coc-definition)
nnoremap <C-a> <C-o>

let g:coc_global_extensions = ['coc-tsserver', 'coc-python', 'coc-rust-analyzer', 'coc-go', 'coc-docker']
nnoremap <silent><leader>1 :source ~/.config/nvim/init.vim \| :PlugInstall<CR>
let g:kite_supported_languages = ['python', 'javascript']
let NERDTreeShowHidden=1

" More plugins
Plug 'folke/tokyonight.nvim'
Plug 'morhetz/gruvbox'
Plug 'rust-lang/rust.vim'
Plug 'cespare/vim-toml', {'branch': 'main'}
Plug 'stephpy/vim-yaml'
Plug 'plasticboy/vim-markdown'
Plug 'vim-airline/vim-airline'
Plug 'vim-airline/vim-airline-themes'
Plug 'ryanoasis/vim-devicons'
Plug 'scrooloose/nerdcommenter'
Plug 'sheerun/vim-polyglot'
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
Plug 'jiangmiao/auto-pairs'
Plug 'nvim-treesitter/nvim-treesitter', {'do': ':TSUpdate'}
Plug 'wbthomason/packer.nvim'
Plug 'svrana/neosolarized.nvim'
Plug 'nvim-lualine/lualine.nvim'
Plug 'onsails/lspkind-nvim'
Plug 'neovim/nvim-lspconfig'
Plug 'jose-elias-alvarez/null-ls.nvim'
Plug 'MunifTanjim/prettier.nvim'
Plug 'williamboman/mason.nvim'
Plug 'williamboman/mason-lspconfig.nvim'
Plug 'glepnir/lspsaga.nvim'
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
Plug 'kyazdani42/nvim-web-devicons'
Plug 'nvim-lualine/lualine.nvim'
call plug#end()

let g:AutoPairsMapCR = 0
let g:bargreybars_auto=0
let g:airline_solorized_bg='dark'
let g:airline_powerline_fonts=1
let g:airline#extension#tabline#left_sep=' '
let g:airline#extension#tabline#left_alt_sep='|'
let g:airline#extension#tabline#formatter='unique_tail'
let NERDTreeQuitOnOpen=1
let g:airline_theme = 'onedark'
let g:WebDevIconsUnicodeDecorateFolderNodes = 1
let g:WebDevIconsUnicodeDecorateFolderNodeDefaultSymbol = '#'
let g:WebDevIconsUnicodeDecorateFileNodesExtensionSymbols = {}
let g:WebDevIconsUnicodeDecorateFileNodesExtensionSymbols['nerdtree'] = '#'

" Prisma language server support via CoC
if executable('prisma-language-server')
  let g:coc_user_config = {
  \   'languageserver': {
  \     'prisma': {
  \       'command': 'prisma-language-server',
  \       'args': ['--stdio'],
  \       'filetypes': ['prisma'],
  \       'rootPatterns': ['schema.prisma'],
  \       'trace.server': 'verbose'
  \     }
  \   }
  \ }
endif

" Lua: theme setup (guarded)
lua << EOF
local ok, catppuccin = pcall(require, "catppuccin")
if ok then
  catppuccin.setup({
    flavour = "mocha",
    integrations = {
      bufferline = true,
      treesitter = true,
      coc_nvim = true,
      nvimtree = true,
      native_lsp = { enabled = true },
    }
  })
  vim.cmd.colorscheme "catppuccin"
end
EOF

" Lua: bufferline setup (guarded)
lua << EOF
local status_ok, bufferline = pcall(require, "bufferline")
if status_ok then
  bufferline.setup({
    options = {
      mode = "buffers",
      diagnostics = "nvim_lsp",
      separator_style = "slant",
      show_close_icon = false,
      show_buffer_close_icons = false,
      always_show_bufferline = true,
    },
  })
end
EOF

" Lua: Treesitter config (guarded)
lua << EOF
local ts_ok, configs = pcall(require, "nvim-treesitter.configs")
if ts_ok then
  configs.setup {
    ensure_installed = {
      "typescript", "tsx", "javascript", "json", "html", "css", "lua", "vim", "bash"
    },
    highlight = {
      enable = true,
      additional_vim_regex_highlighting = false,
    },
  }
end
EOF

set wildmode=longest,list,full
map <leader>o :setlocal spell! spelllang=en_us<CR>
set splitbelow splitright
map <leader>n :NERDTreeToggle<CR>
autocmd bufenter * if (winnr("$") == 1 && exists("b:NERDTree") && b:NERDTree.isTabTree()) | q | endif
if has('nvim')
    let NERDTreeBookmarksFile = stdpath('data') . '/NERDTreeBookmarks'
else
    let NERDTreeBookmarksFile = '~/.vim' . '/NERDTreeBookmarks'
endif

nm <leader>d :call ToggleDeadKeys()<CR>
imap <leader>d <esc>:call ToggleDeadKeys()<CR>a
nm <leader>i :call ToggleIPA()<CR>
imap <leader>i <esc>:call ToggleIPA()<CR>a
nm <leader>q :call ToggleProse()<CR>

if !exists('g:airline_symbols')
    let g:airline_symbols = {}
endif
let g:airline_symbols.colnr = ' C:'
let g:airline_symbols.linenr = ' L:'
let g:airline_symbols.maxlinenr = '☰ '

map <C-h> <C-w>h
map <C-j> <C-w>j
map <C-k> <C-w>k
map <C-l> <C-w>l

nnoremap <silent> <Tab> :BufferLineCycleNext<CR>
nnoremap <silent> <S-Tab> :BufferLineCyclePrev<CR>
nnoremap <silent> <C-x> :bd<CR>
nnoremap <leader>bl :ls<CR>:b<Space>
map <leader>s :!clear && shellcheck -x %<CR>
nnoremap S :%s//g<Left><Left>
autocmd BufNewFile,BufRead *.tsx,*.jsx set filetype=typescriptreact

autocmd BufWritePre * let currPos = getpos(".")
autocmd BufWritePre * %s/\s\+$//e
autocmd BufWritePre * %s/\n\+\%$//e
autocmd BufWritePre *.[ch] %s/\%$/\r/e
autocmd BufWritePre *neomutt* %s/^--$/-- /e
autocmd BufWritePre * cal cursor(currPos[1], currPos[2])

if &diff
    highlight! link DiffText MatchParen
endif

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
inoremap <silent><expr> <C-Space> coc#refresh()
inoremap <silent><expr> <Tab> pumvisible() ? "\<C-n>" : "\<Tab>"
inoremap <silent><expr> <S-Tab> pumvisible() ? "\<C-p>" : "\<S-Tab>"
inoremap <silent><expr> <CR> pumvisible() ? coc#pum#confirm() : "\<CR>"
cnoreabbrev ff FZF!
hi normal guibg=NONE
