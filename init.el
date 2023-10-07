;; -*- coding: utf-8; lexical-binding: t; -*-

  ;; open for debug error when you need.
  ;;(setq debug-on-error t)

;; A big contributor to startup times is garbage collection. We up the gc
;; threshold to temporarily prevent it from running, and then reset it by the
;; `gcmh' package.
(setq gc-cons-threshold most-positive-fixnum
      gc-cons-percentage 0.6)


(let ((dir (locate-user-emacs-file "lisp")))
  (add-to-list 'load-path (file-name-as-directory dir)))  

(setq custom-file (locate-user-emacs-file "custom.el"))
(load custom-file 'no-error 'no-message)  
 
(require 'init-begin)
(require 'init-package)
(require 'init-evil)
(require 'init-basic)
(require 'init-completion)
;;使用内置的 tab-bar 在 init-window 配置 
;(require 'init-awesome-tab)

(require 'init-search)
(require 'init-ui)
(require 'init-org)
(require 'init-text-manipulation)
(require 'init-window)
(require 'init-tabs)
(require 'init-dev)
(require 'init-git)

(provide 'init)

;;; init.el ends here
