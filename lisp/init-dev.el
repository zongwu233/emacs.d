;; Project management
(use-package projectile
  :ensure t
  :hook (after-init . projectile-mode)
  :bind (:map projectile-mode-map
         ("C-c p" . projectile-command-map))
  :config
  (dolist (dir '("bazel-bin"
                 "bazel-out"
                 "bazel-testlogs"))
    (add-to-list 'projectile-globally-ignored-directories dir))
  :custom
  (projectile-use-git-grep t)
  (projectile-indexing-method 'alien)
  (projectile-kill-buffers-filter 'kill-only-files)
  ;; Ignore uninteresting files. It has no effect when using alien mode.
  (projectile-globally-ignored-files '("TAGS" "tags" ".DS_Store"))
  (projectile-globally-ignored-file-suffixes '(".elc" ".pyc" ".o" ".swp" ".so" ".a"))
  (projectile-ignored-projects `("~/"
                                 "/tmp/"
                                 "/private/tmp/"
                                 ,package-user-dir)))

    ;; emacs29 内置 tree-sitter 
    ;; 安装所有 tree-sitter langs libs : M-x treesit-auto-install-all   
    (use-package treesit-auto
      :demand t
      :ensure t
      :init (setq treesit-font-lock-level 4)
      :config
      (setq treesit-auto-install 'prompt)
      (global-treesit-auto-mode))

    ;;查找定义和引用
    ;; xref-find-definitions   M-.
    ;; xref-find-references    M-?
    ;; xref-go-back            M-,
    ;; xref-go-forward         C-M-,


    ;; 使用 consult-imenu 列出文件内函数列表，方便跳转


  (defun my-eglot-keybindgs ()
    (define-key evil-motion-state-map "gR" #'eglot-rename)
    (define-key evil-motion-state-map "gr" #'xref-find-references)
    (define-key evil-normal-state-map "gi" #'eglot-find-implementation)
    (define-key evil-motion-state-map "gh" #'eldoc)
    (define-key evil-normal-state-map "ga" #'eglot-code-actions))
  ;; emacs29 内置 eglot:A client for Language Server Protocol servers
  ;; lsp-mode 集成了很多包，功能丰富， eglot 功能相对简单
  (use-package eglot
    :ensure nil
    :init
    (advice-add 'eglot-ensure :after 'my-eglot-keybindgs)
    :bind (:map eglot-mode-map
		("C-c l a" . eglot-code-actions)
		("C-c l r" . eglot-rename)
		("C-c l o" . eglot-code-action-organize-imports)
		("C-c l f" . eglot-format)
		("C-c l d" . eldoc)
		("s-<return>" . eglot-code-actions))
    :hook
    (css-mode . eglot-ensure)
    (js2-mode . eglot-ensure)
    (js-mode . eglot-ensure)
    (web-mode . eglot-ensure)
    (rust-mode . eglot-ensure)
    (elixir-mode . eglot-ensure)
    (c++-mode . eglot-ensure)
    (python-mode . eglot-ensure)

    :config
    (setq eglot-send-changes-idle-time 0.2)
    ;(add-to-list 'eglot-server-programs '(rust-mode "rust-analyzer"))
    ;(add-to-list 'eglot-server-programs '(c++-mode . ("clangd" "--enable-config")))
    (add-to-list 'eglot-server-programs '(web-mode . ("vscode-html-language-server" "--stdio")))
    ;(add-to-list 'eglot-server-programs '(elixir-mode "~/.emacs.d/elixir-ls/release/language_server.sh"))

  (setq read-process-output-max (* 1024 1024))
  (push :documentHighlightProvider eglot-ignored-server-capabilities)
  (setq eldoc-echo-area-use-multiline-p nil))

  (use-package consult-eglot
    :ensure t
    :defer t)


    (use-package yasnippet
    :ensure t
    :hook ((prog-mode . yas-minor-mode)
	   (org-mode . yas-minor-mode))
    :init
    :config
    (progn
      (setq hippie-expand-try-functions-list
	    '(yas/hippie-try-expand
	      try-complete-file-name-partially
	      try-expand-all-abbrevs
	      try-expand-dabbrev
	      try-expand-dabbrev-all-buffers
	      try-expand-dabbrev-from-kill
	      try-complete-lisp-symbol-partially
	      try-complete-lisp-symbol))))

    (use-package yasnippet-snippets
    :ensure t
    :after yasnippet) 

  (provide 'init-dev)
