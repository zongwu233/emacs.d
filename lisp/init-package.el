;; -*- coding: utf-8; lexical-binding: t; -*-

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


;;; 安装最新 org 需要，这个配置一定要配置在 use-package 的初始化之前，否则无法正常安装
;;(assq-delete-all 'org package--builtins)
;;(assq-delete-all 'org package--builtin-versions)


;; Bootstrap `use-package'
(unless (package-installed-p 'use-package)
  (package-refresh-contents)
  (package-install 'use-package))
(eval-and-compile
  (setq use-package-always-ensure nil)
  (setq use-package-always-defer nil)
  (setq use-package-always-demand nil)
  (setq use-package-expand-minimally nil)
  (setq use-package-enable-imenu-support t))
(eval-when-compile
  (require 'use-package))

;; Bootstrap `quelpa'.
(use-package quelpa
  :ensure t
  :commands quelpa
  :custom
  (quelpa-git-clone-depth 1)
  (quelpa-self-upgrade-p nil)
  (quelpa-update-melpa-p nil)
  (quelpa-checkout-melpa-p nil))

(unless (package-installed-p 'quelpa-use-package)
      (quelpa
       '(quelpa-use-package
	 :fetcher git
	 :url "https://github.com/quelpa/quelpa-use-package.git")))

(use-package quelpa-use-package
      :init
      (setq quelpa-use-package-inhibit-loading-quelpa t)
      :demand t)

(provide 'init-package)
