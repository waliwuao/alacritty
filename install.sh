#!/bin/bash
set -e

# Alacritty dependency installer (Debian/Ubuntu)
# Usage: chmod +x install.sh && ./install.sh

ZSH_CONFIG="$HOME/.zshrc"
ZSH_WAS_NEW=false

echo "==> 1. Check and install zsh"
if ! command -v zsh &>/dev/null; then
    echo "zsh not found, installing..."
    sudo apt update
    sudo apt install -y zsh
    ZSH_WAS_NEW=true
    echo "zsh installed"
else
    echo "zsh already installed: $(zsh --version)"
fi

echo "==> 2. Check and install Rust/Cargo"
if ! command -v cargo &>/dev/null; then
    echo "Rust not found, installing..."
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
    source "$HOME/.cargo/env"
    echo "Rust installed"
else
    echo "Cargo already installed: $(cargo --version)"
fi

echo "==> 3. Configure Cargo Tsinghua mirror"
mkdir -p "$HOME/.cargo"
cat > "$HOME/.cargo/config.toml" << 'EOF'
[source.crates-io]
replace-with = 'tuna'

[source.tuna]
registry = "sparse+https://mirrors.tuna.tsinghua.edu.cn/crates.io-index/"
EOF
echo "Cargo mirror set to Tsinghua"

echo "==> 4. Install Oh My Zsh"
if [ ! -d "$HOME/.oh-my-zsh" ]; then
    sh -c "$(wget -O- https://install.ohmyz.sh/)"
    echo "Oh My Zsh installed"
else
    echo "Oh My Zsh already installed"
fi

echo "==> 5. Configure OSC 133 shell integration"
if ! grep -q "OSC 133" "$ZSH_CONFIG" 2>/dev/null; then
    cat >> "$ZSH_CONFIG" << 'ZSHEOF'

# OSC 133 shell integration (Alacritty command navigator)
preexec() { print -Pn "\e]133;C;\e\\" }
precmd()  { print -Pn "\e]133;A;\e\\" }
ZSHEOF
    echo "OSC 133 appended to: $ZSH_CONFIG"
else
    echo "OSC 133 already present in zshrc"
fi

echo ""
echo "=============================="
echo "  Done!"
echo "=============================="
echo "  Shell:  $(which zsh)"
echo "  Rust:   $(rustc --version 2>/dev/null || echo 'not found')"
echo "  Cargo:  $(cargo --version 2>/dev/null || echo 'not found')"
echo "=============================="
