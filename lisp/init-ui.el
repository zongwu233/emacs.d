;; -*- lexical-binding: t -*-
  ;; install theme
(use-package gruvbox-theme :ensure t)

(load-theme 'gruvbox-light-soft t)

(use-package doom-modeline
  :ensure t
  :init
  (setq doom-modeline-minor-modes t)
  :custom-face
  (mode-line ((t (:height 0.95))))
  (mode-line-inactive ((t (:height 0.95))))
  :hook (after-init . doom-modeline-mode))

  (use-package simple
    :ensure nil
    :hook (after-init . size-indication-mode)
    :init
    (progn
      (setq column-number-mode t)
      ))

  ;; M-x nerd-icons-install-fonts 安装必要的字体，否则有些字符不显示
  (use-package nerd-icons
    :ensure t
    ;; :custom
    ;; The Nerd Font you want to use in GUI
    ;; "Symbols Nerd Font Mono" is the default and is recommended
    ;; but you can use any other Nerd Font if you want
    ;; (nerd-icons-font-family "Symbols Nerd Font Mono")
    )



  (provide 'init-ui)
