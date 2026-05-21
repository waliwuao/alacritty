# AGENTS.md

> 本地 fork，用于魔改，不参与上游贡献。

## 项目结构

Cargo workspace，4 个 crate：

| Crate | 用途 |
|---|---|
| `alacritty` | 主二进制：UI（winit/glutin）、配置、事件循环、渲染、IPC daemon |
| `alacritty_terminal` | 纯终端模拟库（grid、PTY I/O、VT 解析、选择、vi-mode），无平台 UI |
| `alacritty_config` | 容错 TOML 配置合并，`SerdeReplace` trait |
| `alacritty_config_derive` | 过程宏：`#[derive(ConfigDeserialize, SerdeReplace)]` |

## 常用命令

```sh
cargo test                              # 全部测试
cargo test -p alacritty_terminal        # 仅终端库测试（含 ref tests）
cargo test -p alacritty_terminal --no-default-features   # 不带 serde
cargo clippy --all-targets              # lint
cargo fmt                               # 格式化
cargo build --release                   # 发布构建
```

## 架构要点

- **配置系统**：`ConfigDeserialize` 是容错的——无效值会被记录日志，字段回退到默认值。配置文件是 TOML 格式（`serde_yaml` 仅用于窗口主题文件）。
- **IPC daemon**：支持 `alacritty daemon` 和 `alacritty msg` 子命令，通过 Unix socket 实现多窗口控制。
- **`alacritty_terminal` 版本**：始终带 `-dev` 后缀，跟踪下一个发布版。
- **MSRV**：`Cargo.toml` 中 `rust-version` 字段定义，当前 1.85.0。

## Ref Tests

位置：`alacritty_terminal/tests/ref/`。每个测试目录含 `grid.json`（预期输出）、`alacritty.recording`、`config.json`、`size.json`。

新增 ref test 步骤：
1. 构建 release 二进制：`cargo build --release`
2. 用 `--ref-test` 运行录制输出
3. 关闭窗口（Ctrl+C/`exit`/`^D` 不会触发保存，需 kill 或点击关闭）
4. 将生成的文件复制到 `alacritty_terminal/tests/ref/NEW_TEST_NAME/`
5. 在 `alacritty_terminal/tests/ref.rs` 的 `ref_tests!` 宏中注册

## 代码风格

- `.rs` 和 `.toml` 用 **4 空格缩进**；`Makefile` 和 `.scd` 用 tab
- **注释必须以句号结尾**（文档注释和普通注释都是）
- `rustfmt.toml` 非默认设置：`imports_granularity = "Module"`、`use_small_heuristics = "Max"`、`comment_width = 100`、`format_strings = true`、`reorder_impl_items = true`
- Clippy 严格：`#![deny(clippy::all, clippy::if_not_else, clippy::enum_glob_use)]`（主二进制和 terminal 中）
- Unix 平台必须启用至少一个 `x11`/`wayland` feature（`compile_error` 强制）

## 注意事项

- `x11-clipboard` 使用了 git patch（见 workspace `Cargo.toml` 的 `[patch.crates-io]`）
- `vte` crate 被本地 fork 到 `vte/` 目录，添加了 `Handler::shell_integration_kind` 方法用于 OSC 133 解析
- 修改 `config.rs` 时需同步更新 `extra/man/` 下的 man pages
- 默认 features：`x11` + `wayland`。如需仅保留一个或忽略系统库依赖，调整 `--no-default-features` / `--features`

## 命令导航器

基于 OSC 133 shell integration 的命令历史导航，实现在 `alacritty_terminal/src/term/mod.rs`：

- `command_markers: Vec<Line>` — 存储命令起始行；`scroll_up` 时同步移位
- `shell_integration_kind(b'A')` — vte Handler 回调，在 `precmd` 时创建 marker
- `command_prev/next` — 查找前/后一个 marker
- `command_region_text` — 提取两个 marker 之间的文本（Ctrl+Y 复制）
- `scroll_to_line` — 居中滚动到指定行（Ctrl+Up/Down）
- 快捷键处理见 `alacritty/src/input/mod.rs` 和 `alacritty/src/config/bindings.rs`
