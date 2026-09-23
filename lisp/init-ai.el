;; -*- coding: utf-8; lexical-binding: t; -*-
;;; init-ai.el --- AI coding features -*- lexical-binding: t; -*-

;; gptel + gptel-agent + gptel-preset-collection. Default backend is Zhipu GLM
;; (coding-plan endpoint). Dedicated chat buffers use Org; replies are wrapped
;; in quote blocks. Inline completion is minuet on the same GLM endpoint.

(defconst my/gptel-zhipu-endpoint
  "https://open.bigmodel.cn/api/coding/paas/v4/chat/completions"
  "Zhipu GLM coding-plan endpoint (the local account is on zhipu-coding-plan).
If you switch to a standard API key, change back to
https://open.bigmodel.cn/api/paas/v4/chat/completions.")

(defcustom my/gptel-session-directory
  (locate-user-emacs-file "gptel-sessions/")
  "Directory for gptel sessions saved when Emacs exits."
  :type 'directory)

(defun my/gptel-session-file-name (buffer)
  "Return a unique session filename for BUFFER."
  (let* ((name (replace-regexp-in-string
                "\\`[-.]+\\|[-.]+\\'" ""
                (replace-regexp-in-string "[^[:alnum:]_.-]+" "-"
                                          (buffer-name buffer))))
         (base (format-time-string
                (concat "%Y%m%d-%H%M%S-" (if (string-empty-p name) "gptel" name))))
         (file (expand-file-name (concat base ".org") my/gptel-session-directory))
         (suffix 1))
    (while (file-exists-p file)
      (setq file (expand-file-name (format "%s-%d.org" base suffix)
                                   my/gptel-session-directory)
            suffix (1+ suffix)))
    file))

(defun my/gptel-save-unsaved-sessions-on-exit ()
  "Ask to save each unsaved gptel buffer before Emacs exits."
  (dolist (buffer (buffer-list))
    (with-current-buffer buffer
      (when (and gptel-mode (null buffer-file-name) (> (buffer-size) 0)
                 (y-or-n-p (format "Save gptel session %s? " (buffer-name))))
        (make-directory my/gptel-session-directory t)
        (set-visited-file-name (my/gptel-session-file-name buffer) t)
        (save-buffer)))))

(defun my/gptel-close-org-quote (beg end)
  "Insert #+END_QUOTE at END, matching the org-mode response prefix.

`gptel-post-response-functions' runs after the next prompt prefix is
inserted, but END is locked to the response tail (see
`gptel--handle-post-insert'), so this does not wrap the following prompt."
  (when (and end beg (not (eq beg end)) (derived-mode-p 'org-mode))
    (save-excursion
      (goto-char end)
      (unless (looking-at-p "[ \t]*#\\+END_QUOTE")
        (unless (bolp) (insert "\n"))
        (insert "#+END_QUOTE\n")))))

(defun my/gptel-plan ()
  "Open a gptel-agent session with the planning preset."
  (interactive)
  (require 'project)
  (gptel-agent (if-let ((proj (project-current)))
                   (project-root proj)
                 default-directory)
               'gptel-plan))

(use-package gptel
  :ensure t
  :demand t
  :custom
  (gptel-default-mode 'org-mode)
  (gptel-include-reasoning t)
  :config
  (require 'gptel-openai)
  ;; gptel requires host/path separation: a full-URL :endpoint stacks the default
  ;; host on top and trips the api.openai.com check, building a responses backend
  ;; by mistake (see gptel-make-openai).
  (defvar my/gptel-zhipu
    (gptel-make-openai "zhipu"
      :host "open.bigmodel.cn"
      :stream t
      :endpoint "/api/coding/paas/v4/chat/completions"
      ;; gptel's default --compressed negotiates gzip; some servers only flush
      ;; once the compressed buffer fills, so SSE arrives in one lump.
      :curl-args '("-H" "Accept-Encoding: identity")
      :key (lambda () (or (getenv "ZHIPUAI_API_KEY") "MISSING-ZHIPUAI-API-KEY"))
      :models '(glm-5.3-flash glm-4.6 glm-4.5 glm-4.5-air glm-4.5-flash)))
  (defvar my/gptel-deepseek
    (gptel-make-openai "deepseek"
      :host "api.deepseek.com"
      :stream t
      :endpoint "/v1/chat/completions"
      :curl-args '("-H" "Accept-Encoding: identity")
      :key (lambda () (or (getenv "DEEPSEEK_API_KEY") "MISSING-DEEPSEEK-API-KEY"))
      :models '(deepseek-chat deepseek-reasoner)))
  (defvar my/gptel-vllm
    (gptel-make-openai "vllm"
      :host "localhost:8000"
      :stream t
      :protocol "http"
      :endpoint "/v1/chat/completions"
      :key "EMPTY"
      :curl-args '("-H" "Accept-Encoding: identity")
      :models '(local-model)))
  (setq-default gptel-backend my/gptel-zhipu
                gptel-model 'glm-5.3-flash)
  ;; GLM 5.x thinks in interleaved mode; gptel's block parsing assumes reasoning
  ;; only precedes the answer. Disable thinking via Zhipu's official parameter.
  (put 'glm-5.3-flash :request-params '(:thinking (:type "disabled")))
  (setf (alist-get 'org-mode gptel-response-prefix-alist) "#+BEGIN_QUOTE\n")
  ;; Keep reasoning available from providers that return it; GLM thinking is
  ;; disabled above because gptel expects reasoning before the final answer.
  (set-face-attribute 'org-quote nil
                      :background "#21242b"
                      :foreground "#bbc2cf"
                      :box '(:line-width 4 :color "#51afef")
                      :extend t)
  (add-hook 'kill-emacs-hook #'my/gptel-save-unsaved-sessions-on-exit)
  ;; add-hook prepends: last add runs first. end-of-response must see original
  ;; BEG/END before #+END_QUOTE is inserted.
  (add-hook 'gptel-post-response-functions #'my/gptel-close-org-quote)
  (add-hook 'gptel-post-response-functions #'gptel-end-of-response)
  (add-hook 'after-init-hook
            (lambda ()
              (unless (or (getenv "ZHIPUAI_API_KEY") (getenv "DEEPSEEK_API_KEY"))
                (message "init-ai: ZHIPUAI_API_KEY / DEEPSEEK_API_KEY not set, AI features unavailable")))))

(use-package gptel-agent
  :ensure t
  :demand t
  :after gptel
  :config
  (gptel-agent-update))

(use-package gptel-preset-collection
  :quelpa (gptel-preset-collection
           :fetcher github
           :repo "karthink/gptel-preset-collection")
  :after gptel
  :demand t)

(use-package minuet
  :ensure t
  :demand t
  :config
  (setq minuet-provider 'openai-compatible
        minuet-auto-suggestion-debounce-delay 0.4
        minuet-auto-suggestion-throttle-delay 1.0)
  (plist-put minuet-openai-compatible-options :end-point my/gptel-zhipu-endpoint)
  (plist-put minuet-openai-compatible-options :api-key "ZHIPUAI_API_KEY")
  (plist-put minuet-openai-compatible-options :model "glm-5.3-flash")
  (plist-put minuet-openai-compatible-options :optional '(:thinking (:type "disabled")))
  (define-key minuet-active-mode-map (kbd "TAB") #'minuet-accept-suggestion)
  (define-key minuet-active-mode-map [tab] #'minuet-accept-suggestion)
  (add-hook 'prog-mode-hook #'minuet-auto-suggestion-mode)
  (add-hook 'minuet-active-mode-hook #'evil-normalize-keymaps))

;;; AI menu (SPC a)------------------------------------------------
(+general-global-menu! "ai" "a"
  "s" 'gptel
  "S" 'gptel-menu
  "a" 'gptel-agent
  "p" 'my/gptel-plan
  "C" 'gptel-agent-compact
  "i" 'minuet-show-suggestion)

(defconst my/gptel-init-version "1.0-gptel"
  "Config version probe: after restarting Emacs, M-: my/gptel-init-version should show this value.")

(provide 'init-ai)
