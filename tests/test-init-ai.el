;;; -*- lexical-binding: t; -*-
;; Config-level tests for lisp/init-ai.el (gptel + GLM + minuet).
;; Runner: emacs --batch -l init.el -l tests/test-init-ai.el -f ert-run-tests-batch-and-exit
(require 'ert)
(require 'gptel)
(require 'minuet nil t)

(ert-deftest gptel/default-backend-is-zhipu-glm ()
  (should (eq (default-value 'gptel-backend) my/gptel-zhipu))
  (should (eq (default-value 'gptel-model) 'glm-5.3-flash))
  (should (equal (gptel-backend-host my/gptel-zhipu) "open.bigmodel.cn"))
  (should (equal (gptel-backend-endpoint my/gptel-zhipu)
                 "/api/coding/paas/v4/chat/completions")))

(ert-deftest gptel/org-mode-default-and-quote-prefix ()
  (should (eq gptel-default-mode 'org-mode))
  (should (equal (alist-get 'org-mode gptel-response-prefix-alist)
                 "#+BEGIN_QUOTE\n")))

(ert-deftest gptel/reasoning-enabled-and-quote-face-styled ()
  (should (eq gptel-include-reasoning t))
  (should (equal (face-attribute 'org-quote :background) "#21242b"))
  (should (equal (face-attribute 'org-quote :foreground) "#bbc2cf"))
  (should (equal (face-attribute 'org-quote :box)
                 '(:line-width 4 :color "#51afef")))
  (should (eq (face-attribute 'org-quote :extend) t)))

(ert-deftest gptel/exit-save-writes-session-to-configured-directory ()
  (let* ((my/gptel-session-directory (make-temp-file "gptel-sessions-" t))
         (buffer (generate-new-buffer "*gptel-test*"))
         saved-file)
    (unwind-protect
        (progn
          (with-current-buffer buffer
            (org-mode)
            (insert "* Chat\n#+BEGIN_QUOTE\nhello\n#+END_QUOTE\n")
            (setq-local gptel-mode t))
          (cl-letf (((symbol-function 'y-or-n-p) (lambda (&rest _) t)))
            (my/gptel-save-unsaved-sessions-on-exit))
          (setq saved-file (buffer-file-name buffer))
          (should (file-in-directory-p saved-file my/gptel-session-directory))
          (should (string-match-p "hello" (with-temp-buffer
                                             (insert-file-contents saved-file)
                                             (buffer-string)))))
      (when (buffer-live-p buffer) (kill-buffer buffer))
      (delete-directory my/gptel-session-directory t))))

(ert-deftest gptel/close-org-quote-inserts-end-at-response-end ()
  (with-temp-buffer
    (org-mode)
    (insert "* Chat\n#+BEGIN_QUOTE\nhello")
    (let ((beg (point-min))
          (end (point-max)))
      (insert "\n*** \n")                ; next prompt prefix, as gptel does
      (my/gptel-close-org-quote beg end)
      (should (equal (buffer-string)
                     "* Chat\n#+BEGIN_QUOTE\nhello\n#+END_QUOTE\n\n*** \n")))))

(ert-deftest gptel/post-response-hooks-registered ()
  (should (memq #'my/gptel-close-org-quote gptel-post-response-functions))
  (should (memq #'gptel-end-of-response gptel-post-response-functions))
  (should (memq #'my/gptel-save-unsaved-sessions-on-exit kill-emacs-hook)))
(ert-deftest gptel/glm-thinking-disabled ()
  (should (equal (get 'glm-5.3-flash :request-params)
                 '(:thinking (:type "disabled")))))

(ert-deftest gptel/agent-and-presets-loaded ()
  (should (featurep 'gptel-agent))
  (should (featurep 'gptel-preset-collection))
  (should (fboundp 'gptel-agent))
  (should (fboundp 'gptel-agent-compact)))

(ert-deftest gptel/minuet-provider-config ()
  (skip-unless (featurep 'minuet))
  (should (eq minuet-provider 'openai-compatible))
  (should (string-match-p "bigmodel"
                          (plist-get minuet-openai-compatible-options :end-point)))
  (should (equal "glm-5.3-flash"
                 (plist-get minuet-openai-compatible-options :model))))

(ert-deftest gptel/minuet-thinking-disabled-via-optional ()
  (skip-unless (featurep 'minuet))
  (should (equal '(:thinking (:type "disabled"))
                 (plist-get minuet-openai-compatible-options :optional)))
  (should-not (plist-get minuet-openai-compatible-options :thinking)))
