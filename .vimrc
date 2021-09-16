
"
" _   ________  ___    _________  _  _______________
"| | / /  _/  |/  /   / ___/ __ \/ |/ / __/  _/ ___/
"| |/ // // /|_/ /   / /__/ /_/ /    / _/_/ // (_ / 
"|___/___/_/  /_/    \___/\____/_/|_/_/ /___/\___/  
"                                                   
"
" vim config
"

" Vim-Plug =====================================================
let vim_plug_installed=0
if has('unix')
    let vim_plug_path = expand('~/.vim/autoload/plug.vim')
    let vim_plug_home=expand('~/.vim/plugged')
    if !filereadable(vim_plug_path)
        echo "Installing Vim-plug..."
        echo ""
        silent !mkdir -p ~/.vim/autoload
        silent !curl -fLo ~/.vim/autoload/plug.vim --create-dirs https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
        let vim_plug_installed = 1
    endif
endif

if vim_plug_installed
    :execute 'source ' . fnameescape(vim_plug_path)
endif

" Plug Config ==================================================
call plug#begin(vim_plug_home)

Plug 'neoclide/coc.nvim', {'branch': 'release'}

Plug 'kien/rainbow_parentheses.vim'

call plug#end()

function! PlugLoaded(name)
    return (
        \ has_key(g:plugs, a:name) &&
        \ isdirectory(g:plugs[a:name].dir) &&
        \ strlen(g:plugs[a:name].dir) > 2 &&
        \ stridx(&rtp, g:plugs[a:name].dir[:-2]) >= 0)
endfunction

" coc.nvim config
if PlugLoaded('coc.nvim')
    nmap <silent> gd <Plug>(coc-definition)
    nmap <silent> gy <Plug>(coc-type-definition)
    nmap <silent> gi <Plug>(coc-implementation)
    nmap <silent> gr <Plug>(coc-references)
else
    echo "Coc.nvim is not installed. Try to install it"
endif

" rainbow_parentheses.vim config
if PlugLoaded('rainbow_parentheses.vim')
    let g:rainbow_active = 1
    au VimEnter * RainbowParenthesesToggle
    au Syntax * RainbowParenthesesLoadRound
    au Syntax * RainbowParenthesesLoadSquare
    au Syntax * RainbowParenthesesLoadBraces
else
    echom "RainbowParentheses.vim is not installed. Try to install it"
endif

" Basic Config ===================================

colorscheme ron

set backspace=indent,eol,start

set nu
set cursorline
set mouse=a
set wildmenu
set ffs=unix,mac,dos
set ruler
set rulerformat=%30(%F%=%y%m%r%w\ %l,%c\ %p%%%)
set showcmd
set showmatch
set incsearch
set cindent
set scrolloff=3
set timeoutlen=200

autocmd InsertEnter * set nocursorline
autocmd InsertLeave * set cursorline

filetype on
filetype plugin on
syntax enable

noremap q :noh<CR>

" Indent Config ================================================
set expandtab
set shiftwidth=4
set tabstop=4
set softtabstop=4
"use :retab! to convert <tab> to <space>

set list
set listchars=tab:··>

" Switch Indent of Space and Tab
function! s:SwitchIndent(opt)
    if a:opt ==? 'TAB'
        set noexpandtab
        %retab!
    elseif a:opt ==? 'SPACE'
        set expandtab
        %retab!
    else
        echo "Indent [Tab|Space]"
    endif
endfunc

function! s:SwitchIndentComplete(ArgLead, CmdLine, CursorPos)
    let myList = ['SPACE', "TAB"]
    return filter(myList, 'v:val =~ "^'. toupper(a:ArgLead) .'"')
endfunction
command! -bang -complete=customlist,s:SwitchIndentComplete -nargs=1 Indent call s:SwitchIndent(<q-args>)


" Paste Config =================================================
function s:SetPaste()
    set paste
    echo "Set paste"
endfunc

function s:SetNoPaste()
    set nopaste
    echo "Set nopaste"
endfunc
command -nargs=0 P call s:SetPaste()
command -nargs=0 NP call s:SetNoPaste()


" Leader Config ================================================
nnoremap <Space> <Nop>
let mapleader="\<Space>"
nnoremap <leader>w :w<CR>
nnoremap H ^
nnoremap E $

inoremap <C-c> <Esc>
inoremap <C-d> <Del>

" Pairs Config =================================================

function! SkipDupPair(pair)
    if getline('.')[col('.') - 1] == a:pair
        return "\<Esc>la"
    else 
        return a:pair
    endif
endfunc

function! SkipQuote(quote)
    if getline('.')[col('.') - 1] == a:quote
        return "\<Esc>la"
    else
        return a:quote . a:quote . "\<Esc>i"
    endif
endfunc

inoremap ) <C-r>=SkipDupPair(')')<CR>
inoremap ] <C-r>=SkipDupPair(']')<CR>
inoremap } <C-r>=SkipDupPair('}')<CR>
inoremap > <C-r>=SkipDupPair('>')<CR>

inoremap ' <C-r>=SkipQuote("'")<CR>
inoremap " <C-r>=SkipQuote('"')<CR>
inoremap ` <C-r>=SkipQuote('`')<CR>

inoremap ( ()<ESC>i
inoremap () ()<ESC>a

inoremap [ []<Esc>i
inoremap [] []<Esc>a

inoremap { {}<Esc>i
inoremap {} {}<Esc>a

inoremap < <><Esc>i
inoremap << <<<Esc>a
inoremap <= <=<Esc>a
inoremap <> <><Esc>i
inoremap <<SPACE> <<SPACE>


function! GetPreCursorChar()
    if col('.') <= 1
        return ''
    endif
    let before = getline('.')[:col('.') - 2]
    return strcharpart(before, strchars(before)-1)
endfunc

function! GetAfterLines()
    let line = getline('.')
    let pos = col('.') - 1
    let after = strpart(line, pos)
    let n = line('$')
    let i = line('.') + 1
    while i <= n
        let line = getline(i)
        let after = after.' '.line
        if !(line =~ '\v^\s*$')
            break
        endif
        let i = i + 1
    endwhile
    return after
endfunc

function! DeleteMatchPair()
    let pairs = [['(', ')'], ['[', ']'], ['{', '}'], ['"', '"'], ["'", "'"], ['<', '>'], ['`', '`']]
    let before = GetPreCursorChar()
    for p in pairs
        if before == p[0]
            let after = GetAfterLines()
            let blankLen = strlen(after)
            let afterSplit = split(after, '^\s*')
            if len(afterSplit) > 0
                let noBlankLen = strlen(afterSplit[0])
                let i = blankLen - noBlankLen
                if afterSplit[0][0] == p[1]
                    return "\<BS>".repeat("\<DEL>", i + 1)
                endif
            endif
        endif
    endfor
    return "\<BS>"
endfunc

inoremap <Bs> <C-r>=DeleteMatchPair()<CR>
inoremap <C-H> <C-r>=DeleteMatchPair()<CR>




