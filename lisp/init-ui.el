;; -*- lexical-binding: t -*-
;; install theme
(use-package gruvbox-theme :ensure t)
(load-theme 'gruvbox-light-soft t)
(use-package doom-modeline
  :ensure t
					;fix doom modeline 
  :custom-face
  (mode-line ((t (:height 0.9))))
  (mode-line-inactive ((t (:height 0.9))))
  :init
  (doom-modeline-mode t))
(use-package simple
  :ensure nil
  :hook (after-init . size-indication-mode)
  :init
  (progn
    (setq column-number-mode t)
    ))

(use-package nerd-icons
  :ensure t
  ;; :custom
  ;; The Nerd Font you want to use in GUI
  ;; "Symbols Nerd Font Mono" is the default and is recommended
  ;; but you can use any other Nerd Font if you want
  ;; (nerd-icons-font-family "Symbols Nerd Font Mono")
  )



(provide 'init-ui)
