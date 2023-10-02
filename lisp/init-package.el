(require 'package)
(setq package-archives '(("gnu"   . "https://mirrors.163.com/elpa/gnu/")

			 ("melpa" . "https://mirrors.163.com/elpa/melpa/")))
(package-initialize)

;;防止反复调用 package-refresh-contents 会影响加载速度
(when (not package-archive-contents)
  (package-refresh-contents))

;;添加本地目录插件
(add-to-list 'load-path (expand-file-name "~/.emacs.d/site-lisp/awesome-tab") )


(provide 'init-package)
