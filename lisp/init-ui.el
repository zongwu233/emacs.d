;; -*- lexical-binding: t -*-
;; install theme
(use-package gruvbox-theme :ensure t)
(load-theme 'gruvbox-light-soft t)
(use-package doom-modeline
  :ensure t
  :init
  (doom-modeline-mode t))
(use-package simple
  :ensure nil
  :hook (after-init . size-indication-mode)
  :init
  (progn
    (setq column-number-mode t)
  ))


(provide 'init-ui)
