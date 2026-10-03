;; -*- coding: utf-8; lexical-binding: t; -*-
;;; init-ai.el --- AI coding features -*- lexical-binding: t; -*-

;; gptel + gptel-agent + gptel-preset-collection. Backends are generated from
;; `my/ai-providers'. Provider hosts are the machine fields of ~/.authinfo
;; (machine = API base_url host, login = entry, password = API key); only zhipu
;; (no authinfo entry) reads its key from the environment. Dedicated chat
;; buffers use Org and gptel's response highlight. Inline completion is minuet
;; on the same GLM endpoint.

(defconst my/gptel-zhipu-endpoint
  "https://open.bigmodel.cn/api/coding/paas/v4/chat/completions"
  "Zhipu GLM coding-plan endpoint (the local account is on zhipu-coding-plan).
If you switch to a standard API key, change back to
https://open.bigmodel.cn/api/paas/v4/chat/completions.")

(defvar my/ai-backends nil
  "Provider name -> gptel backend, built by `my/ai-build-backends'.")

(defcustom my/ai-providers
  '((zhipu
     :host "open.bigmodel.cn"
     :endpoint "/api/coding/paas/v4/chat/completions"
     :auth (:env "ZHIPUAI_API_KEY")
     :models (glm-5.3-flash glm-4.6 glm-4.5 glm-4.5-air glm-4.5-flash)
     :default glm-5.3-flash)
    (deepseek
     :host "RELAY.EXAMPLE" :login "deepseek-REDACTED"
     :models (deepseek-v4.1-flash deepseek-v4.1-flash-0910
              deepseek-v4-flash deepseek-v4-flash-0731
              deepseek-v4-pro deepseek-v4-pro-0813)
     :default deepseek-v4.1-flash)
    (gemini
     :host "RELAY.EXAMPLE" :login "gemini-REDACTED"
     :models (gemini-3.1-pro gemini-3.1-pro-high gemini-3.1-pro-low
              gemini-3.1-flash-lite gemini-3.5-flash
              gemini-3-pro-high gemini-3-pro-preview gemini-3-flash
              claude-sonnet-4-6 claude-opus-4-6-thinking)
     :default gemini-3.1-pro)
    (grok
     :host "RELAY.EXAMPLE" :login "xai-REDACTED"
     :models (grok-4.5-latest grok-4.5 grok-4.3-latest grok-4.3
              grok-4.20-reasoning grok-4.20-non-reasoning
              grok-4.20-multi-agent-latest grok-3-mini grok-3-mini-fast)
     :default grok-4.5-latest)
    (gpt
     :host "RELAY.EXAMPLE" :login "openai-REDACTED"
     :models (gpt-6 gpt-6-astra gpt-6-astra-direct gpt-6-sol gpt-6.1-sol
              gpt-5.6 gpt-5.6-sol gpt-5.6-terra gpt-5.5
              gpt-5.4 gpt-5.4-mini gpt-5.3-codex-spark)
     :default gpt-5.6)
    (gpt-REDACTED
     :host "RELAY.EXAMPLE" :login "REDACTED"
     :models (gpt-6 gpt-6-astra gpt-6-luna gpt-6-sol
              gpt-5.6 gpt-5.6-sol gpt-5.6-terra gpt-5.5
              gpt-5.4 gpt-5.4-mini gpt-5.3-codex-spark)
     :default gpt-5.6)
    (gpt-REDACTED
     :host "RELAY.EXAMPLE" :login "REDACTED"
     :models (chat-latest gpt-6.1-sol gpt-6-astra gpt-6-luna gpt-6-sol
              gpt-5.6-luna gpt-5.6-sol gpt-5.6-terra gpt-5.5 gpt-4.1-mini)
     :default gpt-5.5)
    (REDACTED
     :host "LOCAL.EXAMPLE" :login "REDACTED"
     ;; Probe 2026-09-30: /v1/models returned empty and chat answered
     ;; 401 Invalid API Key. Fill :models once the key works.
     :models nil)
    (local
     :host "localhost:9000" :login "REDACTED" :protocol "http"
     :models (local-model)
     :default local-model))
  "AI provider registry; `my/ai-build-backends' makes one backend per entry.
:host     API base_url host = the machine field of ~/.authinfo.
:login    authinfo login whose password is the API key.
:auth     (:env VAR) reads the key from VAR (zhipu has no authinfo entry).
:endpoint chat path, default \"/v1/chat/completions\" (OpenAI-compatible).
:protocol \"https\" (default) or \"http\" for local servers.
:models   model symbols offered in the menu.
:default  preselected model."
  :type '(repeat (cons symbol plist)))

(defun my/ai-provider-spec (name)
  "Return the `my/ai-providers' plist of provider NAME."
  (cdr (assq name my/ai-providers)))

(defun my/ai-backend (name)
  "Return the gptel backend built for provider NAME, or nil."
  (alist-get name my/ai-backends))

(defun my/ai-provider-default-model (name)
  "Default model symbol configured for provider NAME."
  (let ((spec (my/ai-provider-spec name)))
    (or (plist-get spec :default)
        (car (plist-get spec :models)))))

(defun my/ai-provider-key (spec)
  "Resolve the API key of provider SPEC, or nil.
The :auth environment variable wins, then the authinfo password of
:login on :host (see `auth-source-search')."
  (or (when-let ((var (plist-get (plist-get spec :auth) :env)))
        (getenv var))
      (when-let ((login (plist-get spec :login)))
        (require 'auth-source)
        (let* ((entry (car (auth-source-search
                            :max 1
                            :host (plist-get spec :host)
                            :user login
                            :require '(:secret))))
               (secret (plist-get entry :secret)))
          (cond ((functionp secret) (funcall secret))
                ((stringp secret) secret))))))

(defun my/ai-build-backends ()
  "Register one OpenAI-compatible gptel backend per `my/ai-providers' entry.
Every configured provider exposes an OpenAI-compatible /v1 API, so a
single backend type covers them all."
  (setq my/ai-backends nil)
  (dolist (entry my/ai-providers)
    (let ((name (car entry))
          (spec (cdr entry)))
      (push
       (cons name
             (gptel-make-openai
                 (symbol-name name)
               :host (plist-get spec :host)
               :protocol (or (plist-get spec :protocol) "https")
               :stream t
               :endpoint (or (plist-get spec :endpoint)
                             "/v1/chat/completions")
               ;; gptel 的默认 --compressed 协商 gzip；部分服务器压缩缓冲区
               ;; 填满才 flush，SSE 会整块到达。
               :curl-args '("-H" "Accept-Encoding: identity")
               :key (lambda () (my/ai-provider-key spec))
               :models (plist-get spec :models)))
       my/ai-backends)))
  (setq my/ai-backends (nreverse my/ai-backends)))

(defun my/ai-check-keys ()
  "Report providers whose API key cannot be resolved."
  (let ((missing (cl-loop for (name . spec) in my/ai-providers
                          unless (my/ai-provider-key spec)
                          collect name)))
    (when missing
      (message "init-ai: no API key resolved for: %s"
               (mapconcat #'symbol-name missing ", ")))))

(defun my/ai-select-provider (provider)
  "Prompt for PROVIDER and a model, then set them as the gptel default.
Affects new gptel sessions; `gptel-menu' switches per buffer."
  (interactive
   (list (intern
          (completing-read "AI provider: "
                           (mapcar (lambda (e) (symbol-name (car e)))
                                   my/ai-backends)
                           nil t))))
  (let ((backend (my/ai-backend provider)))
    (unless backend
      (user-error "No AI provider backend: %s" provider))
    (let* ((models (mapcar #'symbol-name (gptel-backend-models backend)))
           (default (my/ai-provider-default-model provider))
           (model (completing-read
                   (format "Model for %s: " provider)
                   models nil t nil nil
                   (and (member default models) default))))
      (setq-default gptel-backend backend
                    gptel-model (intern model))
      (message "init-ai: default provider %s, model %s" provider model))))

(defcustom my/gptel-session-directory
  (expand-file-name "~/org/gptel/")
  "Directory for gptel sessions shared by the user's Org workspace."
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

(defun my/gptel-open-session ()
  "Open a saved gptel session and let gptel restore its state."
  (interactive)
  (unless (file-directory-p my/gptel-session-directory)
    (user-error "No gptel session directory: %s" my/gptel-session-directory))
  (let* ((files (directory-files my/gptel-session-directory nil
                                 "\\.\\(org\\|md\\)\\'" t))
         (file (completing-read "Open gptel session: " files nil t)))
    (find-file (expand-file-name file my/gptel-session-directory))
    (gptel-mode 1)
    (current-buffer)))
(defun my/gptel-setup-display ()
  "Enable window-width soft wrapping without visual-fill-column margins."
  (visual-line-mode 1)
  (setq-local truncate-lines nil
              word-wrap t)
  (when (and (boundp 'visual-fill-column-mode)
             visual-fill-column-mode)
    (visual-fill-column-mode -1))
  (when (boundp 'visual-fill-column-center-text)
    (setq-local visual-fill-column-center-text nil))
  (when (boundp 'visual-fill-column-width)
    (setq-local visual-fill-column-width nil))
  ;; gptel-highlight 的 margin 方法会修改 window margin 引发全窗口重排，
  ;; Emacs 29.4 GUI 下与 redisplay 相互作用可死循环（auth-source.org 复现）。
  ;; 改用 fringe（highlight--decorate 的 fringe 路径实测稳定），标记视觉保留。
  (gptel-highlight-mode 1)
  (make-local-variable 'mode-line-misc-info)
  (add-to-list 'mode-line-misc-info
               '(:eval (when (and gptel-mode
                                  (caddr gptel--token-usage-strings))
                         (concat " " (caddr gptel--token-usage-strings))))
               t))

(defun my/gptel-plan ()
  "Open a gptel-agent session with the planning preset."
  (interactive)
  (require 'project)
  (gptel-agent (if-let ((proj (project-current)))
                   (project-root proj)
                 default-directory)
               'gptel-plan))

(defun my/gptel-agent-confirm-bash (command)
  "Ask before Bash COMMANDS with common destructive operations."
  (string-match-p
   "\\_<\\(rm\\|rmdir\\|shred\\|unlink\\|wipefs\\|dd\\|truncate\\|mkfs[^[:space:]]*\\)\\_>\\|\\_<find\\_>.*\\_<-delete\\_>\\|\\_<git[[:space:]]+\\(clean\\|reset\\|restore\\)\\_>.*\\(--hard\\|-[[:alnum:]]*f\\|--staged\\|--worktree\\)"
   command))

(defun my/gptel-agent-confirm-write (path filename _content)
  "Ask before the Write tool overwrites PATH/FILENAME."
  (file-exists-p (expand-file-name filename path)))

(defun my/gptel-agent-configure-tool-confirmation ()
  "Allow routine agent tools and confirm destructive or privileged actions."
  (setq gptel-confirm-tool-calls 'auto)
  (dolist (name '("Bash" "Mkdir" "Edit" "Insert" "Write" "Eval" "Agent"))
    (when-let ((tool (gptel-get-tool name)))
      (let ((confirm
             (pcase name
               ("Bash" #'my/gptel-agent-confirm-bash)
               ("Write" #'my/gptel-agent-confirm-write)
               ("Agent" t)
               (_ nil))))
        (apply #'gptel-make-tool
               (append (cl-loop for slot in '(function name description args async category include)
                                for value = (pcase slot
                                              ('function (gptel-tool-function tool))
                                              ('name (gptel-tool-name tool))
                                              ('description (gptel-tool-description tool))
                                              ('args (gptel-tool-args tool))
                                              ('async (gptel-tool-async tool))
                                              ('category (gptel-tool-category tool))
                                              ('include (gptel-tool-include tool)))
                                append (list (intern (concat ":" (symbol-name slot))) value))
                       (list :confirm confirm)))))))
(use-package gptel
  :ensure t
  :demand t
  :custom
  (gptel-default-mode 'org-mode)
  (gptel-include-reasoning t)
  (gptel-display-buffer-action '(display-buffer-full-frame))
  ;; fringe/margin 方法通过 line-prefix/wrap-prefix overlay 实现标记，
  ;; 但首次激活后 redisplay 不会重算这些行的折行布局，导致 gptel 会话
  ;; 文本不自动换行（切换 gptel-mode 强制重排版才恢复，Linux/Win 均复现）。
  ;; 改用 face 方法：纯文本高亮，无 overlay 前缀，无此问题。
  (gptel-highlight-methods '(face))
  (gptel-cache t)
  (gptel-use-header-line nil)
  :config
  (require 'gptel-openai)
  (setq gptel-expert-commands t)

  ;; gptel requires host/path separation: a full-URL :endpoint stacks the default
  ;; host on top and trips the api.openai.com check, building a responses backend
  ;; by mistake (see gptel-make-openai).
  (my/ai-build-backends)
  (setq-default gptel-backend (my/ai-backend 'zhipu)
                gptel-model 'glm-5.3-flash)
  ;; GLM 5.x thinks in interleaved mode; gptel's block parsing assumes reasoning
  ;; only precedes the answer. Disable thinking via Zhipu's official parameter.
  (put 'glm-5.3-flash :request-params '(:thinking (:type "disabled")))
  (add-hook 'kill-emacs-hook #'my/gptel-save-unsaved-sessions-on-exit)
  (add-hook 'gptel-post-response-functions #'gptel-end-of-response)
  (add-hook 'gptel-mode-hook #'my/gptel-setup-display)
  (add-hook 'after-init-hook #'my/ai-check-keys))

(use-package gptel-agent
  :ensure t
  :demand t
  :after gptel
  :config
  (gptel-agent-update)
  (my/gptel-agent-configure-tool-confirmation))

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
  "o" 'my/gptel-open-session
  "S" 'gptel-menu
  "P" 'my/ai-select-provider
  "a" 'gptel-agent
  "p" 'my/gptel-plan
  "C" 'gptel-agent-compact
  "i" 'minuet-show-suggestion)

(defconst my/gptel-init-version "2.0-multi-provider"
  "Config version probe: after restarting Emacs, M-: my/gptel-init-version should show this value.")

(provide 'init-ai)
