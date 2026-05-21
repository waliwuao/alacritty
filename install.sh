#!/bin/bash
set -e

# Alacritty 一键安装脚本 (Debian/Ubuntu)
# 功能：安装依赖 → 编译 Alacritty → 配置 → 设为默认终端

PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"
ALACRITTY_BIN="$PROJECT_DIR/target/release/alacritty"
CONFIG_SRC="$PROJECT_DIR/config/alacritty.toml"
CONFIG_DST="$HOME/.config/alacritty/alacritty.toml"
ZSH_CONFIG="$HOME/.zshrc"
ZSH_WAS_NEW=false

echo "==> 1. 检查并安装 zsh"
if ! command -v zsh &>/dev/null; then
    echo "zsh 未安装，正在安装..."
    sudo apt update
    sudo apt install -y zsh
    ZSH_WAS_NEW=true
    echo "zsh 安装完成"
else
    echo "zsh 已安装: $(zsh --version)"
fi

echo "==> 2. 检查并安装 Rust/Cargo"
if ! command -v cargo &>/dev/null; then
    echo "Rust 未安装，正在安装..."
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
    source "$HOME/.cargo/env"
    echo "Rust 安装完成"
else
    echo "Cargo 已安装: $(cargo --version)"
fi

echo "==> 3. 配置 Cargo 清华源"
mkdir -p "$HOME/.cargo"
cat > "$HOME/.cargo/config.toml" << 'EOF'
[source.crates-io]
replace-with = 'tuna'

[source.tuna]
registry = "sparse+https://mirrors.tuna.tsinghua.edu.cn/crates.io-index/"
EOF
echo "Cargo 镜像已设置为清华源"

echo "==> 4. 配置 zsh"
if [ "$ZSH_WAS_NEW" = true ]; then
    cat > "$ZSH_CONFIG" << 'ZSHEOF'
# zsh 基础配置

# 历史记录
HISTSIZE=50000
SAVEHIST=50000
HISTFILE=~/.zsh_history
setopt EXTENDED_HISTORY
setopt INC_APPEND_HISTORY
setopt SHARE_HISTORY
setopt HIST_IGNORE_DUPS
setopt HIST_IGNORE_ALL_DUPS
setopt HIST_FIND_NO_DUPS
setopt HIST_SAVE_NO_DUPS

# 补全
autoload -Uz compinit
compinit
zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Z}'

# 基础别名
alias ll='ls -alFh'
alias la='ls -Ah'
alias l='ls -CFh'
alias ..='cd ..'
alias ...='cd ../..'
alias grep='grep --color=auto'

# OSC 133 shell integration（Alacritty 命令导航器）
preexec() { print -Pn "\e]133;C;\e\\" }
precmd()  { print -Pn "\e]133;A;\e\\" }

# 提示符
autoload -Uz promptinit
promptinit
prompt adam1

# PATH
export PATH="$HOME/.local/bin:$HOME/.cargo/bin:$PATH"
ZSHEOF
    echo "zshrc 已创建: $ZSH_CONFIG"
else
    # 追加 OSC 133 shell integration
    if ! grep -q "OSC 133" "$ZSH_CONFIG" 2>/dev/null; then
        cat >> "$ZSH_CONFIG" << 'ZSHEOF'

# OSC 133 shell integration（Alacritty 命令导航器）
preexec() { print -Pn "\e]133;C;\e\\" }
precmd()  { print -Pn "\e]133;A;\e\\" }
ZSHEOF
        echo "OSC 133 已追加到: $ZSH_CONFIG"
    fi
fi

echo "==> 5. 设置 zsh 为默认 Shell"
ZSH_PATH="$(which zsh)"
if [ "$SHELL" != "$ZSH_PATH" ]; then
    sudo chsh -s "$ZSH_PATH" "$USER"
    echo "默认 Shell 已设置为 zsh（需重新登录生效）"
else
    echo "默认 Shell 已是 zsh"
fi

echo "==> 6. 编译 Alacritty"
cd "$PROJECT_DIR"
cargo build --release
echo "编译完成: $ALACRITTY_BIN"

echo "==> 7. 放置配置文件"
mkdir -p "$(dirname "$CONFIG_DST")"
cp "$CONFIG_SRC" "$CONFIG_DST"
echo "配置文件已放置: $CONFIG_DST"

echo "==> 8. 设置 Alacritty 为系统默认终端"
# GNOME Terminal / Console 默认设置
gsettings set org.gnome.desktop.default-applications.terminal exec "$ALACRITTY_BIN"
gsettings set org.gnome.desktop.default-applications.terminal exec-arg ""
# Nautilus（文件管理器）右键"在终端打开"
gsettings set org.gnome.desktop.default-applications.terminal exec "$ALACRITTY_BIN"
echo "默认终端已设置为 Alacritty"

echo ""
echo "=============================="
echo "  安装完成！"
echo "=============================="
echo "  默认终端:  $ALACRITTY_BIN"
echo "  配置文件:  $CONFIG_DST"
echo "  默认 Shell: $ZSH_PATH"
echo ""
echo "  请注销或重启，或者运行:"
echo "    gsettings set org.gnome.desktop.default-applications.terminal exec '$ALACRITTY_BIN'"
echo ""
echo "  快捷键:"
echo "    Ctrl+Up/Down  命令历史导航"
echo "    Ctrl+Y        复制命令+输出"
echo "    Ctrl+Enter    跳回底部"
echo "=============================="
