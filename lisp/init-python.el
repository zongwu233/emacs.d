;; -*- coding: utf-8; lexical-binding: t; -*-
  ;; Python Mode
  ;; Install: pip install pyflakes autopep8
  (use-package python
    :ensure t
    :defer t
    :mode ("\\.py\\'" . python-mode)
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

(use-package pyvenv
  :ensure t
  :config
  (setenv "WORKON_HOME" (expand-file-name "/usr/local/anaconda3/envs"))
  (setq python-shell-interpreter "python3")  ; （可选）更改解释器名字
  (pyvenv-mode t)
  ;; （可选）如果希望启动后激活 anaconda 的 base 环境，就使用如下的 hook
  ;; :hook
  ;; (python-mode . (lambda () (pyvenv-workon "..")))
)

    (provide 'init-python)
