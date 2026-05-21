<p align="center">
    <img width="200" alt="Alacritty Logo" src="https://raw.githubusercontent.com/alacritty/alacritty/master/extra/logo/compat/alacritty-term%2Bscanlines.png">
</p>

<h1 align="center">Alacritty — Linux Terminal Emulator</h1>

> 基于 [alacritty/alacritty](https://github.com/alacritty/alacritty) 的本地 fork，面向 Linux 魔改。

## 构建

```sh
cargo build --release
```

二进制位于 `target/release/alacritty`。

### 依赖

- Rust >= 1.85.0
- OpenGL ES 2.0

## 配置

示例配置见 `config/alacritty.toml`。运行时可通过 `--config-file` 指定：

```sh
alacritty --config-file config/alacritty.toml
```

默认配置文件查找顺序：

1. `$XDG_CONFIG_HOME/alacritty/alacritty.toml`
2. `$XDG_CONFIG_HOME/alacritty.toml`
3. `$HOME/.config/alacritty/alacritty.toml`
4. `$HOME/.alacritty.toml`

## 命令导航器

基于 OSC 133 shell integration 的命令历史导航。需在 `~/.zshrc` 中启用：

```zsh
preexec() { print -Pn "\e]133;C;\e\\" }
precmd()  { print -Pn "\e]133;A;\e\\" }
```

| 快捷键 | 功能 |
|---|---|
| **Ctrl+Up** / **Ctrl+Down** | 在历史命令之间跳转 |
| **Ctrl+Y** | 复制当前命令区域（提示符 + 输入 + 输出） |
| **Ctrl+Enter** | 跳回底部，退出导航模式 |

导航时自动进入 vi 模式显示光标位置，按 `i` 或 Ctrl+Enter 退出。

## License

Apache License, Version 2.0
