(use-package evil
  :ensure t
  :init
  ;; 不使用 evil 自带的 keybinding 
  (setq evil-want-keybinding nil)
  ;; 使用 vim 的 C-u 滚动界面操作
  ;; C-d C-u 向前翻页 向后翻页
  (setq evil-want-C-u-scroll t)
  (evil-mode)

  ;; https://emacs.stackexchange.com/questions/46371/how-can-i-get-ret-to-follow-org-mode-links-when-using-evil-mode
  (with-eval-after-load 'evil-maps
    (define-key evil-motion-state-map (kbd "RET") nil))

  ;; insert state 不使用 vi keybinding
  (setcdr evil-insert-state-map nil)
  (define-key evil-insert-state-map [escape] 'evil-normal-state)

  (define-key evil-normal-state-map (kbd "[ SPC") (lambda () (interactive) (evil-insert-newline-above) (forward-line)))
  (define-key evil-normal-state-map (kbd "] SPC") (lambda () (interactive) (evil-insert-newline-below) (forward-line -1)))


  (define-key evil-normal-state-map (kbd "[ b") 'previous-buffer)
  (define-key evil-normal-state-map (kbd "] b") 'next-buffer)
  (define-key evil-motion-state-map (kbd "[ b") 'previous-buffer)
  (define-key evil-motion-state-map (kbd "] b") 'next-buffer)

  (evil-define-key 'normal dired-mode-map
    (kbd "<RET>") 'dired-find-alternate-file
    (kbd "C-k") 'dired-up-directory
    "`" 'dired-open-term
    "q" 'quit-window
    "o" 'dired-find-file-other-window
    ")" 'dired-omit-mode)


  )

;; 支持 vim 的 redo undo ，而且更强大
;; u undo  C-r redo
(use-package undo-tree
  :ensure t
  :diminish
  :init
  (global-undo-tree-mode 1)
  (setq undo-tree-auto-save-history nil)
  (evil-set-undo-system 'undo-tree))

;;文本搜索  doom modeline 会显示结果总数以及当前 index
(use-package evil-anzu
:ensure t
:after evil
:diminish
:demand t
:init
(global-anzu-mode t))

;;社区更统一的定义各种常用 mode 下的 evil state
(use-package evil-collection
:ensure t
:demand t
:config
(setq evil-collection-mode-list (remove 'lispy evil-collection-mode-list))
(evil-collection-init)

(cl-loop for (mode . state) in
	 '((org-agenda-mode . normal)
	   (Custom-mode . emacs)
	   (eshell-mode . emacs)
	   (org-mode . emacs)
	   (makey-key-mode . motion))
	 do (evil-set-initial-state mode state)))

;; vim surround plugin
(use-package evil-surround
 :ensure t
 :init
 (global-evil-surround-mode 1))

(use-package evil-nerd-commenter
  :ensure t
  :init
  (define-key evil-normal-state-map (kbd ",/") 'evilnc-comment-or-uncomment-lines)
  (define-key evil-visual-state-map (kbd ",/") 'evilnc-comment-or-uncomment-lines)
)
(use-package evil-snipe
  :ensure t
  :diminish
  :init
  (evil-snipe-mode +1)
  (evil-snipe-override-mode +1))

;; 按 % 跳转到匹配的符号，比如 () {} 甚至 begin end
(use-package evil-matchit
  :ensure
  :init
  (global-evil-matchit-mode 1))



(provide 'init-evil)
