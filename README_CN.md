# Emacs.d

[English](README.md)

基于 [Org-mode literate programming](https://orgmode.org/worg/org-contrib/babel/intro.html) 组织的模块化 Emacs 配置，使用 Evil 模式提供 Vim 风格的编辑体验。

## 特性

- **Literate 配置** — 所有配置集中在 [init-v2.org](init-v2.org)，通过 org-babel tangle 生成 `.el` 文件
- **Evil 模式** — 完整的 Vim 键绑定体系（evil + evil-collection + evil-surround + evil-snipe 等）
- **SPC Leader Key** — 类 Spacemacs 的 leader key 体系，通过 [general](https://github.com/noctuid/general.el) 管理
- **Vertico 生态** — vertico + orderless + marginalia + consult + embark 补全框架
- **Org-mode 增强** — org-superstar / org-appear / org-download / org-capture / org-agenda 自定义 Dashboard
- **LSP** — 内置 eglot + consult-eglot，支持 Python / JS / CSS / Rust / Elixir / C++
- **跨平台** — 支持 macOS / Linux / Windows，自动适配字体、编码、剪贴板等

## 依赖

### Emacs 版本

**Emacs >= 29.4**（内置 use-package 和 tree-sitter 支持）

### 字体

安装以下字体以获得最佳显示效果：

| 字体 | 用途 | 安装方式 |
|------|------|----------|
| [Hack Nerd Font Mono](https://www.nerdfonts.com/font-downloads) | 英文等宽字体 | 手动下载安装 |
| Noto Sans CJK SC (Linux) / PingFang SC (macOS) / Microsoft YaHei (Windows) | 中文字体 | 系统包管理器 |

首次启动后执行 `M-x nerd-icons-install-fonts` 安装图标字体（Windows 用户可能需要代理或手动下载）。

### 外部工具（可选）

- [ripgrep](https://github.com/BurntSushi/ripgrep) — `consult-ripgrep` 项目内搜索
- [fd](https://github.com/sharkdp/fd) — 更快的文件查找
- [git](https://git-scm.com/) — magit / diff-hl 依赖
- Python LSP — `pip install python-lsp-server` 配合 eglot 使用

## 安装

```bash
# 备份现有配置
mv ~/.emacs.d ~/.emacs.d.bak

# 克隆仓库
git clone https://github.com/zongwu233/emacs.d.v2.git ~/.emacs.d
```

首次启动时 Emacs 会自动下载并安装所有包。安装完成后重启 Emacs。

> **注意**：包源使用的是 163 镜像（`mirrors.163.com/elpa/`），国内用户无需额外配置。如果你在海外，可以在 `lisp/init-package.el` 中改为 MELPA 官方源。

## 项目结构

```
~/.emacs.d/
├── init-v2.org              # Literate 配置源文件（所有配置都在这里）
├── init.el                  # 入口文件，加载各模块
├── early-init.el            # 早期初始化（GC、编码、UI 延迟）
├── custom.el                # Emacs Custom 自动生成的包列表（已 gitignore）
├── lisp/                    # 模块化配置文件（从 init-v2.org tangle 生成）
│   ├── init-package.el      # 包管理
│   ├── init-evil.el         # Evil 模式及扩展
│   ├── init-basic.el        # 基础编辑设置
│   ├── init-leader-key.el   # Leader key 定义
│   ├── init-completion.el   # 补全框架
│   ├── init-search.el       # 搜索与替换
│   ├── init-ui.el           # 主题与界面
│   ├── init-org.el          # Org-mode 配置
│   ├── init-text-manipulation.el  # 文本操作与高亮
│   ├── init-window.el       # 窗口管理
│   ├── init-tabs.el         # Tab / Workspace 管理
│   ├── init-dev.el          # 编程支持（tree-sitter / eglot / yasnippet）
│   ├── init-git.el          # Git 集成
│   ├── init-python.el       # Python 开发
│   ├── init-tools.el        # 辅助工具
│   └── init-md.el           # Markdown 配置
├── snippets/                # 自定义 yasnippet 代码片段
├── site-lisp/               # 本地第三方包
└── win-autohotkey-install.org  # Windows AutoHotKey 改键指南
```

## 快捷键速查

### Leader Key（SPC）

| 前缀 | 功能 | 常用命令 |
|------|------|----------|
| `SPC SPC` | M-x 命令 | |
| `SPC f` | 文件操作 | `f` find-file / `s` save / `r` recent-file |
| `SPC b` | Buffer | `b` switch-buffer / `d` kill-buffer |
| `SPC w` | 窗口 | `d` delete / `s` split-below / `v` split-right |
| `SPC p` | 项目 | `f` find-file / `s` switch-project / `g` grep |
| `SPC s` | 搜索 | `s` consult-line / `f` ripgrep / `i` imenu |
| `SPC g` | Git | `g` magit-status / `b` blame / `l` log |
| `SPC u` | Universal argument | |
| `,` | Major-mode leader | 当前模式相关命令 |

### 常用快捷键

| 按键 | 功能 |
|------|------|
| `C-s` | consult-line（文件内搜索） |
| `C-x b` | consult-buffer |
| `C-;` | embark-act（上下文操作） |
| `C-c a` | org-agenda |
| `C-c c` | org-capture |
| `C-c d` | 归档已完成的 org 任务 |
| `C-x g` | magit-status |
| `C-=` | expand-region（区域扩展） |
| `<f2>` | 打开 init-v2.org 配置文件 |

## Windows 用户

Windows 环境下推荐使用 [AutoHotKey V2](https://www.autohotkey.com/) 将 CapsLock 映射为 Ctrl，详见 [win-autohotkey-install.org](win-autohotkey-install.org)。

## 自定义

编辑 `init-v2.org` 文件后，在 Emacs 中执行 `org-babel-tangle`（`C-c C-v t`）重新生成 `.el` 文件，然后重启 Emacs 生效。

## 致谢

- [condy0919/.emacs.d](https://github.com/condy0919/.emacs.d) — 结构设计参考
- [zilongshanren/.emacs.d](https://github.com/zilongshanren/.emacs.d) — 配置参考

## License

[MIT](LICENSE)
