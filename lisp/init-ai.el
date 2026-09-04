;; -*- coding: utf-8; lexical-binding: t; -*-
;;; init-ai.el --- AI coding features -*- lexical-binding: t; -*-

;; The omy-ai library (sessions, agent wiring, workflow commands, backends,
;; chat UI) lives in the standalone emacs-agent repo; this file only installs
;; the package dependencies and wires keybindings.
(defconst my-emacs-agent-dir
  (file-name-as-directory (expand-file-name "emacs-agent" "~/project"))
  "Standalone emacs-agent repo providing the omy-ai library.")

(use-package gptel
  :ensure t
  :demand t)

(add-to-list 'load-path my-emacs-agent-dir)
(require 'omy-ai)

;;; Agent (gptel-agent provides the toolset and presets) ---------------------------
(use-package gptel-agent
  :ensure t
  :demand t
  :config
  ;; omy-ai unifies all gptel buffers on Org (see omy-ai.el)
  (add-to-list 'gptel-agent-dirs (expand-file-name "agents" my-emacs-agent-dir))
  (gptel-agent-update))

;;; Inline completion (minuet, on the GLM low-cost tier) -------------------------------
(use-package minuet
  :ensure t
  :demand t
  :config
  (setq minuet-provider 'openai-compatible
        minuet-auto-suggestion-debounce-delay 0.4
        minuet-auto-suggestion-throttle-delay 1.0)
  (plist-put minuet-openai-compatible-options :end-point omy-ai-zhipu-endpoint)
  ;; minuet accepts an environment variable name directly
  (plist-put minuet-openai-compatible-options :api-key "ZHIPUAI_API_KEY")
  (plist-put minuet-openai-compatible-options :model "glm-5.3-flash")
  ;; completion does not need thinking; disabling it lowers latency. Non-OpenAI-standard
  ;; parameters must go into :optional, which minuet merely splices into the request body
  (plist-put minuet-openai-compatible-options :optional '(:thinking (:type "disabled")))
  (define-key minuet-active-mode-map (kbd "TAB") #'minuet-accept-suggestion)
  (define-key minuet-active-mode-map [tab] #'minuet-accept-suggestion)
  (add-hook 'prog-mode-hook #'minuet-auto-suggestion-mode)

  (add-hook 'minuet-active-mode-hook #'evil-normalize-keymaps))

;;; AI menu (SPC a)------------------------------------------------
(+general-global-menu! "ai" "a"
  "s" 'omy-ai-session-new
  "S" 'omy-ai-session-open)
(general-def :keymaps '+general-global-ai-map "a" 'omy-ai-agent)
(general-def :keymaps '+general-global-ai-map
  "p" 'omy-ai-plan
  "c" 'omy-ai-commit
  "r" 'omy-ai-review
  "e" 'omy-ai-explain
  "f" 'omy-ai-refactor)
(general-def :keymaps '+general-global-ai-map "i" 'omy-ai-complete)
(general-def :keymaps '+general-global-ai-map "C" 'omy-ai-compact)

(defconst omy-ai-version "0.8-extlib"
  "Config version probe: after restarting Emacs, M-: omy-ai-version should show this value.")

(provide 'init-ai)
