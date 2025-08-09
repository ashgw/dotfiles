" ==========================================================
"                 LEADER & BOOTSTRAP SETUP
" ==========================================================
let mapleader = ","

" Auto setup all the plugins on first launch (vim-plug bootstrap)
if ! filereadable(system('echo -n "${XDG_CONFIG_HOME:-$HOME/.config}/nvim/autoload/plug.vim"'))
    echo "Downloading junegunn/vim-plug to manage plugins..."
    silent !mkdir -p ${XDG_CONFIG_HOME:-$HOME/.config}/nvim/autoload/
    silent !curl "https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim" > ${XDG_CONFIG_HOME:-$HOME/.config}/nvim/autoload/plug.vim
    autocmd VimEnter * PlugInstall
endif

" Custom mapping for quick text placeholder navigation
map ,, :keepp /<++><CR>ca<
imap ,, <esc>:keepp /<++><CR>ca<

" ==========================================================
"                   BASIC EDITOR SETTINGS
" ==========================================================
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

" ==========================================================
"                      PLUGIN SECTION
" ==========================================================
call plug#begin(system('echo -n "${XDG_CONFIG_HOME:-$HOME/.config}/nvim/plugged"'))

" ----- Theme Plugins -----
Plug 'Mofiqul/dracula.nvim'
Plug 'catppuccin/nvim', { 'as': 'catppuccin' }
Plug 'folke/tokyonight.nvim'
Plug 'morhetz/gruvbox'
Plug 'svrana/neosolarized.nvim'
Plug 'nvim-lualine/lualine.nvim'

" ----- Helper Plugins -----
Plug 'nvim-lua/plenary.nvim'
Plug 'tpope/vim-surround'
Plug 'preservim/nerdtree'
Plug 'junegunn/goyo.vim'
Plug 'jreybert/vimagit'
Plug 'vimwiki/vimwiki'
Plug 'vim-airline/vim-airline-themes'
Plug 'vim-airline/vim-airline'
Plug 'tpope/vim-commentary'
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
Plug 'scrooloose/nerdcommenter', { 'on':  'NERDTreeToggle' }
Plug 'tpope/vim-fireplace', { 'for': 'clojure' }
Plug 'junegunn/fzf', { 'do': { -> fzf#install() } }
Plug 'junegunn/fzf.vim'
Plug 'jiangmiao/auto-pairs'
Plug 'nvim-treesitter/nvim-treesitter', {'do': ':TSUpdate'}
Plug 'wbthomason/packer.nvim'
Plug 'onsails/lspkind-nvim'
Plug 'neovim/nvim-lspconfig'
Plug 'jose-elias-alvarez/null-ls.nvim'
Plug 'MunifTanjim/prettier.nvim'
Plug 'williamboman/mason.nvim'
Plug 'williamboman/mason-lspconfig.nvim'
Plug 'glepnir/lspsaga.nvim'
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

" ----- Language-specific Plugins -----
Plug 'ap/vim-css-color'
Plug 'prisma/vim-prisma'
Plug 'pangloss/vim-javascript'
Plug 'leafgarland/typescript-vim'
Plug 'maxmellon/vim-jsx-pretty'
Plug 'jparise/vim-graphql'
Plug 'rust-lang/rust.vim'
Plug 'cespare/vim-toml', {'branch': 'main'}
Plug 'stephpy/vim-yaml'
Plug 'plasticboy/vim-markdown'

" ----- LSP/Autocomplete -----
Plug 'neoclide/coc.nvim', {'branch': 'release'}

call plug#end()

" ==========================================================
"                      PLUGIN CONFIG
" ==========================================================
" Airline configuration
let g:airline_solorized_bg='dark'
let g:airline_powerline_fonts=1
let g:airline#extension#tabline#left_sep=' '
let g:airline#extension#tabline#left_alt_sep='|'
let g:airline#extension#tabline#formatter='unique_tail'
let g:airline_theme = 'onedark'
let g:airline_symbols = {}
let g:airline_symbols.colnr = ' C:'
let g:airline_symbols.linenr = ' L:'
let g:airline_symbols.maxlinenr = '☰ '

" NERDTree settings
let NERDTreeShowHidden=1
let NERDTreeQuitOnOpen=1

" Devicons settings
let g:WebDevIconsUnicodeDecorateFolderNodes = 1
let g:WebDevIconsUnicodeDecorateFolderNodeDefaultSymbol = '#'
let g:WebDevIconsUnicodeDecorateFileNodesExtensionSymbols = {}
let g:WebDevIconsUnicodeDecorateFileNodesExtensionSymbols['nerdtree'] = '#'

" Auto-pairs
let g:AutoPairsMapCR = 0

" Kite supported languages
let g:kite_supported_languages = ['python', 'javascript']

" CoC global extensions
let g:coc_global_extensions = ['coc-tsserver', 'coc-python', 'coc-rust-analyzer', 'coc-go', 'coc-docker']

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

" ==========================================================
"                    LUA CONFIGURATIONS
" ==========================================================

" Telescope config
lua << EOF
local telescope = require("telescope")
local actions = require("telescope.actions")

telescope.setup({
  defaults = {
    vimgrep_arguments = {
      "rg",
      "--hidden",
      "--glob", "!.git/*",
      "--no-heading",
      "--with-filename",
      "--line-number",
      "--column",
      "--smart-case",
    },
    sorting_strategy = "ascending",
    layout_config = { prompt_position = "top" },
    mappings = {
      i = { ["<C-q>"] = actions.send_selected_to_qflist + actions.open_qflist },
      n = { ["q"] = actions.close },
    },
  },
  pickers = {
    live_grep = { only_sort_text = true },
    grep_string = { only_sort_text = true },
  },
})
EOF

" Catppuccin theme setup
lua << EOF
require("catppuccin").setup({
  flavour = "mocha",
  integrations = {
    bufferline = true,
    treesitter = true,
    coc_nvim = true,
    nvimtree = true,
    native_lsp = { enabled = true }
  }
})
vim.cmd.colorscheme "catppuccin"
EOF

" Bufferline setup
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

" Treesitter configuration
lua << EOF
require'nvim-treesitter.configs'.setup {
  ensure_installed = {
    "typescript", "tsx", "javascript", "json",
    "html", "css", "lua", "vim", "bash"
  },
  highlight = {
    enable = true,
    additional_vim_regex_highlighting = false,
  },
}
EOF

" ==========================================================
"                  KEYBINDINGS & COMMANDS
" ==========================================================
" Buffer navigation
nnoremap <silent> <Tab> :BufferLineCycleNext<CR>
nnoremap <silent> <S-Tab> :BufferLineCyclePrev<CR>
nnoremap <silent> <C-x> :bd<CR>
nnoremap <leader>bl :ls<CR>:b<Space>

" Split navigation
map <C-h> <C-w>h
map <C-j> <C-w>j
map <C-k> <C-w>k
map <C-l> <C-w>l

" CoC navigation
nmap <leader>ac  <Plug>(coc-codeaction)
nmap <leader>qf  <Plug>(coc-fix-current)
nmap <silent> gd <Plug>(coc-definition)
nmap <silent> gy <Plug>(coc-type-definition)
nmap <silent> gi <Plug>(coc-implementation)
nmap <silent> gr <Plug>(coc-references)
nnoremap <C-d> <Plug>(coc-definition)
nnoremap <C-a> <C-o>

" Spell-check toggle
map <leader>o :setlocal spell! spelllang=en_us<CR>

" NerdTree toggle
map <leader>n :NERDTreeToggle<CR>

" FZF alias
cnoreabbrev ff FZF!

" CoC Autocomplete mappings
inoremap <silent><expr> <C-Space> coc#refresh()
inoremap <silent><expr> <Tab> pumvisible() ? "\<C-n>" : "\<Tab>"
inoremap <silent><expr> <S-Tab> pumvisible() ? "\<C-p>" : "\<S-Tab>"
inoremap <silent><expr> <CR> pumvisible() ? coc#pum#confirm() : "\<CR>"

" Replace all alias
nnoremap S :%s//g<Left><Left>

" Telescope search hotkeys
nnoremap <silent> <leader>r <cmd>Telescope live_grep<cr>
nnoremap <silent> <leader>R <cmd>Telescope grep_string<cr>

" ==========================================================
"                  AUTOCOMMANDS & FUNCTIONS
" ==========================================================
" Filetype fixes
autocmd BufNewFile,BufRead *.tsx,*.jsx set filetype=typescriptreact

" Remove trailing whitespace on save
autocmd BufWritePre * let currPos = getpos(".")
autocmd BufWritePre * %s/\s\+$//e
autocmd BufWritePre * %s/\n\+\%$//e
autocmd BufWritePre *.[ch] %s/\%$/\r/e
autocmd BufWritePre *neomutt* %s/^--$/-- /e
autocmd BufWritePre * cal cursor(currPos[1], currPos[2])

" Close NERDTree if it's the last window
autocmd bufenter * if (winnr("$") == 1 && exists("b:NERDTree") && b:NERDTree.isTabTree()) | q | endif

" Diff highlighting tweak
if &diff
    highlight! link DiffText MatchParen
endif

" Toggle all UI elements (status bar, mode, ruler)
let s:hidden_all = 0
function! ToggleHiddenAll()
    if s:hidden_all == 0
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

" ==========================================================
"                  MISC VISUAL SETTINGS
" ==========================================================
hi normal guibg=NONE
