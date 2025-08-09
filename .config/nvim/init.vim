" =========================================================d
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
" Buffers
" === UI: lualine + bufferline only
" Truecolor and global statusline for lualine
set termguicolors
set laststatus=3

lua << EOF
-- Safe Catppuccin palette load with fallback, that bubble line
local ok, palettes = pcall(require, "catppuccin.palettes")
local pal
if ok and palettes and type(palettes.get_palette) == "function" then
  pal = palettes.get_palette("mocha")
else
  pal = {
    rosewater = "#f5e0dc", flamingo = "#f2cdcd", pink = "#f5c2e7", mauve = "#cba6f7",
    red = "#f38ba8", maroon = "#eba0ac", peach = "#fab387", yellow = "#f9e2af",
    green = "#a6e3a1", teal = "#94e2d5", sky = "#89dceb", sapphire = "#74c7ec",
    blue = "#89b4fa", lavender = "#b4befe",
    text = "#cdd6f4", subtext1 = "#bac2de", overlay0 = "#6c7086",
    surface0 = "#313244", base = "#1e1e2e", mantle = "#181825", crust = "#11111b",
  }
end

-- Bubbles theme
local bubbles_theme = {
  normal = {
    a = { fg = pal.crust, bg = pal.lavender, gui = "bold" },
    b = { fg = pal.text,  bg = pal.surface0 },
    c = { fg = pal.subtext1, bg = pal.base },
  },
  insert  = { a = { fg = pal.crust, bg = pal.green,   gui = "bold" } },
  visual  = { a = { fg = pal.crust, bg = pal.mauve,   gui = "bold" } },
  replace = { a = { fg = pal.crust, bg = pal.red,     gui = "bold" } },
  command = { a = { fg = pal.crust, bg = pal.peach,   gui = "bold" } },
  inactive = {
    a = { fg = pal.overlay0, bg = pal.mantle },
    b = { fg = pal.overlay0, bg = pal.mantle },
    c = { fg = pal.overlay0, bg = pal.mantle },
  },
}

require("lualine").setup({
  options = {
    theme = bubbles_theme,
    icons_enabled = true,
    component_separators = { left = "", right = "" },
    section_separators   = { left = "", right = "" },
    globalstatus = true,
    disabled_filetypes = { "NERDTree", "packer" },
  },
  sections = {
    lualine_a = { { "mode", separator = { left = "" }, right_padding = 2 } },
    lualine_b = { "branch", "diff", "diagnostics" },
    lualine_c = { { "filename", path = 1 } },
    lualine_x = { "encoding", "fileformat", "filetype" },
    lualine_y = { "progress" },
    lualine_z = { { "location", separator = { right = "" }, left_padding = 2 } },
  },
  inactive_sections = {
    lualine_a = { { "filename", separator = { left = "", right = "" } } },
    lualine_b = {}, lualine_c = {},
    lualine_x = {}, lualine_y = {}, lualine_z = {},
  },
  extensions = { "fzf", "quickfix", "fugitive" },
})
EOF

set laststatus=2  " show statusline so lualine renders

lua << EOF
require('lualine').setup({
  options = {
    theme = 'auto',
    icons_enabled = true,
    component_separators = '',
    section_separators = ''
  },
  extensions = { 'fzf', 'quickfix', 'fugitive' }
})
EOF

" Better buffer UX
silent! nunmap <leader>bl
nnoremap <silent> <leader>bl <cmd>Telescope buffers sort_lastused=true ignore_current_buffer=true<cr>
nnoremap <silent> <leader>bp :BufferLinePick<CR>

" Toggle buffer tabs visibility for a clean top bar
let g:ash_showtabline = 2
function! ToggleBufferTabs()
  if g:ash_showtabline == 2
    let g:ash_showtabline = 0
  else
    let g:ash_showtabline = 2
  endif
  execute 'set showtabline=' . g:ash_showtabline
endfunction
nnoremap <silent> <leader>bt :call ToggleBufferTabs()<CR>

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

" configure auto imports for TS
let g:coc_user_config = {
\   'typescript.suggest.autoImports': v:true,
\   'javascript.suggest.autoImports': v:true,
\   'typescript.preferences.importModuleSpecifier': 'relative',
\   'javascript.preferences.importModuleSpecifier': 'relative',
\   'suggest.noselect': v:false
\ }

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
" === VSCode-style Undo/Redo, Save, Suspend ===
" 0) Clear any old conflicting maps
silent! nunmap <C-r>
silent! vunmap <C-r>
silent! iunmap <C-r>
silent! nunmap <C-u>
silent! vunmap <C-u>
silent! iunmap <C-u>
silent! nunmap <C-z>
silent! vunmap <C-z>
silent! iunmap <C-z>
silent! nunmap <C-s>
silent! vunmap <C-s>
silent! iunmap <C-s>
silent! nunmap <C-q>
silent! vunmap <C-q>
silent! iunmap <C-q>

" 1) Ctrl+Z = Undo
nnoremap <C-z> u
inoremap <C-z> <C-o>u
vnoremap <C-z> <Esc>u

" 2) Redo
" Ctrl+Shift+Z preferred, Ctrl+Y as universal fallback
nnoremap <C-S-z> <C-r>
inoremap <C-S-z> <C-o><C-r>
vnoremap <C-S-z> <Esc><C-r>
nnoremap <C-y> <C-r>
inoremap <C-y> <C-o><C-r>
vnoremap <C-y> <Esc><C-r>

" 3) Ctrl+S = Save (only writes if modified)
nnoremap <C-s> :update<CR>
inoremap <C-s> <C-o>:update<CR>
vnoremap <C-s> <Esc>:update<CR>gv

" 4) Ctrl+Q = Suspend to shell (quit with :q! manually)
nnoremap <C-q> :stop<CR>
inoremap <C-q> <C-o>:stop<CR>
vnoremap <C-q> <Esc>:stop<CR>

" =====
" Buffer navigation
"
" Smart buffer cycling: Bufferline when visible, fallback to :bnext/:bprevious
function! CycleBufNext()
  if exists(':BufferLineCycleNext') && &showtabline > 0
    execute 'BufferLineCycleNext'
  else
    bnext
  endif
endfunction

function! CycleBufPrev()
  if exists(':BufferLineCyclePrev') && &showtabline > 0
    execute 'BufferLineCyclePrev'
  else
    bprevious
  endif
endfunction

nnoremap <silent> <Tab>   :call CycleBufNext()<CR>
nnoremap <silent> <S-Tab> :call CycleBufPrev()<CR>
" Pick by label even if bar is hidden
nnoremap <silent> <leader>bp :BufferLinePick<CR>
" Quick list of buffers, then type the number
nnoremap <leader>bl :ls<CR>:b<Space>

"""
nnoremap <silent> <C-x> :bd<CR>
nnoremap <leader>bl :ls<CR>:b<Space>
"""
" Open/close quickfix and hop through results fast
nnoremap <silent> <leader>qo :copen<CR>
nnoremap <silent> <leader>qc :cclose<CR>
nnoremap <silent> ]q :cnext<CR>
nnoremap <silent> [q :cprev<CR>

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
" jump to all usages (list) – CoC
nnoremap <silent> <C-r> <Plug>(coc-references)
" Spell-check toggle
map <leader>o :setlocal spell! spelllang=en_us<CR>
" Add missing imports via code action
nnoremap <leader>mi :call CocActionAsync('codeAction', '', ['source.addMissingImports.ts'])<CR>
" Organize imports
nnoremap <leader>oi :call CocActionAsync('runCommand', 'editor.action.organizeImport')<CR>

" NerdTree toggle

" --- NERDTree clean UI + fixed width + open-on-current-file ---
let g:NERDTreeWinPos = 'left'
let g:NERDTreeWinSize = 28          " default width
let g:NERDTreeMinimalUI = 1
let g:NERDTreeDirArrows = 1
let g:NERDTreeShowHidden = 1

" Tidy the tree window visuals
augroup NerdTreeTweak
  autocmd!
  autocmd FileType nerdtree setlocal nonumber norelativenumber nocursorline signcolumn=no
  autocmd FileType nerdtree setlocal winfixwidth
augroup END

" Toggle tree focused on the current file, enforce width
function! ToggleNERDTreeFind()
  if exists("t:NERDTreeBufName") && bufwinnr(t:NERDTreeBufName) != -1
    NERDTreeClose
  else
    execute 'NERDTreeFind'
    execute 'vertical resize ' . get(g:, 'NERDTreeWinSize', 28)
  endif
endfunction
nnoremap <leader>n :call ToggleNERDTreeFind()<CR>

" Fast resize when the width feels wrong
nnoremap <silent> <leader>[ :let g:NERDTreeWinSize=max([16, get(g:,'NERDTreeWinSize',28)-4]) \| execute 'vertical resize ' . g:NERDTreeWinSize<CR>
nnoremap <silent> <leader>] :let g:NERDTreeWinSize=get(g:,'NERDTreeWinSize',28)+4 \| execute 'vertical resize ' . g:NERDTreeWinSize<CR>

" Equalize non-tree windows without touching the fixed tree
nnoremap <silent> <leader>= :wincmd =<CR>



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
