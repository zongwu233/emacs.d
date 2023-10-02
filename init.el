;; -*- coding: utf-8; lexical-binding: t; -*-

;; open for debug error when you need.
(setq debug-on-error t)

(add-to-list 'load-path "~/.emacs.d/lisp/")
(require 'custom)
(require 'init-package)
(require 'init-keybinding)
(require 'init-defaults-better)
(require 'init-company)
(require 'init-vertico)
(require 'init-orderless)
(require 'init-marginalia)
(require 'init-embark)
(require 'init-awesome-tab)
(require 'init-search)
(require 'init-theme)
(require 'init-org)
