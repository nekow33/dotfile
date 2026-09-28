" ============================================================================
"  ~/.vimrc —— 单文件配置（2026-09-28 由 ~/.vim/conf/、plugins.vim、
"              after/plugin/zz-emacs-compat.vim、autoload/ec*、colors/ 合并而来）
"
"  配置对齐 ~/.emacs.d/init.el（Evil + SPC leader + doom-tomorrow-night）。
"
"  为什么能合成一个文件（原来必须拆开的原因与现在的处理）：
"    · 插件选项（let g:xxx）—— 插件在 vimrc 执行完之后才加载，所以写在文件里
"      任何位置都早于插件读取它们，无需单独文件。
"    · LSP 注册与选项 —— 交给插件的官方便捷变量 g:lsp_servers / g:lsp_options，
"      插件加载时会自己 LspAddServer / LspOptionsSet（见 plugged/lsp/plugin/lsp.vim）。
"    · 「插件加载之后」才能做的事（读插件的 <Plug> 映射、调用插件函数）——
"      统一放进文件末尾的 EcPluginIntegrate()，由 autocmd VimEnter 调用
"      （VimEnter 在插件加载之后、用户操作之前触发）。
"    · 函数本体原来在 autoload/ec*（按需加载），现在全部是全局函数 EcXxx()，
"      定义在本文件里；状态栏用 %!EcUiStatusline() 引用。
"    · 配色原来在 colors/doom-tomorrow-night.vim，已内联到第 3 节。
"      ⚠ 代价：:colorscheme 不再可用，改配色直接改第 3 节那一段。
"
"  备份：合并前的分层配置在 ~/vim-recon/config-single-file-20260928-202150/
"  对照说明与踩坑记录：~/.vim/EMACS-VIM.md
" ============================================================================

set nocompatible
filetype plugin indent on
syntax on


" ==========================================================================
" 1. leader（必须最先：后面所有映射都依赖它）
" （原 conf/00-leader.vim）
" ==========================================================================

let mapleader = "\<Space>"
let maplocalleader = ","

" ==========================================================================
" 2. 基础：兼容性、启动响应、文件 / 编码 / 历史
" （原 conf/10-basic.vim）
" ==========================================================================

set ttimeoutlen=10          " 终端键序列（Esc/方向键）立即响应
set timeoutlen=400          " leader 前缀等待时间（对应 which-key 的 0.5s）
set updatetime=300          " 与 Emacs 的 eldoc-idle-delay / corfu-auto-delay 对齐
set lazyredraw              " 执行宏 / 寄存器时不重绘
set report=0                " 总是报告改动行数（默认 2）
set shortmess=aoOtTIcF      " 少打扰
" showcmd 默认就是开的，不用写
set confirm                 " 未保存退出时询问（对应 Emacs confirm-kill-emacs）

" ------------------------------------------------------------ 编码 / 文件 --
" encoding 在本机通常已经是 utf-8；显式写出来是防 locale 不是 UTF-8 时
" Vim 退回 latin1（那会让中文全部乱码），所以这不是冗余项。
set encoding=utf-8
set fileencodings=utf-8,gb2312,gbk,gb18030,ucs-bom,cp936,latin1
set autoread                " 外部改动自动重载
set hidden                  " 切换 buffer 不强制保存
set nowritebackup           " writebackup 默认是开的，这里关掉（配合默认的 nobackup，不留任何备份文件）
set noswapfile
set undofile                " 持久化撤销（对应 Emacs undo-redo + vundo）
set undodir=~/.vim/undo
set undolevels=10000
set history=2000
set viminfo='200,<500,s100,h
set nojoinspaces            " J 合并行不加双空格
set backspace=indent,eol,start
set whichwrap+=<,>,h,l,[,]  " 方向键 / h / l 可以跨行（默认只有 b,s）
set virtualedit=block
set nostartofline           " C-d / C-u / G / H 保持当前列（默认 startofline 会跳到行首）
" 跳转时优先复用上次访问过的窗口（:sbuffer / LSP 跳转之类都用得上）
set switchbuf=uselast
" 注：jumpoptions 这边只有 stack 一个旗标（C-o 回来恢复视图的 view 是 Neovim 的东西，
"     Vim 9.2 设它直接报 E474），所以不动它。
set nrformats=hex           " C-a / C-x 只认十进制与 0x

" ---------------------------------------------------------------- 剪贴板 ----
" 本机 Vim 编译时没有 +clipboard（-clipboard -X11 -wayland），g:clipboard 也不生效。
" 系统剪贴板由 <leader>y 系列映射实现：
"   映射见 conf/60-keymaps.vim，实现在 autoload/ec/clip.vim。

" ==========================================================================
" 3. 界面与外观（含内联配色，原 conf/20-ui.vim + colors/doom-tomorrow-night.vim）
" ==========================================================================

set termguicolors
set background=dark
" 故意不用 silent!：silent! 会把配色脚本里的错误一起吞掉。
"（主题里三个 markdown 组引用了未定义的调色板键，就是被它掩盖了很久。）
hi clear
if exists('syntax_on')
  syntax reset
endif
let g:colors_name = 'doom-tomorrow-night'
set background=dark

" 名称 -> [GUI 十六进制, 256 色近似]
let s:p = {
      \ 'bg':         ['#1d1f21', 234],
      \ 'bg_alt':     ['#161719', 233],
      \ 'bg_hi':      ['#2b2e30', 236],
      \ 'sel':        ['#373b41', 237],
      \ 'base4':      ['#3f4040', 238],
      \ 'base5':      ['#5c5e5e', 240],
      \ 'grey':       ['#5a5b5a', 240],
      \ 'doc':        ['#6f7170', 242],
      \ 'fg':         ['#c5c8c6', 251],
      \ 'fg_alt':     ['#767876', 243],
      \ 'modeline':   ['#0f1011', 233],
      \ 'red':        ['#cc6666', 167],
      \ 'orange':     ['#de935f', 174],
      \ 'yellow':     ['#f0c674', 223],
      \ 'green':      ['#b5bd68', 144],
      \ 'blue':       ['#81a2be', 110],
      \ 'cyan':       ['#8abeb7', 109],
      \ 'violet':     ['#b294bb', 140],
      \ 'magenta':    ['#c9b4cf', 183],
      \ 'md_h1':      ['#51afef',  76],
      \ 'md_h2':      ['#c678dd', 177],
      \ 'md_h3':      ['#98be65', 107],
      \ 'md_h4':      ['#d19a66', 174],
      \ 'md_h5':      ['#56b6c2',  74],
      \ 'md_h6':      ['#e5c07b', 181],
      \ 'md_bold':    ['#dfdfdf', 253],
      \ 'md_italic':  ['#c8c8c8', 251],
      \ 'md_code_fg': ['#a9a1e1', 147],
      \ 'md_code_bg': ['#21242b', 235],
      \ 'faint':      ['#5c6370', 241],
      \ 'md_link':    ['#51afef',  76],
      \ 'md_url':     ['#56b6c2',  74],
      \ }

function! s:hi(group, fg, bg, attr, ...) abort
  let l:sp = a:0 > 0 ? a:1 : ''
  let l:cmd = 'highlight ' . a:group
  if a:fg !=# ''
    let l:cmd .= ' guifg=' . s:p[a:fg][0] . ' ctermfg=' . s:p[a:fg][1]
  endif
  if a:bg !=# ''
    let l:cmd .= ' guibg=' . s:p[a:bg][0] . ' ctermbg=' . s:p[a:bg][1]
  endif
  " 注意：即使不需要属性也必须显式写 gui=NONE cterm=NONE。
  " 否则 hi clear 之后 Vim 的默认属性会留下来（TabLineFill 默认 reverse、
  " TabLine 默认 underline），反显会把前景色翻成背景色 —— tabline 空位就是这样变白的。
  let l:a = a:attr ==# '' ? 'NONE' : a:attr
  let l:cmd .= ' gui=' . l:a . ' cterm=' . l:a
  if l:sp !=# ''
    let l:cmd .= ' guisp=' . l:sp
  endif
  execute l:cmd
endfunction

" ---------------------------------------------------------------- 基础 UI --
call s:hi('Normal',        'fg',   'bg',   '')
call s:hi('NormalNC',      'fg',   'bg',   '')
call s:hi('NonText',       'base4', 'bg',  '')
call s:hi('EndOfBuffer',   'base4', 'bg',  '')
call s:hi('SpecialKey',    'base4', 'bg',  '')
call s:hi('Whitespace',    'base4', 'bg',  '')
call s:hi('Cursor',        'bg',   'fg',   '')
call s:hi('lCursor',       'bg',   'fg',   '')
call s:hi('TermCursor',    'bg',   'fg',   '')
call s:hi('CursorLine',    '',     'bg_hi','')
call s:hi('CursorColumn',  '',     'bg_hi','')
call s:hi('ColorColumn',   '',     'bg_alt','')
call s:hi('LineNr',        'grey', 'bg',   '')
call s:hi('LineNrAbove',   'base5','bg',   '')
call s:hi('LineNrBelow',   'base5','bg',   '')
call s:hi('CursorLineNr',  'yellow', '',   'bold')
call s:hi('CursorLineSign','',     'bg_hi','')
call s:hi('SignColumn',    'base4','bg',   '')   " 必须显式给背景，否则回落 #bebebe 白边
call s:hi('FoldColumn',    'grey', 'bg',   '')
call s:hi('Folded',        'grey', 'bg_alt','italic')
call s:hi('VertSplit',     'base4','bg',   '')
call s:hi('WinSeparator',  'base4','bg',   '')
call s:hi('Visual', 'fg', 'sel',  '')
call s:hi('VisualNOS', 'fg', 'sel',  '')
call s:hi('MatchParen',    'bg',   'orange','bold')
call s:hi('Search',        'bg',   'yellow','')
call s:hi('IncSearch',     'bg',   'orange','')
call s:hi('CurSearch',     'bg',   'orange','bold')
call s:hi('QuickFixLine',  '',     'bg_hi','bold')
call s:hi('Directory',     'blue', '',     '')
call s:hi('Title',         'blue', '',     'bold')
call s:hi('Removed',        'red',  'bg',   '')
call s:hi('Added',          'green','bg',   '')
call s:hi('Changed',        'yellow','bg',  '')
call s:hi('PmenuShadow',    'bg',   'bg',   '')
call s:hi('Underlined',    'blue', '',     'underline')
call s:hi('Conceal',       'faint','bg',   '')
call s:hi('Ignore',        '',     '',     '')
call s:hi('Error',         'red',  'bg',   '')
call s:hi('ErrorMsg',      'red',  '',     '')
call s:hi('WarningMsg',    'yellow','',    '')
call s:hi('MoreMsg',       'green','',     '')
call s:hi('ModeMsg',       'fg',   '',     'bold')
call s:hi('Question',      'green','',     '')
call s:hi('Todo',          'bg',   'yellow','bold')
call s:hi('SpellBad',      '',     '',     'undercurl', s:p.red[0])
call s:hi('SpellCap',      '',     '',     'undercurl', s:p.orange[0])

" --------------------------------------------------------------- 状态栏 ---
call s:hi('StatusLine',    'fg',   'modeline','')
call s:hi('StatusLineNC',  'base5','modeline','')
call s:hi('StatusLineTerm','fg',   'modeline','')
call s:hi('TabLine',       'grey', 'bg_alt','')
call s:hi('TabLineFill',   '',     'bg_alt','')
call s:hi('TabLineSel',    'fg',   'bg_hi','bold')
" 模式块（doom-modeline 每个状态一种颜色）
call s:hi('EcModeNormal',  'bg',   'blue',  'bold')
call s:hi('EcModeInsert',  'bg',   'green', 'bold')
call s:hi('EcModeVisual',  'bg',   'violet','bold')
call s:hi('EcModeReplace', 'bg',   'red',   'bold')
call s:hi('EcModeCommand', 'bg',   'yellow','bold')
call s:hi('EcModeTerminal','bg',   'cyan',  'bold')
call s:hi('EcModified',    'orange','',     'bold')
call s:hi('EcReadOnly',    'red',  '',      '')
call s:hi('EcFileName',    'fg',   'bg_alt','')
call s:hi('EcFileType',    'cyan', 'bg_alt','')
call s:hi('EcPosition',    'yellow','bg_alt','')
call s:hi('EcPercent',     'grey', 'bg_alt','')
call s:hi('EcEncoding',    'base5','bg_alt','')
" avy 风格的跳转标签（对应 avy 的候选高亮）
" ---- 浮窗 / 弹出菜单边框（which-key、补全菜单用）----
call s:hi('NormalFloat',      'fg',   'bg_alt','')
call s:hi('FloatBorder',      'base4','bg_alt','')
call s:hi('FloatTitle',       'blue', 'bg_alt','bold')
call s:hi('FloatFooter',      'faint','bg_alt','')
call s:hi('PmenuBorder',      'base4','bg_alt','')
call s:hi('PmenuKindSel',     'bg',   'blue', '')
call s:hi('PmenuExtraSel',    'bg',   'blue', '')
call s:hi('PmenuMatch',       'cyan', 'bg_alt','')
call s:hi('PmenuMatchSel',    'cyan', 'blue', '')
call s:hi('ComplMatchIns',    'faint','bg_alt','')

" ---- 命令行 / 消息区 ----
call s:hi('MsgArea',          'fg',   'bg',   '')
call s:hi('MsgSeparator',     'base4','bg',   '')
call s:hi('Question',         'green','bg',   '')
call s:hi('MoreMsg',          'green','bg',   '')
call s:hi('WarningMsg',       'yellow','bg',  '')
call s:hi('ErrorMsg',         'red',  'bg',   '')
call s:hi('ModeMsg',          'fg',   'bg',   'bold')

" ---- 窗口栏 / 终端 / 其它边缘组（同样必须显式给背景）----
call s:hi('WinBar',           'fg',   'bg_alt','bold')
call s:hi('WinBarNC',         'base5','bg_alt','')
call s:hi('CursorLineFold',   '',     'bg_hi','')
call s:hi('StatusLineTerm',   'fg',   'modeline','')
call s:hi('StatusLineTermNC', 'base5','modeline','')
call s:hi('Terminal',         'fg',   'bg',   '')
call s:hi('ToolbarLine',      '',     'bg_alt','')
call s:hi('ToolbarButton',    'fg',   'bg_alt','')
call s:hi('Substitute',       'bg',   'red',  '')
call s:hi('CursorColumn',     '',     'bg_hi','')
call s:hi('ColorColumn',      '',     'bg_alt','')
call s:hi('EcJumpLabel',   'bg',   'orange','bold')
call s:hi('EcJumpDim',     'faint','',     '')
call s:hi('EcLspProgress','yellow','bg_alt','bold')
call s:hi('EcDiagError',   'red',  'bg_alt','')
call s:hi('EcDiagWarn',    'yellow','bg_alt','')
call s:hi('EcDiagInfo',    'cyan', 'bg_alt','')

" ---------------------------------------------------------------- 补全菜单 --
call s:hi('Pmenu',         'fg',   'bg_alt','')
call s:hi('PmenuSel',      'bg',   'blue', 'bold')
call s:hi('PmenuKind',     'cyan', 'bg_alt','')
call s:hi('PmenuExtra',    'grey', 'bg_alt','')
call s:hi('PmenuSbar',     '',     'base4','')
call s:hi('PmenuThumb',    '',     'grey', '')
call s:hi('WildMenu',      'bg',   'blue', '')

" ---------------------------------------------------------------- diff -----
call s:hi('DiffAdd',       'green','bg_alt','')
call s:hi('DiffChange',    'yellow','bg_alt','')
call s:hi('DiffDelete',    'red',  'bg_alt','')
call s:hi('DiffText',      'orange','bg_hi','bold')
call s:hi('diffAdded',     'green','',     '')
call s:hi('diffRemoved',   'red',  '',     '')
call s:hi('diffChanged',   'yellow','',    '')
call s:hi('diffLine',      'cyan', '',     '')
call s:hi('diffFile',      'blue', '',     '')
call s:hi('diffIndexLine', 'violet','',    '')
call s:hi('diffSubname',   'grey', '',     '')
call s:hi('diffOldFile',   'red',  '',     '')
call s:hi('diffNewFile',   'green','',     '')
call s:hi('fugitiveHeading','violet','',   'bold')

" ------------------------------------------------------- 诊断 / LSP --------
" ⚠ 组名必须用 yegappan/lsp 源码里 hlset()/prop_type_add() 真正引用的名字。
"   原来这里抄的是 Neovim 内置 LSP 的组名（Diagnostic*、LspReference*、LspSymbolKind*、
"   LspDiagBorder* 等 50 个），Vim 这边没有任何插件引用，等于白写；
"   而插件真正要用的 LspDiagInline* / LspDiagVirtualTextWarning 反而没有定义，
"   于是出错代码段的 undercurl 退回 SpellBad、警告的虚拟文字退回 SpellCap。
"   现在按插件源码逐个对齐（见 ~/.vim/EMACS-VIM.md 第 7.7 节）。
" 符号列里的 E> / W> / I> / H>
call s:hi('LspDiagSignErrorText',   'red',   'bg', '')
call s:hi('LspDiagSignWarningText', 'yellow','bg', '')
call s:hi('LspDiagSignInfoText',    'cyan',  'bg', '')
call s:hi('LspDiagSignHintText',    'blue',  'bg', '')
" 出错代码段本身的 undercurl（highlightDiagInline，插件默认开）
call s:hi('LspDiagInlineError',   '', '', 'undercurl', s:p.red[0])
call s:hi('LspDiagInlineWarning', '', '', 'undercurl', s:p.yellow[0])
call s:hi('LspDiagInlineInfo',    '', '', 'undercurl', s:p.cyan[0])
call s:hi('LspDiagInlineHint',    '', '', 'undercurl', s:p.blue[0])
" 行内诊断文字（showDiagWithVirtualText，见 <leader>lv）
call s:hi('LspDiagVirtualTextError',   'red',   'bg_alt','')
call s:hi('LspDiagVirtualTextWarning', 'yellow','bg_alt','')
call s:hi('LspDiagVirtualTextInfo',    'cyan',  'bg_alt','')
call s:hi('LspDiagVirtualTextHint',    'blue',  'bg_alt','')
" :LspHighlight 手动高亮同名符号时的三色
call s:hi('LspTextRef',   '', 'sel', '')
call s:hi('LspReadRef',   '', 'sel', '')
call s:hi('LspWriteRef',  '', 'sel', 'underline')
" 函数签名浮窗里的当前参数
call s:hi('LspSigActiveParameter', 'orange', '', 'bold')
" 类型 / 参数 inlay hint（默认关，:LspInlayHints enable 才出现）
call s:hi('LspInlayHintsType',  'faint', 'bg_alt', '')
call s:hi('LspInlayHintsParam', 'faint', 'bg_alt', '')

" ------------------------------------------------------------- 语法高亮 ----
call s:hi('Comment',        'grey', '',     'italic')
call s:hi('Constant',       'orange','',    '')
call s:hi('String',         'green','',     '')
call s:hi('Character',      'green','',     '')
call s:hi('Number',         'orange','',    '')
call s:hi('Boolean',        'orange','',    '')
call s:hi('Float',          'orange','',    '')
call s:hi('Identifier',     'red',  '',     '')
call s:hi('Function',       'blue', '',     '')
call s:hi('Statement',      'violet','',    '')
call s:hi('Conditional',    'violet','',    '')
call s:hi('Repeat',         'violet','',    '')
call s:hi('Label',          'orange','',    '')
call s:hi('Operator',       'fg',   '',     '')
call s:hi('Keyword',        'violet','',    '')
call s:hi('Exception',      'violet','',    '')
call s:hi('PreProc',        'violet','',    '')
call s:hi('Include',        'violet','',    '')
call s:hi('Define',         'violet','',    '')
call s:hi('Macro',          'violet','',    '')
call s:hi('PreCondit',      'violet','',    '')
call s:hi('Type',           'yellow','',    '')
call s:hi('StorageClass',   'yellow','',    '')
call s:hi('Structure',      'yellow','',    '')
call s:hi('Typedef',        'yellow','',    '')
call s:hi('Special',        'cyan', '',     '')
call s:hi('SpecialChar',    'cyan', '',     '')
call s:hi('Tag',            'red',  '',     '')
call s:hi('Delimiter',      'fg',   '',     '')
call s:hi('SpecialComment', 'doc',  '',     '')
call s:hi('Debug',          'orange','',    '')
call s:hi('debugPC',        '',     'bg_hi','')
call s:hi('debugBreakpoint', 'red', 'bg_alt','')

" 文档注释（doom: doc-comments 比普通注释亮一点）
call s:hi('rustDocComment', 'doc',  '',     'italic')
call s:hi('markdownCode',   'md_code_fg','md_code_bg','')
call s:hi('markdownCodeBlock','',  'md_code_bg','')
call s:hi('markdownCodeDelimiter','faint','md_code_bg','')

" ------------------------------------------------------- Markdown / Org ----
call s:hi('markdownH1',     'md_h1','',     'bold')
call s:hi('markdownH2',     'md_h2','',     'bold')
call s:hi('markdownH3',     'md_h3','',     'bold')
call s:hi('markdownH4',     'md_h4','',     'bold')
call s:hi('markdownH5',     'md_h5','',     'bold')
call s:hi('markdownH6',     'md_h6','',     'bold')
call s:hi('markdownHeadingDelimiter','faint','','')
call s:hi('markdownHeadingRule','faint','', '')
call s:hi('markdownBold',   'md_bold','',   'bold')
call s:hi('markdownItalic', 'md_italic','', 'italic')
call s:hi('markdownBoldItalic','md_bold','','bold,italic')
call s:hi('markdownLinkText',   'md_link','','')
call s:hi('markdownLinkTextDelimiter','faint','','')
call s:hi('markdownUrl',        'md_url','','underline')
call s:hi('markdownAutolink',   'md_url','','underline')
call s:hi('markdownLinkDelimiter','faint','','')
call s:hi('markdownListMarker', 'md_h3','', '')
call s:hi('markdownOrderedListMarker','md_h3','','')
call s:hi('markdownRule',       'faint','', '')
call s:hi('markdownBlockquote', 'faint','', 'italic')
call s:hi('markdownBoldDelimiter','faint','','')
call s:hi('markdownItalicDelimiter','faint','','')
call s:hi('markdownEscape',     'cyan', '', '')
call s:hi('markdownId',         'cyan', '', '')
call s:hi('markdownIdDeclaration','blue','','')
call s:hi('markdownH1Delimiter','faint','', '')
call s:hi('markdownH2Delimiter','faint','', '')
call s:hi('markdownH3Delimiter','faint','', '')
call s:hi('htmlH1',         'md_h1','',     'bold')
call s:hi('htmlH2',         'md_h2','',     'bold')
call s:hi('htmlH3',         'md_h3','',     'bold')
call s:hi('htmlH4',         'md_h4','',     'bold')
call s:hi('htmlH5',         'md_h5','',     'bold')
call s:hi('htmlH6',         'md_h6','',     'bold')

" ---------------------------------------------------------------- 终端 -----
" :terminal 里那 16 个 ANSI 颜色，用同一套色板，避免默认的刺眼配色
let g:terminal_ansi_colors = [
      \ s:p.base4[0],  s:p.red[0],    s:p.green[0],  s:p.yellow[0],
      \ s:p.blue[0],   s:p.violet[0], s:p.cyan[0],   s:p.fg[0],
      \ s:p.grey[0],   s:p.red[0],    s:p.green[0],  s:p.yellow[0],
      \ s:p.blue[0],   s:p.magenta[0],s:p.cyan[0],   s:p.base5[0],
      \ ]

delfunction s:hi

set number                  " Emacs 用绝对行号
set cursorline              " global-hl-line-mode
set cursorlineopt=number,line
set signcolumn=yes          " 诊断 / diff 标记列（flymake + diff-hl 对应）
set laststatus=2
set showtabline=2           " 常驻 buffer 列表
set noshowmode              " 模式已经画在状态栏里
set scrolloff=5             " 与 helix scrolloff / Emacs scroll-conservatively 对齐
set sidescrolloff=8
set splitbelow
set splitright
set splitkeep=screen        " 开分屏时屏幕内容不跳（默认 cursor）
set smoothscroll            " Vim 9.1+ 平滑滚动（对应 pixel-scroll-precision-mode）
set display=lastline
set showbreak=↪             " 折行提示符（原来写成 showbreak=↪\ 会把反斜杠也设进去）
set fillchars=vert:│,fold:·,eob:~
set belloff=all
set foldlevel=99            " 手工折叠默认全展开（foldmethod 默认就是 manual）
set matchtime=1
set showmatch               " show-paren-mode
set matchpairs+=<:>
set mouse=a
set mousemodel=popup
set keymodel=startsel,stopsel
set pumheight=10
set pumwidth=20
set winminheight=0
set synmaxcol=500           " 长行保护（对应 Emacs so-long-threshold=500）
set maxmempattern=8000      " 行数 / 字节数再多也不截断

" 状态栏 / bufferline：实现在 autoload/ec/ui.vim
set statusline=%!EcUiStatusline()
set tabline=%!EcUiTabline()

" ==========================================================================
" 4. 搜索
" （原 conf/30-search.vim）
" ==========================================================================

packadd nohlsearch

set hlsearch
set incsearch
set ignorecase
set smartcase               " 含大写才区分大小写
set wrapscan                " isearch 到末尾绕回
set gdefault                " :s 默认全局替换（evil 习惯）

" ==========================================================================
" 5. 编辑：缩进、折行、补全、diff
" （原 conf/40-edit.vim）
" ==========================================================================

set expandtab
set tabstop=4
set shiftwidth=4
set softtabstop=4
set autoindent
" 这里故意不设 smartindent：'filetype plugin indent on' 已经为各语言提供缩进，
" smartindent 只对没有 indentexpr 的 filetype 生效，还会和 '#' / '}' 的规则打架。
set breakindent
set breakindentopt=shift:2,min:20
set linebreak
set formatoptions+=mM       " 支持中文断行
set completeopt=menuone,noinsert,noselect,fuzzy,popup
set wildoptions=pum,fuzzy   " 命令 / 文件名模糊补全（对应 vertico + orderless）
set wildmode=longest:full,full
set wildignorecase
set diffopt+=vertical,algorithm:histogram,indent-heuristic
set sessionoptions-=options
set viewoptions-=options

" 说明：这里原来还有两行
"   set iskeyword+=-            —— 全局改词法，会连纯文本 / python 的 w、*、补全一起改，
"                                 现在收窄到需要的语言（见 conf/50-autocmds.vim）
"   set omnifunc=syntaxcomplete#Complete
"                               —— 会和 LSP 抢 omnifunc（插件对附加了服务器的 buffer 用
"                                 setlocal 设 g:LspOmniFunc），各语言的 ftplugin 也自带
"                                 omnifunc，所以全局那行是多余的
"
" 保存时自动格式化（对应 apheleia-global-mode）的开关，实现在 autoload/ec/fmt.vim。
" 设 0 只关掉「保存时自动」；<leader>l f 的手动格式化不受影响。
let g:ec_autoformat = get(g:, 'ec_autoformat', 1)

" ==========================================================================
" 6. 函数库（原 autoload/ec.vim + ec/clip.vim + ec/fmt.vim + ec/jump.vim + ec/ui.vim）
" ==========================================================================

" ---------------------------------------------------------------- ec.vim --
function! EcHasCmd(name) abort
  return exists(':' . a:name) > 0
endfunction

" ------------------------------------------------------------ 分发器 --------
" fzf 提示行里的 <C-p> 粘贴：fzf 是**独立进程**，读不到 Vim 寄存器，
" 所以只能在启动前把剪贴板内容注入 `--bind ctrl-p:put(文本)`。
" 实测（fzf 0.72.0）put() 的参数是**字面量**：空格、单双引号、逗号、括号、| & % 都不用转义；
" 只有换行必须折成空格（fzf 的 query 是单行），另外去掉控制字符、限制长度。
let s:fzf_base_opts = ''
" 把一段文本变成 fzf 的 --bind '...:put(文本)' 片段
" 规则（实测 fzf 0.72）：值必须用单引号包住；内部单引号转义成 '\''
" 换行折成空格（query 单行）、去掉控制字符、限长 800 字节
function! EcFzfPutBind(key, text) abort
  let l:q = "'"
  let l:esc = l:q . '\' . l:q . l:q
  let l:t = substitute(a:text, '[\r\n]\+', ' ', 'g')
  let l:t = substitute(l:t, '[\x00-\x08\x0b\x0c\x0e-\x1f]', '', 'g')
  if strlen(l:t) > 800
    let l:t = strpart(l:t, 0, 800)
  endif
  let l:t = substitute(l:t, l:q, escape(l:esc, '\\&'), 'g')
  return " --bind='" . a:key . ':put(' . l:t . ")'"
endfunction

function! EcFzfClipBind() abort
  if s:fzf_base_opts ==# ''
    let s:fzf_base_opts = $FZF_DEFAULT_OPTS
  endif
  let l:opts = s:fzf_base_opts
  " <C-p> = 「我刚在 Vim 里 y 的东西」：寄存器 0（最近一次 yank）→ "（最近一次
  " yank/删除）。注意 y 只进 Vim 寄存器，**不会**写系统剪贴板 —— 这正是
  " 「按 <C-p> 却粘出别的东西」的原因。
  let l:reg = getreg('0') !=# '' ? getreg('0') : getreg('"')
  if l:reg !=# ''
    let l:opts .= EcFzfPutBind('ctrl-p', l:reg)
  endif
  " <C-y> = 系统剪贴板（外部程序复制的东西走这条）；寄存器为空时 <C-p> 也回退到它。
  " 为什么不是 <C-v>：fzf.vim 用 --expect=ctrl-t,ctrl-x,ctrl-v 把这三个键抢走了
  " （ctrl-v 在 picker 里是「垂直分屏打开」），所以在 fzf 里只有 <C-y> 可用。
  let l:sys = EcClipGet()
  if l:sys !=# ''
    let l:opts .= EcFzfPutBind('ctrl-y', l:sys)
    if l:reg ==# ''
      let l:opts .= EcFzfPutBind('ctrl-p', l:sys)
    endif
  endif
  let $FZF_DEFAULT_OPTS = l:opts
endfunction

function! EcPick(preferred, fallback) abort
  if EcHasCmd(a:preferred)
    call EcFzfClipBind()                         " 让 fzf 也能 <C-p> 粘贴（读剪贴板约 200ms）
    execute a:preferred
  else
    execute a:fallback
  endif
endfunction

function! EcGit(preferred, fallback) abort
  execute (EcHasCmd('Git') ? a:preferred : a:fallback)
endfunction

function! EcLsp(cmd, fallback) abort
  let l:name = split(a:cmd)[0]
  if EcHasCmd(l:name)
    execute a:cmd
  elseif a:fallback !=# ''
    execute a:fallback
  else
    echomsg '未安装 LSP 插件（~/.vimrc），该功能不可用'
  endif
endfunction

" 诊断文字（错误提示内容）的运行期开关。
" 对应 Emacs：flymake 把错误直接标在 buffer 上、eldoc 回显错误全文。
" ⚠ 用 exists('*LspOptionsSet') 判断而不是 exists(':LspOptionsSet')：
"   插件（plugin/lsp.vim）只导出了全局函数 g:LspOptionsSet()，并没有同名命令。
" action 取值：'on' / 'off' / 'toggle'
function! EcDiagText(action) abort
  if !exists('*LspOptionsSet')
    echomsg '未安装 LSP 插件（~/.vimrc），该功能不可用'
    return
  endif
  if a:action ==# 'on'
    let l:new = v:true
  elseif a:action ==# 'off'
    let l:new = v:false
  else
    " ⚠ 必须显式给 v:true / v:false：legacy 脚本里 !v:false 得到的是 Number 1，
    "   而插件内部（Vim9 的 LspDiagsOptionsChanged）是拿 != 跟 Bool 比较的，
    "   类型不一致会抛 E1091 并被静默吞掉 —— 表现就是「关得掉、开不回来」。
    let l:new = get(LspOptionsGet(), 'showDiagWithVirtualText', v:false)
          \ ? v:false : v:true
  endif
  " 改完选项后插件会自己触发 LspOptionsChanged → 重画诊断，不用手动刷新
  call LspOptionsSet(#{showDiagWithVirtualText: l:new})
  echo '行内诊断文字：' . (l:new ? '开' : '关')
endfunction

" M-x：对应 Emacs 的 execute-extended-command
function! EcPalette() abort
  if EcHasCmd('Commands')        " fzf.vim 的 :Commands
    execute 'Commands'
  else
    call feedkeys(':', 'n')        " Vim 的 M-x 就是 :
  endif
endfunction

" ------------------------------------------------ 文件管理器 / 终端 --------
" 对应 Emacs：SPC d d = dirvish、SPC d o = dirvish-quick-access
function! EcExplore(cwd) abort
  let l:dir = a:cwd ? '.' : '%:h'
  if EcHasCmd('Dirvish')
    execute 'Dirvish' fnameescape(expand(l:dir))
  elseif EcHasCmd('Lexplore')    " 没装 dirvish 时退回 netrw
    execute 'Lexplore'
  else
    execute 'edit' fnameescape(expand(l:dir))
  endif
endfunction

" 对应 Emacs：SPC e t = vterm、SPC e e = eshell、SPC e c = eshell-command
"
" action 取值：
"   'toggle'  呼出 / 收起浮窗（收起时终端进程保留，再呼出还是同一个 shell）
"   'new'     新开一个浮窗
"   'cmd'     问一条命令并在浮窗里跑（跑完自动关）
"   'kill'    关掉当前浮窗并结束它的进程
"   'killall' 关掉所有浮窗和进程
"
" 为什么不只用 F7/F8：很多键盘（60%/75%）没有独立 F 键，Windows Terminal 也会
" 截走一部分 F 键，所以关闭动作必须有 leader 键这条路。
function! EcTerminal(action) abort
  if !EcHasCmd('FloatermNew')    " 没装 floaterm 时退回内置终端
    if a:action ==# 'kill' || a:action ==# 'killall'
      call EcCloseWindow()       " 内置终端跑完会因 ++close 自己关，这里只是兜底
    else
      execute 'terminal ++close'
    endif
    return
  endif
  if a:action ==# 'toggle'
    FloatermToggle
  elseif a:action ==# 'new'
    FloatermNew
  elseif a:action ==# 'kill'
    FloatermKill
  elseif a:action ==# 'killall'
    FloatermKill!
  else
    let l:cmd = input('命令: ')
    if l:cmd !=# ''
      execute 'FloatermNew' l:cmd
    endif
  endif
endfunction

" ---------------------------------------------------------- buffer / 窗口 ---
function! EcCloseOthers() abort
  let l:cur = bufnr('%')
  for l:b in range(1, bufnr('$'))
    if l:b != l:cur && buflisted(l:b)
      execute 'silent! bdelete' l:b
    endif
  endfor
endfunction

" 只有一个窗口时 :close 会报 E444，这里静默跳过
function! EcCloseWindow() abort
  if winnr('$') > 1
    close
  else
    echomsg '只有一个窗口，忽略'
  endif
endfunction

" ---------------------------------------------------------- 配置自身 -------
" $MYVIMRC 只在 Vim 用默认方式读 vimrc 时才被设置（-u / --clean 启动时是空的），
" 所以兜底到 ~/.vimrc，否则 <leader>ho / ro / hr / re 会报 E484。
function! EcConfigFile() abort
  return $MYVIMRC !=# '' ? $MYVIMRC : expand('~/.vimrc')
endfunction

function! EcOpenConfig() abort
  execute 'edit' fnameescape(EcConfigFile())
endfunction

function! EcReloadConfig() abort
  let l:f = EcConfigFile()
  if !filereadable(l:f)
    echomsg '找不到配置文件：' . l:f
    return
  endif
  " 不能在函数里直接 source：重新定义正在执行的函数会触发
  " E127: Cannot redefine function ... It is in use，source 就此中断（配置只加载一半）。
  " 用 timer 推迟到函数返回之后再 source。
  echomsg '正在重新加载 ' . l:f
  call timer_start(0, {-> execute('source ' . fnameescape(l:f))})
endfunction

" --------------------------------------------------------- 撤销 / 选区 -----
function! EcUndoTree() abort
  if EcHasCmd('UndotreeToggle')
    execute 'UndotreeToggle'
  elseif EcHasCmd('Undotree')
    execute 'Undotree'
  else
    execute 'normal! g-'          " 内置：撤销树导航
    silent! undolist
  endif
endfunction

let s:region_cycle = ['iw', 'iW', 'i"', "i'", 'i`', 'i(', 'i[', 'i{',
      \ 'a(', 'a[', 'a{', 'a"', "a'", 'ap', 'G']
let s:region_i = 0

" n == 0 从普通模式开始（选中当前词）；n > 0 扩大；n < 0 收缩。
" 装了 vim-expand-region 时 after/plugin 会把 <leader>x x 直接绑到它的 <Plug>，
" 这里是没装插件时的兜底（原来还有个 :ExpandRegion 分支，但那个命令并不存在）。
function! EcRegionEx(n) abort
  if a:n == 0
    let s:region_i = 0
    execute 'normal! viw'
    return
  endif
  let s:region_i = max([0, min([len(s:region_cycle) - 1, s:region_i + a:n])])
  " gv 先恢复可视选区，随后用新的文本对象替换它
  execute 'normal! gv' . s:region_cycle[s:region_i]
endfunction

" 对应 Emacs 的 consult-focus-lines：把匹配行收进 quickfix
function! EcFocusLines() abort
  let l:pat = input('/')
  if l:pat ==# '' | return | endif
  silent! execute 'vimgrep /' . escape(l:pat, '/') . '/j %'
  if empty(getqflist()) | echomsg '没有匹配：' . l:pat | return | endif
  copen
endfunction

" <leader>lf 的兜底：手动格式化，不受 g:ec_autoformat 开关影响
function! EcFormatBuffer() abort
  if !EcFmtRun(&filetype)
    echomsg '没有可用的格式化器（filetype=' . (&filetype ==# '' ? '空' : &filetype) . '）'
  endif
endfunction

" ------------------------------------------------------------ 大文件降级 ---
" 对应 Emacs 的 my/optimize-for-large-file（>8MB 关掉高开销功能）。
" 注意：'syntax' 是全局选项不能 setlocal，用 syntax clear 关掉本 buffer 的高亮。
function! EcBigfile() abort
  let l:size = getfsize(expand('<afile>'))
  if l:size <= 0
    let l:size = line2byte(line('$') + 1)
  endif
  if l:size > 8 * 1024 * 1024
    let b:ec_bigfile = 1
    setlocal noundofile
    setlocal nolist
    setlocal nocursorline
    setlocal foldmethod=manual    " filetype 插件可能把 foldmethod 设成 syntax
    setlocal synmaxcol=200        " 长行保护（Emacs 那边是 so-long）
    silent! syntax clear
  endif
endfunction

" ------------------------------------------------ 插件加载后的键位兜底 ----
" 2026-09-27 起改成「Vim 原生优先」，这里**不再夺回 gc / go / gi / Y**：
"   gc 归 vim-commentary（注释操作符）、go / gi / Y 归 Vim 自己
"   （Vim 9.2 的 Y 原生就是 yy，gi 是回到上次插入位置）。
" 只保留插入态这几条：lexima 会接管 <CR>，而 <C-n>/<C-p>/<Tab> 在补全菜单里的
" 行为需要在所有插件加载完之后重申一次，否则会被插件的映射盖掉。
function! EcReassertMappings() abort
  " 插入态：lexima 会接管 <CR>（补全菜单弹出时它的 prehook 仍回 <C-y>），
  " 所以这里刻意不重申 <CR>，只补其余几个。
  inoremap <expr> <C-n> pumvisible() ? "\<C-n>" : "\<Down>"
  inoremap <expr> <C-p> pumvisible() ? "\<C-p>" : "\<Up>"
  inoremap <expr> <Tab>   pumvisible() ? "\<C-n>" : "\<Tab>"
  inoremap <expr> <S-Tab> pumvisible() ? "\<C-p>" : "\<S-Tab>"
endfunction

" ---------------------------------------------------------------- clip.vim --
" 读 Windows 剪贴板（≈200ms/次：WSL 里只有 powershell.exe 可用，wl-paste/xclip 都没装）
function! EcClipGet() abort
  let l:t = system(['powershell.exe', '-NoProfile', '-NoLogo', '-Command', 'Get-Clipboard'])
  if v:shell_error != 0
    echomsg '读取 Windows 剪贴板失败'
    return ''
  endif
  return substitute(substitute(l:t, '\r\n', '\n', 'g'), '\n$', '', '')
endfunction

" 命令行版本：把换行折成空格（命令行里塞不进换行）
function! EcClipGetCmdline() abort
  return substitute(EcClipGet(), '\n', ' ', 'g')
endfunction

" 搜索提示行（/ ?）按 <C-p> 粘贴：优先「最近 yank 的内容」，
" 没有 yank 记录就退回系统剪贴板；在 : 命令行里保持原生的「历史上一条」。
" · 为什么优先 "0 而不是 "：按 Emacs 的直觉「粘贴我刚复制的东西」——
"   如果中间又删过东西，" 会被覆盖，而 "0 只存最近一次 yank。
" · 原生写法 <C-r>" 也一直可用（Vim 自带，不依赖剪贴板寄存器）。
function! EcSearchPasteKeys() abort
  " 搜索提示行（/ ?）与 input() 对话框（getcmdtype() == '@'，例如
  " <leader>ec 的命令输入、:LspRename、dirvish 的 gd）都粘贴；
  " : 命令行里保持原生的「历史上一条」。
  if getcmdtype() !~# '[/?@]'
    return "\<C-p>"
  endif
  if getreg('0') !=# ''
    return "\<C-r>0"
  endif
  if getreg('"') !=# ''
    return "\<C-r>\""
  endif
  return "\<C-r>=" . 'EcClipGetCmdline()' . "\<CR>"   " 什么都没有就读系统剪贴板
endfunction

" 当前终端是否支持 OSC 52
function! s:osc_ok() abort
  if !exists('*OSCYank') | return 0 | endif
  let l:mode = get(g:, 'ec_clipboard', 'auto')
  if l:mode ==# 'clip'  | return 0 | endif
  if l:mode ==# 'osc52' | return 1 | endif
  if $WT_SESSION !=# ''                                              | return 1 | endif
  if $KITTY_WINDOW_ID !=# '' || $WEZTERM_PANE !=# ''                 | return 1 | endif
  if $TERM_PROGRAM =~? 'kitty\|wezterm\|ghostty\|vscode\|iterm'      | return 1 | endif
  if $TERM =~? '^xterm-kitty\|^alacritty\|^foot\|^wezterm\|^contour' | return 1 | endif
  return 0
endfunction

function! EcClipSet(text) abort
  if a:text ==# '' | return | endif

  " 1) clip.exe 兜底：不依赖终端能力，保证粘贴一定读得到
  let l:tmp = tempname()
  call writefile(split(a:text, "\n", 1), l:tmp)
  call system('clip.exe < ' . shellescape(l:tmp))
  let l:rc = v:shell_error
  call delete(l:tmp)

  " 2) OSC 52 后写：支持的终端会用它覆盖成无损版本
  if s:osc_ok() && OSCYank(a:text)
    echomsg '已复制到系统剪贴板（OSC 52 无损 + clip.exe 兜底，' . strlen(a:text) . ' 字节）'
    return
  endif

  if l:rc == 0
    echomsg '已复制到系统剪贴板（clip.exe：非 BMP 字符可能丢字节）'
  else
    echomsg '复制到剪贴板失败（clip.exe 返回 ' . l:rc . '）'
  endif
endfunction

" 可视选区（'< / '> 标记）
function! EcClipCopy() abort
  let l:a = getpos("'<")
  let l:b = getpos("'>")
  if l:a[1] == 0 | return | endif
  let l:lines = getline(l:a[1], l:b[1])
  if empty(l:lines) | return | endif
  let l:lines[-1] = strpart(l:lines[-1], 0, l:b[2])
  let l:lines[0]  = strpart(l:lines[0], l:a[2] - 1)
  call EcClipSet(join(l:lines, "\n"))
endfunction

function! EcClipYankLine() abort
  " 注意：getline('.') 返回 String，而 Vim 9 的 join() 只接受 List（否则 E1529）
  call EcClipSet(getline('.'))
endfunction

" 用 z 寄存器中转，避免污染默认寄存器
function! s:put(text, before) abort
  if a:text ==# '' | return | endif
  if stridx(a:text, "\n") >= 0
    call setreg('z', split(a:text, "\n", 1), 'V')
  else
    call setreg('z', a:text, 'v')
  endif
  execute 'normal! "z' . (a:before ? 'P' : 'p')
endfunction

function! EcClipPaste(before) abort
  call s:put(EcClipGet(), a:before)
endfunction

function! EcClipReplace() abort
  let l:t = EcClipGet()
  if l:t ==# '' | return | endif
  silent! execute 'normal! gv"_d'
  call s:put(l:t, 1)
endfunction

" ---------------------------------------------------------------- fmt.vim --
let s:formatters = {
      \ 'rust': ['rustfmt',     'rustfmt --edition 2021'],
      \ 'c':    ['clangformat', 'clang-format'],
      \ 'cpp':  ['clangformat', 'clang-format'],
      \ }

" g:ec_autoformat 的默认值在 conf/40-edit.vim 里设（那里是「选项」的家，
" 而且能保证在任何时候都被定义，不用等本文件被 autoload）。

" 手写兜底：把整个 buffer 喂给命令行工具，再整段换回来（保留视图）
function! s:plain(cmd) abort
  if !executable(split(a:cmd)[0]) | return | endif
  let l:old = getline(1, '$')
  let l:out = system(a:cmd, l:old)
  if v:shell_error != 0 || empty(l:out) | return | endif
  let l:new = split(l:out, "\n", 1)
  if !empty(l:new) && l:new[-1] ==# '' | call remove(l:new, -1) | endif
  if l:new ==# l:old | return | endif
  let l:view = winsaveview()
  silent call setline(1, l:new)
  if len(l:new) < len(l:old)
    silent execute (len(l:new) + 1) . ',$delete _'
  endif
  call winrestview(l:view)
  echomsg '已用 ' . split(a:cmd)[0] . ' 格式化'
endfunction

" 真正执行格式化；返回 1 表示确实调用了格式化器，0 表示这个 filetype 没有可用工具。
" 只管「有没有工具」，不管 g:ec_autoformat（那个由调用方决定）。
function! EcFmtRun(ft) abort
  if !has_key(s:formatters, a:ft) | return 0 | endif
  let [l:neo, l:cmd] = s:formatters[a:ft]
  if !executable(split(l:cmd)[0]) | return 0 | endif
  if EcHasCmd('Neoformat')
    " undojoin：让格式化不单独占一步撤销
    silent! undojoin
    execute 'Neoformat' l:neo
  else
    call s:plain(l:cmd)
  endif
  return 1
endfunction

" BufWritePre 入口：尊重 g:ec_autoformat 开关。
" a:ft 由自动命令显式给出 —— *.h 这类扩展名 Vim 探测出的 filetype 可能是空的。
function! EcFmtSave(ft) abort
  if !g:ec_autoformat | return | endif
  if &buftype !=# '' || !&modifiable || &readonly | return | endif
  let l:ft = &filetype
  if l:ft ==# ''
    let l:ft = a:ft
  endif
  call EcFmtRun(l:ft)
endfunction

" ---------------------------------------------------------------- jump.vim --
let s:keys = split('asdfghjklqwertyuiopzxcvbnm', '\zs')

" mode: 'word' | 'line' | 'char'
"   'char' 需要额外传一个字符
function! s:targets(mode, ...) abort
  let l:top = line('w0')
  let l:bot = line('w$')
  let l:res = []
  if a:mode ==# 'line'
    for l:l in range(l:top, l:bot)
      call add(l:res, [l:l, 1, 1])
    endfor
  elseif a:mode ==# 'char'
    " \V 之后的模式里只有反斜杠有特殊含义，所以要转义它
    let l:pat = '\V' . escape(a:1, '\')
    let l:len = len(a:1)
    for l:l in range(l:top, l:bot)
      let l:text = getline(l:l)
      let l:idx = 0
      while 1
        let l:m = match(l:text, l:pat, l:idx)
        if l:m < 0 | break | endif
        call add(l:res, [l:l, l:m + 1, l:len])
        let l:idx = l:m + l:len
      endwhile
    endfor
  else
    for l:l in range(l:top, l:bot)
      let l:text = getline(l:l)
      let l:idx = 1
      while 1
        let l:m = match(l:text, '\k\+', l:idx - 1)
        if l:m < 0 | break | endif
        let l:e = matchend(l:text, '\k\+', l:idx - 1)
        call add(l:res, [l:l, l:m + 1, l:e - l:m])
        let l:idx = l:e + 1
      endwhile
    endfor
  endif
  " 离光标近的优先
  let l:cur = line('.')
  call sort(l:res, {a, b -> abs(a[0] - l:cur) - abs(b[0] - l:cur)})
  return l:res
endfunction

function! EcJumpGo(mode) abort
  if a:mode ==# 'char'
    let l:ch = nr2char(getchar())
    if l:ch ==# '' || l:ch ==# "\<Esc>" | return | endif
    let l:targets = s:targets('char', l:ch)
  else
    let l:targets = s:targets(a:mode)
  endif
  if empty(l:targets) | return | endif

  let l:n = min([len(s:keys), len(l:targets)])
  let l:targets = l:targets[: l:n - 1]
  " prop_type_add 重复调用会 E969，先判断
  if empty(prop_type_get('ecJump'))
    call prop_type_add('ecJump', {'highlight': 'EcJumpLabel', 'priority': 30})
  endif

  let l:map = {}
  let l:i = 0
  for l:t in l:targets
    let l:k = s:keys[l:i]
    try
      call prop_add(l:t[0], l:t[1], {'type': 'ecJump', 'text': l:k})
      let l:map[l:k] = l:t
    catch
    endtry
    let l:i += 1
  endfor

  redraw
  let l:ch = nr2char(getchar())
  silent! call prop_remove({'type': 'ecJump', 'all': 1})
  redraw
  if has_key(l:map, l:ch)
    call cursor(l:map[l:ch][0], l:map[l:ch][1])
  endif
endfunction

" ---------------------------------------------------------------- ui.vim --
function! EcUiMode() abort
  let l:m = mode(1)
  if l:m =~# '^n'              | return ['NORMAL',   'EcModeNormal']
  elseif l:m =~# '^i'          | return ['INSERT',   'EcModeInsert']
  elseif l:m =~# '^R'          | return ['REPLACE',  'EcModeReplace']
  elseif l:m =~# '^[vV\<C-v>]' | return ['VISUAL',   'EcModeVisual']
  elseif l:m =~# '^c'          | return ['COMMAND',  'EcModeCommand']
  elseif l:m =~# '^t'          | return ['TERMINAL', 'EcModeTerminal']
  endif
  return ['NORMAL', 'EcModeNormal']
endfunction

" 诊断计数（对应 doom-modeline 上的 flymake 计数）。
"
" ⚠ 两个坑（原来这里两个都踩了，所以状态栏从来没显示过诊断数）：
"   1) yegappan/lsp **没有** LspDiagCount 这个函数 —— 原来判断的就是它，
"      于是整个分支永远不执行（死代码）。真正可用的是
"      lsp#diag#DiagsGetErrorCount()（autoload/lsp/diag.vim）。
"   2) 它返回的键是 'Error' / 'Warn'，**不是** 'Warning'。
"
" 状态栏每次重绘都会被调用，所以这里不在状态栏里现算，而是缓存起来：
" 由 User LspDiagsUpdated 和 BufEnter 触发刷新（见 conf/50-autocmds.vim），
" 状态栏只读两个脚本变量 —— 对前台零开销。
let s:diag_buf  = -1
let s:diag_err  = 0
let s:diag_warn = 0

function! EcUiDiagRefresh() abort
  let s:diag_buf  = bufnr('%')
  let s:diag_err  = 0
  let s:diag_warn = 0
  if !EcHasCmd('LspDiag')          " LSP 插件没装
    return
  endif
  try
    let l:c = lsp#diag#DiagsGetErrorCount(s:diag_buf)
  catch
    return
  endtry
  let s:diag_err  = get(l:c, 'Error', 0)
  let s:diag_warn = get(l:c, 'Warn', 0)
endfunction

function! EcUiDiag() abort
  if s:diag_buf != bufnr('%')        " 缓存还没更新到当前 buffer
    return ''
  endif
  let l:s = ''
  if s:diag_err > 0  | let l:s .= ' E' . s:diag_err  | endif
  if s:diag_warn > 0 | let l:s .= ' W' . s:diag_warn | endif
  return l:s
endfunction

" LSP 进度（对应 Emacs 里 eglot 在 mode-line 上的 "eglot(...)" 指示）。
"
" 为什么需要它：yegappan/lsp 拉诊断用的是**同步** RPC（lspserver.vim 的 Rpc() →
" ch_evalexpr，默认无超时）。服务器在索引 / 跑 cargo check 时不回话，Vim 的
" 主循环就整段被冻住（实测：小工程 1.8-2s，工作区越大越久），冻结期间界面
" 完全不能重绘。所以至少要把「正在忙什么」提前显示出来。
"
" ⚠ 两条实测出来的实现约束（详见文档第 10 节与 conf/50-autocmds.vim）：
"   1) 不能给 User LspProgressUpdate 挂函数：插件是在 job 回调里 doautocmd 的，
"      那个上下文里自动命令只要调用函数就抛 E20: Mark not set（一次冷启动 100+ 条）；
"   2) 不能靠常驻定时器轮询：定时器每跳一次就把 Vim 从等待里唤醒一次，终端上周期性
"      刷光标序列，打扰前台安静（实测还会把 wait_quiet 类测试全拖慢到 25s 超时）。
" 最终：**事件驱动** —— 由 BufEnter / CursorHold / CursorHoldI 触发刷新
"（updatetime=300ms，和诊断计数共用一条自动命令）。用户一停下来看代码指示器就更新；
" 打开 rust 文件时 BufEnter 先画上「加载中」占位，冻结发生前它就在屏幕上了
"（冻结期间主循环停了，只能靠提前挂上）。
let s:prog = ''
let s:busy_since = []

" 把 g:LspProgress 里的内容算成状态栏文本（title + 百分比/消息，截断到 30 字符）
function! EcUiProgressRefresh() abort
  let l:p = get(g:, 'LspProgress', {})
  if empty(l:p)
    let s:prog = ''
    return
  endif
  for l:v in values(l:p)
    let l:s = get(l:v, 'title', '')
    let l:pct = get(l:v, 'percentage', -1)
    if l:pct >= 0
      let l:s .= ' ' . l:pct . '%'
    else
      " 没有百分比时用 message 的第一段（后面常跟一长串路径，会挤坏状态栏）
      let l:msg = get(l:v, 'message', '')
      if l:msg !=# ''
        let l:s .= ' ' . split(substitute(l:msg, '/.*$', '', ''), ':')[0]
      endif
    endif
    let s:prog = l:s
    break
  endfor
  if strlen(s:prog) > 30
    let s:prog = s:prog[:27] . '…'
  endif
  " 顶层文本要自己转义 %
  let s:prog = substitute(s:prog, '%', '%%', 'g')
endfunction

" 没有进度事件时：如果刚打开过 rust/c 文件（服务器附加后头 ~5 秒），继续挂
" 「rust-analyzer 加载中…」占位 —— 实测那 1-3 秒的卡顿就落在这段时间。
function! EcUiProgressBusy(...) abort
  if !empty(get(g:, 'LspProgress', {}))
    let s:busy_since = []
    return
  endif
  if get(g:, 'ec_lsp_busy', 0)
    if empty(s:busy_since)
      let s:busy_since = reltime()
      " 一次性兜底：用户一直不操作（没有 CursorHold）时，5.5 秒后自动再评估一次，
      " 把过期的占位清掉。一次性定时器没有周期唤醒的问题。
      call timer_start(5500, 'EcUiProgressBusy')
    endif
    if reltimefloat(reltime(s:busy_since)) < 5.0
      if s:prog !=# 'rust-analyzer 加载中…'
        let s:prog = 'rust-analyzer 加载中…'
      endif
      return
    endif
    let g:ec_lsp_busy = 0
  endif
  let s:busy_since = []
  if s:prog !=# ''
    let s:prog = ''
  endif
endfunction

function! EcUiProgressRefresh() abort
  let l:p = get(g:, 'LspProgress', {})
  if empty(l:p)
    let s:prog = ''
    return
  endif
  for l:v in values(l:p)
    let l:s = get(l:v, 'title', '')
    let l:pct = get(l:v, 'percentage', -1)
    if l:pct >= 0
      let l:s .= ' ' . l:pct . '%'
    else
      " 没有百分比时用 message 的第一段（后面常跟一长串路径，会挤坏状态栏）
      let l:msg = get(l:v, 'message', '')
      if l:msg !=# ''
        let l:s .= ' ' . split(substitute(l:msg, '/.*$', '', ''), ':')[0]
      endif
    endif
    let s:prog = l:s
    break
  endfor
  if strlen(s:prog) > 30
    let s:prog = s:prog[:27] . '…'
  endif
  " 顶层文本要自己转义 %
  let s:prog = substitute(s:prog, '%', '%%', 'g')
endfunction

" 返回状态栏片段：“ ⏳<在忙什么> ”，没有进度时返回空串。
" ⚠ 返回值会被拼到状态栏顶层（不是放进 %{...}），所以这里的 % 必须写成 %%
"   —— 否则像「Indexing 17%」会被状态栏当成格式项吃掉字符。
function! EcUiProgress() abort
  return s:prog ==# '' ? '' : ' ⏳' . s:prog . ' '
endfunction

function! EcUiStatusline() abort
  let [l:name, l:hl] = EcUiMode()
  let l:s  = '%#' . l:hl . '# ' . l:name . ' '
  let l:s .= '%#EcModified#' . (&modified ? ' ●' : '  ')
  let l:s .= '%#EcReadOnly#' . (&readonly ? ' RO ' : '')
  let l:s .= '%#EcFileName# %f '
  let l:s .= '%#EcDiagError#%{EcUiDiag()}'
  let l:s .= '%#EcLspProgress#' . EcUiProgress()
  let l:s .= '%='                                  " 以下右对齐
  let l:s .= '%#EcFileType# %{&filetype ==# "" ? "text" : &filetype} '
  let l:s .= '%#EcEncoding#%{&fenc ==# "" ? &enc : &fenc} '
  let l:s .= '%#EcPosition# %l:%-2c '
  let l:s .= '%#EcPercent# %3p%% '
  return l:s
endfunction

function! EcUiTabline() abort
  let l:s = ''
  for l:i in range(1, bufnr('$'))
    if !buflisted(l:i) | continue | endif
    let l:nm = bufname(l:i)
    let l:nm = l:nm ==# '' ? '[无标题]' : fnamemodify(l:nm, ':t')
    let l:nm = substitute(l:nm, '%', '%%', 'g')
    let l:s .= (l:i == bufnr('%') ? '%#TabLineSel#' : '%#TabLine#')
    let l:s .= ' ' . l:i . ' ' . l:nm . (getbufvar(l:i, '&modified') ? ' ●' : '') . ' '
  endfor
  let l:s .= '%#TabLineFill#%T'
  return l:s
endfunction

" ==========================================================================
" 7. 自动命令（恢复光标、大文件降级、按语言、存盘格式化）
" （原 conf/50-autocmds.vim）
" ==========================================================================

augroup ec_core
  autocmd!
  " 打开文件回到上次位置
  autocmd BufReadPost *
        \ if line("'\"") > 1 && line("'\"") <= line("$") && &ft !~# 'commit'
        \ | execute 'normal! g`"' | endif
  " 大文件降级（对应 Emacs my/optimize-for-large-file），实现在 autoload/ec.vim
  autocmd BufReadPost * call EcBigfile()
  " FileType 之后语法会被重新装上，这里再清一次
  autocmd Syntax * if get(b:, 'ec_bigfile', 0) | silent! syntax clear | endif
  " 按语言调整缩进（Emacs 里 rust / c / cpp 用 4 空格、yaml / json 用 2 空格）
  autocmd FileType yaml,json,javascript,typescript,html,css,xml setlocal ts=2 sw=2 sts=2
  " 连字符算作标识符的一部分（原先是全局 set iskeyword+=-，会污染所有 filetype）
  autocmd FileType rust,css,scss,less,sass,xml,html,vue,svelte setlocal iskeyword+=-
  " 纯文本类 filetype 没有 commentstring，vim-commentary 的 gcc 会静默什么都不做，
  " 这里给个合理的默认（# 开头）
  autocmd FileType text,conf,dosini,gitconfig setlocal commentstring=#\ %s
  " Markdown / Org：自动折行 + 隐藏标记（visual-line-mode + markdown-hide-markup）
  autocmd FileType markdown,markdown.gfm,org,text,gitcommit setlocal wrap linebreak nolist
  autocmd FileType markdown,markdown.gfm,org setlocal conceallevel=2 concealcursor=nc
  " quickfix 里不要折行
  autocmd FileType qf setlocal nowrap
  " 诊断计数缓存：状态栏每次重绘都要读，所以不在状态栏里现算，
  " 只在下面这几种时机查一次，实现见 autoload/ec/ui.vim。
  "
  " 为什么用 CursorHold 而不是插件的 User LspDiagsUpdated 事件：
  " 实测那个事件不可靠 —— 有时根本不触发，有时触发了但在该事件里同步调用
  " 它的 lsp#diag#DiagsGetErrorCount() 会失败（异常被 try/catch 吞掉，
  " 表现为状态栏诊断数永远是空）。CursorHold 是 Vim 自己的事件：用户一停下来
  " 就触发一次（updatetime=300ms），正好是「会去看状态栏」的时刻，
  " 而且每次空闲只查一次，对前台零开销。
  autocmd BufEnter,CursorHold,CursorHoldI * call EcUiDiagRefresh() | call EcUiProgressRefresh() | call EcUiProgressBusy()
  " LSP 进度指示器**不在这里挂会调用函数的自动命令**：插件是在 job 回调里
  " doautocmd 的，实测那个上下文里只要自动命令调用函数就抛 E20: Mark not set，
  " 会把后续自动命令全打断。所以这两条**只做纯赋值**（记时间戳），
  " 真正的状态栏更新交给 conf/20-ui.vim 启动的常驻轻量定时器，
  " 细节见 autoload/ec/ui.vim。
  autocmd BufReadPost *.rs,*.c,*.cc,*.cpp,*.cxx,*.h,*.hpp let g:ec_lsp_busy = 1
  autocmd User LspAttached * let g:ec_lsp_busy = 1
augroup END

" 保存时格式化（对应 apheleia-global-mode）。
" 优先交给 neoformat，没有它时退回手写实现；实现在 autoload/ec/fmt.vim。
" a:1 显式给出 filetype —— *.h 这类扩展名 Vim 探测出的 filetype 可能是空的。
augroup ec_format
  autocmd!
  autocmd BufWritePre *.rs call EcFmtSave('rust')
  autocmd BufWritePre *.c,*.h,*.cc,*.cpp,*.cxx,*.hpp,*.hh call EcFmtSave('c')
augroup END

" ==========================================================================
" 8. 全部键位 + 兜底命令
" （原 conf/60-keymaps.vim）
" ==========================================================================

nnoremap <silent> <leader><leader> :<C-u>call EcPalette()<CR>
nnoremap <silent> <leader>u        :<C-u>call EcUndoTree()<CR>
nnoremap <silent> <leader>U        :<C-u>normal! g+<CR>
nnoremap <silent> <leader>A        :<C-u>normal! ggVG<CR>

" -------------------------------------------------------- 文件 / buffer ----
nnoremap <silent> <leader>ff :<C-u>call EcPick('Files',   'edit .')<CR>
nnoremap <silent> <leader>fr :<C-u>call EcPick('History', 'browse oldfiles')<CR>
nnoremap <silent> <leader>fs :<C-u>write<CR>
nnoremap <silent> <leader>fS :<C-u>write!<CR>

" bl/bc 是原生没有的能力；bd/bn/bp 只是别名，方便记（原生 :bd / :bn / :bp / <C-^> 同样可用）
nnoremap <silent> <leader>bl :<C-u>call EcPick('Buffers', 'ls')<CR>
nnoremap <silent> <leader>bd :<C-u>bdelete<CR>
nnoremap <silent> <leader>bn :<C-u>bnext<CR>
nnoremap <silent> <leader>bp :<C-u>bprevious<CR>
nnoremap <silent> <leader>bc :<C-u>call EcCloseOthers()<CR>

" ---------------------------------------------------------------- 窗口 ------
" 这些是 <C-w> 前缀的别名（原生 <C-w>h/j/k/l、<C-w>v/s、<C-w>c、<C-w>o、<C-w>=、
" <C-w>>/< 一样可用）。留着是为了和 Emacs 的 SPC w 习惯一致，which-key 里也能看到。
nnoremap <silent> <leader>wh <C-w>h
nnoremap <silent> <leader>wj <C-w>j
nnoremap <silent> <leader>wk <C-w>k
nnoremap <silent> <leader>wl <C-w>l
nnoremap <silent> <leader>wd :<C-u>call EcCloseWindow()<CR>
nnoremap <silent> <leader>w/ :<C-u>vsplit<CR>
nnoremap <silent> <leader>w- :<C-u>split<CR>
nnoremap <silent> <leader>wo :<C-u>only<CR>
nnoremap <silent> <leader>w= <C-w>=
nnoremap <silent> <leader>w> :<C-u>vertical resize +5<CR>
nnoremap <silent> <leader>w< :<C-u>vertical resize -5<CR>

" ---------------------------------------------------------------- 搜索 ------
nnoremap <silent> <leader>ss :<C-u>call EcPick('BLines', '/')<CR>
nnoremap <silent> <leader>sr :<C-u>call EcPick('Rg',     'grep!')<CR>
nnoremap <silent> <leader>sf :<C-u>call EcFocusLines()<CR>
nnoremap <silent> <leader>sS :<C-u>call EcLsp('LspDocumentSymbol', 'ls')<CR>

" ---------------------------------------------------------------- 剪贴板 ----
" 对应 Emacs：SPC y p = consult-yank-pop、SPC y r = consult-yank-replace
nnoremap <silent> <leader>yy :<C-u>call EcClipYankLine()<CR>
xnoremap <silent> <leader>yy :<C-u>call EcClipCopy()<CR>
nnoremap <silent> <leader>yp :<C-u>call EcClipPaste(0)<CR>
xnoremap <silent> <leader>yp :<C-u>call EcClipPaste(0)<CR>
nnoremap <silent> <leader>yr :<C-u>call EcClipReplace()<CR>
xnoremap <silent> <leader>yr :<C-u>call EcClipReplace()<CR>

" 命令行 / 插入态也能粘贴系统剪贴板。
" 背景：本机 Vim 是 has('clipboard') == 0（-clipboard 编译），所以原生的
"   <C-r>+ / <C-r>* 只会报 W24: Clipboard register not available —— 命令输入行里
"   根本粘不进东西。这里把它们接到 Windows 剪贴板（读一次约 200ms）。
" · 命令行：<C-v>、<C-r>+、<C-r>* 都粘贴（多行会折成单行空格）
" · 插入态：<C-r>+、<C-r>* 原样插入（多行保持多行）
" · 命令行的 <C-v> 原本是「原样插入下一个字符」，想保留原生行为：
"     let g:ec_clip_cmdline_ctrlv = 0
if get(g:, 'ec_clip_cmdline_ctrlv', 1)
  cnoremap <C-v> <C-r>=EcClipGetCmdline()<CR>
endif
cnoremap <C-r>+ <C-r>=EcClipGetCmdline()<CR>
cnoremap <C-r>* <C-r>=EcClipGetCmdline()<CR>
inoremap <C-r>+ <C-r>=EcClipGet()<CR>
inoremap <C-r>* <C-r>=EcClipGet()<CR>

" 搜索提示行的粘贴（见 EcSearchPasteKeys）：/ 或 ? 里 <C-p> = 粘贴，
" : 命令行里 <C-p> 仍是「历史上一条」；<C-n> / <Up> / <Down> 历史随时可用。
cnoremap <expr> <C-p> EcSearchPasteKeys()

" ---------------------------------------------------------------- git -------
nnoremap <silent> <leader>gs :<C-u>call EcGit('Git', 'terminal git status')<CR>
nnoremap <silent> <leader>gd :<C-u>call EcGit('Git diff', 'terminal git diff')<CR>
nnoremap <silent> <leader>gD :<C-u>call EcGit('Git diff --staged', 'terminal git diff --staged')<CR>
nnoremap <silent> <leader>gl :<C-u>call EcGit('Git log --oneline --graph --decorate -50', 'terminal git log --oneline --graph --decorate -50')<CR>
nnoremap <silent> <leader>gb :<C-u>call EcGit('Git blame', 'terminal git blame %')<CR>
" 对应 Emacs：SPC g c = magit-commit-create、g P = magit-push、g F = magit-pull
nnoremap <silent> <leader>gc :<C-u>call EcGit('Git commit', 'terminal git commit')<CR>
nnoremap <silent> <leader>gP :<C-u>call EcGit('Git push',   'terminal git push')<CR>
nnoremap <silent> <leader>gF :<C-u>call EcGit('Git pull',   'terminal git pull')<CR>

" ---------------------------------------------------------------- LSP -------
nnoremap <silent> <leader>la :<C-u>call EcLsp('LspCodeAction',      '')<CR>
nnoremap <silent> <leader>lR :<C-u>call EcLsp('LspRename',          '')<CR>
nnoremap <silent> <leader>lf :<C-u>call EcLsp('LspFormat',          'EcFormat')<CR>
nnoremap <silent> <leader>ld :<C-u>call EcLsp('LspGotoDefinition',  'tag')<CR>
nnoremap <silent> <leader>lD :<C-u>call EcLsp('LspGotoDeclaration', 'tag')<CR>
nnoremap <silent> <leader>li :<C-u>call EcLsp('LspGotoImpl',        'tag')<CR>
nnoremap <silent> <leader>lr :<C-u>call EcLsp('LspShowReferences',  'grep!')<CR>
nnoremap <silent> <leader>lh :<C-u>call EcLsp('LspHover',           'echo expand("<cword>")')<CR>
nnoremap <silent> <leader>lo :<C-u>call EcLsp('LspOrganizeImports', 'LspCodeAction')<CR>
nnoremap <silent> <leader>ls :<C-u>call EcLsp('LspSymbolSearch',    'EcTags')<CR>
nnoremap <silent> <leader>le :<C-u>call EcLsp('LspDiag show',       'copen')<CR>
nnoremap <silent> <leader>lt :<C-u>call EcLsp('LspGotoTypeDef',     'tag')<CR>
nnoremap <silent> <leader>ln :<C-u>call EcLsp('LspDiag next',       'cnext')<CR>
nnoremap <silent> <leader>lN :<C-u>call EcLsp('LspDiag prev',       'cprev')<CR>
nnoremap <silent> <leader>lS :<C-u>call EcLsp('LspShowAllServers',  '')<CR>
" 行内诊断文字（错误提示内容）开关：Emacs 那边是 flymake 直接把错误标在 buffer 里，
" 插件默认不显示 message 文本（只有 E> 标记），这里补上，并留一个随时能关的开关。
nnoremap <silent> <leader>lv :<C-u>call EcDiagText('toggle')<CR>

" ------------------------------------------------ 文件管理器 / 终端 -------
" 对应 Emacs：SPC d d = dirvish、SPC d o = dirvish-quick-access、
"            SPC e t = vterm、SPC e e = eshell、SPC e c = eshell-command
nnoremap <silent> <leader>dd :<C-u>call EcExplore(0)<CR>
nnoremap <silent> <leader>do :<C-u>call EcExplore(1)<CR>
nnoremap <silent> <leader>ec :<C-u>call EcTerminal('cmd')<CR>
nnoremap <silent> <leader>ee :<C-u>call EcTerminal('new')<CR>
nnoremap <silent> <leader>et :<C-u>call EcTerminal('toggle')<CR>
" 关闭浮窗终端。F 键在很多键盘/终端里按不到，所以关闭动作走 leader：
"   SPC e k  关掉当前这个（连同终端进程）
"   SPC e K  一次关掉所有浮窗
" 在浮窗里时先按 <C-\><C-n> 回到普通模式再按；或者直接在浮窗 buffer 的
" 普通模式下按 q（见 after/plugin 里的 FileType floaterm 处理）。
" 另外在 shell 里按 <C-d>（EOF）也能让浮窗随进程退出而关闭。
nnoremap <silent> <leader>ek :<C-u>call EcTerminal('kill')<CR>
nnoremap <silent> <leader>eK :<C-u>call EcTerminal('killall')<CR>

" ---------------------------------------------------------------- 帮助 ------
" 只留原生没有的：hm 看当前 buffer 属性、ho/hr 开关/重载自己的配置。
" hk/hb/hf/hv/ht 是 :map <Space> / :map / :command / :let / :help 的别名（原生同样可用）；
" hm 看当前 buffer 属性、ho/hr 开关 / 重载自己的配置则是原生没有的。
nnoremap <silent> <leader>hk :<C-u>map <Space><CR>
nnoremap <silent> <leader>hb :<C-u>map<CR>
nnoremap <silent> <leader>hf :<C-u>command<CR>
nnoremap <silent> <leader>hv :<C-u>let<CR>
nnoremap <silent> <leader>ht :<C-u>help<CR>
nnoremap <silent> <leader>hm :<C-u>echo 'filetype=' . &filetype . '  buftype=' . &buftype . '  syntax=' . (&syntax ==# '' ? 'off' : &syntax)<CR>
nnoremap <silent> <leader>ho :<C-u>call EcOpenConfig()<CR>
nnoremap <silent> <leader>hr :<C-u>call EcReloadConfig()<CR>

" ------------------------------------------- 跳转 / 选区 / 重载 / 退出 ----
" 与 Emacs 的 SPC j 前缀一一对应：
"   SPC j j = avy-goto-char-timer（跳到指定字符）
"   SPC j w = avy-goto-word-1（跳到词首）
"   SPC j l = avy-goto-line（跳到行）
" 装了 easymotion 时由 after/plugin 换成它的实现，这里是无插件时的兜底。
nnoremap <silent> <leader>jj :<C-u>call EcJumpGo('char')<CR>
nnoremap <silent> <leader>jw :<C-u>call EcJumpGo('word')<CR>
nnoremap <silent> <leader>jl :<C-u>call EcJumpGo('line')<CR>
nnoremap <silent> <leader>jJ :<C-u>call EcPick('Jumps', 'jumps')<CR>

" 普通模式只有「扩展」有意义（原来 xx / xX 在普通模式是同一个动作）
nnoremap <silent> <leader>xx :<C-u>call EcRegionEx(0)<CR>
xnoremap <silent> <leader>xx :<C-u>call EcRegionEx(1)<CR>
xnoremap <silent> <leader>xX :<C-u>call EcRegionEx(-1)<CR>

nnoremap <silent> <leader>re :<C-u>call EcReloadConfig()<CR>
nnoremap <silent> <leader>ro :<C-u>call EcOpenConfig()<CR>
nnoremap <silent> <leader>rl :<C-u>edit!<CR>

" 退出：leader 别名（原生 :q / :q! / :qa / :qa! 也同样可用）
nnoremap <silent> <leader>qq :<C-u>quit<CR>
nnoremap <silent> <leader>qQ :<C-u>quit!<CR>
nnoremap <silent> <leader>qa :<C-u>quitall<CR>
nnoremap <silent> <leader>qA :<C-u>quitall!<CR>

" ------------------------------------------- 与 Vim 原生对齐（不再抢原生键）----
" gc / gcc / 可视 gc = vim-commentary 的注释操作符（原生手感，且能被 . 重复）。
" 取消搜索高亮不占键位了：改用 Vim 自带的 nohlsearch 包（见 conf/30-search.vim），
" 空闲 updatetime 或进插入模式时自动清。
"
" C-s：Vim 原生 C-s 在终端里是 XOFF（会把终端冻住），这里接管成「前向搜索」。
nnoremap <silent> <C-s> /
"
" gi / go / Y 都不再映射，交回 Vim：
"   gi = 回到上次插入位置（原生，很实用）
"   go = 跳到第 N 个字节（原生，罕用）
"   Y  = 整行复制（Vim 9.2 原生就是 yy，见 :h Y）
" 改动列表 g; / g, 、跳转列表 C-o / C-i 、buffer 切换 <C-^> / :bn / :bp 也都是原生键。
" 顺带：<Tab> 与 <C-i> 是同一个键码，所以 <Tab> 一直没被拿来做 buffer 切换。

" ---------------------------------------------------------------- 插入态 ----
" 对齐 evil-insert-state-map；补全菜单弹出时方向键仍可用于选候选。
inoremap <expr> <C-a> pumvisible() ? "\<C-a>" : "\<Home>"
inoremap <expr> <C-e> pumvisible() ? "\<C-e>" : "\<End>"
inoremap <expr> <C-n> pumvisible() ? "\<C-n>" : "\<Down>"
inoremap <expr> <C-p> pumvisible() ? "\<C-p>" : "\<Up>"
inoremap <expr> <C-y> pumvisible() ? "\<C-y>" : "\<C-r>\""
inoremap <C-k> <C-o>D
inoremap <expr> <Tab>   pumvisible() ? "\<C-n>" : "\<Tab>"
inoremap <expr> <S-Tab> pumvisible() ? "\<C-p>" : "\<S-Tab>"
inoremap <expr> <CR>    pumvisible() ? "\<C-y>" : "\<CR>"
inoremap <C-Space> <C-x><C-o>

" ---------------------------------------------------------------- 小工具 ----
nnoremap <A-j> :m .+1<CR>==
nnoremap <A-k> :m .-2<CR>==
inoremap <A-j> <Esc>:m .+1<CR>==gi
inoremap <A-k> <Esc>:m .-2<CR>==gi
vnoremap <A-j> :m '>+1<CR>gv=gv
vnoremap <A-k> :m '<-2<CR>gv=gv
vnoremap < <gv
vnoremap > >gv

" --------------------------------------------- 供兜底动作引用的命令 --------
" execute 的字符串里 s: / <SID> 不会被解析，所以给「兜底动作」包一层命令：
"   <leader>lf 的兜底 EcFormat、<leader>ls 的兜底 EcTags
command! -bar EcFormat call EcFormatBuffer()
command! -bar EcTags   call EcPick('BTags', 'ls')

" ==========================================================================
" 9. 插件声明与插件选项（原 plugins.vim）
" ==========================================================================

" --- 自举 1/2：没有 vim-plug 就自动下载（把 ~/.vim 整个删掉也能自愈）----
let s:vimhome  = expand('~/.vim')
let s:plug_vim = s:vimhome . '/autoload/plug.vim'
let s:plug_url = 'https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim'

if empty(glob(s:plug_vim))
  echomsg '未发现 vim-plug，正在下载…'
  call mkdir(s:vimhome . '/autoload', 'p')
  if executable('curl')
    call system('curl -fsSL --connect-timeout 10 --max-time 120 --create-dirs -o '
          \ . shellescape(s:plug_vim) . ' ' . s:plug_url)
  elseif executable('wget')
    call system('wget -q -O ' . shellescape(s:plug_vim) . ' ' . s:plug_url)
  endif
  if empty(glob(s:plug_vim))
    echomsg 'vim-plug 下载失败（检查网络），本次跳过插件层'
  else
    echomsg 'vim-plug 已下载：' . s:plug_vim
  endif
endif

" 顺带保证 undo / fzf 历史目录存在（它们也在 ~/.vim 下，可能被一起删掉）
call mkdir(expand('~/.vim/undo'), 'p')
call mkdir(expand('~/.vim/fzf-history'), 'p')

" 文档副本在 ~/vim-recon/EMACS-VIM.md，~/.vim 被删后自动恢复
if !filereadable(expand('~/.vim/EMACS-VIM.md'))
      \ && filereadable(expand('~/vim-recon/EMACS-VIM.md'))
  call writefile(readfile(expand('~/vim-recon/EMACS-VIM.md')),
        \ expand('~/.vim/EMACS-VIM.md'))
  echomsg '已从 ~/vim-recon/EMACS-VIM.md 恢复文档'
endif

if empty(glob(s:plug_vim))
  echomsg '未找到 vim-plug，已跳过插件层（本文件的内置功能仍然可用）'
else

" ===================================================== 插件选项（须提前设） ==

" ---- fzf / fzf.vim：对应 vertico + consult + orderless ----
" fzf 默认把 ctrl-n / ctrl-p 绑成 down-match / up-match（只在「匹配到的行」之间跳）。
" 在 buffer / 文件 / 搜索列表里所有行都匹配时，表现就是「按了 C-n / C-p 没反应」。
" 这里改回普通的 down / up，与 Emacs 的 consult-buffer / vertico 里 C-n / C-p 一致。
" 对所有 fzf 选择器（:Files :Buffers :Rg :BLines :History …）都生效。
" ⚠ FZF_DEFAULT_OPTS 里的选项值**必须加引号**（fzf 是 shell 式切分）：
"    `--bind=x` / `--bind x` 这两种写法会被**整条忽略**（实测 fzf 0.72），只有
"    `--bind='x'` 生效。原来这里就是漏了引号，等于没设（好在 fzf 默认就是
"    ctrl-n=down / ctrl-p=up，所以一直没人发现）。
let $FZF_DEFAULT_OPTS = $FZF_DEFAULT_OPTS
      \ . " --bind='ctrl-n:down,ctrl-p:up,ctrl-d:half-page-down,ctrl-u:half-page-up'" 

let g:fzf_layout         = { 'down': '40%' }   " 贴底弹出，像 minibuffer
let g:fzf_preview_window = []                  " 关预览（对应 dirvish-preview-dispatchers nil）
let g:fzf_history_dir    = '~/.vim/fzf-history'
let g:fzf_buffers_jump   = 1
let g:fzf_action         = {
      \ 'ctrl-t': 'tab split',
      \ 'ctrl-x': 'split',
      \ 'ctrl-v': 'vsplit' }
let g:fzf_colors = {
      \ 'fg':      ['fg', 'Normal'],
      \ 'bg':      ['bg', 'Normal'],
      \ 'hl':      ['fg', 'Statement'],
      \ 'fg+':     ['fg', 'Normal'],
      \ 'bg+':     ['bg', 'CursorLine'],
      \ 'hl+':     ['fg', 'Statement'],
      \ 'info':    ['fg', 'Comment'],
      \ 'border':  ['fg', 'Ignore'],
      \ 'prompt':  ['fg', 'Function'],
      \ 'pointer': ['fg', 'Exception'],
      \ 'marker':  ['fg', 'Keyword'],
      \ 'spinner': ['fg', 'Label'],
      \ 'header':  ['fg', 'Comment'] }

" ---- 编辑增强 ----
" lexima（对应 electric-pair-mode）：g:lexima_no_default_rules = 1 ——
" 它的默认规则太宽（还含反引号、markdown 三引号、空格规则、endwise 补 end），
" 我们在 after/plugin 里按 Emacs 的 electric-pair-pairs 重新装一遍收窄后的规则。
let g:lexima_no_default_rules = 1
" 补全菜单弹出时 <CR> 确认候选（与 corfu 一致）。Vim 下默认是 0，这里显式打开。
let g:lexima_accept_pum_with_enter = 1
let g:lexima_ctrlh_as_backspace = 0            " 不要抢 <C-h>

" expand-region：用可视模式而不是 select 模式（与 evil 一致）
let g:expand_region_use_select_mode = 0

" vim-visual-multi（对应 evim 的多光标）
let g:VM_maps = {}
let g:VM_maps['Find Under']         = '<C-n>'  " 与 evim / Emacs 的 C-n 一致
let g:VM_maps['Find Subword Under'] = '<C-n>'
let g:VM_maps['Add Cursor Down']    = '<C-Down>'
let g:VM_maps['Add Cursor Up']      = '<C-Up>'
let g:VM_mouse_mappings = 1

" ---- 【10】tpope/vim-repeat：让 . 能重放插件操作 ----
" Emacs 的 evil-repeat 天然支持；Vim 的 . 只认原生操作。
" 装上之后 commentary / visual-multi / lexima / surround 等都能被 . 重复。
" （无选项）

" ---- 【5】ojroques/vim-oscyank：OSC 52 剪贴板（UTF-8 无损） ----
" 提示信息由 autoload/ec/clip.vim 负责，这里关掉插件自己的消息；
" 不设长度上限（Windows Terminal 支持长序列），也不做 trim（Emacs 不 trim）。
let g:oscyank_silent     = 1
let g:oscyank_max_length = 0
let g:oscyank_trim       = 0

" ---- 【2】sbdchd/neoformat：保存时格式化（对应 apheleia） ----
" 只覆盖 rust 的定义 —— 它默认不带 --edition，会和手写兜底
" `rustfmt --edition 2021` 的行为不一致。c / cpp 保持 neoformat 自带定义，
" 它带 -assume-filename，能正确读到文件所在目录的 .clang-format
"（手写版走 stdin、读不到，这里反而是个改进）。
" 注意：g:neoformat_<ft>_<name> 是整体替换、不与内置定义合并，所以要写全。
let g:neoformat_enabled_rust = ['rustfmt']
let g:neoformat_rust_rustfmt = {
      \ 'exe':   'rustfmt',
      \ 'args':  ['--edition', '2021'],
      \ 'stdin': 1 }
let g:neoformat_enabled_c   = ['clangformat']
let g:neoformat_enabled_cpp = ['clangformat']
let g:neoformat_only_msg_on_error = 1          " 只在出错时提示（对应 apheleia 的安静行为）

" ---- yegappan/lsp：对应 eglot ----
" 语言服务器的 nice 优先级（0 = 不降优先级）。
" 实测 rust-analyzer 附加到 Cargo 工程后会冲到 200%+ CPU、约 2GB 内存并持续
" 索引几十秒；用 nice 把它压到后台，前台编辑不受影响。只改调度优先级，
" 不影响任何 LSP 功能。用法见 after/plugin/zz-emacs-compat.vim 第 4 节。
let g:ec_lsp_nice = get(g:, 'ec_lsp_nice', 10)

" ---- 【4】easymotion/vim-easymotion：对应 avy ----
" g:EasyMotion_do_mapping = 0 是关键：关掉它自带的全部默认映射，
" 因为它的默认前缀 <Leader><Leader> 正好等于我们的 <Space><Space>
"（M-x 命令面板），不关会把命令面板顶掉。
" <Plug>(easymotion-*) 不受这个开关影响，我们在 after/plugin 里按
" Emacs 的 SPC j 键位自己绑。
let g:EasyMotion_do_mapping = 0
let g:EasyMotion_keys = 'asdfghjklqwertyuiopzxcvbnm'  " 与 autoload/ec/jump.vim 的 s:keys 一致
let g:EasyMotion_smartcase          = 0   " Emacs 侧没开 smartcase
let g:EasyMotion_use_upper          = 0   " 不用大写字母做标签
let g:EasyMotion_off_screen_search  = 0   " 与 avy 一致：只标注当前窗口内的目标
let g:EasyMotion_enter_jump_first   = 0
let g:EasyMotion_space_jump_first   = 0
let g:EasyMotion_add_search_history = 0   " 不往 / 的搜索历史里塞东西
let g:EasyMotion_verbose            = 0

" ---- 【3】justinmk/vim-dirvish：目录即 buffer（对应 Emacs 的 dirvish） ----
" 它自己会在 `-` 没被占用时把 `-` 绑成「去上级目录」（plugin/dirvish.vim 里用
" mapcheck('-','n') 判断），这跟 Emacs 里 evil-collection 的 dired 一致，
" 所以我们不去占用 `-`。
let g:dirvish_relative_paths = 0          " 用完整路径（显示时前缀会被 conceal）
let g:dirvish_mode = ':sort ,^.*[\/],'    " 目录在前、文件在后

" ---- 【12】chrisbra/NrrwRgn：把选区摘到独立 buffer 里编辑（对应 narrow-to-region） ----
" g:nrrw_rgn_nomap_nr / _Nr = 1：禁用插件自带的 <Leader>nr / <Leader>Nr。
" 它自带的是「<Plug> + opfunc + g@」形式，需要后续输入，经 <leader> 前缀
"（which-key 的输入循环）执行不可靠 —— 和 easymotion 同一个坑。
" 我们在 after/plugin 里用 :call 命令形式自己绑。
" 注意 g:nrrw_rgn_incr 是「窄窗尺寸的调整步长」，不是「增量同步」，别设错。
let g:nrrw_rgn_nomap_nr = 1
let g:nrrw_rgn_nomap_Nr = 1
let g:nrrw_rgn_vert = 1     " 垂直分屏（默认 0 = 水平）
let g:nrrw_rgn_wdth = 60    " 窄窗宽度（vert 时是列数；默认 20 太窄）

" ---- 【17】voldikss/vim-floaterm：浮窗终端（对应 Emacs 的 vterm） ----
" <leader>e t 呼出/隐藏、<leader>e e 新开、<leader>e c 跑一条命令
"（对应 Emacs 的 SPC e t = vterm、e e = eshell、e c = eshell-command）。
" F7/F8/F9 在浮窗里也能用 —— 本配置里 F 键完全空闲。
let g:floaterm_wintype    = 'float'    " 浮窗（Vim 用 popup window 实现）
let g:floaterm_width      = 0.85
let g:floaterm_height     = 0.85
let g:floaterm_position   = 'center'
let g:floaterm_autoclose  = 'smart'    " 用命令启动的浮窗跑完自动关
let g:floaterm_autoinsert = 'smart'
let g:floaterm_keymap_toggle = '<F7>'
let g:floaterm_keymap_kill   = '<F8>'
let g:floaterm_keymap_new    = '<F9>'
" 浮窗终端里把 <Esc> 绑成「回到普通模式」（默认 1）。
" 为什么要这个：终端输入模式（Terminal-Job）下**所有按键都直接发给 shell**，
" 连 leader（<Space>）也只会打出一个空格，于是「在终端里用不了 leader 键」。
" 绑上之后：<Esc> 回普通模式 → leader 全部可用 → i / a 继续往 shell 打字。
" ⚠ 代价：<Esc> 不再送给浮窗里运行的程序。如果要在浮窗里跑自己要吃 <Esc> 的
"   TUI 程序（嵌套 vim / hx / lazygit / htop 等），把这里设成 0 即可：
"       let g:ec_floaterm_esc = 0
"   那样就仍用 Vim 自带的 <C-\><C-n> 离开终端模式。
let g:ec_floaterm_esc = get(g:, 'ec_floaterm_esc', 1)

" ============================================================ 插件清单 ======
" --- 自举 2/2：插件目录缺失时自动安装；装完把本地补丁打回去并重新加载配置 ---
" （首次启动、或 ~/.vim/plugged 被删掉之后会自动走到这里）
function! EcReapplyLocalPatches() abort
  " yegappan/lsp：把「拉诊断改成异步」的本地 patch 打回去
  " （插件是 git clone 来的，重新安装后补丁没了，这里自动重放）
  let l:patch = expand('~/vim-recon/lsp-async-pull.patch')
  let l:plugd = expand('~/.vim/plugged/lsp')
  if !filereadable(l:patch) || !isdirectory(l:plugd)
    return
  endif
  " 已经打过（补丁能反向应用）就跳过
  call system('cd ' . shellescape(l:plugd) . ' && git apply --check --reverse '
        \ . shellescape(l:patch) . ' >/dev/null 2>&1')
  if v:shell_error == 0
    return
  endif
  let l:r = system('cd ' . shellescape(l:plugd) . ' && git apply '
        \ . shellescape(l:patch) . ' 2>&1')
  if v:shell_error == 0
    echomsg '已重放 LSP 异步 patch'
  else
    echomsg 'LSP patch 应用失败：' . substitute(l:r, '\n', ' ', 'g')
  endif
endfunction

call plug#begin('~/.vim/plugged')

Plug 'junegunn/fzf'          " 系统已装 fzf 可执行文件，无需 do 钩子
Plug 'junegunn/fzf.vim'
Plug 'tpope/vim-fugitive'
Plug 'tpope/vim-commentary'
Plug 'mbbill/undotree'
Plug 'mg979/vim-visual-multi'
Plug 'terryma/vim-expand-region'
Plug 'cohama/lexima.vim'
Plug 'liuchengxu/vim-which-key'
Plug 'yegappan/lsp'
Plug 'tpope/vim-repeat'
Plug 'ojroques/vim-oscyank'
Plug 'sbdchd/neoformat'
Plug 'easymotion/vim-easymotion'
Plug 'justinmk/vim-dirvish'
Plug 'chrisbra/NrrwRgn'
Plug 'voldikss/vim-floaterm'

call plug#end()

  " --- 自举 2/2：插件目录缺失就自动下载安装（首次启动 / 删过 ~/.vim 之后）----
  " g:plugs 是 plug#end() 建好的「插件名 -> 信息」表，dir 不存在就说明没装。
  let s:missing = filter(copy(get(g:, 'plugs', {})), '!isdirectory(v:val.dir)')
  if !empty(s:missing)
    echomsg printf('检测到 %d 个插件未安装，正在自动下载安装（首次需要网络，请稍候）…',
          \ len(s:missing))
    redraw
    " 为什么不用 :PlugInstall：
    "   · 无界面模式（-es / 非交互）下它会开窗口做进度显示，直接失败，
    "     还会打断后续的 VimEnter 自动命令（实测整个启动流程就此中断）；
    "   · 子进程 `vim +PlugInstall +qall` 同样静默失败（实测 3 秒返回、0 个插件）。
    " 所以这里直接用 g:plugs 里记录的仓库地址 git clone —— headless 与交互都可靠。
    " 目录地址由 plug#begin/end 事先写进 runtimepath，克隆完本会话即可加载。
    let s:fail = []
    for [s:name, s:info] in items(s:missing)
      " vim-plug 把 GitHub 地址存成 https://git::@github.com/...（内部形式），还原成普通地址
      let s:url = substitute(s:info.uri, 'https://git::@', 'https://', '')
      let s:branch = empty(s:info.branch) ? ''
            \ : '--branch ' . shellescape(s:info.branch) . ' '
      if !isdirectory(s:info.dir)
        call mkdir(s:info.dir, 'p')
      endif
      " 先试浅克隆（快）；有些仓库/代理不支持，失败就退完整克隆
      call system('git clone --quiet --depth 1 ' . s:branch
            \ . shellescape(s:url) . ' ' . shellescape(s:info.dir) . ' 2>&1')
      if v:shell_error != 0
        call system('rm -rf ' . shellescape(s:info.dir))
        call system('git clone --quiet ' . s:branch
              \ . shellescape(s:url) . ' ' . shellescape(s:info.dir) . ' 2>&1')
      endif
      if !isdirectory(s:info.dir . '.git')
        call add(s:fail, s:name)
      endif
    endfor
    if empty(s:fail)
      echomsg printf('%d 个插件已装好，继续加载配置', len(s:missing))
    else
      echomsg '这些插件没装成功：' . join(s:fail, ', ') . '（检查网络 / git）'
    endif
    " 新克隆下来的 lsp 是干净的，把我们本地的异步 patch 打回去
    call EcReapplyLocalPatches()
  endif
endif

" ==========================================================================
" 10. 插件加载之后的配置（原 after/plugin/zz-emacs-compat.vim）
" ==========================================================================

" 顶层部分：纯数据（g: 变量）与「只在事件触发时才用到插件」的自动命令

" ---- 4) LSP（对应 eglot + rust-analyzer / clangd）----
  " ⚠ 判断顺序非常关键（2026-09-27 用 --startuptime + profile 定位）：
  "   PATH 里混进了 23 条 /mnt/c/... （Windows 盘，走 9p）路径，而 rust-analyzer
  "   **并不在 PATH 里** —— executable('rust-analyzer') 要把整条 PATH 扫完，
  "   实测一次 54.2ms（executable('clangd') 因为 /usr/bin 排在前面只要 0.025ms）。
  "   vim 启动 90ms 里 55ms 就是这么来的。先查已知的绝对路径（一次 stat，0.015ms），
  "   查不到再退回扫 PATH：启动 90ms → 39ms（实测三次：41/39/37ms）。
  function! s:exe(name, fallback) abort
    if a:fallback !=# '' && executable(a:fallback) | return a:fallback | endif
    if executable(a:name) | return a:name | endif
    return ''
  endfunction

  " ⚠ autoHighlight 必须是 false（插件默认也是 false）：
  "   它开着时插件会给每个 buffer 装一条
  "     CursorMoved → LspDocHighlightClear | LspDocHighlight(bnr, "silent")
  "   于是**每移动一次光标**就发一个 textDocument/documentHighlight 请求；
  "   而 DocHighlight 在发请求前会先 listener_flush() 把挂起的改动推给服务器，
  "   rust-analyzer 一旦发现请求期间的文档版本变了就回 ContentModified(-32801)，
  "   插件在 AsyncRpcCb 里对**所有**异步请求错误都无条件
  "   ProcessLspServerError 报错（它自己的 "silent" 只挡得住
  "   DocHighlightReply 那条 "Document highlight failed:"），
  "   于是打开/编辑文件时就会蹦出：
  "     request textDocument/documentHighlight failed
  "       (content modified, error = ContentModified)
  "   关掉之后这个请求根本不会发出，报错随之消失，也省掉每次移光标的
  "   一次 LSP 往返。想临时看一眼同名符号可以用 :LspHighlight（手动触发时才报错）。
  "   顺带一提：Emacs 那边也没开任何「高亮同名符号」的功能，关掉更贴近 Emacs。
  "
  " 【错误提示文本】对应 Emacs 的 eldoc：错误内容回显在底部那一行（就是敲 : 命令的
  " 消息/输入区），光标离开那一行就自动清掉；符号列的 E> 和出错代码段的 undercurl 照旧。
  " 插件里这几个选项默认**全是关的**，这就是「只有 E> 标记、看不到错误内容」的原因：
  "   showDiagOnStatusLine     光标停在有诊断的行上时，把完整 message（带错误码，如
  "                            [E0308]）回显到底部消息区 —— 默认开。
  "   showDiagWithVirtualText  把 message 当虚拟文本画进 buffer —— 默认关（会把下面的
  "                            代码顶下去），想临时开用 <leader>lv，想常开就
  "                            let g:ec_diag_text = v:true。
  "   diagVirtualTextAlign     行内文字的位置：above=行上方（推荐）/ below=行下方 / after=行尾。
  "                            实测 after 会把同一行上的所有诊断（含 hint）都堆到代码行尾、
  "                            message 里的换行被拍平、长消息被窗口右边缘截断/折行（还会
  "                            带上 showbreak 的 ↪）；above/below 每条诊断独占一个虚拟行、
  "                            完整显示、代码行原样不动。
  "   diagVirtualTextWrap      插件默认 default（above/below 模式会截断），设 wrap 显示完整内容。
  "   highlightDiagInline      插件默认 true：出错的那段代码本身加 undercurl。
  "                            前提是主题里定义了 LspDiagInline* —— 原来 colors 文件里
  "                            写的是 Neovim 的 DiagnosticUnderline*，插件根本不认（已修）。
  " ⚠ showDiagOnStatusLine 只在 buffer 附加到 LSP 服务器时（diag#BufferInit）注册
  "   CursorMoved 自动命令，所以改这个开关要**重启 vim** 才生效（行内文字那个随时可切）。
  " 太长被截断的 message 想看全：:LspDiag current（弹窗），或 SPC l e 列出全部诊断。
  let g:ec_diag_align = get(g:, 'ec_diag_align', 'above')
  let g:ec_diag_text  = get(g:, 'ec_diag_text', v:false)
  let g:ec_diag_echo  = get(g:, 'ec_diag_echo', v:true)

  " 【死配置清理 2026-09-28】下面 5 个键在当前插件版本里已不存在（上游删除/改名）：
  "   autoDiagnostic            拉诊断根本没有开关，这个键毫无用途
  "   completionPumWidth        补全菜单宽度选项已被删除
  "   hoverPopupBorder          被统一的 popupBorder 取代（默认 false = 无边框，正合原意）
  "   completionPopupBorder     同上
  "   showCompletionDocumentation  补全文档现在总是显示
  " 它们会被 LspOptionsSet 静默并进 dict 但完全无效，留着只会误导人。
let g:lsp_options = {
      \ 'autoComplete': v:true,
      \ 'autoHighlight': v:false,
      \ 'autoHighlightDiags': v:true,
      \ 'autoPopulateDiags': v:false,
      \ 'formatFallback': v:true,
      \ 'completionTextEdit': v:true,
      \ 'completionMatcher': 'fuzzy',
      \ 'diagSignErrorText': 'E>',
      \ 'diagSignWarningText': 'W>',
      \ 'diagSignInfoText': 'I>',
      \ 'diagSignHintText': 'H>',
      \ 'diagVirtualTextAlign': g:ec_diag_align,
      \ 'diagVirtualTextWrap': 'wrap',
      \ 'echoSignature': v:false,
      \ 'hideDisabledCodeActions': v:false,
      \ 'hoverFallback': v:true,
      \ 'hoverInPreview': v:true,
      \ 'outlineWinSize': 25,
      \ 'showDiagInBalloon': v:true,
      \ 'showDiagInPopup': v:true,
      \ 'showDiagWithVirtualText': g:ec_diag_text,
      \ 'showDiagOnStatusLine': g:ec_diag_echo,
      \ 'showSignature': v:true,
      \ 'snippetSupport': v:true,
      \ 'useBufferCompletion': v:true,
      \ 'useQuickfixForLocations': v:false }

  " 【性能】语言服务器放到低优先级跑，让它在后台默默索引、不跟前台抢资源。
  " 实测：rust-analyzer 附加到工程后会冲到 200%+ CPU、约 2GB 内存，索引持续
  " 几十秒（Vim 自己的输入回显一直是 21ms，卡的是整机资源被抢）。
  " nice 只改调度优先级、不影响任何 LSP 功能；g:ec_lsp_nice = 0 可关掉。
  "
  " 实现方式：插件是拿 [path] + args 直接 job_start 的，所以把 path 换成 nice、
  " 把真正的服务器路径放到 args 末尾即可。注意插件会检查 server.path 是否
  " 可执行，而且本机的 nice 在 /usr/sbin/nice（不在 /usr/bin）。
  " 副作用：:LspShowAllServers 里显示的 Server Path 会是 nice 的路径。
  function! s:with_nice(path, args) abort
    let l:n = get(g:, 'ec_lsp_nice', 10)
    if l:n > 0 && executable('/usr/sbin/nice')
      return #{ path: '/usr/sbin/nice',
            \   args: ['-n', string(l:n)] + a:args + [a:path] }
    endif
    return #{ path: a:path, args: a:args }
  endfunction

  " 说明：原来这里的 syncInit: v:false 已删除 —— 插件里 syncInit 默认就是 false
  "（autoload/lsp/lsp.vim），而且只有 inlay hints 读它，写了等于没写。
  let s:servers = []
  let s:ra = s:exe('rust-analyzer', '/usr/lib/rustup/bin/rust-analyzer')
  if s:ra !=# ''
    let s:w = s:with_nice(s:ra, [])
    " ⚠ 不要给 rust-analyzer 传 workspaceConfig（2026-09-27 实测回退）：
    "   试过 {'check': {'workspace': v:false}} 和 {'cachePriming': {'enable': v:false}}
    "   —— 想让服务器少干活、少卡前台。结果 A/B 三次复现：**任一个开关都会让
    "   rust-analyzer 不再发布诊断**（符号列 E> 60 秒不出现；什么都不传 1.8 秒就出）。
    "   诊断是刚需，所以保持默认；「打开 rs 文件卡一下」改由状态栏进度提示解决
    "   （见 autoload/ec/ui.vim 与文档第 10 节）。
    call add(s:servers, #{
          \ name: 'rust-analyzer',
          \ filetype: ['rust'],
          \ path: s:w.path,
          \ args: s:w.args,
          \ })
  endif
  let s:cd = s:exe('clangd', '/usr/bin/clangd')
  if s:cd !=# ''
    let s:w = s:with_nice(s:cd, ['--background-index'])
    call add(s:servers, #{
          \ name: 'clangd',
          \ filetype: ['c', 'cpp'],
          \ path: s:w.path,
          \ args: s:w.args,
          \ })
  endif
  if !empty(s:servers)
    let g:lsp_servers = s:servers
  endif

  " ---- 4.1) 把 Vim 的原生接口接到 LSP 上（比记 <leader>l* 更 Vim）----
  " 下面这些都是 Vim 自己的机制，接上之后手感就是「原生 Vim + 语言服务器」：
  "   'tagfunc'  → C-] / g] / :tjump / :tag 跳定义
  "                （definitionFallback 保持默认 false：这条路上没有 tags 文件工作流，
  "                 打开它会让「没有 LSP 的 buffer 里按 <leader>ld」去 tjump，
  "                 直接抛 E433: No tags file + E426: Tag not found）
  "   K          → LSP hover；没有内容时 hoverFallback 会让插件执行原生 K（man 等）
  "   'omnifunc' → 插件自己会给附加了服务器的 buffer 设 g:LspOmniFunc，即 <C-x><C-o>
  "                （所以全局的 syntaxcomplete#Complete 已删，见 conf/40-edit.vim）
  " ⚠ 格式化**没有**接 gq / 'formatexpr'，这是实测结论（2026-09-27）：
  "   · 插件文档给的两条路是 setlocal formatexpr=lsp#lsp#FormatExpr() 和
  "     nnoremap gq <Plug>(LspFormat)；
  "   · 前者走 CurbufGetServerChecked('documentRangeFormatting')，实测返回 1（=未格式化），
  "     Vim 于是回退到内置 gq，等于什么都没做；
  "   · 后者走 DocRangeFormat，同样要 documentRangeFormatting，实测 rust-analyzer
  "     只提供 documentFormatting（BufLspServerGet 对 range 返回空），于是只打印
  "     "Formatting unsupported; falling back to built-in."；
  "   · 只有不带范围的 :LspFormat 走 documentFormatting，实测可用（<leader>lf 就是它；
  "     另外保存时也会经 EcFmtSave → rustfmt 格式化）。
  " 结论：gq 保持 Vim 原生（只管按 'formatoptions' 折行），格式化的入口仍是 <leader>lf。
  function! s:lsp_native() abort
    setlocal tagfunc=lsp#lsp#TagFunc
    " K 用 <Cmd> 形式绑定：不改变模式、不产生额外的 :normal! 副作用
    nnoremap <silent> <buffer> K <Cmd>LspHover<CR>
  endfunction

  augroup ec_lsp_native
    autocmd!
    autocmd FileType rust,c,cpp call s:lsp_native()
  augroup END

  let g:which_key_hspace           = 2
  let g:which_key_use_floating_win = 1     " popup 浮窗，不挤动窗口布局
  let g:which_key_timeout          = 0     " 立即弹（总延迟 = Vim timeoutlen 400ms）
  let g:which_key_map = {
        \ 'f': { 'name': '+file',      'f': 'find file', 'r': 'recent',
        \        's': 'save', 'S': 'save (force)' },
        \ 'b': { 'name': '+buffer',    'l': 'switch', 'd': 'close', 'n': 'next', 'p': 'prev',
        \        'c': 'close others' },
        \ 'w': { 'name': '+window',    'h': 'left', 'j': 'down', 'k': 'up', 'l': 'right',
        \        'd': 'close', '/': 'vsplit', '-': 'hsplit', 'o': 'only',
        \        '=': 'equalize', '>': 'wider', '<': 'narrower' },
        \ 's': { 'name': '+search',    's': 'search buffer', 'r': 'ripgrep project',
        \        'f': 'focus lines', 'S': 'document symbols' },
        \ 'y': { 'name': '+clipboard', 'y': 'copy line', 'p': 'paste', 'r': 'replace selection' },
        \ 'g': { 'name': '+git',       's': 'status', 'd': 'diff', 'D': 'diff staged',
        \        'l': 'log', 'b': 'blame', 'c': 'commit', 'P': 'push', 'F': 'pull' },
        \ 'l': { 'name': '+lsp',       'a': 'code action', 'R': 'rename', 'f': 'format',
        \        'd': 'definition', 'D': 'declaration', 'i': 'implementation',
        \        'r': 'references', 'h': 'hover', 'o': 'organize imports',
        \        's': 'workspace symbols', 'e': 'diagnostics',
        \        't': 'type definition', 'n': 'next diag', 'N': 'prev diag',
        \        'v': 'diag text inline', 'S': 'show all servers' },
        \ 'd': { 'name': '+dirvish',   'd': 'dirvish（当前文件所在目录）',
        \        'o': 'dirvish（当前工作目录）' },
        \ 'e': { 'name': '+terminal',  'c': 'run command', 'e': 'new terminal',
        \        't': 'toggle（收起/呼出）', 'k': 'close terminal', 'K': 'close ALL terminals' },
        \ 'n': { 'name': '+narrow',    'r': 'narrow 选区 / 当前段落' },
        \ 'h': { 'name': '+help',      'k': 'leader 绑定', 'b': '全部绑定',
        \        'f': 'commands', 'v': 'variables', 'm': 'mode info',
        \        'o': 'open vimrc', 'r': 'reload vimrc', 't': 'help' },
        \ 'j': { 'name': '+jump',      'j': 'jump to char', 'w': 'jump to word',
        \        'l': 'jump to line', 'J': 'jumplist' },
        \ 'm': { 'name': '+motion',    'w': 'word', 'e': 'word end',
        \        'f': 'char', 'F': 'char back', 't': 'till', 'T': 'till back',
        \        's': '2 chars', 'j': 'lines down', 'k': 'lines up',
        \        'n': 'next match', 'N': 'prev match' },
        \ 'x': { 'name': '+region',    'x': 'expand region', 'X': 'shrink region' },
        \ 'r': { 'name': '+reload',    'e': 'reload config', 'o': 'open config',
        \        'l': 'reload file' },
        \ 'q': { 'name': '+quit',      'q': 'quit', 'Q': 'quit!', 'a': 'quit all', 'A': 'quit all!' },
        \ 'c': 'comment',
        \ 'u': 'undo-tree',
        \ 'U': 'redo (later)',
        \ 'A': 'select-all',
        \ ' ': 'M-x' }

" ---- 6) lexima（对应 electric-pair-mode）----
" 收窄到 Emacs 的 electric-pair-pairs：( ) [ ] { } " " ' '
"   · basic 规则里去掉反引号、markdown 三引号 / 三单引号；
"   · 不要 space 规则（Emacs 不会往 {} 里塞空格）；
"   · 不要 endwise 规则（Emacs 不会自动补 end）；
"   · 保留 newline 规则 —— 在 {} () [] 里按 <CR> 展开成三行，
"     这正是 Emacs electric-pair-mode + electric-indent-mode 的行为。
"
" ⚠ 三个坑（都踩过，见 ~/.vim/EMACS-VIM.md）：
"   1) 必须用 g:loaded_lexima 判断 —— exists('*lexima#init') 对「尚未 autoload 的
"      autoload 函数」返回 0，那样整段会被静默跳过，配对功能就完全没了。
"   2) 这里是脚本层（不在函数里），不能用 l: 作用域变量 ——
"      `for l:rule in ...` 会抛 E461: Illegal variable name，循环体一行都不执行。
"   3) 别用 string(rule) 去匹配 —— 字典里 'char': '''' 的字符串表示是 ''''，
"      本身就含三个连续单引号，会把「单引号配对」这条基础规则一起误删。
"      所以下面逐个字段取值再判断。
function! s:lexima_keep(rule) abort
  for l:field in ['char', 'at', 'input', 'input_after']
    let l:val = get(a:rule, l:field, '')
    if type(l:val) != v:t_string
      continue
    endif
    " 反引号；markdown 三引号 / 三单引号 —— Emacs 的 electric-pair-pairs 里都没有
    if l:val =~# '`' || l:val =~# '"""' || l:val =~# "'''"
      return 0
    endif
  endfor
  return 1
endfunction

" ---- 7) easymotion（对应 avy）----
" 键位照 Emacs 的 SPC j 前缀，另开 SPC m（+motion）把其它跳法都放出来。
" 装了 easymotion 时 <leader>j j/w/l 会覆盖 conf/60-keymaps.vim 里的内置兜底。
"
" ⚠ 为什么不用 nmap 直接绑 <Plug>：实测经 <leader> 前缀（会先进 which-key 的
"   输入循环）执行时，需要后续输入的目标不可靠 —— 按键会被 which-key 的
"   getchar() 截走，最后跑出 fzf 命令面板 / :map 列表这种莫名其妙的状态。
"   所以这里把 <Plug> 的定义转成 :<C-u>call ...<CR> 命令形式，和 <leader>u
"   走同一条路径；顺带也不必把 easymotion 的内部函数签名写死在配置里。
function! s:em_cmd(name) abort
  let l:rhs = maparg('<Plug>(easymotion-' . a:name . ')', 'n')
  if l:rhs ==# ''
    return ''
  endif
  let l:cmd = substitute(l:rhs, '^\s*:\s*\%(<C-[Uu]>\s*\)\?', '', '')
  return substitute(l:cmd, '<CR>\s*$', '', '')
endfunction

" ---- 8) dirvish（对应 Emacs 的 dirvish）----
" 只补 Emacs 那边 dirvish-mode-map 里常用的几个键：
"   Emacs: q = dirvish-quit       -> q
"   Emacs: h = dired-up-directory -> -（插件自带，见 ~/.vim/plugins.vim）
"   Emacs: l / 回车 = 打开        -> 回车（插件自带）
"   Emacs: g d = 跳到任意路径     -> g d
  function! s:dirvish_maps() abort
    nnoremap <silent> <buffer> q <Plug>(dirvish_quit)
    nnoremap <silent> <buffer> gd :<C-u>Dirvish <C-r>=fnameescape(input('目录: ', '', 'dir'))<CR><CR>
    " <C-^>：在原文件和目录之间来回切（dirvish 保留了 alternate buffer）
    nnoremap <silent> <buffer> <C-^> <C-^>
  endfunction

  augroup ec_dirvish
    autocmd!
    autocmd FileType dirvish call s:dirvish_maps()
  augroup END

" ---- 8.5) 浮窗终端里「顺手关掉」的键 ----
" 浮窗 buffer 的 filetype 是 floaterm、buftype 是 terminal。
" 在里面输入是发给 shell 的（Terminal-Job 模式），所以这里只在
" 「终端-普通模式」（按 <C-\><C-n> 之后）加一个 q —— 和 dirvish 的 q 一个约定，
" 不会影响往 shell 里打字。
if exists('g:loaded_floaterm') || !empty(globpath(&runtimepath, 'plugin/floaterm.vim'))
  augroup ec_floaterm
    autocmd!
    autocmd FileType floaterm call s:floaterm_maps()
  augroup END

  function! s:floaterm_maps() abort
    " 终端-普通模式里按 q：关掉这个浮窗，**连同终端进程**（和 dirvish 的 q 一个约定）
    nnoremap <silent> <buffer> q :<C-u>FloatermKill<CR>
    "
    " 终端-普通模式里按 <Esc>：收起浮窗，**保留终端进程**。
    " 配合下面的 tnoremap 就是「连按两次 <Esc> 收起终端」：
    "   第 1 次 <Esc>：Terminal-Job -> 终端-普通模式（tnoremap 那条）
    "   第 2 次 <Esc>：收起浮窗（这条）；下次 SPC e t 还是同一个 shell
    " 为什么收起不会丢进程：floaterm 的 hide 只是 popup_close()，而 conf/10-basic.vim
    " 里有 set hidden，终端 buffer 不会被卸载、job 继续跑（实测收起/呼出多次，fish 的
    " PID 一直不变）。想连进程一起结束：终端-普通模式按 q，或 SPC e k / SPC e K。
    nnoremap <silent> <buffer> <Esc> :<C-u>FloatermHide<CR>
    "
    " 终端-输入模式（Terminal-Job）里按 <Esc>：回到终端-普通模式。
    " 为什么要这个映射：在 Terminal-Job 模式下**所有按键都直接发给 shell**，
    " 连 leader（<Space>）也只会打出一个空格 —— 所以「在终端里没法用 leader 键」。
    " Vim 自带的逃逸是 <C-\><C-n> 四个键，太别扭；绑成 <Esc> 之后：
    "   <Esc>          -> 回到普通模式，leader 全部可用（SPC e k 关浮窗等）
    "   <Esc> <Esc>    -> 收起浮窗（进程保留，再 SPC e t 还是这个 shell）
    "   i / a / A      -> 继续往 shell 里打字
    "   q              -> 关掉浮窗（进程一起结束）
    " 如果浮窗里跑的是自己要用 <Esc> 的 TUI 程序（嵌套 vim / hx / lazygit …），
    " 在 ~/.vim/plugins.vim 里设 let g:ec_floaterm_esc = 0 关掉这条映射，
    " 那样就仍用 Vim 自带的 <C-\><C-n> 离开终端模式。
    if get(g:, 'ec_floaterm_esc', 1)
      tnoremap <silent> <buffer> <Esc> <C-\><C-n>
    endif
  endfunction
endif

" ------------------------------------------------------------- 顶层之后运行 --
" 下面这些必须等插件加载完才能做（读 <Plug> 映射、调用插件函数），
" 所以收起一个函数由 VimEnter 触发 —— VimEnter 在所有插件加载之后触发。
function! EcPluginIntegrate() abort
" ---- 0) 夺回被插件抢走的键位（vim-commentary 会抢 gc 等）----
call EcReassertMappings()
" ---- 1) 注释：gcc / gc{motion} / 可视 gc 就是 vim-commentary 的原生映射 ----
" <leader>c 只是同一个操作的 leader 别名（which-key 里能看到，可选）。
" 取消搜索高亮原来占用 gc，现在交给 Vim 自带的 nohlsearch 包（conf/30-search.vim）。
if !empty(maparg('<Plug>CommentaryLine', 'n'))
  nmap <silent> <leader>c <Plug>CommentaryLine
endif
if !empty(maparg('<Plug>Commentary', 'x'))
  xmap <silent> <leader>c <Plug>Commentary
endif

" ---- 2) 撤销树（对应 Emacs 的 vundo / SPC u）----
if exists(':UndotreeToggle')
  nnoremap <silent> <leader>u :UndotreeToggle<CR>
endif

" ---- 3) expand-region（对应 Emacs 的 expand-region / SPC x x）----
" 不需要后续输入，所以绑 <Plug> 是安全的（<leader>x x 的兜底在 EcRegionEx）。
if !empty(maparg('<Plug>(expand_region_expand)', 'x'))
  nmap <silent> <leader>xx viw<Plug>(expand_region_expand)
  xmap <silent> <leader>xx <Plug>(expand_region_expand)
  xmap <silent> <leader>xX <Plug>(expand_region_shrink)
endif
" ---- 5) which-key（对应 Emacs 的 which-key）----
" ⚠ 两个必须注意的点（都踩过，见 ~/.vim/EMACS-VIM.md 第 4 节）：
"   1) 描述「前缀键」（f / b / w / s …）必须用 { 'name': '+xxx' }，写成字符串会走到
"      which-key 内部 s:merge 的 native[k][0]，抛
"      E716: Key not present in Dictionary: "0" 并把菜单搞坏。叶子键才用字符串。
"   2) g:which_key_timeout 要设 0，否则按 <Space> 后要等
"      Vim 的 timeoutlen(400ms) + which-key 默认的 1000ms。
" 这里的每一项都必须在 conf/60-keymaps.vim 或本文件里有对应的真实映射
"（~/vim-recon/wk_audit.py 会双向核对，防止菜单与实际键位脱节）。
if exists(":WhichKey")

  call which_key#register('<Space>', 'g:which_key_map')
  nnoremap <silent> <leader> :<C-u>WhichKey '<Space>'<CR>
  vnoremap <silent> <leader> :<C-u>WhichKeyVisual '<Space>'<CR>
endif
if exists('g:loaded_lexima')
  call lexima#init()          " 触发 autoload，拿到 g:lexima#default_rules
  call lexima#clear_rules()
  let s:lexima_n = 0
  for s:rule in g:lexima#default_rules + g:lexima#newline_rules
    if !s:lexima_keep(s:rule)
      continue
    endif
    call lexima#add_rule(s:rule)
    let s:lexima_n += 1
  endfor
  let g:ec_lexima_rules = s:lexima_n      " 供自检（~/vim-recon/lint.sh）读取
  unlet! s:rule
endif
if !empty(maparg('<Plug>(easymotion-bd-w)', 'n'))
  " [leader 键, easymotion 动作名]
  " ⚠ 续行的 List 字面量里不能写行尾 " 注释（会抛 E696: Missing comma in List）。
  "   SPC j j = avy-goto-char-timer   SPC j w = avy-goto-word-1
  "   SPC j l = avy-goto-line         SPC m * = easymotion 的其它跳法
  let s:em = [
        \ ['jj', 'bd-f'],
        \ ['jw', 'bd-w'],
        \ ['jl', 'bd-jk'],
        \ ['mw', 'bd-w'],
        \ ['me', 'bd-e'],
        \ ['mf', 'bd-f'],
        \ ['mF', 'F'],
        \ ['mt', 'bd-t'],
        \ ['mT', 'T'],
        \ ['ms', 's'],
        \ ['mj', 'j'],
        \ ['mk', 'k'],
        \ ['mn', 'next'],
        \ ['mN', 'prev'],
        \ ]
  for [s:k, s:name] in s:em
    let s:c = s:em_cmd(s:name)
    if s:c !=# ''
      execute 'nnoremap <silent> <leader>' . s:k . ' :<C-u>' . s:c . '<CR>'
    endif
  endfor
  unlet! s:k s:name s:em
endif
" ---- 9) NrrwRgn（对应 narrow-to-region）----
" 用 :call 命令形式绑定（原因同 easymotion）：
"   SPC n r（可视模式）= 把选区摘到独立 buffer 里编辑
"   SPC n r（普通模式）= 把当前段落摘出去
" 窄窗里 :WidenRegion 同步回原 buffer 并关闭，直接 :w 也行。
if !empty(maparg('<Plug>NrrwrgnDo', 'n'))
  xnoremap <silent> <leader>nr :<C-u>call nrrwrgn#NrrwRgn(visualmode(), '')<CR>
  nnoremap <silent> <leader>nr :<C-u>normal! vip<CR>:<C-u>call nrrwrgn#NrrwRgn(visualmode(), '')<CR>
endif
endfunction

augroup ec_plugin_integrate
  autocmd!
  autocmd VimEnter * call EcPluginIntegrate()
augroup END
