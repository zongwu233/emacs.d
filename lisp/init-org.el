;;安装最新版本 org 不使用内置版本
(use-package org
  :pin gnu
  :ensure t)

(use-package org-contrib
  :pin nongnu
  :ensure t)

(require 'org-tempo)  ;开启easy template

;; 需要开启 electric-pair-mode
;; 禁用左尖括号
(setq electric-pair-inhibit-predicate
      `(lambda (c)
	 (if (char-equal c ?\<) t (,electric-pair-inhibit-predicate c))))

(add-hook 'org-mode-hook
	  (lambda ()
	    (setq-local electric-pair-inhibit-predicate
			`(lambda (c)
			   (if (char-equal c ?\<) t (,electric-pair-inhibit-predicate c))))))

(provide 'init-org)
