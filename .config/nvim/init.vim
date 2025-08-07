let mapleader = ","

" Bootstrap vim-plug if missing
if !filereadable(system('echo -n "${XDG_CONFIG_HOME:-$HOME/.config}/nvim/autoload/plug.vim"'))
  echo "Downloading junegunn/vim-plug to manage plugins..."
  silent !mkdir -p ${XDG_CONFIG_HOME:-$HOME/.config}/nvim/autoload/
  silent !curl -fLo ${XDG_CONFIG_HOME:-$HOME/.config}/nvim/autoload/plug.vim --create-dirs \
        https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
  autocmd VimEnter * PlugInstall
endif

" Shell with alias support
set shell=/usr/bin/zsh
set shellcmdflag=-ic

" General UI
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
set nocompatible
filetype plugin on
syntax on
set wildmode=longest,list,full
set splitbelow splitright
set laststatus=2
set showmode
set showcmd
set ruler

" Airline + Catppuccin integration
let g:airline_powerline_fonts = 1
let g:airline_theme = 'catppuccin'
let g:airline_extensions = ['branch', 'tabline', 'hunks', 'virtualenv']
let g:airline#extensions#tabline#enabled = 1
let g:airline#extensions#tabline#formatter = 'unique_tail'

" Custom mappings
map ,, :keepp /<++><CR>ca<
imap ,, <esc>:keepp /<++><CR>ca<
nnoremap c "_c

" Plugin install
call plug#begin(system('echo -n "${XDG_CONFIG_HOME:-$HOME/.config}/nvim/plugged"'))

" === Theme & UI ===
Plug 'catppuccin/nvim', { 'as': 'catppuccin' }
Plug 'Mofiqul/dracula.nvim'
Plug 'folke/tokyonight.nvim'
Plug 'morhetz/gruvbox'
Plug 'ryanoasis/vim-devicons'
Plug 'vim-airline/vim-airline'
Plug 'vim-airline/vim-airline-themes'

" === File nav & fuzzy ===
Plug 'kyazdani42/nvim-tree.lua'
Plug 'ibhagwan/fzf-lua'
Plug 'junegunn/fzf', { 'do': { -> fzf#install() } }
Plug 'junegunn/fzf.vim'

" === Code & Language ===
Plug 'neoclide/coc.nvim', {'branch': 'release'}
Plug 'pantharshit00/vim-prisma'
Plug 'leafgarland/typescript-vim'
Plug 'pangloss/vim-javascript'
Plug 'maxmellon/vim-jsx-pretty'
Plug 'jparise/vim-graphql'
Plug 'rust-lang/rust.vim'
Plug 'cespare/vim-toml', {'branch': 'main'}
Plug 'stephpy/vim-yaml'
Plug 'plasticboy/vim-markdown'
Plug 'ap/vim-css-color'
Plug 'davidhalter/jedi-vim'
Plug 'vim-scripts/indentpython.vim'
Plug 'tpope/vim-fireplace', { 'for': 'clojure' }

" === Treesitter, LSP, Lint, Format ===
Plug 'nvim-treesitter/nvim-treesitter', {'do': ':TSUpdate'}
Plug 'williamboman/mason.nvim'
Plug 'williamboman/mason-lspconfig.nvim'
Plug 'neovim/nvim-lspconfig'
Plug 'jose-elias-alvarez/null-ls.nvim'
Plug 'MunifTanjim/prettier.nvim'
Plug 'onsails/lspkind-nvim'
Plug 'glepnir/lspsaga.nvim'

" === Extra Productivity ===
Plug 'tpope/vim-surround'
Plug 'tpope/vim-commentary'
Plug 'scrooloose/nerdcommenter'
Plug 'sheerun/vim-polyglot'
Plug 'jlanzarotta/bufexplorer'
Plug 'junegunn/goyo.vim'
Plug 'jreybert/vimagit'
Plug 'vimwiki/vimwiki'
Plug 'windwp/nvim-autopairs'
Plug 'windwp/nvim-ts-autotag'
Plug 'norcalli/nvim-colorizer.lua'
Plug 'akinsho/nvim-bufferline.lua'
Plug 'lewis6991/gitsigns.nvim'
Plug 'dinhhuy258/git.nvim'
Plug 'folke/zen-mode.nvim'
Plug 'iamcco/markdown-preview.nvim'
Plug 'SirVer/ultisnips' | Plug 'honza/vim-snippets'

call plug#end()

" CoC extensions
let g:coc_global_extensions = ['coc-tsserver', 'coc-python', 'coc-rust-analyzer', 'coc-go', 'coc-docker']
let g:kite_supported_languages = ['python', 'javascript']

" Prisma LSP for CoC
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

" Lua config
lua << EOF
-- Theme
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

-- Nvim tree
require("nvim-tree").setup {
  view = { width = 35, side = "left", preserve_window_proportions = true },
  renderer = {
    highlight_git = true,
    icons = { show = { file = true, folder = true, folder_arrow = true, git = true } },
  },
  filters = { dotfiles = false },
}

-- FZF Lua
require("fzf-lua").setup({
  winopts = {
    preview = { default = "bat" }
  }
})

-- Bufferline
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

-- Treesitter
require'nvim-treesitter.configs'.setup {
  ensure_installed = {
    "typescript", "tsx", "javascript", "json", "html",
    "css", "lua", "vim", "bash"
  },
  highlight = {
    enable = true,
    additional_vim_regex_highlighting = false,
  },
}

-- Auto-close nvim if only nvim-tree is open
vim.api.nvim_create_autocmd("BufEnter", {
  nested = true,
  callback = function()
    if #vim.api.nvim_list_wins() == 1 and vim.bo.filetype == "NvimTree" then
      vim.cmd("quit")
    end
  end,
})
EOF

" === Keymaps ===
nnoremap <leader>n :NvimTreeToggle<CR>
nnoremap <leader>f :lua require("fzf-lua").files()<CR>
nnoremap <leader>ac  <Plug>(coc-codeaction)
nnoremap <leader>qf  <Plug>(coc-fix-current)
nnoremap <silent> gd <Plug>(coc-definition)
nnoremap <silent> gy <Plug>(coc-type-definition)
nnoremap <silent> gi <Plug>(coc-implementation)
nnoremap <silent> gr <Plug>(coc-references)
nnoremap <C-d> <Plug>(coc-definition)
nnoremap <C-a> <C-o>
nnoremap <leader>1 :source ~/.config/nvim/init.vim \| :PlugInstall<CR>
nnoremap <leader>bl :ls<CR>:b<Space>
nnoremap <silent> <Tab> :BufferLineCycleNext<CR>
nnoremap <silent> <S-Tab> :BufferLineCyclePrev<CR>
nnoremap <silent> <C-x> :bd<CR>
nnoremap <leader>s :!clear && shellcheck -x %<CR>
nnoremap S :%s//g<Left><Left>

" Split navigation
map <C-h> <C-w>h
map <C-j> <C-w>j
map <C-k> <C-w>k
map <C-l> <C-w>l

" CoC completion mappings
inoremap <silent><expr> <C-Space> coc#refresh()
inoremap <silent><expr> <Tab> pumvisible() ? "\<C-n>" : "\<Tab>"
inoremap <silent><expr> <S-Tab> pumvisible() ? "\<C-p>" : "\<S-Tab>"
inoremap <silent><expr> <CR> pumvisible() ? coc#pum#confirm() : "\<CR>"

" Filetype fixes
autocmd BufNewFile,BufRead *.tsx,*.jsx set filetype=typescriptreact

" Whitespace & formatting cleanup
autocmd BufWritePre * let currPos = getpos(".")
autocmd BufWritePre * %s/\s\+$//e
autocmd BufWritePre * %s/\n\+\%$//e
autocmd BufWritePre * cal cursor(currPos[1], currPos[2])

" Transparent background
hi Normal guibg=NONE
