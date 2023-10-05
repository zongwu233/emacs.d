;; -*- coding: utf-8; lexical-binding: t; -*-

;; open for debug error when you need.
;;(setq debug-on-error t)

(add-to-list 'load-path "~/.emacs.d/lisp/")
(require 'init-begin)
(require 'init-package)
(require 'init-keybinding)
(require 'init-basic)
(require 'init-completion)
;;使用内置的 tab-bar 在 init-window 配置 
;(require 'init-awesome-tab)

(require 'init-search)
(require 'init-ui)
(require 'init-org)
(require 'init-evil)
(require 'init-text-manipulation)
(require 'init-programming-basic)
(require 'init-window)
(require 'init-tabs)


(setq custom-file (expand-file-name "~/.emacs.d/lisp/custom.el"))
(load custom-file 'no-error 'no-message)
