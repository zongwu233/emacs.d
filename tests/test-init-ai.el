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

(ert-deftest gptel/new-session-display-uses-full-frame ()
  (should (equal gptel-display-buffer-action
                 '(display-buffer-full-frame))))

(ert-deftest gptel/session-buffers-use-full-width-soft-wrapping ()
  (with-temp-buffer
    (org-mode)
    (setq-local truncate-lines t
                word-wrap nil)
    (let ((visual-line-mode-hook
           (cons 'visual-fill-column-mode visual-line-mode-hook)))
      (run-hooks 'gptel-mode-hook))
    (should visual-line-mode)
    (should-not truncate-lines)
    (should word-wrap)
    (should-not (bound-and-true-p visual-fill-column-mode))
    (should-not visual-fill-column-center-text)
    (should-not visual-fill-column-width)))

(ert-deftest gptel/open-session-restores-native-properties-and-styles ()
  (let* ((my/gptel-session-directory (make-temp-file "gptel-sessions-" t))
         (file (expand-file-name "old-session.org" my/gptel-session-directory))
         buffer)
    (unwind-protect
        (progn
          (write-region
           (concat ":PROPERTIES:\n"
                   ":GPTEL_BACKEND: zhipu\n"
                   ":GPTEL_MODEL: glm-5.3-flash\n"
                   ":GPTEL_BOUNDS: ((response (130 172)))\n"
                   ":END:\n\n"
                   "* Chat\n#+BEGIN_QUOTE\n"
                   "AI response line one\nAI response line two\n"
                   "#+END_QUOTE\n\n*** Prompt\n")
           nil file)
          (cl-letf (((symbol-function 'completing-read)
                     (lambda (&rest _) "old-session.org")))
            (setq buffer (my/gptel-open-session)))
          (with-current-buffer buffer
            (should gptel-mode)
            (should (eq gptel-backend my/gptel-zhipu))
            (should (eq gptel-model 'glm-5.3-flash))
            (should visual-line-mode)
            (should-not truncate-lines)
            (should word-wrap)
            (should-not (bound-and-true-p visual-fill-column-mode))
            (goto-char (point-min))
            (search-forward "AI response line one")
            (should gptel-highlight-mode)
            (should (eq (get-char-property (line-beginning-position) 'gptel)
                        'response))
            (should (get-char-property (line-beginning-position) 'line-prefix))))
      (when (buffer-live-p buffer) (kill-buffer buffer))
      (delete-directory my/gptel-session-directory t))))

(ert-deftest gptel/agent-confirms-destructive-bash-only ()
  (should (eq gptel-confirm-tool-calls 'auto))
  (should (my/gptel-agent-confirm-bash "rm -rf /tmp/example"))
  (should (my/gptel-agent-confirm-bash "git reset --hard HEAD"))
  (should (my/gptel-agent-confirm-bash "find . -delete"))
  (should-not (my/gptel-agent-confirm-bash "git status --short"))
  (should-not (my/gptel-agent-confirm-bash "printf 'ok\\n'"))
  (should-not (gptel-tool-confirm (gptel-get-tool "Edit")))
  (should-not (gptel-tool-confirm (gptel-get-tool "Read")))
  (should (eq (gptel-tool-confirm (gptel-get-tool "Write"))
              #'my/gptel-agent-confirm-write))
  (should-not (gptel-tool-confirm (gptel-get-tool "Eval")))
  (should (gptel-tool-confirm (gptel-get-tool "Agent")))
  (let ((directory (make-temp-file "gptel-write-confirm-" t)))
    (unwind-protect
        (progn
          (should-not (funcall (gptel-tool-confirm (gptel-get-tool "Write"))
                               directory "new.org" "text"))
          (write-region "old" nil (expand-file-name "old.org" directory))
          (should (funcall (gptel-tool-confirm (gptel-get-tool "Write"))
                           directory "old.org" "new"))
          (delete-file (expand-file-name "old.org" directory)))
      (delete-directory directory t))))

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

(ert-deftest gptel/quote-boundary-preserves-org-rendering-and-folding ()
  (with-temp-buffer
    (org-mode)
    (gptel-mode 1)
    (insert "* Chat\n#+BEGIN_QUOTE\n")
    (let ((beg (point)))
      (insert (propertize
               "* AI heading\n#+BEGIN_SRC emacs-lisp\n(message \"ok\")\n#+END_SRC\n"
               'gptel 'response))
      (let ((end (point)))
        (insert "\n*** Next prompt\n")
        (my/gptel-close-org-quote beg end)
        (gptel-highlight--update beg (point-max))
        (font-lock-ensure)
        (goto-char beg)
        (should (memq 'org-level-1 (get-text-property (point) 'face)))
        (should (get-char-property (point) 'line-prefix))
        (search-forward "#+BEGIN_SRC")
        (beginning-of-line)
        (should (eq (get-text-property (point) 'face) 'org-block-begin-line))
        (search-forward "#+END_QUOTE")
        (beginning-of-line)
        (should-not (get-char-property (point) 'line-prefix))
        (should-not (get-char-property (point) 'gptel))
        (goto-char (point-min))
        (search-forward "#+BEGIN_QUOTE")
        (beginning-of-line)
        (org-cycle)
        (should (org-fold-folded-p beg 'block))
        (org-cycle)
        (should-not (org-fold-folded-p beg 'block))))))

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
