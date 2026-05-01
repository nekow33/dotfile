;;; init.el --- Windows Emacs with Evil + Straight.el -*- lexical-binding: t; -*-

;;; Commentary:
;; 基于 straight.el 的 Windows Emacs + Evil 配置
;; 安装：将此文件保存为 ~/.emacs.d/init.el

;;; Code:

;; ============================================
;; 1. 启动优化
;; ============================================

;; 设置配置目录
(setq user-emacs-directory (expand-file-name "~/.emacs.d/"))

;; 完全禁用所有文件生成（不创建任何额外文件）
(setq make-backup-files nil)
(setq auto-save-default nil)
(setq auto-save-list-file-prefix nil)
(setq create-lockfiles nil)

;; 历史记录和自定义变量也强制放到用户目录
(setq recentf-save-file (expand-file-name "recentf" user-emacs-directory))
(setq custom-file (expand-file-name "custom.el" user-emacs-directory))

;; 降低垃圾回收阈值提升启动速度
(setq gc-cons-threshold (* 50 1000 1000))
(add-hook 'emacs-startup-hook
          (lambda () (setq gc-cons-threshold (* 2 1000 1000))))

;; 禁止启动画面
(setq inhibit-startup-screen t)
(setq initial-scratch-message nil)
(tool-bar-mode -1)
(menu-bar-mode -1)
(scroll-bar-mode -1)

;; 窗口默认全屏
(add-to-list 'initial-frame-alist '(fullscreen . maximized))

;; Windows 编码
(set-language-environment "UTF-8")
(set-default-coding-systems 'utf-8-unix)
(prefer-coding-system 'utf-8-unix)

;; Windows Shell
(when (eq system-type 'windows-nt)
  (setq explicit-shell-file-name "powershell.exe")
  (setq shell-file-name "powershell.exe"))


;; ============================================
;; 2. Bootstrap straight.el
;; ============================================
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

;; 使用 use-package 集成
(straight-use-package 'use-package)
(setq straight-use-package-by-default t)
(setq use-package-always-defer t)


;; ============================================
;; 3. 外观
;; ============================================
(use-package doom-themes
  :straight t
  :demand t
  :config
  (setq doom-themes-enable-bold t
        doom-themes-enable-italic t)
  (load-theme 'doom-one t)
  (doom-themes-visual-bell-config))

(use-package nerd-icons
  :straight t
  :demand t)

(use-package doom-modeline
  :straight t
  :demand t
  :init (doom-modeline-mode 1)
  :config
  (setq doom-modeline-height 25)
  (setq doom-modeline-icon t))
  
 ;; 行号与外观
(global-display-line-numbers-mode t)
(setq display-line-numbers-type 'relative)
(global-hl-line-mode 1)
(show-paren-mode 1)
(setq show-paren-delay 0)
(electric-pair-mode 1)
(setq electric-pair-pairs
      '((?\( . ?\))
        (?\[ . ?\])
        (?\{ . ?\})
        (?\" . ?\"))) 

;; 字体配置
(when (eq system-type 'windows-nt)
  ;; 1. 主字体
  (set-face-attribute 'default nil
                      :font "Maple Mono NF CN"
                      :height 140)
  
  ;; 2. 关键：让 nerd-icons 知道用哪个字体家族
  (setq nerd-icons-font-family "Maple Mono NF CN")
  
  (set-fontset-font t '(#xe000 . #xfdff)
                  (font-spec :family "Maple Mono NF CN")
                  nil 'prepend))


;; ============================================
;; 4. Buffer管理
;; ============================================
;; 1. 模糊搜索切换
(use-package vertico :straight t :init (vertico-mode))
(use-package orderless :straight t :init (setq completion-styles '(orderless basic)))

(use-package consult
  :straight t
  :demand t
  :config
  ;; 强制确保 consult 主文件已加载
  (require 'consult)
  
  ;; 安全设置：先检查变量是否存在
  (if (boundp 'consult--source-hidden-buffer)
      (setq consult-buffer-sources
            '(consult--source-hidden-buffer
              consult--source-buffer
              consult--source-recent-file
              consult--source-bookmark))
    ;; 如果变量不存在（版本太旧），回退到不过滤所有 buffer
    (setq consult-buffer-filter nil)))


;; ============================================
;; 5. Evil配置
;; ============================================
(use-package evil
  :demand t
  :init
  (setq evil-want-integration t)
  (setq evil-want-keybinding nil)
  (setq evil-want-C-u-scroll t)
  (setq evil-want-C-i-jump nil)
  (setq evil-undo-system 'undo-redo)
  (setq evil-search-module 'evil-search)
  :config
  (evil-mode 1)
  
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

(use-package general
  :straight t
  :demand t
  :after evil
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
    "bb" '(consult-buffer :which-key "switch buffer")
    "bd" '(kill-current-buffer :which-key "kill buffer")
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
   
    ;; 其他
    "SPC" '(execute-extended-command :which-key "M-x")   ;; SPC SPC 打开 M-x
    "qq"  '(save-buffers-kill-terminal :which-key "quit")
    "re"  '(eval-buffer :which-key "eval buffer")))

;; 确保 which-key 能显示 leader 提示（如果你装了 which-key）
(use-package which-key
  :straight t
  :init (which-key-mode)
  :config
  (setq which-key-idle-delay 0.5))

(use-package dirvish
  :straight t
  :demand t
  :init
  ;; 接管所有 dired 调用
  (dirvish-override-dired-mode)
  :config
  ;; ========== 外观设置 ==========
  ;; 显示属性（顺序很重要）：图标、折叠状态、git状态、文件大小、修改时间
  (setq dirvish-attributes
        '(nerd-icons collapse subtree-state vc-state git-msg file-size file-time))
  
  ;; 侧边栏模式属性（更精简）
  (setq dirvish-side-attributes
        '(nerd-icons collapse file-size))
  
  ;; 默认布局：左侧文件列表 + 右侧预览
  ;; 格式：(header-height file-list-width preview-width)
  (setq dirvish-default-layout '(0 0.3 0.7))
  
  ;; 模式行格式
  (setq dirvish-mode-line-format
        '(:left (sort symlink) :right (omit yank index)))
  
  ;; ========== 预览设置 ==========
  ;; 支持的预览类型
  (setq dirvish-preview-dispatchers
        '(image gif video audio epub pdf archive))
  
  ;; 子树展开样式（使用 nerd-icons）
  (setq dirvish-subtree-state-style 'nerd)
  
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
    
    ;; 子树展开/折叠（类似 treemacs 的展开体验）
    (kbd "TAB") 'dirvish-subtree-toggle
    (kbd "zo") 'dirvish-subtree-toggle
    (kbd "zc") 'dirvish-subtree-toggle
    
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
    (kbd "M-s") 'dirvish-setup-menu      ;; 设置菜单
    (kbd "M-p") 'dirvish-preview-toggle) ;; 开关预览

  ;; ========== 鼠标支持（Emacs 29+） ==========
  (when (>= emacs-major-version 29)
    (setq dired-mouse-drag-files t)
    (setq mouse-drag-and-drop-region-cross-program t)
    (setq mouse-1-click-follows-link nil)
    (define-key dirvish-mode-map (kbd "<mouse-1>") 'dirvish-subtree-toggle-or-open)
    (define-key dirvish-mode-map (kbd "<mouse-2>") 'dired-mouse-find-file-other-window)
    (define-key dirvish-mode-map (kbd "<mouse-3>") 'dired-mouse-find-file)))         ;; 智能模式（单窗口全屏，多窗口不抢占）

(with-eval-after-load 'general
  (with-eval-after-load 'dirvish
    (my-leader-def
      "d"  '(:ignore t :which-key "dirvish")
      "do" '(dirvish-quick-access :which-key "quick-access")
      "dd" '(dirvish :which-key "dirvish"))))
;; ============================================
;; 6. LSP配置
;; ============================================
;; 1. 确保 eglot 可用（Emacs 29+ 内置，无需 straight 安装）
(require 'eglot)

;; 性能优化：关闭不必要的文件监听（Windows 上尤其重要）
(setq eglot-events-buffer-size 0)
(setq eglot-sync-connect 1)
(setq eglot-autoshutdown t)
(setq eglot-send-changes-idle-time 0.5)

;; 2. Rust 语言支持
(use-package rust-mode
  :straight t
  :mode "\\.rs\\'"
  :hook (rust-mode . eglot-ensure)
  :config
  (setq rust-format-on-save t)
  (setq indent-tabs-mode nil))

;; 3. C/C++ 语言支持（内置 cc-mode）
(add-hook 'c-mode-hook #'eglot-ensure)
(add-hook 'c++-mode-hook #'eglot-ensure)

;; 4. 可选：consult-eglot（与 vertico 集成，搜索工作区符号）
(use-package consult-eglot
  :straight t
  :after (consult eglot)
  :bind (:map eglot-mode-map
              ("C-c l s" . consult-eglot-symbols)))

;; 1. Corfu 核心（弹窗补全）
(use-package corfu
  :straight t
  :demand t
  :init
  (global-corfu-mode)
  :config
  ;; 自动弹出（不需要按 TAB）
  (setq corfu-auto t)
  (setq corfu-auto-delay 0.2)
  (setq corfu-auto-prefix 2)        ;; 输入 2 个字符后弹出
  (setq corfu-count 10)             ;; 最多显示 10 个候选
  (setq corfu-cycle t)              ;; 循环选择
  (setq corfu-preselect 'prompt)    ;; 默认选中 prompt，不自动选第一个
  
  ;; 样式
  (setq corfu-min-width 20)
  (setq corfu-max-width 80)
  (setq corfu-left-margin-width 1)
  (setq corfu-right-margin-width 1)
  
  ;; 滚动条
  (setq corfu-scroll-margin 2))

;; 2. Corfu 图标扩展（显示类型图标）
(use-package kind-icon
  :straight t
  :after corfu
  :config
  (setq kind-icon-default-face 'corfu-default)
  (add-to-list 'corfu-margin-formatters #'kind-icon-margin-formatter))

;; ============================================
;; eglot Leader 键绑定（SPC l 前缀）
;; ============================================
(with-eval-after-load 'general
  (with-eval-after-load 'eglot
    (my-leader-def
      "l"  '(:ignore t :which-key "lsp")
      "la" '(eglot-code-actions :which-key "code action")
      "lr" '(eglot-rename :which-key "rename")
      "lf" '(eglot-format-buffer :which-key "format")
      "ld" '(xref-find-definitions :which-key "definition")
      "lD" '(xref-find-declaration :which-key "declaration")
      "li" '(eglot-find-implementation :which-key "implementation")
      "lR" '(xref-find-references :which-key "references")
      "lh" '(eldoc-doc-buffer :which-key "hover/doc")
      "lo" '(eglot-code-action-organize-imports :which-key "organize imports")
      "ls" '(consult-eglot-symbols :which-key "workspace symbols")
      "le" '(flymake-show-buffer-diagnostics :which-key "diagnostics"))))

;; 5. 可选：关闭 eldoc 的自动显示（避免 minibuffer 频繁跳动）
(setq eldoc-idle-delay 0.5)
(setq eldoc-echo-area-use-multiline-p nil)


;; ============================================
;; 7. 美化org
;; ============================================
;; ============================================
;; Org 保守美化（不隐藏标记，避免显示问题）
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
   
   ;; 强调样式（确保生效）
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
  :config
  (setq org-superstar-headline-bullets-list '("●" "○" "◆" "◇"))
  (setq org-superstar-leading-bullet ?\s))

(require 'org-tempo)

;; ============================================
;; 8. 杂项配置
;; ============================================

;; 平滑滚动
(pixel-scroll-precision-mode 1)

;; 剪贴板共享
(setq select-enable-clipboard t)

;; Windows 优化
(when (eq system-type 'windows-nt)
  (setq w32-get-true-file-attributes nil)
  (setq w32-pipe-read-delay 0)
  (setq w32-pipe-buffer-size (* 64 1024)))

;; 启动时间
(message "Emacs initialized in %s" (emacs-init-time))

(provide 'init)
