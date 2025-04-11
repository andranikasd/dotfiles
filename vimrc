" ~/.vimrc - Fully Commented and Extended for DevOps, Tmux, Clipboard, and System Tools
" Copyright (C) 2024 Andranik
"
" This configuration file is distributed under the GNU General Public License
" for open and free usage, sharing, and modification. Refer to
" https://www.gnu.org/licenses/gpl-3.0.html for full terms.
"
" ============================================================
" INSTALLATION GUIDE FOR FULL FUNCTIONALITY
" ============================================================
" 1. Install Vim (with +clipboard support if available) and curl
"    sudo apt update && sudo apt install vim curl
"
" 2. Install vim-plug plugin manager
"    curl -fLo ~/.vim/autoload/plug.vim --create-dirs \
"    https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
"
" 3. Install required binaries for full plugin use:
"    - Node.js: for coc.nvim (https://github.com/neoclide/coc.nvim)
"    - golang: for vim-go
"    - tmux: for terminal multiplexing
"    - fzf: for fuzzy search (https://github.com/junegunn/fzf)
"    - win32yank.exe → place in C:\tools (=/mnt/c/tools/) and chmod +x in WSL
"
" 4. Inside Vim, install plugins with:
"    :PlugInstall
"
" ============================================================
" KEYBINDING REFERENCE TABLE
" ============================================================
" Key Combo           ---+--- Action
" jk / kj             ---+--- Exit insert mode
" <C-h/j/k/l>         ---+--- Navigate between splits (normal/terminal)
" <Leader>tt          ---+--- Open terminal in current window
" <Leader>tn / tc     ---+--- Open new tab / Close current tab
" <C-Left> / <Right>  ---+--- Previous / Next tab
" <Leader>sh / sv     ---+--- Horizontal / Vertical split
" <Leader>= / -       ---+--- Resize split height + / -
" <Leader>> / <       ---+--- Resize split width + / -
" <Leader>n           ---+--- Toggle NERDTree
" <Leader>gb / gd     ---+--- Git blame / Git diff
" <Leader>y           ---+--- Yank visually selected text to Windows clipboard
" <Leader>Y           ---+--- Yank current line to Windows clipboard
" gd / gy / gi / gr   ---+--- Jump to Definition / Type / Impl / Refs (coc.nvim)
" BufWritePre         ---+--- Autoformat on save via Neoformat

" ------------------------------------------------------------
" 1. CORE VIM BEHAVIOR
" ------------------------------------------------------------
let mapleader = " "              " Set <Leader> to space for ergonomic shortcuts
set number                       " Show absolute line numbers
set relativenumber               " Relative line numbers for motions
set tabstop=2                    " Number of spaces per tab
set shiftwidth=2                 " Indentation width for autoindent
set expandtab                    " Convert tabs to spaces
set hidden                       " Allow background buffers
filetype plugin indent on        " Enable plugin & indent detection
syntax enable                    " Enable syntax highlighting

" ------------------------------------------------------------
" 2. SYSTEM CLIPBOARD (MANUAL YANK FOR WSL)
" ------------------------------------------------------------
" Visual mode clipboard yank to Windows
vnoremap <Leader>y :w !/mnt/c/tools/win32yank.exe -i --crlf<CR>
" Normal mode clipboard yank current line
nnoremap <Leader>Y :.w !/mnt/c/tools/win32yank.exe -i --crlf<CR>

" ------------------------------------------------------------
" 3. KEYBINDINGS
" ------------------------------------------------------------
" Insert mode escape shortcut
inoremap jk <Esc>
inoremap kj <Esc>

" Window navigation
nnoremap <C-h> <C-w>h
nnoremap <C-j> <C-w>j
nnoremap <C-k> <C-w>k
nnoremap <C-l> <C-w>l
tnoremap <C-h> <C-\><C-N><C-w>h
tnoremap <C-j> <C-\><C-N><C-w>j
tnoremap <C-k> <C-\><C-N><C-w>k
tnoremap <C-l> <C-\><C-N><C-w>l

" Terminal toggles
nnoremap <leader>tt :terminal ++curwin<CR>

" Tab navigation
nnoremap <leader>tn :tabnew<CR>
nnoremap <leader>tc :tabclose<CR>
nnoremap <C-Left> :tabprevious<CR>
nnoremap <C-Right> :tabnext<CR>
tnoremap <C-Left> <C-\><C-N>:tabprevious<CR>
tnoremap <C-Right> <C-\><C-N>:tabnext<CR>

" Split manipulation
nnoremap <leader>sh :split<CR>
nnoremap <leader>sv :vsplit<CR>
nnoremap <leader>= :resize +5<CR>
nnoremap <leader>- :resize -5<CR>
nnoremap <leader>> :vertical resize +5<CR>
nnoremap <leader>< :vertical resize -5<CR>

" NERDTree file explorer
nnoremap <leader>n :NERDTreeToggle<CR>

" Git
nnoremap <leader>gb :Gblame<CR>
nnoremap <leader>gd :Gdiffsplit<CR>

" Format before save
" autocmd BufWritePre *.go,*.py,*.js,*.ts,*.lua Neoformat

" ------------------------------------------------------------
" 4. PLUGIN SECTION (vim-plug)
" ------------------------------------------------------------
call plug#begin('~/.vim/plugged')

" Colorscheme
" Plug 'morhetz/gruvbox'

" LSP / Completion
Plug 'neoclide/coc.nvim', {'branch': 'release'}

" DevOps Tools
Plug 'fatih/vim-go', { 'do': ':GoUpdateBinaries' }
Plug 'tpope/vim-sensible'
Plug 'dense-analysis/ale'         " Linter for YAML, Ansible, Docker, etc.
Plug 'hashivim/vim-terraform'
Plug 'pearofducks/ansible-vim'
Plug 'towolf/vim-helm'
Plug 'mattn/vim-goimports'

" Git
Plug 'tpope/vim-fugitive'
Plug 'airblade/vim-gitgutter'

" Navigation
Plug 'preservim/nerdtree'
Plug 'junegunn/fzf.vim'

" Statusline
Plug 'vim-airline/vim-airline'
Plug 'vim-airline/vim-airline-themes'

" Editing
Plug 'jiangmiao/auto-pairs'
Plug 'tpope/vim-commentary'

" Formatting
Plug 'sbdchd/neoformat'

call plug#end()


" ============================================================
" 5. APPEARANCE
" ============================================================
" Use default colorscheme with customized highlights for softer tones
if exists("syntax_on")
  syntax reset
endif
set background=dark " Or 'light' depending on your terminal
colorscheme default

" Transparent background and soft contrast
highlight Normal ctermbg=NONE guibg=NONE
highlight NonText ctermbg=NONE guibg=NONE
highlight LineNr ctermfg=yellow ctermbg=NONE guifg=#d7af5f guibg=NONE
highlight StatusLine ctermfg=white ctermbg=black
highlight VertSplit ctermfg=grey ctermbg=NONE
highlight TabLineFill ctermfg=grey ctermbg=NONE

" Slightly dimmed comments, bold function names
highlight Comment ctermfg=darkgrey gui=italic
highlight Function ctermfg=yellow gui=bold
highlight Identifier ctermfg=white
highlight Type ctermfg=lightblue
highlight String ctermfg=yellow guifg=#ffd700

" Adjust Diagnostic colors (if using ALE or LSP)
highlight ALEWarning ctermfg=yellow
highlight ALEError ctermfg=red
highlight ALEInfo ctermfg=cyan


" " ------------------------------------------------------------
" 6. TERMINAL
" ------------------------------------------------------------
set splitright
set splitbelow
tnoremap <Esc> <C-\><C-n>

" ------------------------------------------------------------
" 7. COC LSP KEYBINDINGS
" ------------------------------------------------------------
nmap <silent> gd <Plug>(coc-definition)
nmap <silent> gy <Plug>(coc-type-definition)
nmap <silent> gi <Plug>(coc-implementation)
nmap <silent> gr <Plug>(coc-references)


" -----------------------------------------------------------
" 6. Go performance tunings 
" ----------------------------------------------------------

" let g:go_code_completion_enabled = 0
" let g:go_fmt_autosave = 0
" let g:go_imports_autosave = 0
" let g:go_doc_keywordprg_enabled = 0
" let g:go_def_mapping_enabled = 0
" let g:go_code_navigation_enabled = 0
" let g:go_metalinter_enabled = []

" Use ALE instead of vim-go for linting
let g:ale_linters = {
\   'go': ['gopls'],
\ }
let g:ale_fixers = {
\   'go': ['gofmt', 'goimports'],
\ }
let g:ale_lint_on_text_changed = 'never'
let g:ale_lint_on_insert_leave = 1
