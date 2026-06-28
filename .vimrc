
"
" _   ________  ___    _________  _  _______________
"| | / /  _/  |/  /   / ___/ __ \/ |/ / __/  _/ ___/
"| |/ // // /|_/ /   / /__/ /_/ /    / _/_/ // (_ /
"|___/___/_/  /_/    \___/\____/_/|_/_/ /___/\___/
"
"
" vim config
"

" ============================================
" 基础行为
" ============================================
set nocompatible          " 关闭 Vi 兼容模式
filetype on               " 开启文件类型检测
filetype plugin on        " 根据文件类型加载内置插件
filetype indent on        " 根据文件类型加载内置缩进规则

" ============================================
" 编辑体验
" ============================================
set encoding=utf-8        " 内部编码
set fileencodings=utf-8,gb2312,gbk,gb18030,ucs-bom,cp936  " 自动识别文件编码
set autoread              " 文件在外部修改后自动重载
set hidden                " 允许切换 buffer 时不保存
set clipboard=unnamedplus " 与系统剪贴板互通（Vim 7.4+）
set backspace=indent,eol,start  " 退格键可跨行

" ============================================
" 显示设置
" ============================================
syntax on                 " 语法高亮
set number                " 显示行号
" set relativenumber        " 显示相对行号（Vim 7.3+）
set cursorline            " 高亮当前行
set laststatus=2          " 始终显示状态栏
set showcmd               " 显示已输入但未完成的命令
set showmode              " 显示当前模式
set ruler                 " 显示光标位置
set wildmenu              " 命令补全增强菜单
set wildmode=longest:full,full

" ============================================
" 搜索
" ============================================
set hlsearch              " 高亮搜索结果
set incsearch             " 增量搜索
set ignorecase            " 搜索忽略大小写
set smartcase             " 包含大写时区分大小写

" 按空格或回车取消搜索高亮
nnoremap <silent> <Space> :nohlsearch<CR>
nnoremap <silent> <CR> :nohlsearch<CR>

" ============================================
" 缩进与排版
" ============================================
set expandtab             " Tab 转空格
set tabstop=4             " Tab 显示为 4 空格
set shiftwidth=4          " 自动缩进 4 空格
set softtabstop=4         " 按 Tab 插入 4 空格
set autoindent            " 继承上一行缩进
set smartindent           " 智能缩进（C 风格）
set cindent               " C 风格自动缩进
set textwidth=120         " 自动换行长度
set formatoptions+=mM     " 支持中文断行

" ============================================
" 界面美化（终端下）
" ============================================
" set background=dark       " 暗色背景
set t_Co=256              " 256 色终端
" colorscheme default       " 使用内置配色，可改为 desert/elflord/evening 等

" 状态栏自定义（无插件实现）
set laststatus=2
function! ModeName() abort
    let m = mode()
    if m == 'n' | return 'NORMAL' | endif
    if m == 'i' | return 'INSERT' | endif
    if m == 'v' | return 'VISUAL' | endif
    if m == 'V' | return 'V-LINE' | endif
    if m == "\<C-v>" | return 'V-BLOCK' | endif
    if m == 'R' | return 'REPLACE' | endif
    if m == 'c' | return 'COMMAND' | endif
    if m == 't' | return 'TERMINAL' | endif
    return m
endfunction

function! BufCount() abort
    return len(filter(range(1, bufnr('$')), 'buflisted(v:val)'))
endfunction

set statusline=
set statusline+=%{ModeName()}%m%r%h%w
set statusline+=\ [%l/%L]
set statusline+=\ %{&fenc!=''?&fenc:&enc}
set statusline+=\ %p%%
set statusline+=%=
set statusline+=%F
set statusline+=\ [%{BufCount()}]

" ============================================
" 文件与备份
" ============================================
set nobackup              " 不生成备份文件
set noswapfile            " 不生成 swap 文件
set undofile              " 持久化撤销（Vim 7.3+）
set undodir=~/.vim/undo   " 撤销文件目录（需手动创建目录）

" ============================================
" 实用快捷键映射
" ============================================
let mapleader = "\<Space>"       " Leader 键设为空格
nnoremap <leader><leader> :map<leader><CR>
set timeout

" 快速保存/退出
nnoremap <leader>fs :w<CR>
nnoremap <leader>qq :q<CR>

" 分屏操作
nnoremap <leader>wv :vsplit<CR>
nnoremap <leader>ws :split<CR>
nnoremap <leader>wc :close<CR>
nnoremap <C-h> <C-w>h
nnoremap <C-j> <C-w>j
nnoremap <C-k> <C-w>k
nnoremap <C-l> <C-w>l

" 快速调整窗口大小
nnoremap <leader>= <C-w>=
nnoremap <leader>> <C-w>5>
nnoremap <leader>< <C-w>5<

" Buffer管理
nnoremap <leader>bb :ls!<CR>
nnoremap <leader>bl :blast<CR>
nnoremap <leader>bn :bnext<CR>
nnoremap <leader>bp :bprev<CR>


" 行首/行尾快速跳转
nnoremap H ^
nnoremap L $

" 可视模式下缩进不丢失选择
vnoremap < <gv
vnoremap > >gv

" 上下移动行（类似 VS Code Alt+↑/↓）
nnoremap <A-j> :m .+1<CR>==
nnoremap <A-k> :m .-2<CR>==
inoremap <A-j> <Esc>:m .+1<CR>==gi
inoremap <A-k> <Esc>:m .-2<CR>==gi
vnoremap <A-j> :m '>+1<CR>gv=gv
vnoremap <A-k> :m '<-2<CR>gv=gv

" 系统复制/粘贴（兼容无 +clipboard 的编译版本）
vnoremap <leader>y "+y
nnoremap <leader>p "+p

" ============================================
" 自动命令
" ============================================
augroup myvimrc
    autocmd!
    " 保存时自动删除行尾空格
    autocmd BufWritePre * :%s/\s\+$//e
    " 打开文件回到上次位置
    autocmd BufReadPost * if line("'\"") > 1 && line("'\"") <= line("$") | exe "normal! g'\"" | endif
    " 对特定文件类型调整缩进
    autocmd FileType yaml,json,html,css,javascript setlocal ts=2 sw=2 sts=2
augroup END

" ============================================
" 内置补全增强
" ============================================
set completeopt=menuone,longest,preview
set omnifunc=syntaxcomplete#Complete  " 语法补全
set tags=./tags;,tags;
set noignorecase
set completeopt=menuone,noinsert,noselect
set pumheight=7
set splitbelow
inoremap <expr> <Tab> pumvisible() ? "\<C-n>" : (col('.')>2 && getline('.')[col('.')-2]=~'\k' ? "\<C-x>\<C-]>" : "\<Tab>")
inoremap <expr> <S-Tab> pumvisible() ? "\<C-p>" : "\<S-Tab>"
inoremap <expr> <CR> pumvisible() ? "\<C-y>" : "\<CR>"
inoremap <expr> <C-e> pumvisible() ? "\<C-e>" : "\<C-e>"
