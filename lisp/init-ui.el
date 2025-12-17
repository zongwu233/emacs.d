;; -*- coding: utf-8; lexical-binding: t; -*-

;; install theme
;;(use-package gruvbox-theme :ensure t)
;;(load-theme 'gruvbox-light-soft t)

;; Use default theme in terminals
(use-package doom-themes
  :ensure t
  :when (display-graphic-p)
  :config
  (load-theme 'doom-one t)
  (doom-themes-org-config))

(use-package emacs
  :ensure nil
  :unless (display-graphic-p)
  :config
  (load-theme 'leuven t))


(use-package doom-modeline
  :ensure t
  :hook (after-init . doom-modeline-mode)
  :custom
  (doom-modeline-irc nil)
  (doom-modeline-mu4e nil)
  (doom-modeline-gnus nil)
  (doom-modeline-github nil)
  (doom-modeline-persp-name nil)
  (doom-modeline-unicode-fallback t)
  (doom-modeline-enable-word-count nil))

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
  :when (display-graphic-p)
  :demand t
  )

(use-package visual-fill-column
  :ensure t
  :init
  (add-hook 'visual-line-mode-hook #'visual-fill-column-mode)
  ;; Configure fill width
  (setq visual-fill-column-center-text t))

(use-package dashboard
  :ensure t
  :init
  ;; Format: "(icon title help action face prefix suffix)"
  (setq dashboard-navigator-buttons 
        `(((,(if (fboundp 'nerd-icons-octicon) (nerd-icons-octicon "nf-oct-mark_github") "★")
            "GitHub" "Browse" (lambda (&rest _) (browse-url homepage-url)))
           (,(if (fboundp 'nerd-icons-octicon) (nerd-icons-octicon "nf-oct-heart") "♥")
            "Stars" "Show stars" (lambda (&rest _) (browse-url stars-url)))
           (,(if (fboundp 'nerd-icons-octicon) (nerd-icons-octicon "nf-oct-alert") "\u2691")
            "Issue" "Report issue" (lambda (&rest _) (browse-url issue-url)) warning)
           ))
        )

  (dashboard-setup-startup-hook)
  :config
  (defconst homepage-url "https://github.com/zongwu233/zongwu233.github.io")
  (defconst stars-url (concat homepage-url "/stargazers"))
  (defconst issue-url (concat homepage-url "/issues/new"))
  :custom
  (dashboard-startup-banner 'logo)
  (dashboard-set-heading-icons t)
  (dashboard-set-file-icons t)
  (dashboard-set-init-info t)
  (dashboard-items '((recents   . 10)
                     (projects  . 7)))
  (dashboard-startupify-list '(dashboard-insert-banner
                             dashboard-insert-newline
                             dashboard-insert-banner-title
                             dashboard-insert-newline
                             dashboard-insert-navigator
                             dashboard-insert-newline
                             dashboard-insert-init-info
                             dashboard-insert-items
                             dashboard-insert-newline
                             dashboard-insert-footer)))


(provide 'init-ui)
