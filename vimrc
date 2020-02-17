" hahaws vim config
" Edit By hahaws
" version: 0.1.0
"
" ==========================================================
" Vim-plug initialization
"

let vim_plug_installed = 0
let vim_plug_path = expand('~/.vim/autoload/plug.vim')
if !filereadable(vim_plug_path)
    echo "Installing Vim-plug..."
    echo ""
    silent !mkdir -p ~/.vim/autoload
    silent !curl -fLo ~/.vim/autoload/plug.vim --create-dirs https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
    let vim_plug_installed = 1
endif

" manually load vim-plug the first time
if vim_plug_installed
    :execute 'source '.fnameescape(vim_plug_path)
endif

" once Vim_plug installed, you can now modify the rest of the .vimrc as you wish
"
" =====================================================================================
" Active plugins
" you can find vim plug in https://vimawesome.com/
"
" this should not be deleted
call plug#begin('~/.vim/plugged')

" Plugins from github repos

" Better file browser
Plug 'scrooloose/nerdtree'

" line up text
Plug 'godlygeek/tabular'

" Auto close character
Plug 'Townk/vim-autoclose'

" Vim-airline
Plug 'vim-airline/vim-airline'

" Markdown
Plug 'iamcco/markdown-preview.nvim', { 'do': { -> mkdp#util#install_sync() }, 'for': ['markdown','vim-plug'] }



call plug#end()

" ==============================================================
" Install Plugins the first time vim runs

if vim_plug_installed
    echo "Plugins is installing"
    :PlugInstall
endif

" =================================================================
" Vim Plug setting
"

"
" NERDTree ----------------------------------------\
" 
let g:NERDTreeHidden              = 1
let g:NERDTreeShowHiddeen         = 0
let g:NERDTreeShowFiles           = 1
let g:NERDTreeShowLineNumbers     = 0
let g:NERDTreeWinSize             = 29
let g:NERDTreeMinimalUI           = 1
let g:NERDTreeDirArrows           = 1
autocmd bufenter * if (winnr("$") == 1 && exists("b:NERDTree") && b:NERDTree.isTabTree()) | q | endif
autocmd vimenter * NERDTree
autocmd VimEnter * wincmd w

let g:NERDTreeIndicatorMapCustom = {
            \ "Modified"  : "✹",
            \ "Staged"    : "✚",
            \ "Untracked" : "✭",
            \ "Renamed"   : "➜",
            \ "Unmerged"  : "═",
            \ "Deleted"   : "✖",
            \ "Dirty"     : "✗",
            \ "Clean"     : "✔︎",
            \ "Unknown"   : "?"
            \ }

"
" Markdown Preview------------------------------------
" 
let g:mkdp_auto_close = 1


"
" ctrlp -------------------------------------------------------------------
"
let g:ctrlp_user_command = [
            \ '.git/',
            \ 'git --git-dir=%s/.git ls-files -oc --exclude-standard'
            \ ]
let g:ctrlp_match_window       = 'bottom,order:btt,min:5,max:5,results:10'
let g:ctrlp_cmd                = 'CtrlPMixed'
let g:ctrlp_mruf_default_order = 1


" =========================================================================
" Apperence Setting
"

"
" Statusline -------------------------------------------------------------
"
"
" set laststatus=2
" set statusline=%{mode()}\ \ %<%f
" set statusline+=%w%h%m%r
" set statusline+=\ %{getcwd()}
" set statusline+=\ [%{&ff}:%{&fenc}:%Y]
" set statusline+=%=%-14.(%l,%c%V%)\ %p%%

"
" Color scheme -----------------------------------------------------------
"
colorscheme torte


"
"
filetype on
filetype plugin indent on
filetype plugin on

set ambiwidth=double
set autoread
set autowriteall
" backup on
set backup
set smartindent cindent autoindent
set shiftwidth=4 tabstop=4 smarttab
set cursorline
set expandtab
set ma
" endcoding
set encoding=utf-8 fileencodings=utf-8,ucs-bom,cp936 fileencoding=utf-8
set foldmethod=manual
set hidden hlsearch
set number
set shell=/bin/bash
set t_co=256        " Make vim better in putty
hi Normal ctermfg=252 ctermbg=none

if !has('gui_running')
  set t_Co=256
endif

set textwidth=0
syntax on

" set timeoutlen
set timeoutlen=50

" ================================================================================
" Custom Setting
"

" move in insert mode
inoremap <C-l> <Right>
inoremap <C-h> <Left>
inoremap <C-j> <Down>
inoremap <C-k> <Up>

" delete in move mode
inoremap <C-d><C-l> <esc>ddo
inoremap <C-d><C-x> <esc>xa
inoremap <C-o> <esc>o
" Toggle NERDTree display
map <C-t> :NERDTreeToggle<CR>

" Run file
com! -nargs=* Run call RunFile()
func! RunFile()
  exec "w"
  if &filetype == 'c'
    exec "!gcc % -o %< && ./%<"
  elseif &filetype == 'cpp'
    exec "!g++ % -o %< && ./%<"
  elseif &filetype == 'java'
    exec "!javac %"
  elseif &filetype == 'sh'
    :!bash %
  elseif &filetype == 'python'
    silent! exec "!clear"
    exec "!python3 %"
  elseif &filetype == 'html'
    exec "!firefox % &"
  elseif &filetype == 'markdown'
    exec "MarkdownPreview"
  elseif &filetype == 'vimwiki'
    exec "MarkdownPreview"
  endif
  exec "redraw!"
endfunc

com! -nargs=* Run call TRunFile()
func! TRunFile()
  exec "w"
  if &filetype == 'c'
    exec "!gcc % -o %< && time ./%<"
  elseif &filetype == 'cpp'
    exec "!g++ % -o %< && time ./%<"
  elseif &filetype == 'java'
    exec "!javac % && time java %<"
  elseif &filetype == 'sh'
    :!time bash %
  elseif &filetype == 'python'
    silent! exec "!clear"
    exec "!time python3 %"
  elseif &filetype == 'html'
    exec "!firefox % &"
  elseif &filetype == 'markdown'
    exec "MarkdownPreview"
  elseif &filetype == 'vimwiki'
    exec "MarkdownPreview"
  endif
  exec "redraw!"
endfunc

com! -nargs=* Compile call CompileFile()
func! CompileFile()
  exec "w"
  if &filetype == 'c'
    silent exec "!gcc % -o %<"
  elseif &filetype == 'cpp'
    silent exec "!g++ % -o %<"
  elseif &filetype == 'java'
    silent exec "!javac % &&"
  endif
  exec "redraw!"
endfunc


