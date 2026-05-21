# Emacs.d

[中文说明](README_CN.md)

A modular Emacs configuration organized with [Org-mode literate programming](https://orgmode.org/worg/org-contrib/babel/intro.html), providing a Vim-like editing experience via Evil mode.

## Features

- **Literate Config** — All configuration lives in a single [init-v2.org](init-v2.org), tangled into `.el` files via org-babel
- **Evil Mode** — Full Vim keybinding ecosystem (evil + evil-collection + evil-surround + evil-snipe, etc.)
- **SPC Leader Key** — Spacemacs-style leader key system powered by [general.el](https://github.com/noctuid/general.el)
- **Vertico Stack** — vertico + orderless + marginalia + consult + embark completion framework
- **Enhanced Org-mode** — org-superstar / org-appear / org-download / org-capture / custom org-agenda Dashboard
- **LSP** — Built-in eglot + consult-eglot with support for Python / JS / CSS / Rust / Elixir / C++
- **Cross-platform** — macOS / Linux / Windows with automatic font, encoding, and clipboard adaptation

## Requirements

### Emacs Version

**Emacs >= 29.4** (built-in use-package and tree-sitter support)

### Fonts

Install the following fonts for the best experience:

| Font | Purpose | Installation |
|------|---------|--------------|
| [Hack Nerd Font Mono](https://www.nerdfonts.com/font-downloads) | Monospace (Latin) | Download and install manually |
| Noto Sans CJK SC (Linux) / PingFang SC (macOS) / Microsoft YaHei (Windows) | CJK text | System package manager |

After first launch, run `M-x nerd-icons-install-fonts` to install icon fonts. (Windows users may need a proxy or manual download.)

### External Tools (optional)

- [ripgrep](https://github.com/BurntSushi/ripgrep) — for `consult-ripgrep` project search
- [fd](https://github.com/sharkdp/fd) — faster file finder
- [git](https://git-scm.com/) — required by magit / diff-hl
- Python LSP — `pip install python-lsp-server` for eglot

## Installation

```bash
# Back up existing config
mv ~/.emacs.d ~/.emacs.d.bak

# Clone the repo
git clone https://github.com/zongwu233/emacs.d.v2.git ~/.emacs.d
```

Emacs will automatically download and install all packages on first launch. Restart Emacs after installation completes.

> **Note:** The package archive is configured to use the 163 mirror (`mirrors.163.com/elpa/`). If you're outside China, you can switch to the official MELPA source in `lisp/init-package.el`.

## Project Structure

```
~/.emacs.d/
├── init-v2.org              # Literate config source (everything is here)
├── init.el                  # Entry point, loads all modules
├── early-init.el            # Early init (GC, encoding, UI deferral)
├── custom.el                # Auto-generated package list (gitignored)
├── lisp/                    # Modular config files (tangled from init-v2.org)
│   ├── init-package.el      # Package management
│   ├── init-evil.el         # Evil mode and extensions
│   ├── init-basic.el        # Basic editing settings
│   ├── init-leader-key.el   # Leader key definitions
│   ├── init-completion.el   # Completion framework
│   ├── init-search.el       # Search and replace
│   ├── init-ui.el           # Theme and UI
│   ├── init-org.el          # Org-mode config
│   ├── init-text-manipulation.el  # Text operations and highlighting
│   ├── init-window.el       # Window management
│   ├── init-tabs.el         # Tab / Workspace management
│   ├── init-dev.el          # Dev support (tree-sitter / eglot / yasnippet)
│   ├── init-git.el          # Git integration
│   ├── init-python.el       # Python development
│   ├── init-tools.el        # Utility packages
│   └── init-md.el           # Markdown config
├── snippets/                # Custom yasnippet snippets
├── site-lisp/               # Local third-party packages
└── win-autohotkey-install.org  # Windows AutoHotKey remap guide
```

## Keybindings

### Leader Key (SPC)

| Prefix | Category | Key Commands |
|--------|----------|--------------|
| `SPC SPC` | M-x command | |
| `SPC f` | File | `f` find-file / `s` save / `r` recent-file |
| `SPC b` | Buffer | `b` switch-buffer / `d` kill-buffer |
| `SPC w` | Window | `d` delete / `s` split-below / `v` split-right |
| `SPC p` | Project | `f` find-file / `s` switch-project / `g` grep |
| `SPC s` | Search | `s` consult-line / `f` ripgrep / `i` imenu |
| `SPC g` | Git | `g` magit-status / `b` blame / `l` log |
| `SPC u` | Universal argument | |
| `,` | Major-mode leader | Mode-specific commands |

### Frequently Used

| Key | Action |
|-----|--------|
| `C-s` | consult-line (in-file search) |
| `C-x b` | consult-buffer |
| `C-;` | embark-act (context actions) |
| `C-c a` | org-agenda |
| `C-c c` | org-capture |
| `C-c d` | Archive done org tasks |
| `C-x g` | magit-status |
| `C-=` | expand-region |
| `<f2>` | Open init-v2.org |

## Windows Users

On Windows, [AutoHotKey V2](https://www.autohotkey.com/) is recommended to remap CapsLock to Ctrl. See [win-autohotkey-install.org](win-autohotkey-install.org) for setup instructions.

## Customization

Edit `init-v2.org`, then run `org-babel-tangle` (`C-c C-v t`) in Emacs to regenerate the `.el` files. Restart Emacs for changes to take effect.

## Acknowledgements

- [condy0919/.emacs.d](https://github.com/condy0919/.emacs.d) — structural design reference
- [zilongshanren/.emacs.d](https://github.com/zilongshanren/.emacs.d) — configuration reference

## License

[MIT](LICENSE)
