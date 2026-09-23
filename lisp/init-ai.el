;; -*- coding: utf-8; lexical-binding: t; -*-
;;; init-ai.el --- AI coding features -*- lexical-binding: t; -*-

;; The omy-ai library (sessions, agent wiring, workflow commands, backends,
;; chat UI) lives in the standalone emacs-agent repo; this file only installs
;; the package dependencies and wires keybindings.  The repo is cloned from
;; the private GitHub remote on first start and cached under site-lisp/.
;; When git or SSH access to GitHub is unavailable, the rest of the config
;; still initializes; the AI menu and minuet stay disabled until it is fixed.
(defconst my-emacs-agent-repo "git@github.com:zongwu233/emacs-agent.git"
  "SSH remote of the private emacs-agent repo providing the omy-ai library.")

(defconst my-emacs-agent-dir
  (file-name-as-directory
   (expand-file-name "emacs-agent"
                     (expand-file-name "site-lisp" user-emacs-directory)))
  "Local checkout of the emacs-agent repo providing the omy-ai library.")

(defun my/bootstrap-emacs-agent ()
  "Ensure the emacs-agent repo is present in `my-emacs-agent-dir'.
Clone it from `my-emacs-agent-repo' when missing.  Return non-nil when
`omy-ai.el' is available afterwards."
  (cond
   ((file-exists-p (expand-file-name "omy-ai.el" my-emacs-agent-dir)) t)
   ((not (executable-find "git"))
    (warn "Cannot bootstrap emacs-agent: git not found in PATH")
    nil)
   (t
    (message "Cloning emacs-agent from %s..." my-emacs-agent-repo)
    (make-directory (file-name-directory (directory-file-name my-emacs-agent-dir)) t)
    (unless (zerop (call-process "git" nil
                                 (get-buffer-create "*emacs-agent-clone*") t
                                 "clone" my-emacs-agent-repo
                                 (directory-file-name my-emacs-agent-dir)))
      (warn "Failed to clone %s; check *emacs-agent-clone* and SSH access to GitHub"
            my-emacs-agent-repo))
    (file-exists-p (expand-file-name "omy-ai.el" my-emacs-agent-dir)))))

(use-package gptel
  :ensure t
  :demand t)

(defconst my/emacs-agent-loaded
  (and (my/bootstrap-emacs-agent)
       (progn (add-to-list 'load-path my-emacs-agent-dir) t)
       (require 'omy-ai nil t))
  "Non-nil after init when omy-ai was loaded from the emacs-agent repo.
Nil means the AI menu and minuet are disabled for this session.")

(unless my/emacs-agent-loaded
  (display-warning
   '(init-ai emacs-agent)
   (format "omy-ai library unavailable; the AI menu (SPC a) and minuet are disabled.
The repo is private and needs your GitHub SSH key.  Fix with:
  git clone %s %s
then restart Emacs."
           my-emacs-agent-repo (directory-file-name my-emacs-agent-dir))))

(when my/emacs-agent-loaded
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
  (general-def :keymaps '+general-global-ai-map "C" 'omy-ai-compact))

(defconst omy-ai-version "0.9.1-site-lisp"
  "Config version probe: after restarting Emacs, M-: omy-ai-version should show this value.")
(provide 'init-ai)
