;; -*- lexical-binding: t -*-
;;增强文件内搜索和跳转函数定义
(package-install 'consult)
;;同时使用需要这个
(package-install 'embark-consult)
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
      (shell-command-to-string (encode-coding-string (replace-regexp-in-string "/" "\\\\"
									       (format "explorer.exe %s" (file-name-directory (expand-file-name file)))) 'gbk))
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




(provide 'init-consult)
