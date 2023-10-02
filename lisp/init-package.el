(require 'package)
(setq package-archives '(("gnu"   . "https://mirrors.163.com/elpa/gnu/")
			 ("melpa" . "https://mirrors.163.com/elpa/melpa/")))
;; add nongnu resource
(add-to-list 'package-archives
	    (cons "nongnu" (format "http%s://elpa.nongnu.org/nongnu/"
				   (if (gnutls-available-p) "s" ""))))

(package-initialize)

;;防止反复调用 package-refresh-contents 会影响加载速度
(when (not package-archive-contents)
  (package-refresh-contents))

;;; 这个配置一定要配置在 use-package 的初始化之前，否则无法正常安装
(assq-delete-all 'org package--builtins)
(assq-delete-all 'org package--builtin-versions)


;; Setup `use-package'
(unless (package-installed-p 'use-package)
  (package-refresh-contents)
  (package-install 'use-package))

;; 重启命令
(use-package restart-emacs
  :ensure t)

;;添加本地目录插件
(add-to-list 'load-path (expand-file-name "~/.emacs.d/site-lisp/awesome-tab") )


(provide 'init-package)
