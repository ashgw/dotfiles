let mapleader = ","

" Auto-install vim-plug if missing
if !filereadable(expand('${XDG_CONFIG_HOME:-$HOME/.config}/nvim/autoload/plug.vim'))
  echo "Downloading junegunn/vim-plug to manage plugins..."
  silent !mkdir -p ${XDG_CONFIG_HOME:-$HOME/.config}/nvim/autoload/
  silent !curl -fLo ${XDG_CONFIG_HOME:-$HOME/.config}/nvim/autoload/plug.vim --create-dirs https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
  autocmd VimEnter * PlugInstall
endif

" Jump placeholder
map ,, :keepp /<++><CR>ca<
imap ,, <esc>:keepp /<++><CR>ca<

" General settings
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
set wildmode=longest,list,full
set splitbelow splitright

" Plugin manager start
call plug#begin(stdpath('data') . '/plugged')

" Themes/UI
Plug 'Mofiqul/dracula.nvim'
Plug 'catppuccin/nvim', { 'as': 'catppuccin' }
Plug 'folke/tokyonight.nvim'
Plug 'morhetz/gruvbox'
Plug 'ryanoasis/vim-devicons'
Plug 'vim-airline/vim-airline'
Plug 'vim-airline/vim-airline-themes'
Plug 'nvim-lualine/lualine.nvim'
Plug 'akinsho/nvim-bufferline.lua'
Plug 'norcalli/nvim-colorizer.lua'
Plug 'svrana/neosolarized.nvim'

" Navigation & file browsing
Plug 'preservim/nerdtree', { 'on': 'NERDTreeToggle' }
Plug 'Xuyuanp/nerdtree-git-plugin'
Plug 'tiagofumo/vim-nerdtree-syntax-highlight'
Plug 'PhilRunninger/nerdtree-visual-selection'
Plug 'jlanzarotta/bufexplorer'
Plug 'nvim-telescope/telescope.nvim'
Plug 'nvim-telescope/telescope-file-browser.nvim'
Plug 'junegunn/fzf', { 'do': { -> fzf#install() } }
Plug 'junegunn/fzf.vim'

" Editing enhancements
Plug 'tpope/vim-surround'
Plug 'tpope/vim-commentary'
Plug 'scrooloose/nerdcommenter'
Plug 'jiangmiao/auto-pairs'
Plug 'windwp/nvim-autopairs'
Plug 'windwp/nvim-ts-autotag'
Plug 'tpope/vim-fugitive'
Plug 'jreybert/vimagit'
Plug 'vimwiki/vimwiki'
Plug 'junegunn/goyo.vim'
Plug 'plasticboy/vim-markdown'
Plug 'sheerun/vim-polyglot'

" Snippets
Plug 'SirVer/ultisnips'
Plug 'honza/vim-snippets'

" Languages
Plug 'pangloss/vim-javascript'
Plug 'leafgarland/typescript-vim'
Plug 'maxmellon/vim-jsx-pretty'
Plug 'ap/vim-css-color'
Plug 'jparise/vim-graphql'
Plug 'pantharshit00/vim-prisma'
Plug 'rust-lang/rust.vim'
Plug 'cespare/vim-toml', {'branch': 'main'}
Plug 'stephpy/vim-yaml'
Plug 'davidhalter/jedi-vim'
Plug 'vim-scripts/indentpython.vim'
Plug 'tpope/vim-fireplace', { 'for': 'clojure' }

" LSP / IntelliSense
Plug 'neoclide/coc.nvim', {'branch': 'release'}
Plug 'nvim-treesitter/nvim-treesitter', {'do': ':TSUpdate'}
Plug 'onsails/lspkind-nvim'
Plug 'neovim/nvim-lspconfig'
Plug 'jose-elias-alvarez/null-ls.nvim'
Plug 'MunifTanjim/prettier.nvim'
Plug 'williamboman/mason.nvim'
Plug 'williamboman/mason-lspconfig.nvim'
Plug 'glepnir/lspsaga.nvim'

call plug#end()

" CoC Config
let g:coc_global_extensions = ['coc-tsserver', 'coc-python', 'coc-rust-analyzer', 'coc-go', 'coc-docker']
let g:kite_supported_languages = ['python', 'javascript']
let NERDTreeShowHidden = 1
let NERDTreeQuitOnOpen = 1

" UI Tweaks
let g:airline_powerline_fonts=1
let g:airline_theme = 'onedark'
let g:airline#extension#tabline#left_sep=' '
let g:airline#extension#tabline#left_alt_sep='|'
let g:airline#extension#tabline#formatter='unique_tail'
let g:WebDevIconsUnicodeDecorateFolderNodes = 1
let g:WebDevIconsUnicodeDecorateFolderNodeDefaultSymbol = '#'
let g:WebDevIconsUnicodeDecorateFileNodesExtensionSymbols = {'nerdtree': '#'}

" Keybindings
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
map <leader>n :NERDTreeToggle<CR>
map <leader>o :setlocal spell! spelllang=en_us<CR>

" COC Navigation
nmap <leader>ac  <Plug>(coc-codeaction)
nmap <leader>qf  <Plug>(coc-fix-current)
nmap <silent> gd <Plug>(coc-definition)
nmap <silent> gy <Plug>(coc-type-definition)
nmap <silent> gi <Plug>(coc-implementation)
nmap <silent> gr <Plug>(coc-references)
nnoremap <C-d> <Plug>(coc-definition)
nnoremap <C-a> <C-o>
inoremap <silent><expr> <C-Space> coc#refresh()
inoremap <silent><expr> <Tab> pumvisible() ? "\<C-n>" : "\<Tab>"
inoremap <silent><expr> <S-Tab> pumvisible() ? "\<C-p>" : "\<S-Tab>"
inoremap <silent><expr> <CR> pumvisible() ? coc#pum#confirm() : "\<CR>"

" Prisma LSP support
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

" Auto formatting and cleanup
autocmd BufWritePre * let currPos = getpos(".")
autocmd BufWritePre * %s/\s\+$//e
autocmd BufWritePre * %s/\n\+\%$//e
autocmd BufWritePre * cal cursor(currPos[1], currPos[2])
autocmd BufNewFile,BufRead *.tsx,*.jsx set filetype=typescriptreact

" Diff mode fix
if &diff
  highlight! link DiffText MatchParen
endif

" NerdTree auto-close
autocmd bufenter * if (winnr("$") == 1 && exists("b:NERDTree") && b:NERDTree.isTabTree()) | q | endif
let NERDTreeBookmarksFile = stdpath('data') . '/NERDTreeBookmarks'

" UI toggle helpers
function! ToggleHiddenAll()
  if get(g:, 'hidden_ui', 0)
    set showmode ruler laststatus=2 showcmd
    let g:hidden_ui = 0
  else
    set noshowmode noruler laststatus=0 noshowcmd
    let g:hidden_ui = 1
  endif
endfunction

nnoremap <leader>h :call ToggleHiddenAll()<CR>

" Custom text modes
nm <leader>d :call ToggleDeadKeys()<CR>
imap <leader>d <esc>:call ToggleDeadKeys()<CR>a
nm <leader>i :call ToggleIPA()<CR>
imap <leader>i <esc>:call ToggleIPA()<CR>a
nm <leader>q :call ToggleProse()<CR>

" Airline symbols
let g:airline_symbols = {
\ 'colnr': ' C:',
\ 'linenr': ' L:',
\ 'maxlinenr': '☰ ',
\}

" Lua: Catppuccin setup
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

" Lua: Bufferline
lua << EOF
local ok, bufferline = pcall(require, "bufferline")
if ok then
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

" Lua: Treesitter
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

" Transparent background fix
hi normal guibg=NONE
