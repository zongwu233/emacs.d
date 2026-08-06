;; -*- coding: utf-8; lexical-binding: t; -*-

(use-package haskell-mode
  :ensure t
  :defer t
  :mode (("\\.hs\\'"     . haskell-mode)
         ("\\.hsc\\'"    . haskell-mode)
         ("\\.lhs\\'"    . haskell-literate-mode)
         ("\\.cabal\\'"  . haskell-cabal-mode))
  :interpreter ("runghc" . haskell-mode)
  :init
  ;; 关闭局部 electric-indent，避免与 Haskell 自动缩进冲突（haskell-mode 文档建议）
  (add-hook 'haskell-mode-hook (lambda () (electric-indent-local-mode -1)))
  :hook
  (haskell-mode . interactive-haskell-mode)   ; 启用 cabal REPL 集成
  (haskell-mode . haskell-indentation-mode)   ; 智能缩进（haskell-mode 自带）
  (haskell-mode . haskell-decl-scan-mode)     ; imenu 函数/类型列表
  (haskell-mode . my-haskell-eglot-ensure)     ; HLS 存在时才启动（见 :config）
  :custom
  ;; 用 cabal 构建
  (haskell-compile-cabal-build-command "cabal build --ghc-options=-ferror-reports")
  ;; REPL：cabal new-repl（支持多包项目）
  (haskell-process-type 'cabal-repl)
  (haskell-process-wrapper-function
   (lambda (argv) (append '("cabal" "new-repl") argv)))
  ;; REPL 行为
  (haskell-process-auto-import-loaded-modules t)
  (haskell-process-log t)
  (haskell-process-suggest-remove-import-lines t)
  (haskell-process-suggest-hoogle-imports t)
  ;; 缩进：2 空格（社区惯例）
  (haskell-indentation-layout-offset 2)
  (haskell-indentation-left-offset 2)
  :config
  ;; 未装 HLS 时静默跳过，避免每次打开 .hs 都触发 LSP 启动失败/超时
  (defun my-haskell-eglot-ensure ()
    "HLS 存在时才启动 eglot，缺失时静默跳过（无工具链机器不报错）。"
    (when (executable-find "haskell-language-server-wrapper")
      (eglot-ensure))))

;; 按键绑定：延迟到 haskell-mode 真正加载后（此时 haskell-mode-map 已存在）。
;; 用 with-eval-after-load 而非 use-package :config，因为 general 的
;; global-leader 宏会立即调用 define-key，而 :defer t 的包加载前 map 为 void。
(with-eval-after-load 'haskell-mode
  (global-leader
    :major-modes
    '(haskell-mode t haskell-cabal-mode t)
    :keymaps
    '(haskell-mode-map haskell-cabal-mode-map)
    "=" 'haskell-mode-stylish-buffer          ; 格式化（需 stylish-haskell）
    "c" 'haskell-compile                      ; 构建 (cabal build)
    "l" 'haskell-process-load-or-reload       ; 发送到 REPL
    "r" 'haskell-process-reload               ; 重载模块
    "i" 'haskell-process-do-info              ; 查询类型/定义 (:info)
    "t" 'haskell-process-do-type              ; 查询类型 (:type)
    "s" 'haskell-interactive-switch           ; 切到 REPL
    "d" 'haskell-hoogle)                      ; Hoogle 查询（haskell-mode 自带）
  ;; 本地 Hoogle 快捷键（社区惯例）
  ;;   在线模式默认走 https://hoogle.haskell.org，无需安装。
  ;;   离线模式：cabal install hoogle && hoogle generate
  (define-key haskell-mode-map (kbd "C-c h") 'haskell-hoogle))

(provide 'init-haskell)
