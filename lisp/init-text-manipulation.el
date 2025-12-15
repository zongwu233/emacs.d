;; -*- coding: utf-8; lexical-binding: t; -*-  
;; doom emacs 的代码片段. 选择区域 -> 扩展操作 -> 快捷动作 -> 高亮/搜索/替换 
;;在选中某段文本时 use-region-p 用 consult-ripgrep 搜索整个项目目录
(defun my/search-project-for-symbol-at-point ()
  (interactive)
  (if (use-region-p)
  (progn
	(consult-ripgrep (project-root (project-current))
			   (buffer-substring (region-beginning) (region-end))))))

(defun my/evil-quick-replace (beg end )
  (interactive "r")
  (when (evil-visual-state-p)
  (evil-exit-visual-state)
  (let ((selection (regexp-quote (buffer-substring-no-properties beg end))))
	(setq command-string (format "%%s /%s//g" selection))
	(minibuffer-with-setup-hook
	    (lambda () (backward-char 2))
	    (evil-ex command-string)))))

(define-key evil-visual-state-map (kbd "C-r") 'my/evil-quick-replace)

;; expand-region 在选中之后，增加更多自定义 action ，使用 C-= 开启交互面板
(use-package expand-region
  :ensure t
  :bind ("C-=" . er/expand-region)
  :config
  (defadvice er/prepare-for-more-expansions-internal
  (around helm-ag/prepare-for-more-expansions-internal activate)
  ad-do-it
  (let ((new-msg (concat (car ad-return-value)
			     ", H to highlight in buffers"
			     ", / to search in project, "
			     "e iedit mode in functions, "
			     "f to search in files, "
			     "b to search in opened buffers"))
	    (new-bindings (cdr ad-return-value)))
	(cl-pushnew
	 '("H" (lambda ()
		 (interactive)
		 (call-interactively
		  'my/highlight-dwim)))
	 new-bindings)
	(cl-pushnew
	 '("/" (lambda ()
		 (interactive)
		 (call-interactively
		  'my/search-project-for-symbol-at-point)))
	 new-bindings)
	(cl-pushnew
	 '("e" (lambda ()
		 (interactive)
		 (call-interactively
		  'evil-multiedit-match-all)))
	 new-bindings)
	(cl-pushnew
	 '("f" (lambda ()
		 (interactive)
		 (call-interactively
		  'find-file)))
	 new-bindings)
	(cl-pushnew
	 '("b" (lambda ()
		 (interactive)
		 (call-interactively
		  'consult-line)))
	 new-bindings)
	(setq ad-return-value (cons new-msg new-bindings)))))

;;Do What I Mean 风格的高亮,若有选择区域使用 highlight-global 高亮区域，否则，使用symbol-overlay 高亮光标 
(defun my/highlight-dwim ()
  (interactive)
  (if (use-region-p)
	(progn
	  (highlight-frame-toggle)
	  (deactivate-mark))
	(symbol-overlay-put)))


(use-package symbol-overlay
    :ensure t
    :config
    (define-key symbol-overlay-map (kbd "h") 'nil))

(use-package highlight-global
    :ensure nil
    :commands (highlight-frame-toggle)
    :quelpa (highlight-global :fetcher github :repo "glen-dai/highlight-global")
    :config
    (progn
  (setq-default highlight-faces
		    '(('hi-red-b . 0)
		  ('hi-aquamarine . 0)
		  ('hi-pink . 0)
		  ('hi-blue-b . 0)))))
(defun my/clear-highlight ()
  (interactive)
  (clear-highlight-frame) ;; highlight-global function
  (symbol-overlay-remove-all))


(provide 'init-text-manipulation)
