;; -*- coding: utf-8; lexical-binding: t; -*-
;;; init-ai-local.el --- glue for the external ai-agent-in-emacs repo -*- lexical-binding: t; -*-

;; 通用实现在 ~/project/ai-agent-in-emacs/init-ai.el，本文件不重复其逻辑。
(add-to-list 'load-path (expand-file-name "ai-agent-in-emacs" "~/project/"))

(require 'init-ai)

;; 个人 relay providers：host 即 ~/.authinfo 的 machine 字段，login 选择条目，
;; password 即 API key。追加到仓库默认注册表（zhipu）之后并重建 backends。
(setq my/ai-providers
      (append my/ai-providers
              '((deepseek
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
                 :default local-model))))
(my/ai-build-backends)

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

(provide 'init-ai-local)
;;; init-ai-local.el ends here
