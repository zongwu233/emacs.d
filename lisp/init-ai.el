;; -*- coding: utf-8; lexical-binding: t; -*-
;;; init-ai.el --- AI coding features -*- lexical-binding: t; -*-

;; site-lisp is not on load-path by default; omy-ai.el lives there
(let ((dir (locate-user-emacs-file "site-lisp")))
  (add-to-list 'load-path (file-name-as-directory dir)))

(use-package gptel
  :ensure t
  :demand t)

(require 'omy-ai)
;;; Backend registration (OpenAI-compatible protocol) ------------------------------------
(defvar omy-ai-zhipu-endpoint
  "https://open.bigmodel.cn/api/coding/paas/v4/chat/completions"
  "Zhipu GLM coding-plan endpoint (the local account is on zhipu-coding-plan).
If you switch to a standard API key, change back to
https://open.bigmodel.cn/api/paas/v4/chat/completions.")

;; gptel requires host/path separation: a full-URL :endpoint stacks the default
;; host on top and trips the api.openai.com check, building a responses backend
;; by mistake (see the gptel-make-openai source)
(defvar omy-ai--zhipu
  (gptel-make-openai "zhipu"
    :host "open.bigmodel.cn"
    :stream t
    :endpoint "/api/coding/paas/v4/chat/completions"
    ;; gptel's default --compressed negotiates gzip; some servers only flush once
    ;; the compressed buffer fills, so SSE arrives in one lump. Explicit identity
    ;; keeps streaming chunk by chunk
    :curl-args '("-H" "Accept-Encoding: identity")
    :key (lambda () (or (getenv "ZHIPUAI_API_KEY") "MISSING-ZHIPUAI-API-KEY"))
    :models '(glm-5.3-flash glm-4.6 glm-4.5 glm-4.5-air glm-4.5-flash)))

(defvar omy-ai--deepseek
  (gptel-make-openai "deepseek"
    :host "api.deepseek.com"
    :stream t
    :endpoint "/v1/chat/completions"
    :curl-args '("-H" "Accept-Encoding: identity")
    :key (lambda () (or (getenv "DEEPSEEK_API_KEY") "MISSING-DEEPSEEK-API-KEY"))
    :models '(deepseek-chat deepseek-reasoner)))

(defvar omy-ai--vllm
  (gptel-make-openai "vllm"
    :host "localhost:8000"
    :stream t
    :protocol "http"
    :endpoint "/v1/chat/completions"
    :key "EMPTY"
    :curl-args '("-H" "Accept-Encoding: identity")
    ;; After the local vLLM starts, model names follow /v1/models; switch temporarily via gptel-menu
    :models '(local-model)))

(setq-default gptel-backend omy-ai--zhipu
              gptel-model 'glm-5.3-flash
              ;; reasoning blocks enter the buffer but not later turns (see the defcustom doc)
              gptel-include-reasoning 'ignore)

;; GLM 5.x thinks in interleaved mode (reasoning alternates with the answer),
;; while gptel's block parsing assumes reasoning only precedes the answer;
;; interleaved streams would wrap the answer in begin_reasoning blocks.
;; Disable thinking via Zhipu's official parameter (supported on GLM-4.5+):
(put 'glm-5.3-flash :request-params '(:thinking (:type "disabled")))

(defun omy-ai--backend-key-missing-p ()
  "Return a hint string when both API key environment variables are missing, else nil."
  (and (not (getenv "ZHIPUAI_API_KEY"))
       (not (getenv "DEEPSEEK_API_KEY"))
       "omy-ai: ZHIPUAI_API_KEY / DEEPSEEK_API_KEY not set, AI features unavailable"))

(add-hook 'after-init-hook
          (lambda () (when (omy-ai--backend-key-missing-p)
                       (message "%s" (omy-ai--backend-key-missing-p)))))

;;; Agent (gptel-agent provides the toolset and presets) ---------------------------
(use-package gptel-agent
  :ensure t
  :demand t
  :config
  (add-to-list 'gptel-agent-dirs (expand-file-name "agents" user-emacs-directory))
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
;;; Chat UI polish (gptel buffers only) ---------------------------

;; Symbol/emoji font fallback on Windows: symbols and emoji in AI output rely on
;; system fonts; missing glyphs render as boxes with code points
(when (eq system-type 'windows-nt)
  (set-fontset-font t 'symbol (font-spec :family "Segoe UI Symbol") nil 'prepend)
  (set-fontset-font t '(#x1F300 . #x1FAFF)
                    (font-spec :family "Segoe UI Emoji") nil 'prepend))

(defun omy-ai--chat-ui ()
  "Buffer-local polish for gptel chat buffers: proportional font, soft wrapping,
dimmed code-block delimiter lines. Only org buffers are affected - gptel-agent
session buffers are not org-mode and are left alone.
Does not take over heading rendering: keeps gptel's \"*** \" user prompt
headings and the native Org / org-superstar look."
  (when (derived-mode-p 'org-mode)
    (setq-local gptel-org-convert-response nil) ;keep AI output as native markdown
    (variable-pitch-mode 1)
    (visual-line-mode 1)
    ;; visual-fill-column-mode is hooked globally on visual-line-mode-hook (init-ui's
    ;; Org reading layout), squeezing wrapped lines into fill-column and maybe centering;
    ;; the chat window should span the full visual width, so explicitly turn off the
    ;; mode that this hook pulls in
    (when (bound-and-true-p visual-fill-column-mode)
      (visual-fill-column-mode -1))
    (when (fboundp 'company-mode) (company-mode -1))
    ;; streaming insertion follows the visible window; once the response is written,
    ;; expand this reply's reasoning blocks and bring the window to point-max, with
    ;; point landing on gptel's next prompt
    (add-hook 'gptel-post-stream-hook #'omy-ai--follow-stream nil t)
    (add-hook 'gptel-post-response-functions #'omy-ai--complete-response nil t)
    (let ((small-height (round (* 0.8 (face-attribute 'default :height)))))
      (face-remap-add-relative 'org-block-begin-line
                               :height small-height :foreground "gray50")
      (face-remap-add-relative 'org-block-end-line
                               :height small-height :foreground "gray50"))))

(add-hook 'gptel-mode-hook #'omy-ai--chat-ui)


(defun omy-ai-debug-layout ()
  "Diagnose the current session window's margins and wrapping settings."
  (interactive)
  (princ (format
          "LAYOUT: margins=%S width=%s fill=%s center=%s vfc=%s vlp=%s indent=%s\n"
          (window-margins) (window-width) fill-column
          visual-fill-column-center-text
          (bound-and-true-p visual-fill-column-mode)
          visual-line-mode
          (bound-and-true-p org-indent-mode))))

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

(defun omy-ai-complete ()
  "Manually trigger one inline completion suggestion."
  (interactive)
  (minuet-show-suggestion))

(general-def :keymaps '+general-global-ai-map "i" 'omy-ai-complete)
(general-def :keymaps '+general-global-ai-map "C" 'omy-ai-compact)
(defconst omy-ai-version "0.5-winfix"
  "Config version probe: after restarting Emacs, M-: omy-ai-version should show this value.")

(provide 'init-ai)
