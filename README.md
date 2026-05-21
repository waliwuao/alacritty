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

## License

Apache License, Version 2.0
