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

;; emacs29 内置 eglot:A client for Language Server Protocol servers
;; lsp-mode 集成了很多包，功能丰富， eglot 功能相对简单
(require 'eglot)


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

(provide 'init-programming-basic)
