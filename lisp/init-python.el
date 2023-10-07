;;; init-python.el  -*- lexical-binding: t -*-

;; Python Mode
;; Install: pip install pyflakes autopep8
(use-package python
  :ensure t
  :hook (inferior-python-mode . (lambda ()
				  (process-query-on-exit-flag
				   (get-process "Python"))))
  :init
  ;; Disable readline based native completion
  (setq python-shell-completion-native-enable nil)
  :config
  (global-leader
    :major-modes
    '(python-mode t)
    ;;and the keymaps:
    :keymaps
    '(python-mode-map)
    "e" 'live-py-set-version)
  (setq python-shell-interpreter "python3"))

  ;; Live Coding in Python
  (use-package live-py-mode :ensure t)

  (provide 'init-python)
