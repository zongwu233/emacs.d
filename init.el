;; -*- coding: utf-8; lexical-binding: t; -*-

;; open for debug error when you need.
;;(setq debug-on-error t)

(add-to-list 'load-path "~/.emacs.d/lisp/")
(require 'init-begin)
(require 'init-package)
(require 'init-keybinding)
(require 'init-basic)
(require 'init-completion)
(require 'init-awesome-tab)
(require 'init-search)
(require 'init-ui)
(require 'init-org)
(require 'init-evil)
(require 'init-text-manipulation)
(require 'init-programming-basic)
(require 'init-window)


(setq custom-file (expand-file-name "~/.emacs.d/lisp/custom.el"))
(load custom-file 'no-error 'no-message)
