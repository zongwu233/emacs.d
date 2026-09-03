;;; -*- lexical-binding: t; -*-
(require 'ert)
(add-to-list 'load-path (expand-file-name "site-lisp" user-emacs-directory))
(require 'omy-ai)

(ert-deftest omy-ai/backends-registered ()
  (should (string= "zhipu" (gptel-backend-name omy-ai--zhipu)))
  (should (string= "deepseek" (gptel-backend-name omy-ai--deepseek)))
  (should (string= "vllm" (gptel-backend-name omy-ai--vllm)))
  (should (eq (type-of omy-ai--zhipu) 'gptel-openai))
  (should (string= "https://open.bigmodel.cn/api/coding/paas/v4/chat/completions"
                   (gptel-backend-url omy-ai--zhipu)))
  (should (string= "https://api.deepseek.com/v1/chat/completions"
                   (gptel-backend-url omy-ai--deepseek)))
  (should (string= "http://localhost:8000/v1/chat/completions"
                   (gptel-backend-url omy-ai--vllm))))

(ert-deftest omy-ai/default-backend-and-model ()
  (should (eq (default-value 'gptel-backend) omy-ai--zhipu))
  (should (eq (default-value 'gptel-model) 'glm-5.3-flash)))

;; canary: pins gptel's own defcustom default ('ignore) — upstream drift alarm, not a config test
(ert-deftest omy-ai/reasoning-ignore-by-default ()
  (should (eq (default-value 'gptel-include-reasoning) 'ignore)))

(ert-deftest omy-ai/slug ()
  (should (equal "my-proj" (omy-ai--slug "My Proj")))
  (should (equal "default" (omy-ai--slug "!!!")))
  (should (equal "airspace-query" (omy-ai--slug "airspace-query"))))

(ert-deftest omy-ai/session-file-under-project-dir ()
  (let* ((omy-ai-sessions-dir (make-temp-file "sessions" t))
         (default-directory (file-name-as-directory (make-temp-file "proj" t)))
         (path (omy-ai--session-file "fix bug")))
    (should (string-match-p "-fix-bug\\.org$" path))
    (should (file-directory-p (file-name-directory path)))))

(ert-deftest omy-ai/session-new-ends-at-gptel-prompt ()
  ;; 新会话：gptel 开启，光标落在动态 gptel org 提示前缀（"*** "）之后。
  ;; 清理只删捕获的临时目录，绝不依赖动态 current default-directory
  (let* ((sessions-dir (make-temp-file "sessions" t))
         (project-dir (file-name-as-directory (make-temp-file "proj" t)))
         (omy-ai-sessions-dir sessions-dir)
         (default-directory project-dir)
         buffer)
    (unwind-protect
        (progn
          (omy-ai-session-new "chat flow")
          (setq buffer (current-buffer))
          (should (buffer-file-name buffer))
          (should (string-prefix-p (file-name-as-directory sessions-dir)
                                   (buffer-file-name buffer)))
          (should (buffer-local-value 'gptel-mode buffer))
          (should (provided-mode-derived-p (buffer-local-value 'major-mode buffer)
                                           'org-mode))
          (with-current-buffer buffer
            (let ((prefix (gptel-prompt-prefix-string)))
              (should (string= "*** " prefix))
              (should (string= prefix
                               (buffer-substring-no-properties
                                (- (point-max) (length prefix)) (point-max))))
              (should (= (point) (point-max))))))
      (when (buffer-live-p buffer) (kill-buffer buffer))
      (delete-directory sessions-dir 'recursive)
      (delete-directory (directory-file-name project-dir) 'recursive))))

(ert-deftest omy-ai/inside-git-detection ()
  (let* ((repo (file-name-as-directory (make-temp-file "repo" t)))
         (plain (file-name-as-directory (make-temp-file "plain" t))))
    (let ((default-directory repo))
      (call-process "git" nil nil nil "init")
      (should (omy-ai--inside-git-p repo)))
    (should-not (omy-ai--inside-git-p plain))))

(ert-deftest omy-ai/rules-path-found-or-nil ()
  (let* ((dir (file-name-as-directory (make-temp-file "proj" t))))
    (should-not (omy-ai--rules-path dir))
    (write-region "# rules\n" nil (expand-file-name "AGENTS.md" dir))
    (should (string-match-p "AGENTS\\.md$" (omy-ai--rules-path dir)))))

(ert-deftest omy-ai/agent-command-smoke ()
  (let* ((repo (file-name-as-directory (make-temp-file "repo" t)))
         (default-directory repo))
    (call-process "git" nil nil nil "init")
    (write-region "# rules\n" nil (expand-file-name "AGENTS.md" repo))
    (let ((expected (expand-file-name "AGENTS.md" (omy-ai--project-root))))
      (unwind-protect
          (progn
            (omy-ai-agent)
            (let ((buf (seq-find
                        (lambda (b) (string-prefix-p "*gptel-agent:" (buffer-name b)))
                        (buffer-list))))
              (should buf)
              (should (buffer-local-value 'gptel-mode buf))
              (should (local-variable-p 'gptel-confirm-tool-calls buf))
              (should (null (buffer-local-value 'gptel-confirm-tool-calls buf)))
              (should (member (list expected)
                              (buffer-local-value 'gptel-context buf)))
              (should (null (default-value 'gptel-context)))))
        ;; hermetic cleanup: window and agent buffer
        (dolist (b (buffer-list))
          (when (string-prefix-p "*gptel-agent:" (buffer-name b))
            (let ((w (get-buffer-window b)))
              (when (window-live-p w) (ignore-errors (delete-window w))))
            (kill-buffer b)))))))

(ert-deftest omy-ai/plan-command-uses-plan-preset ()
  (let* ((repo (file-name-as-directory (make-temp-file "planrepo" t)))
         (default-directory repo))
    (call-process "git" nil nil nil "init")
    (write-region "# rules\n" nil (expand-file-name "AGENTS.md" repo))
    (let ((expected (expand-file-name "AGENTS.md" (omy-ai--project-root))))
      (unwind-protect
          (progn
            (omy-ai-plan)
            (let ((buf (seq-find
                        (lambda (b) (string-prefix-p "*gptel-agent:" (buffer-name b)))
                        (buffer-list))))
              (should buf)
              (should (buffer-local-value 'gptel-mode buf))
              ;; plan preset: read-only toolset only, no write-class tools
              (let ((tools (mapcar #'gptel-tool-name
                                   (buffer-local-value 'gptel-tools buf))))
                (should (member "Read" tools))
                (should-not (member "Write" tools))
                (should-not (member "Edit" tools))
                (should-not (member "Bash" tools)))
              (let ((sys (buffer-local-value 'gptel--system-message buf)))
                (should (string-match-p "planning agent" sys)))
              ;; session-level policy still applies: git repo -> no per-call
              ;; confirmation, AGENTS.md injected as live context
              (should (local-variable-p 'gptel-confirm-tool-calls buf))
              (should (null (buffer-local-value 'gptel-confirm-tool-calls buf)))
              (should (member (list expected)
                              (buffer-local-value 'gptel-context buf)))
              (should (null (default-value 'gptel-context)))))
        ;; hermetic cleanup: window and agent buffer
        (dolist (b (buffer-list))
          (when (string-prefix-p "*gptel-agent:" (buffer-name b))
            (let ((w (get-buffer-window b)))
              (when (window-live-p w) (ignore-errors (delete-window w))))
            (kill-buffer b)))))))

(ert-deftest omy-ai/staged-diff-reads-index ()
  (skip-unless (executable-find "git"))
  (let* ((dir (file-name-as-directory (make-temp-file "repo" t)))
         (default-directory dir)
         (file (expand-file-name "a.txt" dir)))
    (unwind-protect
        (progn
          (write-region "hello\n" nil file)
          (call-process "git" nil nil nil "init")
          (call-process "git" nil nil nil "add" "a.txt")
          (should (string-match-p "hello" (omy-ai--staged-diff))))
      (delete-directory dir 'recursive))))

(ert-deftest omy-ai/minuet-provider-config ()
  (should (featurep 'minuet))
  (should (eq minuet-provider 'openai-compatible))
  (should (string-match-p "bigmodel"
                          (plist-get minuet-openai-compatible-options :end-point)))
  (should (equal "glm-5.3-flash"
                 (plist-get minuet-openai-compatible-options :model))))

(ert-deftest omy-ai/chat-ui-config ()
  ;; canary: gptel 自带 org-mode 空响应前缀（见 gptel-request.el），
  ;; 不再覆盖——AI 回复不会被冠以 "** " 标题
  (should (string-empty-p (or (alist-get 'org-mode gptel-response-prefix-alist) "")))
  (should (memq 'omy-ai--chat-ui gptel-mode-hook)))

(ert-deftest omy-ai/chat-ui-keeps-native-org-renderer ()
  (with-temp-buffer
    (delay-mode-hooks (org-mode))
    (when (fboundp 'org-superstar-mode) (org-superstar-mode 1))
    (omy-ai--chat-ui)
    ;; 原生标题渲染不被接管：org-superstar 保持启用，org-modern /
    ;; org-indent 不被引入
    (when (featurep 'org-superstar)
      (should (bound-and-true-p org-superstar-mode)))
    (should-not (bound-and-true-p org-modern-mode))
    (should-not (bound-and-true-p org-indent-mode))))

(ert-deftest omy-ai/removed-turn-rendering-absent ()
  (should-not (fboundp 'omy-ai--style-turns))
  (should-not (fboundp 'omy-ai--fix-reasoning-heading))
  (should-not (memq #'omy-ai--fix-reasoning-heading
                    gptel-post-response-functions))
  (dolist (face '(omy-ai-ai-heading omy-ai-user-heading
                   omy-ai-user-block omy-ai-bar))
    (should-not (facep face))))

(ert-deftest omy-ai/chat-ui-uses-soft-wrapping ()
  (with-temp-buffer
    (delay-mode-hooks (org-mode))
    (omy-ai--chat-ui)
    (should buffer-face-mode)           ;variable-pitch-mode 生效
    (should visual-line-mode)
    (should-not (bound-and-true-p visual-fill-column-mode))
    ;; 固定宽度排版已移除：无本地 fill-column / 边距覆盖
    (should (equal (default-value 'fill-column) fill-column))
    (should (equal (default-value 'left-margin-width) left-margin-width))
    (should (equal (default-value 'right-margin-width) right-margin-width))))

(ert-deftest omy-ai/chat-ui-disables-globally-hooked-visual-fill ()
  ;; 全局 visual-line-mode-hook（init-ui 的 Org 阅读排版）会连带开启
  ;; visual-fill-column-mode；chat-ui 必须显式关掉它，聊天窗口才吃满
  ;; 可视宽度
  (skip-unless (fboundp 'visual-fill-column-mode))
  (let ((orig (window-buffer))
        buffer)
    (unwind-protect
        (progn
          (setq buffer (get-buffer-create " *omy-ai-vfc*"))
          (set-window-buffer nil buffer)
          (with-current-buffer buffer
            (delay-mode-hooks (org-mode))
            ;; 模拟全局钩子：visual-line 开启时连带开启 visual-fill-column
            (let ((visual-line-mode-hook
                   (cons 'visual-fill-column-mode visual-line-mode-hook)))
              (visual-line-mode 1))
            (should (bound-and-true-p visual-fill-column-mode))
            (omy-ai--chat-ui)
            (should visual-line-mode)
            (should-not (bound-and-true-p visual-fill-column-mode))))
      (set-window-buffer nil orig)
      (when (buffer-live-p buffer) (kill-buffer buffer)))))

(ert-deftest omy-ai/follow-stream-keeps-visible-windows-at-point-max ()
  ;; 每次流式插入后，所有可见的会话窗口都应跟随到 point-max
  (let ((orig (window-buffer))
        buffer)
    (unwind-protect
        (progn
          (setq buffer (get-buffer-create " *omy-ai-stream*"))
          (set-window-buffer nil buffer)
          (with-current-buffer buffer
            (delay-mode-hooks (org-mode))
            (insert "#+title: stream\n\n*** q\n"))
          (let ((w2 (split-window)))
            (unwind-protect
                (progn
                  (set-window-buffer w2 buffer)
                  (with-current-buffer buffer
                    (goto-char (point-min))
                    (insert "answer text\n")
                    (omy-ai--follow-stream)
                    (should (= (window-point) (point-max)))
                    (should (= (window-point w2) (point-max)))))
              (delete-window w2))))
      (set-window-buffer nil orig)
      (when (buffer-live-p buffer) (kill-buffer buffer)))))

(ert-deftest omy-ai/chat-ui-registers-stream-hooks-buffer-locally ()
  (with-temp-buffer
    (delay-mode-hooks (org-mode))
    (let ((global-stream (default-value 'gptel-post-stream-hook))
          (global-response (default-value 'gptel-post-response-functions)))
      (omy-ai--chat-ui)
      (should (local-variable-p 'gptel-post-stream-hook))
      (should (memq #'omy-ai--follow-stream gptel-post-stream-hook))
      (should (local-variable-p 'gptel-post-response-functions))
      (should (memq #'omy-ai--complete-response gptel-post-response-functions))
      ;; 只挂 buffer-local，不污染全局钩子
      (should (eq global-stream (default-value 'gptel-post-stream-hook)))
      (should (eq global-response
                  (default-value 'gptel-post-response-functions))))))

(ert-deftest omy-ai/complete-response-expands-current-reasoning-only ()
  ;; 只展开本次响应区内的 reasoning 块；旧回复的块保持折叠
  (with-temp-buffer
    (delay-mode-hooks (org-mode))
    (insert "#+title: t\n\n"
            "*** q1\n"
            "#+begin_reasoning\n"
            "old hidden detail\n"
            "#+end_reasoning\n"
            "answer one\n\n"
            "*** q2\n"
            "#+begin_reasoning\n"
            "current hidden detail\n"
            "#+end_reasoning\n"
            "answer two\n")
    (let* ((old-body (progn (goto-char (point-min))
                            (re-search-forward "^old hidden detail")
                            (line-beginning-position)))
           (cur-body (progn (goto-char (point-min))
                            (re-search-forward "^current hidden detail")
                            (line-beginning-position)))
           (cur-beg (progn (goto-char (point-min))
                           (re-search-forward "^\\*\\*\\* q2")
                           (match-beginning 0))))
      ;; 流式落盘后新旧块都处于折叠状态
      (goto-char (point-min))
      (while (re-search-forward "^#\\+begin_reasoning$" nil t)
        (org-hide-block-toggle nil t))
      (should (invisible-p old-body))
      (should (invisible-p cur-body))
      ;; 响应完成：以本次响应边界调用，旧块不动、新块展开
      (omy-ai--complete-response cur-beg (point-max))
      (should (invisible-p old-body))
      (should-not (invisible-p cur-body))
      (should (= (point) (point-max))))))

(ert-deftest omy-ai/glm-thinking-disabled ()
  (should (equal '(:thinking (:type "disabled"))
                 (get 'glm-5.3-flash :request-params)))
  ;; minuet 的非标准参数必须经 :optional 拼进请求体，而非顶层键
  (should (equal '(:thinking (:type "disabled"))
                 (plist-get minuet-openai-compatible-options :optional)))
  (should-not (plist-get minuet-openai-compatible-options :thinking)))

(ert-deftest omy-ai/chat-ui-unifies-block-delimiter-faces ()
  (with-temp-buffer
    (delay-mode-hooks (org-mode))
    (let ((before (copy-sequence face-remapping-alist)))
      (omy-ai--chat-ui)
      (should (and (assq 'org-block-begin-line face-remapping-alist)
                   (assq 'org-block-end-line face-remapping-alist)))
      (should-not (equal before face-remapping-alist)))))

(ert-deftest omy-ai/backends-request-identity-encoding ()
  (dolist (backend (list omy-ai--zhipu omy-ai--deepseek omy-ai--vllm))
    (should (member "Accept-Encoding: identity"
                    (gptel-backend-curl-args backend)))))

(ert-deftest omy-ai/backends-streaming-enabled ()
  (dolist (backend (list omy-ai--zhipu omy-ai--deepseek omy-ai--vllm))
    (should (eq t (gptel-backend-stream backend)))))
