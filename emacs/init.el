;;; init.el --- Windows Emacs with Evil + Straight.el -*- lexical-binding: t; -*-

;;; Commentary:
;; 基于 straight.el 的 Windows Emacs + Evil 配置（优化版）
;; 安装：将此文件保存为 ~/.emacs.d/init.el
;;
;; 相对原 init.el 的主要优化点：
;; 1. 初始化阶段临时禁用 file-name-handler-alist 并提高 GC 阈值，加快启动
;; 2. 禁用 package.el，完全交给 straight.el 管理，避免双重初始化
;; 3. eglot 改为延迟加载（原先 require 'eglot 每次启动都加载），并修复了
;;    已被标记废弃的 eglot-events-buffer-size（改用 eglot-events-buffer-config）
;; 4. 修复 dirvish 中无效变量 dirvish-preview-disabled-p
;;    （该变量不存在，预览实际从未被关闭；改用 dirvish-preview-dispatchers nil）
;; 5. orderless / which-key / vertico 改为加载后启用，避免"未知 completion style"等隐患
;; 6. 清理 eldoc 重复配置（原先同一变量被设置两次且互相冲突）
;; 7. 各包配置改用 :custom 与 setq 批量合并，更简洁、加载更高效
;; 8. 行号对 dired / eshell / special-mode 关闭，避免无意义渲染
;; 9. Windows 下增大 read-process-output-max，提升 eshell/shell 输出性能
;; 10. 空闲 GC 优化：平时阈值 100MB（打字几乎不触发 GC），空闲时手动回收
;; 11. 大文件优化：so-long / 大文件自动降级 / vlf 分块查看 / 关闭双向重排
;; 12. 鼠标选中自动复制（延迟 0.5s 设置剪贴板，WSLg 桥接可靠）
;; 13. 历史记录持久化（savehist + recentf）
;;
;; 注：本文件按主题分组组织，各功能块之间无加载顺序依赖
;;     （straight 引导除外，必须最先执行）。

;;; Code:

;; ============================================
;; 1. 启动优化与 GC
;; ============================================

;; 配置目录（默认值即 ~/.emacs.d/，显式声明便于后续自定义）
(setq user-emacs-directory (expand-file-name "~/.emacs.d/"))

;; 完全禁用所有文件生成，历史记录与自定义变量放到配置目录
(setq make-backup-files nil
      auto-save-default nil
      auto-save-list-file-prefix nil
      create-lockfiles nil
      recentf-save-file (expand-file-name "recentf" user-emacs-directory)
      custom-file (expand-file-name "custom.el" user-emacs-directory))

;; 启动加速：
;; 1) 初始化阶段临时禁用 file-name-handler（可显著加快 load/require）
;; 2) 初始化期间完全不触发 GC，启动完成后恢复正常阈值并回收一次
;;    （旧版存在三套互相覆盖的 GC 配置，现已统一为单一方案）
(defvar my--init-file-name-handler-alist file-name-handler-alist)
(defvar my/gc-cons-threshold (* 64 1024 1024))
(setq file-name-handler-alist nil
      gc-cons-threshold most-positive-fixnum)
(add-hook 'emacs-startup-hook
          (lambda ()
            (setq gc-cons-threshold my/gc-cons-threshold)
            (setq file-name-handler-alist my--init-file-name-handler-alist)
            (garbage-collect)))

;; 运行时 GC：日常阈值 64MB（打字几乎不触发 GC，也不至于无限增长），
;; 失焦或空闲 10s 时手动回收一次
(add-hook 'focus-out-hook #'garbage-collect)
(run-with-idle-timer 10 t #'garbage-collect)

;; ============================================
;; 2. Bootstrap straight.el
;; ============================================

;; 禁用 package.el，完全交给 straight.el 管理，避免重复初始化
(setq package-enable-at-startup nil)

(defvar bootstrap-version)
(let ((bootstrap-file
       (expand-file-name
        "straight/repos/straight.el/bootstrap.el"
        (or (bound-and-true-p straight-base-dir)
            user-emacs-directory)))
      (bootstrap-version 6))
  (unless (file-exists-p bootstrap-file)
    (with-current-buffer
        (url-retrieve-synchronously
         "https://raw.githubusercontent.com/radian-software/straight.el/develop/install.el"
         'silent 'inhibit-cookies)
      (goto-char (point-max))
      (eval-print-last-sexp)))
  (load bootstrap-file nil 'nomessage))

;; use-package 集成
(straight-use-package 'use-package)
(setq straight-use-package-by-default t)
(setq use-package-always-defer t)

;; ============================================
;; 3. 基础环境（编码 / 剪贴板 / 历史 / Shell）
;; ============================================

;; 编码
(set-language-environment "UTF-8")
(prefer-coding-system 'utf-8-unix)
(set-default-coding-systems 'utf-8-unix)

;; 剪贴板共享 + 鼠标选中自动复制
(setq select-enable-clipboard t
      ;; 中键粘贴到光标处（终端习惯）
      mouse-yank-at-point t
      ;; 主选择（primary selection，middle-click 粘贴）
      select-enable-primary t
      ;; 关掉内建鼠标复制逻辑，改由下面的 hook 统一处理（evil 下更可靠）
      mouse-drag-copy-region nil)

;; 鼠标选区完成后自动复制（evil 与原生路径都覆盖）
(defun my/mouse-copy-after-drag ()
  "鼠标选区完成后自动复制到 kill ring 与系统剪贴板。"
  (when (and (region-active-p)
             (or (bound-and-true-p evil--region-from-mouse)
                 (memq this-command '(mouse-set-region
                                      mouse-drag-region
                                      mouse-drag-secondary))))
    (let* ((text (buffer-substring-no-properties (region-beginning) (region-end)))
           ;; 只进 kill ring；剪贴板交给下面延迟设置（已验证该方式可被 WSLg 桥接）
           (interprogram-cut-function nil))
      (copy-region-as-kill (region-beginning) (region-end))
      ;; 延迟 0.5s 设置系统剪贴板：避开鼠标命令上下文，WSLg 桥接才可靠
      (run-at-time 0.5 nil
                   (lambda ()
                     (ignore-errors (gui-set-selection 'CLIPBOARD text)))))
    (when (boundp 'evil--region-from-mouse)
      (setq evil--region-from-mouse nil))))
(add-hook 'post-command-hook #'my/mouse-copy-after-drag)

;; 历史记录持久化：重启后保留 M-x/搜索输入历史与 kill-ring
(savehist-mode 1)
(setq savehist-additional-variables '(kill-ring))
;; 最近文件列表（启用后 SPC fr / consult-recent-file 才能用）
(recentf-mode 1)
(setq recentf-max-saved-items 100)

;; 退出确认：按 y/n 单键即可（默认需输入完整 yes/no）
(setq confirm-kill-emacs 'y-or-n-p)

;; Windows Shell
(when (eq system-type 'windows-nt)
  (setq explicit-shell-file-name "powershell.exe")
  (setq shell-file-name "powershell.exe"))

;; ============================================
;; 4. 界面与外观
;; ============================================

;; 禁止启动画面
(setq inhibit-startup-screen t
      initial-scratch-message nil)
(tool-bar-mode -1)
(menu-bar-mode -1)
(scroll-bar-mode -1)
;; 窗口默认全屏
(add-to-list 'initial-frame-alist '(fullscreen . maximized))

;; 主题
(use-package doom-themes
  :straight t
  :demand t
  :custom
  (doom-themes-enable-bold t)
  (doom-themes-enable-italic t)
  :config
  (load-theme 'doom-tomorrow-night t)
  (doom-themes-visual-bell-config))

;; 图标字体（nerd-icons，供 modeline/dirvish 使用）
(use-package nerd-icons
  :straight t
  :demand t)

;; 模式行
(use-package doom-modeline
  :straight t
  :demand t
  :custom
  (doom-modeline-height 25)
  (doom-modeline-icon t)
  :config
  (doom-modeline-mode 1))

;; 行号与括号
(global-display-line-numbers-mode t)
;; (setq display-line-numbers-type 'relative)
(global-hl-line-mode 1)
(show-paren-mode 1)
(setq show-paren-delay 0)
(electric-pair-mode 1)
(setq electric-pair-pairs
      '((?\( . ?\))
        (?\[ . ?\])
        (?\{ . ?\})
        (?\" . ?\")))

;; 这些模式下不需要行号，避免无意义渲染
(dolist (hook '(dired-mode-hook
                eshell-mode-hook
                special-mode-hook))
  (add-hook hook (lambda () (display-line-numbers-mode 0))))

;; 字体配置（Windows）
(when (eq system-type 'windows-nt)
  ;; 主字体
  (set-face-attribute 'default nil
                      :font "Maple Mono NF CN"
                      :height 108)
  ;; 关键：让 nerd-icons 知道用哪个字体家族
  (setq nerd-icons-font-family "Maple Mono NF CN")
  ;; 图标字体补充
  (set-fontset-font t 'unicode "Segoe UI Symbol" nil 'prepend)
  (set-fontset-font t 'unicode "Symbola" nil 'append))

;; 字体配置（Linux / WSL）
(unless (eq system-type 'windows-nt)
  (set-face-attribute 'default nil
                      :font "Maple Mono NF CN"
                      :height 108)
  (setq nerd-icons-font-family "Maple Mono NF CN")
  ;; WSLg 标题栏随 200% 缩放偏大：隐藏窗口装饰（无标题栏）
  (dolist (f (frame-list))
    (modify-frame-parameters f '((undecorated . t))))
  (add-hook 'after-make-frame-functions
            (lambda (frame)
              (modify-frame-parameters frame '((undecorated . t))))))

;; ============================================
;; 5. 性能优化（大文件 / 滚动 / GC 相关运行时行为）
;; ============================================

;; Windows 平台优化
(when (eq system-type 'windows-nt)
  (setq w32-get-true-file-attributes nil)
  (setq w32-pipe-read-delay 0)
  (setq w32-pipe-buffer-size (* 64 1024))
  ;; 提升进程输出缓冲，eshell/shell 更流畅
  (setq read-process-output-max (* 1024 1024)))

;; 长行关闭双向文本重排（超长行提速最明显）
(setq-default bidi-display-reordering nil)

;; 平滑滚动（Emacs 29+）
(when (>= emacs-major-version 29)
  (pixel-scroll-precision-mode 1))
;; 平滑滚动：快而不精（Emacs 27+）
(setq fast-but-imprecise-scrolling t)
(setq scroll-conservatively 101)

;; 超长行自动降级显示（minified JS/JSON/长日志等），Emacs 27+ 内置
(global-so-long-mode 1)
(setq so-long-threshold 500)               ; 行长超过 500 字符即触发
(setq so-long-max-lines 100000)            ; 行数超过此值不触发(保护大文本)

;; 10MB 才弹"文件过大"警告（默认 10MB 太小）
(setq large-file-warning-threshold (* 100 1024 1024))

;; 大文件打开时自动关闭高开销功能
(defun my/optimize-for-large-file ()
  (let ((size (buffer-size)))
    ;; >8MB：关闭语法高亮/行号/高亮行/版本控制/双向重排，精简模式行
    (when (> size (* 8 1024 1024))
      (font-lock-mode -1)
      (setq-local display-line-numbers nil)
      (setq-local global-hl-line-mode nil)
      (setq-local vc-handled-backends nil)
      (setq-local bidi-display-reordering nil)
      (setq-local mode-line-format (list " %b [big]")))
    ;; >64MB：再关闭撤销（省内存）
    (when (> size (* 64 1024 1024))
      (buffer-disable-undo))))
(add-hook 'find-file-hook #'my/optimize-for-large-file)

;; 后台高亮节奏（大文件不那么卡）
(setq jit-lock-stealth-nice 0.5
      jit-lock-stealth-time 3
      jit-lock-chunk-size 500)
;; 超大 buffer 不自动语法高亮
(setq font-lock-maximum-size 1048576)

;; 超大文件分块查看（几百 MB 级文件不必整载入）
(use-package vlf
  :straight t
  :defer t
  :config
  ;; 加载即自动注册 advice（新版 vlf 无 vlf-setup 函数）
  (require 'vlf-setup)
  ;; 超过 vlf-batch-size 且超过 large-file-warning-threshold 才询问
  (setq vlf-application 'ask
        vlf-batch-size (* 10 1024 1024)))

;; ============================================
;; 6. 补全与搜索（minibuffer / 补全弹窗）
;; ============================================

;; 模糊搜索切换
(use-package vertico
  :straight t
  :demand t
  :config
  (vertico-mode)
  (vertico-mouse-mode))

(use-package orderless
  :straight t
  :demand t
  :custom
  (completion-styles '(orderless basic)))

(use-package consult
  :straight t
  :demand t
  :bind (("M-p" . consult-yank-pop)))

;; xref（定义/引用等）结果改用 minibuffer 展示：选中即跳转，
;; 不再另开 *xref* 窗口且残留（SPC ld/lr/lD 与 M-? 均生效）
(setq xref-show-xrefs-function #'consult-xref)
(setq xref-show-definitions-function #'consult-xref)

;; consult-buffer（SPC bl）主列表：隐藏所有 *…* buffer，仅保留 *scratch*。
;; 说明：Emacs 正则不支持负向断言，故不用 consult-buffer-filter 正则来做
;; "除了 scratch" 的排除，改用自定义列表函数过滤；
;; consult-buffer-filter 仍保留，供 consult-buffer 内按 SPC 窄化的
;; "Hidden Buffer" 组列出 *Messages* 等后台 buffer。
(defun my/consult-user-buffers ()
  "返回用于 consult-buffer 的 buffer 列表：去掉 *…* buffer，仅留 *scratch*。"
  (seq-filter
   (lambda (buf)
     (let ((n (buffer-name buf)))
       (or (not (string-prefix-p "*" n))
           (string= n "*scratch*"))))
   (buffer-list)))
(setq consult-buffer-list-function #'my/consult-user-buffers)

(setq consult-buffer-filter
      (append consult-buffer-filter
              '("\\`\\*\\(?:Messages\\|Warnings\\|Compile-Log\\|Backtrace\\|Async-native-compile-log\\).*\\*\\'")))

;; Corfu 核心（弹窗补全）
(use-package corfu
  :straight t
  :demand t
  :custom
  (corfu-auto t)
  (corfu-auto-delay 0.2)
  (corfu-auto-prefix 2)        ;; 输入 2 个字符后弹出
  (corfu-count 10)             ;; 最多显示 10 个候选
  (corfu-cycle t)              ;; 循环选择
  (corfu-preselect 'prompt)    ;; 默认选中 prompt，不自动选第一个
  (corfu-min-width 20)
  (corfu-max-width 80)
  (corfu-left-margin-width 1)
  (corfu-right-margin-width 1)
  (corfu-scroll-margin 2)
  :config
  (global-corfu-mode))

;; Corfu 图标扩展（显示类型图标）
(use-package kind-icon
  :straight t
  :after corfu
  :custom
  (kind-icon-default-face 'corfu-default)
  :config
  (add-to-list 'corfu-margin-formatters #'kind-icon-margin-formatter))

;; Marginalia：给 minibuffer 候选加说明注释（M-x 的 docstring、
;; buffer 的文件路径、describe-* 的定义位置等），提升可发现性
(use-package marginalia
  :straight t
  :demand t
  :config
  (marginalia-mode))

;; Embark：对"当前候选 / region / 光标处目标"弹出上下文动作菜单
(use-package embark
  :straight t
  :defer t
  :bind (("C-." . embark-act)        ;; M-. 保留给 xref，C-; 已占用于 rime
         ("C-h B" . embark-bindings)))
;; embark-consult：把 consult 的"结果导出 / live-preview"等接入 embark
(use-package embark-consult
  :straight t
  :after (embark consult)
  :demand t
  :config
  ;; collect 模式里跟随预览
  (add-hook 'embark-collect-mode-hook #'consult-preview-at-point-mode))
;; SPC a：对目标做动作（leader 绑定统一放在 section 7 general 之后注册）

;; Cape：补全源兜底（文件路径 / 邻近词），保证非 LSP buffer 也有补全
(use-package cape
  :straight t
  :after corfu
  :demand t
  :config
  (defun my/cape-append-fallbacks ()
    "把 cape 兜底源追加到当前 buffer 的 CAPF 末尾（不覆盖已有来源）。"
    (dolist (fn (list #'cape-file #'cape-dabbrev))
      (unless (memq fn completion-at-point-functions)
        (setq-local completion-at-point-functions
                    (append completion-at-point-functions (list fn))))))
  (add-hook 'prog-mode-hook #'my/cape-append-fallbacks)
  (add-hook 'text-mode-hook #'my/cape-append-fallbacks)
  ;; eglot 连接时会整体替换 buffer 的 CAPF，需在其后重新追加兜底源
  (add-hook 'eglot-managed-mode-hook #'my/cape-append-fallbacks))

;; ============================================
;; 7. Evil 编辑与通用键位
;; ============================================

(use-package evil
  :demand t
  :init
  (setq evil-want-integration t
        evil-want-keybinding nil
        evil-want-C-u-scroll t
        evil-want-C-i-jump nil
        evil-undo-system 'undo-redo
        evil-search-module 'evil-search)
  :config
  (evil-mode 1)

  ;; 全局 g c：取消搜索高亮（任何普通文件 buffer 都可用）
  (define-key evil-normal-state-map (kbd "g c") 'evil-ex-nohighlight)

  ;; g o / g i：跳转列表后退/前进。
  ;; 不用 C-i（终端里 C-i 与 TAB 同键，避免与 TAB 类操作冲突）
  (define-key evil-normal-state-map (kbd "g o") 'evil-jump-backward)
  (define-key evil-normal-state-map (kbd "g i") 'evil-jump-forward)

  ;; 插入模式保留 Emacs 键位
  (define-key evil-insert-state-map (kbd "C-a") 'beginning-of-line)
  (define-key evil-insert-state-map (kbd "C-e") 'end-of-line)
  (define-key evil-insert-state-map (kbd "C-n") 'next-line)
  (define-key evil-insert-state-map (kbd "C-p") 'previous-line)
  (define-key evil-insert-state-map (kbd "C-k") 'kill-line)

  ;; 初始状态设置
  (evil-set-initial-state 'help-mode 'normal)
  (evil-set-initial-state 'Info-mode 'normal)
  (evil-set-initial-state 'eshell-mode 'insert)
  (evil-set-initial-state 'shell-mode 'insert))

(use-package evil-collection
  :straight t
  :after evil
  :demand t
  :config
  (evil-collection-init))

;; general：SPC leader 键位框架
(use-package general
  :straight t
  :after evil
  :demand t
  :config
  ;; 定义 SPC 为 leader（仅在 normal/visual 模式）
  (general-create-definer my-leader-def
    :prefix "SPC"
    :states '(normal visual))

  ;; ========== 常用绑定 ==========
  (my-leader-def
    ;; 文件操作
    "f"  '(:ignore t :which-key "file")
    "ff" '(find-file :which-key "find file")
    "fr" '(consult-recent-file :which-key "recent files")
    "fs" '(save-buffer :which-key "save")

    ;; Buffer 操作
    "b"  '(:ignore t :which-key "buffer")
    "bl" '(consult-buffer :which-key "switch buffer")
    "bd" '(kill-current-buffer :which-key "kill buffer")
    "bb" '(next-buffer :which-key "next")
    "bn" '(next-buffer :which-key "next")
    "bp" '(previous-buffer :which-key "previous")

    ;; 窗口操作
    "w"  '(:ignore t :which-key "window")
    "wh" '(evil-window-left :which-key "left")
    "wj" '(evil-window-down :which-key "down")
    "wk" '(evil-window-up :which-key "up")
    "wl" '(evil-window-right :which-key "right")
    "wd" '(evil-window-delete :which-key "delete")
    "w/" '(evil-window-vsplit :which-key "vsplit")
    "w-" '(evil-window-split :which-key "split")

    ;; 搜索
    "s"  '(:ignore t :which-key "search")
    "ss" '(consult-line :which-key "search line")
    "sf" '(consult-focus-lines :which-key "focus line")
    "sr" '(consult-ripgrep :which-key "ripgrep project search")

    ;; 复制粘贴
    "y"  '(:ignore t :which-key "yank")
    "yp" '(consult-yank-pop :which-key "yank-pop")
    "yr" '(consult-yank-replace :which-key "yank-replace")

    ;; 其他
    "SPC" '(execute-extended-command :which-key "M-x")   ;; SPC SPC 打开 M-x
    "qq"  '(save-buffers-kill-terminal :which-key "quit")
    "re"  '(eval-buffer :which-key "eval buffer")

    ;; Help
    "h"  '(:ignore t :which-key "help")
    "hf" '(describe-function :which-key "describe function")
    "hv" '(describe-variable :which-key "describe variable")
    "hk" '(describe-key :which-key "describe key")
    "hm" '(describe-mode :which-key "describe mode")
    "hb" '(describe-bindings :which-key "describe bindings")))

;; 让 which-key 显示 leader 提示
(use-package which-key
  :straight t
  :demand t
  :custom
  (which-key-idle-delay 0.5)
  :config
  (which-key-mode))

;; 多光标编辑（evim，仿 vim-visual-multi）
(use-package evim
  :after evil
  :demand t
  :config
  (evim-setup-global-keys))

;; ========== Evil 文本增强 ==========
;; vundo：可视化 undo 树（配合 evil-undo-system 的 undo-redo）
(use-package vundo
  :straight t
  :defer t)
;; avy：快速光标跳转
(use-package avy
  :straight t
  :defer t)
;; expand-region：语义化扩展选中区域
(use-package expand-region
  :straight t
  :defer t)

;; 新 leader 前缀统一在此注册（general 已在此前加载，宏已可用）：
;;   SPC a 动作(embark) / SPC u undo树 / SPC j 跳转 / SPC x 文本
(with-eval-after-load 'general
  (my-leader-def
    ;; actions（embark，定义于 section 6）
    "a"  '(:ignore t :which-key "actions")
    "aa" '(embark-act :which-key "act on target")
    "ad" '(embark-dwim :which-key "act dwim")

    ;; undo 树
    "u"  '(vundo :which-key "undo tree")

    ;; 跳转
    "j"  '(:ignore t :which-key "jump")
    "jj" '(avy-goto-char-timer :which-key "jump to char")
    "jl" '(avy-goto-line :which-key "jump to line")
    "jw" '(avy-goto-word-1 :which-key "jump to word")

    ;; 文本操作
    "x"  '(:ignore t :which-key "text")
    "xx" '(er/expand-region :which-key "expand region")))

;; ============================================
;; 8. 文件管理（Dirvish）
;; ============================================
(use-package dirvish
  :straight t
  :demand t
  :config
  ;; 接管所有 dired 调用
  (dirvish-override-dired-mode)

  ;; ========== 外观设置 ==========
  ;; 显示属性（顺序很重要）：图标、折叠状态、git状态、文件大小、修改时间
  (setq dirvish-attributes
        '(nerd-icons collapse subtree-state vc-state git-msg file-size file-time))

  ;; 侧边栏模式属性（更精简）
  ;; (setq dirvish-side-attributes
  ;;       '(nerd-icons collapse file-size))

  ;; 默认布局：左侧文件列表 + 右侧预览
  ;; (setq dirvish-default-layout '(0.3 0.7 0))

  ;; 模式行格式
  (setq dirvish-mode-line-format
        '(:left (sort symlink) :right (omit yank index)))

  ;; ========== 预览设置 ==========
  ;; 完全禁用预览（性能优先）。注：原配置的 dirvish-preview-disabled-p
  ;; 变量不存在，从未生效；此处用正确的 dirvish-preview-dispatchers 实现
  (setq dirvish-preview-dispatchers nil)

  ;; 子树展开样式（GUI 下用 nerd 图标）。
  ;; 注意：必须走 setter —— 直接 setq 不会更新内部预计算的
  ;; `dirvish-subtree--state-icons'，样式会停留在默认值。
  (customize-set-variable 'dirvish-subtree-state-style 'nerd)

  ;; ========== 快速访问目录 ==========
  (setq dirvish-quick-access-entries
        '(("h" "~/"                          "Home")
          ("d" "~/Downloads/"                "Downloads")
          ("c" "~/Documents/Code/"           "Code")
          ("e" "~/.emacs.d/"                 "Emacs")
          ("t" "~/.local/share/Trash/files/" "TrashCan")))

  ;; ========== 性能优化 ==========
  ;; 大目录阈值（超过此文件数用异步方式打开）
  (setq dirvish-large-directory-threshold 20000)
  ;; 重用 session（避免重复创建窗口）
  (setq dirvish-reuse-session t)

  ;; ========== 其他优化 ==========
  ;; 删除时移动到回收站
  (setq delete-by-moving-to-trash t)
  ;; 智能目标（复制/移动时自动选择另一个 dired 窗口作为目标）
  (setq dired-dwim-target t)
  ;; 列表显示参数
  (setq dired-listing-switches
        "-l --almost-all --human-readable --group-directories-first --no-group")

  ;; ========== Evil 键绑定 ==========
  (evil-define-key 'normal dirvish-mode-map
    ;; 基础导航
    (kbd "h") 'dired-up-directory        ;; 返回上级目录
    (kbd "l") 'dired-find-file           ;; 进入目录/打开文件
    (kbd "j") 'dired-next-line
    (kbd "k") 'dired-previous-line
    (kbd "q") 'dirvish-quit              ;; 退出
    ;; g d 快速跳到任意路径（提示输入）
    (kbd "g d") (lambda () (interactive)
                  (dirvish (read-directory-name "Dirvish: ")))

    ;; 子树展开/折叠（类似 treemacs 的展开体验）
    (kbd "TAB") 'dirvish-subtree-toggle

    ;; 标记操作
    (kbd "m") 'dired-mark
    (kbd "u") 'dired-unmark
    (kbd "U") 'dired-unmark-all-marks
    (kbd "t") 'dired-toggle-marks
    (kbd "x") 'dired-do-flagged-delete
    (kbd "D") 'dired-do-delete

    ;; 文件操作
    (kbd "c") 'dired-do-copy
    (kbd "r") 'dired-do-rename
    (kbd "+d") 'dired-create-directory
    (kbd "+f") 'dired-create-empty-file
    (kbd "%") 'dired-do-rename-regexp

    ;; 刷新
    (kbd "R") 'revert-buffer

    ;; 快速访问
    (kbd "O") 'dirvish-quick-access

    ;; 预览相关
    (kbd "M-l") 'dirvish-layout-toggle   ;; 切换布局
    (kbd "M-s") 'dirvish-setup-menu)     ;; 设置菜单

  ;; ========== 鼠标支持（Emacs 29+） ==========
  (when (>= emacs-major-version 29)
    (setq dired-mouse-drag-files t)
    (setq mouse-drag-and-drop-region-cross-program t)
    (setq mouse-1-click-follows-link nil)
    (define-key dirvish-mode-map (kbd "<mouse-1>") 'dirvish-subtree-toggle-or-open)
    (define-key dirvish-mode-map (kbd "<mouse-2>") 'dired-mouse-find-file-other-window)
    (define-key dirvish-mode-map (kbd "<mouse-3>") 'dired-mouse-find-file)))

;; Dirvish 快速访问（SPC d 前缀）
(with-eval-after-load 'general
  (with-eval-after-load 'dirvish
    (my-leader-def
      "d"  '(:ignore t :which-key "dirvish")
      "do" '(dirvish-quick-access :which-key "quick-access")
      "dd" '(dirvish :which-key "dirvish"))))

;; dirvish/dired 里启用 SPC leader：
;; evil-collection 默认把 SPC 绑为 dired-next-line，且优先级高于 general
;; 注册在 evil-normal-state-map 的 SPC 前缀，导致 leader 在 dired 里失效。
;; 这里把 dired-mode-map 的 normal auxiliary 键位里的 SPC 指回 leader 前缀键位图。
(with-eval-after-load 'evil-collection-dired
  (let ((leader (lookup-key evil-normal-state-map (kbd "SPC"))))
    (when (keymapp leader)
      (define-key (evil-get-auxiliary-keymap dired-mode-map 'normal)
                  (kbd "SPC") leader))))

;; ========== Git（magit + diff-hl） ==========
;; magit：全功能 Git 界面（evil 键位由 evil-collection 自动接管；
;; dirvish 已显示的文件 vc 状态与它联动）。
(use-package magit
  :straight t
  :defer t
  :bind (("C-x g" . magit-status)))
;; SPC g 前缀：git 常用操作
(with-eval-after-load 'general
  (my-leader-def
    "g"  '(:ignore t :which-key "git")
    "gs" '(magit-status :which-key "status")
    "gl" '(magit-log-all :which-key "log")
    "gd" '(magit-diff :which-key "diff")
    "gc" '(magit-commit-create :which-key "commit")
    "gb" '(magit-blame :which-key "blame")
    "gP" '(magit-push :which-key "push")
    "gF" '(magit-pull :which-key "pull")))

;; diff-hl：文件改动行标记（fringe 红/绿），可在上下改动点间跳转
(use-package diff-hl
  :straight t
  :demand t
  :config
  (global-diff-hl-mode))

;; ============================================
;; 9. LSP 与代码编辑
;; ============================================

;; Eglot 延迟加载：不再在启动时 require，首次打开支持的代码文件时才加载。
;; eglot-ensure 本身未提供 autoload，这里手动注册，保证 hook 可正常工作。
(autoload 'eglot-ensure "eglot" nil t)
(use-package eglot
  :straight t
  :defer t
  :custom
  (eglot-events-buffer-config '(:size 0))
  (eglot-sync-connect 1)
  (eglot-autoshutdown t)
  (eglot-send-changes-idle-time 0.5))

;; Rust 语言支持
(use-package rust-mode
  :straight t
  :mode "\\.rs\\'"
  :hook (rust-mode . eglot-ensure)
  :custom
  ;; 保存时格式化交给 apheleia（见下），避免与 eglot/rust-analyzer 双重重叠
  (rust-format-on-save nil)
  (indent-tabs-mode nil))

;; C/C++ 语言支持（内置 cc-mode）
(add-hook 'c-mode-hook #'eglot-ensure)
(add-hook 'c++-mode-hook #'eglot-ensure)

;; 可选：consult-eglot（与 vertico 集成，搜索工作区符号）
(use-package consult-eglot
  :straight t
  :after (consult eglot))

;; eglot Leader 键绑定（SPC l 前缀）
;; 绑定注册不依赖 eglot 是否已加载（命令均带 autoload，按下时才触发加载），
;; 避免首次启动未打开代码文件前 SPC l 完全无响应。
(with-eval-after-load 'general
  (my-leader-def
    "l"  '(:ignore t :which-key "lsp")
    "la" '(eglot-code-actions :which-key "code action")
    "lR" '(eglot-rename :which-key "rename")
    "lf" '(eglot-format-buffer :which-key "format")
    "ld" '(xref-find-definitions :which-key "definition")
    "lD" '(xref-find-declaration :which-key "declaration")
    "li" '(eglot-find-implementation :which-key "implementation")
    "lr" '(xref-find-references :which-key "references")
    "lh" '(eldoc-doc-buffer :which-key "hover/doc")
    "lo" '(eglot-code-action-organize-imports :which-key "organize imports")
    "ls" '(consult-eglot-symbols :which-key "workspace symbols")
    "le" '(consult-flymake :which-key "diagnostics"))
  (with-eval-after-load 'eglot
    (setq eglot-ignored-server-capabilities '(:inlayHintProvider))))

;; ========== 文档/诊断显示 ==========
;; echo area 最多显示 3 行（nil=单行, t=不限制）
(setq eldoc-echo-area-use-multiline-p 3
      ;; 不显示烦人的"被截断"提示
      eldoc-echo-area-display-truncation-message nil
      ;; 触发延迟，越小越灵敏
      eldoc-idle-delay 0.3)
;; Emacs 29+ 默认已启用 global-eldoc-mode
(when (< emacs-major-version 29)
  (global-eldoc-mode 1))

;; ★ 关键：在 eglot 接管 buffer 后设置显示策略
;; 让 flymake 诊断和文档信息"抢着显示"，优先看到错误；并确保 flymake 启动
(add-hook 'eglot-managed-mode-hook
          (lambda ()
            (setq-local eldoc-documentation-strategy
                        #'eldoc-documentation-compose-eagerly)
            (flymake-mode)))
;; 保存时自动检查
(setq flymake-start-on-save-buffer t
      flymake-no-changes-timeout 0.5)

;; ========== Tree-sitter 原生模式 ==========
;; C/C++ 改用内建 ts 模式（语法高亮 / 缩进优于 cc-mode），并自动 eglot。
;; 仅当对应语法库已安装时才启用，避免缺 libtree-sitter-*.so 时打开文件报错；
;; 语法库缺失时保持原 cc-mode 路径（下方旧 hook 仍生效）。
(when (treesit-available-p)
  (when (treesit-language-available-p 'c)
    (add-to-list 'major-mode-remap-alist '(c-mode . c-ts-mode))
    (add-hook 'c-ts-mode-hook #'eglot-ensure))
  (when (treesit-language-available-p 'cpp)
    (add-to-list 'major-mode-remap-alist '(c++-mode . c++-ts-mode))
    (add-hook 'c++-ts-mode-hook #'eglot-ensure)))

;; ========== apheleia：保存时异步格式化 ==========
;; 用外部格式化工具（rustfmt / clang-format / prettier 等）统一处理，
;; 替代各语言各自的 format-on-save 开关。缺二进制时自动跳过、不阻塞保存。
(use-package apheleia
  :straight t
  :demand t
  :config
  (apheleia-global-mode 1))

;; ============================================
;; 10. 美化 Org（保守美化，不隐藏标记，避免显示问题）
;; ============================================

(use-package org
  :straight t
  :hook (org-mode . visual-line-mode)
  :config
  ;; 不隐藏标记符号（避免显示问题）
  (setq org-hide-emphasis-markers nil)
  ;; 但隐藏标题星号
  (setq org-hide-leading-stars t)
  ;; 代码块高亮
  (setq org-src-fontify-natively t)
  ;; 标题字体
  (custom-set-faces
   '(org-level-1 ((t (:height 1.3 :weight bold :foreground "#51afef"))))
   '(org-level-2 ((t (:height 1.2 :weight bold :foreground "#c678dd"))))
   '(org-level-3 ((t (:height 1.1 :weight semi-bold :foreground "#98be65"))))
   ;; 强调样式
   '(bold ((t (:weight bold :foreground "#dfdfdf"))))
   '(italic ((t (:slant italic :foreground "#c8c8c8"))))
   '(underline ((t (:underline t :foreground "#a9a1e1"))))
   '(org-verbatim ((t (:foreground "#a9a1e1" :background "#21242b"))))
   '(org-code ((t (:foreground "#a9a1e1" :background "#21242b"))))
   ;; 代码块
   '(org-block ((t (:background "#21242b" :extend t))))
   '(org-link ((t (:foreground "#51afef" :underline t))))
   '(org-todo ((t (:foreground "#ff6c6b" :weight bold))))
   '(org-done ((t (:foreground "#98be65" :weight bold))))))

(use-package org-superstar
  :straight t
  :hook (org-mode . org-superstar-mode)
  :custom
  (org-superstar-headline-bullets-list '("●" "○" "◆" "◇"))
  (org-superstar-leading-bullet ?\s))

(require 'org-tempo)

;; ============================================
;; 11. 美化 Markdown
;; ============================================
(use-package markdown-mode
  :straight t
  :mode (("\\.md\\'" . gfm-mode)
         ("\\.markdown\\'" . markdown-mode)
         ("\\.mdown\\'" . markdown-mode)
         ("\\.mkd\\'" . markdown-mode))
  :hook ((markdown-mode . visual-line-mode)
         (gfm-mode . visual-line-mode))
  :config
  ;; 标题按级别缩放字号
  (setq markdown-header-scaling t)
  ;; 代码块原生语法高亮（不是纯灰色）
  (setq markdown-fontify-code-blocks-natively t)
  ;; 整个标题行着色（而非只有井号）
  (setq markdown-fontify-whole-heading-line t)
  ;; 隐藏标记符号（# * _ 等），显示更干净
  (setq markdown-hide-markup t)
  ;; 数学公式支持（$...$ / $$...$$）
  (setq markdown-enable-math t)
  ;; GFM 复选框渲染为按钮，可切换
  (setq markdown-make-gfm-checkboxes-buttons t)
  ;; 标题/强调/代码等自定义配色（对齐 doom-tomorrow-night）
  (custom-set-faces
   '(markdown-header-face-1 ((t (:weight bold :foreground "#51afef" :height 1.6))))
   '(markdown-header-face-2 ((t (:weight bold :foreground "#c678dd" :height 1.4))))
   '(markdown-header-face-3 ((t (:weight bold :foreground "#98be65" :height 1.2))))
   '(markdown-header-face-4 ((t (:weight bold :foreground "#d19a66" :height 1.05))))
   '(markdown-header-face-5 ((t (:weight bold :foreground "#56b6c2"))))
   '(markdown-header-face-6 ((t (:weight bold :foreground "#e5c07b"))))
   '(markdown-markup-face ((t (:foreground "#5c6370"))))
   '(markdown-link-face ((t (:foreground "#51afef" :underline t))))
   '(markdown-url-face ((t (:foreground "#56b6c2" :underline t))))
   '(markdown-code-face ((t (:background "#21242b" :foreground "#abb2bf"))))
   '(markdown-inline-code-face ((t (:background "#21242b" :foreground "#e5c07b"))))
   '(markdown-bold-face ((t (:weight bold :foreground "#dfdfdf"))))
   '(markdown-italic-face ((t (:slant italic :foreground "#c8c8c8"))))
   '(markdown-list-face ((t (:foreground "#98be65"))))
   '(markdown-blockquote-face ((t (:foreground "#5c6370" :slant italic))))
   '(markdown-gfm-checkbox-face ((t (:foreground "#56b6c2" :weight bold))))))

;; ============================================
;; 12. 终端（vterm）
;; ============================================
;; vterm 基于 C 库 libvterm，比纯 elisp 终端（term/eat）更快、兼容性更好，
;; 可跑 nvim/htop/tmux/ssh 等全屏程序（Emacs 需带动态模块支持，本机已具备）。
;; 说明：
;; - evil 键位由已加载的 evil-collection 自动接管（含 vterm）。
;; - 首次使用会自动编译 vterm 模块（需 cmake/gcc/libvterm，本机已装）；
;;   想重编可 M-x vterm-module-compile。
;; - 可选 shell 侧配置（目录同步/prompt 跟踪/buffer 标题重命名）：
;;   在 ~/.bashrc 里 source "$EMACS_VTERM_PATH/etc/emacs-vterm-bash.sh"
(use-package vterm
  :straight t
  :defer t
  :custom
  (vterm-kill-buffer-on-exit t)   ; 进程退出后自动删除 buffer
  (vterm-max-scrollback 100000)   ; 滚动回看行数上限
  :config
  ;; evil normal 态退出时不把光标后移（终端场景更自然）
  (add-hook 'vterm-mode-hook
            (lambda () (setq-local evil-move-cursor-back nil))))

;; ============================================
;; 13. Eshell
;; ============================================

;; 自定义提示符：用户@主机 目录 λ
(defun my/eshell-prompt ()
  (concat
   (propertize (format "%s@%s" (user-login-name) (system-name))
               'face '(:foreground "#98be65"))
   " "
   (propertize (abbreviate-file-name (eshell/pwd))
               'face '(:foreground "#51afef"))
   (propertize " λ " 'face '(:foreground "#ff6c6b"))))

;; eshell 是内置包，:straight nil 表示不通过 straight 安装
(use-package eshell
  :straight nil
  :defer t
  :custom
  ;; 隐藏启动 banner
  (eshell-banner-message "")
  ;; 历史记录：容量更大、忽略重复命令
  (eshell-history-size 10000)
  (eshell-hist-ignoredups t)
  ;; 输入命令时自动滚到底部
  (eshell-scroll-to-bottom-on-input t)
  (eshell-scroll-show-maximum-output t)
  ;; TUI 程序请在 vterm（SPC et）里运行；eshell 保持纯行式 shell，
  ;; 禁用内置 term 内嵌（避免误开体验较差的 term 终端）
  (eshell-visual-commands nil)
  (eshell-visual-subcommands nil)
  :config
  ;; 自定义提示符。eshell-prompt-regexp 必须能从行首完整匹配提示符
  ;; （直到 "λ " 之后的那个空格为止），否则 eshell-skip-prompt、
  ;; 历史搜索与 C-c C-p 等提示符跳转会失效。
  (setq eshell-prompt-function 'my/eshell-prompt)
  (setq eshell-prompt-regexp
        (concat "^" (regexp-quote (format "%s@%s " (user-login-name) (system-name)))
                "\\(?:.*λ \\)?"))
  ;; 清屏（shell 习惯）
  (define-key eshell-mode-map (kbd "C-l") #'eshell/clear-scrollback)
  (define-key eshell-mode-map (kbd "C-c C-l") #'eshell/clear-scrollback))

;; Eshell / 终端 快速访问（SPC e 前缀）
(with-eval-after-load 'general
  (my-leader-def
    "e"  '(:ignore t :which-key "eshell/term")
    "ee" '(eshell :which-key "eshell")
    "et" '(vterm :which-key "terminal (vterm)")
    "ec" '(eshell-command :which-key "run command")))

;; ============================================
;; 13. 输入法 emacs-rime（RIME 中文输入）
;; ============================================
;; emacs-rime 需要 librime 引擎 + gcc 才能工作（首次按 C-\ 会自动编译动态模块）。
;; Windows 推荐安装方式：
;;   1) 安装 scoop：https://scoop.sh
;;   2) scoop install gcc
;;   3) scoop bucket add wsw0108 https://github.com/wsw0108/scoop-bucket.git
;;   4) scoop install librime
;; 安装后重启 Emacs 即可使用。若 librime 装在其它位置，修改 rime-librime-root。
;; 使用：C-\ 开关输入法；M-j 中/英切换；C-M-j 强制中文（代码区域）；
;;       C-; 首项上屏并切换；ESC 上屏并返回 normal 态；
;;       C-` 打开 RIME 方案菜单（需在 default.custom.yaml 中配置）。

;; 动态模块编译所需的 emacs-module.h（Emacs 自带）
(let ((header-dir (expand-file-name "../include" invocation-directory)))
  (when (file-exists-p (expand-file-name "emacs-module.h" header-dir))
    (setq rime-emacs-module-header-root header-dir)))

;; Windows 下定位 librime：优先用 LIBRIME_ROOT 环境变量，否则用 scoop 默认路径
(when (eq system-type 'windows-nt)
  (setq rime-librime-root
        (or (and (getenv "LIBRIME_ROOT")
                 (directory-file-name (getenv "LIBRIME_ROOT")))
            (expand-file-name "~/scoop/apps/librime/current")))
  (setq rime-share-data-dir
        (expand-file-name "share/rime-data" rime-librime-root)))

;; 注意：若加载 librime-emacs 模块时报错 "找不到指定的程序"（ERROR_PROC_NOT_FOUND），
;; 是因为 Emacs 自带的旧版 MinGW 运行库（libstdc++-6.dll / libgcc_s_seh-1.dll /
;; libwinpthread-1.dll）先于 librime 的新版被载入进程。解决办法：用 librime 的
;; 新版运行库覆盖 Emacs bin 目录下的同名旧版（新版向后兼容，不影响 Emacs）。
;;   以管理员身份运行 PowerShell 执行：
;;     $src = "$env:USERPROFILE\scoop\apps\librime\current\bin"
;;     $dst = "C:\Program Files\Emacs\emacs-30.2\bin"
;;     New-Item -ItemType Directory "$dst\runtime-backup" -Force | Out-Null
;;     foreach ($d in 'libstdc++-6.dll','libgcc_s_seh-1.dll','libwinpthread-1.dll') {
;;       Copy-Item "$dst\$d" "$dst\runtime-backup\$d" -Force
;;       Copy-Item "$src\$d" "$dst\$d" -Force
;;     }

(use-package rime
  :straight (rime :type git
                  :host github
                  :repo "DogLooksGood/emacs-rime"
                  :files ("*.el" "Makefile" "lib.c"))
  :demand t
  :init
  ;; C-\（默认键）切换 RIME 输入法
  (setq default-input-method "rime")
  :custom
  ;; 候选显示在 minibuffer（官方推荐，与 corfu/vertico 无弹窗冲突）
  (rime-show-candidate 'minibuffer)
  ;; 拼音内联显示（不占用候选框）
  (rime-show-preedit 'inline)
  ;; 软光标字符
  (rime-cursor "˰")
  ;; 中英切换采用标准 Shift 语义（rime-inline-ascii 会模拟按下并松开该键）
  (rime-inline-ascii-trigger 'shift-l)
  ;; 中/英切换由 M-j（rime-inline-ascii）手动控制，保证行为可预测。
  ;; 只保留 evil 非编辑态自动英文（normal/visual 时不误输中文）。
  ;; 若希望"代码区域/英文字符后自动英文"，可把下面两行加回去：
  ;;   rime-predicate-after-alphabet-char-p
  ;;   rime-predicate-prog-in-code-p
  (rime-disable-predicates
   '(rime-predicate-evil-mode-p))
  :config
  (defun my/rime-commit1-and-toggle ()
    "首项自动上屏后切换输入法。"
    (interactive)
    (ignore-errors (rime-commit1))
    (toggle-input-method))
  (defun my/rime-commit1-and-evil-normal ()
    "首项自动上屏后回到 evil normal 态。"
    (interactive)
    (ignore-errors (rime-commit1))
    (evil-normal-state))
  ;; 编码时 ESC：首项上屏并返回 normal 态（evil 友好）
  (define-key rime-active-mode-map (kbd "<escape>") #'my/rime-commit1-and-evil-normal)
  ;; M-j 中/英切换（rime-inline-ascii 即模拟 Shift 切换 ascii 模式）
  (define-key rime-mode-map (kbd "M-j") #'rime-inline-ascii)
  (define-key rime-active-mode-map (kbd "M-j") #'rime-inline-ascii)
  ;; C-M-j 强制中文（无视禁用规则，仅本次输入有效；在代码区域想输中文时用）
  (define-key rime-mode-map (kbd "C-M-j") #'rime-force-enable)
  ;; C-` 打开 RIME 方案菜单
  (define-key rime-mode-map (kbd "C-`") #'rime-send-keybinding)
  ;; C-; 首项上屏并切换输入法
  (global-set-key (kbd "C-;") #'my/rime-commit1-and-toggle))

;; 状态栏显示当前是中/英文：重定义 doom-modeline 的 input-method 段。
;; rime 开启时显示“中”（中文，ascii_mode 关）或“英”（英文，ascii_mode 开）；
;; rime 关闭时什么都不显示；其它输入法仍显示其标题。
(with-eval-after-load 'doom-modeline-segments
  (doom-modeline-def-segment input-method
    "当前输入法：rime 显示中/英，其它输入法显示其标题。"
    (when current-input-method
      (let* ((sep (doom-modeline-spc))
             (label (if (and (bound-and-true-p rime-mode)
                             (equal current-input-method "rime")
                             (fboundp 'rime-lib-get-option))
                        (if (rime-lib-get-option "ascii_mode")
                            (propertize "EN" 'face 'doom-modeline-input-method-alt)
                          (propertize "CN" 'face 'doom-modeline-input-method))
                      (propertize current-input-method-title
                                  'face (doom-modeline-face 'doom-modeline-input-method)))))
        (concat sep label sep)))))

;; ============================================
;; 终端（tty）下的图标兜底
;; ============================================
;; 终端 Emacs 不渲染 face 字体，图标依赖终端模拟器配置的 Nerd Font；
;; 若终端未用 Nerd Font，图标会显示成方块/空白，这里关闭图标类显示。
;; 注：以启动时是否图形帧判断，适用于分别启动的 GUI / 终端会话；
;;     若用 daemon + 终端帧混合，建议改为在终端侧设置 Nerd Font（方案 A）。
(unless (display-graphic-p)
  (setq doom-modeline-icon nil)
  (when (boundp 'dirvish-attributes)
    (setq dirvish-attributes (delq 'nerd-icons dirvish-attributes)))
  (when (boundp 'dirvish-side-attributes)
    (setq dirvish-side-attributes (delq 'nerd-icons dirvish-side-attributes)))
  ;; subtree 展开指示器也改为纯 ASCII "+/-"（终端字体无相关字形时也可用）
  (when (boundp 'dirvish-subtree-state-style)
    (customize-set-variable 'dirvish-subtree-state-style 'plus)))

;; ============================================
;; 结束
;; ============================================

;; 载入 Customize 保存的设置（custom.el 存在时），
;; 否则 customize 界面保存的值永远不会生效
(load custom-file 'noerror 'nomessage)

;; 显示启动时间
(message "Emacs initialized in %s" (emacs-init-time))

(provide 'init)
;;; init.el ends here
