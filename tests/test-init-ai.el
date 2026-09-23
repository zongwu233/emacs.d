;;; -*- lexical-binding: t; -*-
;; Config-level tests for lisp/init-ai.el wiring that stays in .emacs.d
;; (minuet).  Library tests live in ~/.emacs.d/site-lisp/emacs-agent/tests/test-omy-ai.el.
;; Runner: emacs --batch -l init.el -l tests/test-init-ai.el -f ert-run-tests-batch-and-exit
(require 'ert)
(require 'minuet nil t)

(ert-deftest omy-ai/minuet-provider-config ()
  (skip-unless (and my/emacs-agent-loaded (featurep 'minuet)))
  (should (featurep 'minuet))
  (should (eq minuet-provider 'openai-compatible))
  (should (string-match-p "bigmodel"
                          (plist-get minuet-openai-compatible-options :end-point)))
  (should (equal "glm-5.3-flash"
                 (plist-get minuet-openai-compatible-options :model))))

(ert-deftest omy-ai/minuet-thinking-disabled-via-optional ()
  (skip-unless (and my/emacs-agent-loaded (featurep 'minuet)))
  ;; minuet 的非标准参数必须经 :optional 拼进请求体，而非顶层键
  (should (equal '(:thinking (:type "disabled"))
                 (plist-get minuet-openai-compatible-options :optional)))
  (should-not (plist-get minuet-openai-compatible-options :thinking)))

(ert-deftest omy-ai/library-agents-dir-registered ()
  (skip-unless my/emacs-agent-loaded)
  ;; init-ai 把 emacs-agent 仓库的 agents/ 目录挂进 gptel-agent-dirs
  (should (member (expand-file-name "agents" my-emacs-agent-dir)
                  gptel-agent-dirs)))
