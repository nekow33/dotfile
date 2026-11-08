# ========== 补全 ==========
if [ -f /usr/share/bash-completion/bash_completion ]; then
    . /usr/share/bash-completion/bash_completion
fi

# ========== 历史记录 ==========
export HISTSIZE=10000
export HISTFILESIZE=20000
export HISTCONTROL=ignoreboth:erasedups
shopt -s histappend
shopt -s checkwinsize

# ========== 别名 ==========

# 文件与导航
alias ll='eza -lah --icons --git'
alias la='eza -A --icons'
alias ls='eza --icons'
alias cat='bat --paging=never'
alias ..='cd ..'
alias ...='cd ../..'

# 安全习惯（可选，不喜欢可删）
alias cp='cp -i'
alias mv='mv -i'
alias rm='rm -i'

# Git 常用
alias gs='git status'
alias ga='git add'
alias gc='git commit'
alias gp='git push'
alias gl='git log --oneline -10'

# ========== 现代工具初始化 ==========
# Starship 提示符
eval "$(starship init bash)"

# zoxide 智能 cd
eval "$(zoxide init bash)"

# fzf 快捷键（Ctrl+R 搜历史，Ctrl+T 搜文件）
if command -v fzf &>/dev/null; then
    eval "$(fzf --bash)"
fi

# ========== 环境变量 ==========
export EDITOR=vim
export LANG=en_US.UTF-8
. "$HOME/.cargo/env"
