;; -*- coding: utf-8; lexical-binding: t; -*-

  (use-package company
    :ensure t
    :bind (:map company-active-map
		("C-n" . 'company-select-next)
		("C-p" . 'company-select-previous))
    :init
    (global-company-mode t)
    :config
    (setq company-minimum-prefix-length 1)
    (setq company-idle-delay 0))

;;增强 minibuffer 补全
(use-package vertico :ensure	t)
(vertico-mode t)

;; make c-j/c-k work in vertico selection
(define-key vertico-map (kbd "C-j") 'vertico-next)
(define-key vertico-map (kbd "C-k") 'vertico-previous)

;;在 minibuffer 支持模糊搜索
(use-package orderless :ensure t)
(setq completion-styles '(orderless))

;; 增强 minibuffer 的annotation
(use-package marginalia :ensure t)
(marginalia-mode t)

;; minibuffer action 就类似于在任何内容上右键点击
(use-package embark :ensure t)
(global-set-key (kbd "C-;") 'embark-act)
;;利用这个 可以不用再记忆快捷键，只需要执行 C-x C-h 呼出帮助命令
;;然后输入想执行命令的关键字，既可以出现提示列表，又因为 orderless
;; 可以不用在意关键字单词的顺序 最后直接回车执行即可
(setq prefix-help-command 'embark-prefix-help-command)

;;增强文件内搜索和跳转函数定义
(use-package consult :ensure t)
;;同时使用需要这个
(use-package embark-consult :ensure t)
;;强大的文件内搜索功能，完全替代了 swiper 插件
(global-set-key (kbd "C-s") 'consult-line)
;;文件内函数跳转
;;consult-imenu

;; consult 默认配置优化
(eval-after-load 'consult
(progn
  (setq
   consult-narrow-key "<"
   consult-line-numbers-widen t
   consult-async-min-input 2
   consult-async-refresh-delay  0.15
   consult-async-input-throttle 0.2
   consult-async-input-debounce 0.1)
  ))

(defun consult-directory-externally (file)
  "Open FILE externally using the default application of the system."
  (interactive "fOpen externally: ")
  (if (and (eq system-type 'windows-nt)
	   (fboundp 'w32-shell-execute))
      (shell-command-to-string (encode-coding-string
				(replace-regexp-in-string "/" "\\\\"
				  (format "explorer.exe %s"
					  (file-name-directory
					(expand-file-name file)))) 'gbk))
    (call-process (pcase system-type
		    ('darwin "open")
		    ('cygwin "cygstart")
		    (_ "xdg-open"))
		  nil 0 nil
		  (file-name-directory (expand-file-name file)))))
;; 给 embark 添加一个 action: E 使用系统的文件浏览器打开当前目录
;; https://github.com/oantolin/embark/tree/fcf068c0e912baa9267cbec02e56a5972d8f31b4#creating-your-own-keymaps
(eval-after-load 'embark
  (defvar-keymap embark-file-map "E" #'consult-directory-externally))
;;打开当前文件的目录
(defun my-open-current-directory ()
  (interactive)
  (consult-directory-externally default-directory))



(provide 'init-completion)
