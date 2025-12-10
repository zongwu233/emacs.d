;;; init-tools.el  -*- lexical-binding: t -*-
;;针对 Emacs 快捷键多而杂的问题，安装后，当按下部分快捷键前缀时，
;;它会通过 minibuffer 提示你都有哪些可以按的快捷键及其命令名
(use-package which-key
  :ensure t
  :init (which-key-mode))

;;使用快捷键，可以快速跳转到任意行，任意符号
;; Jump to arbitrary positions
(use-package avy
  :ensure t
  ;; integrate with isearch and others
  ;; C-' to select isearch-candidate with avy
  :hook (after-init . avy-setup-default)
  :bind (("M-g M-l" . avy-goto-line)
         ("M-g M-r" . avy-goto-char-timer))
  :custom
  (avy-background t)
  (avy-all-windows nil)
  (avy-keys '(?a ?s ?d ?f ?g ?h ?j ?k ?l ?q ?w ?e ?r ?u ?i ?o ?p))
  ;; overlay is used during isearch, `pre' style makes avy keys evident.
  (avy-styles-alist '((avy-isearch . pre))))

(use-package rainbow-delimiters
  :ensure t
  :hook (prog-mode . rainbow-delimiters-mode))

;;不同于普通的代码补全，它的补全还包括了文件名、elisp 函数名等。
;;它的补全规则不包含语法分析，而是纯文本补全，
;; Better abbrev expansion
(use-package hippie-exp
  :ensure nil
  :bind ([remap dabbrev-expand] . hippie-expand)
  :config
  (defun try-expand-tempo (_old)
    (require 'tempo)
    (tempo-expand-if-complete))
  :custom
  (hippie-expand-try-functions-list '(try-expand-tempo
                                      try-expand-dabbrev
                                      try-expand-dabbrev-all-buffers
                                      try-expand-dabbrev-from-kill
                                      try-complete-file-name-partially
                                      try-complete-file-name
                                      try-expand-all-abbrevs
                                      try-expand-list
                                      try-expand-line
                                      try-complete-lisp-symbol-partially
                                      try-complete-lisp-symbol)))

(provide 'init-tools)
