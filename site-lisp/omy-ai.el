;; -*- coding: utf-8; lexical-binding: t; -*-
;;; omy-ai.el --- AI agent glue -*- lexical-binding: t; -*-
(require 'gptel)

;;; Session management -------------------------------------------------------
(defvar omy-ai-sessions-dir
  (expand-file-name "omy-ai/sessions/"
                    (or (getenv "XDG_DATA_HOME") "~/.local/share"))
  "Root directory for gptel session files, one subdirectory per project slug.")

(defun omy-ai--project-root ()
  "Current project root; falls back to default-directory when projectile is unavailable or we are outside a project."
  (if (and (fboundp 'projectile-project-p) (projectile-project-p))
      (projectile-project-root)
    default-directory))

(defun omy-ai--project-slug ()
  (omy-ai--slug (file-name-nondirectory
                 (directory-file-name (omy-ai--project-root)))))

(defun omy-ai--slug (name)
  "Filesystem-safe slug of a project name, keeping CJK characters."
  (let ((s (downcase name)))
    (setq s (replace-regexp-in-string "[^a-z0-9一-鿿]+" "-" s))
    (setq s (replace-regexp-in-string "\\`-+\\|-+$" "" s))
    (if (string-empty-p s) "default" s)))

(defun omy-ai--session-file (title)
  "Org file path for a new session of the current project (creates the directory when missing)."
  (let* ((dir (expand-file-name (omy-ai--project-slug) omy-ai-sessions-dir))
         (safe (omy-ai--slug title))
         (stamp (format-time-string "%Y%m%d-%H%M%S")))
    (make-directory dir t)
    (expand-file-name (format "%s-%s.org" stamp safe) dir)))

(defun omy-ai-session-new (&optional title)
  "Create and open a new gptel session file for the current project."
  (interactive "sSession title (RET for default): ")
  (let* ((title (if (or (not title) (string-empty-p title)) "session" title))
         (path (omy-ai--session-file title)))
    (find-file path)
    (insert (format "#+title: %s\n\n" title))
    (require 'gptel-org)
    ;; Pre-write the backend/model properties: gptel-org prints a "Could not activate
    ;; gptel backend" warning when restoring files without properties; pre-writing
    ;; removes that warning and makes the session file self-describing (recording
    ;; the backend and model at creation time)
    (gptel-org-set-properties (point-min))
    (gptel-mode 1)
    (goto-char (point-max))
    ;; gptel user prompt prefix ("*** " in org): a new session's point lands right where you can type
    (insert (gptel-prompt-prefix-string))))

(defun omy-ai-session-open ()
  "List and open existing gptel sessions of the current project (newest first)."
  (interactive)
  (let* ((dir (expand-file-name (omy-ai--project-slug) omy-ai-sessions-dir))
         (files (when (file-directory-p dir)
                  (sort (directory-files dir t "\\.org\\'")
                        #'file-newer-than-file-p))))
    (if (not files)
        (user-error "omy-ai: no sessions for this project yet, create one with SPC a s first")
      (let* ((names (mapcar #'file-name-nondirectory files))
             (pick (completing-read "Open session: " names nil t)))
        (find-file (expand-file-name pick dir))
        (gptel-mode 1)))))

;;; Stream following and response finalization ----------------------------------------------
(defun omy-ai--follow-stream ()
  "Keep visible windows for this gptel buffer at its newest text."
  (dolist (window (get-buffer-window-list (current-buffer) nil t))
    (set-window-point window (point-max))))

(defun omy-ai--complete-response (beg end)
  "Expand this response's reasoning blocks and prepare gptel's next prompt."
  (when (derived-mode-p 'org-mode)
    (save-excursion
      (goto-char beg)
      (while (re-search-forward "^#\\+begin_reasoning$" end t)
        (forward-line 1)
        (org-fold-show-context))))
  (goto-char (point-max))
  (omy-ai--follow-stream))

;;; AGENTS.md injection and agent sessions ------------------------------------
(defun omy-ai--git (args)
  "Run git ARGS at the project root, returning (SUCCESSP . OUTPUT)."
  (let ((default-directory (omy-ai--project-root))
        (out "") status)
    (setq out (with-output-to-string
                (with-current-buffer standard-output
                  (setq status (apply #'call-process "git" nil (list t nil) nil args)))))
    (cons (zerop status) out)))

(defun omy-ai--inside-git-p (&optional dir)
  "Whether DIR lies inside a git working tree."
  (let ((default-directory (or dir (omy-ai--project-root))))
    (and (executable-find "git")
         (car (omy-ai--git '("rev-parse" "--is-inside-work-tree"))))))

(defun omy-ai--rules-path (&optional root)
  "Path to the project root AGENTS.md, or nil when it does not exist."
  (let ((p (expand-file-name "AGENTS.md" (or root (omy-ai--project-root)))))
    (and (file-exists-p p) p)))

(defun omy-ai--open-agent (&optional preset)
  "Open a gptel-agent session at the project root, loading PRESET when given.
Inside a git repository: write-class tools skip confirmation (direct writes with
git as the safety net) and AGENTS.md is injected.
Outside a repository: retain gptel-agent's default per-call confirmation and show a notice."
  (let* ((root (omy-ai--project-root))
         (in-git (omy-ai--inside-git-p root))
         (rules (omy-ai--rules-path root)))
    (unless in-git
      (message "omy-ai: not inside a git repository, write-class tools keep per-call confirmation"))
    (let ((default-directory root)
          ;; gptel delegates chat-buffer display to the global display-buffer
          ;; machinery (its own action alist carries no display function), so the
          ;; session lands wherever that machinery sends it: a split window by
          ;; default, a separate frame when `pop-up-frames' is non-nil.  Pin the
          ;; agent session to the current window instead, mirroring `find-file'.
          (gptel-display-buffer-action '(display-buffer-same-window)))
      (gptel-agent root preset))
    (let ((buf (or (and (bound-and-true-p gptel-mode) (current-buffer))
                   (seq-find (lambda (b) (buffer-local-value 'gptel-mode b))
                             (buffer-list)))))
      (if buf
          (with-current-buffer buf
            (when in-git (setq-local gptel-confirm-tool-calls nil))
            (when rules (setq-local gptel-context (list (list rules)))))
        (message "omy-ai: agent session buffer not found, confirmation policy left unchanged")))))

(defun omy-ai-agent ()
  "Open a gptel-agent session for the current project.
Inside a git repository: write-class tools skip confirmation (direct writes with
git as the safety net) and AGENTS.md is injected.
Outside a repository: retain gptel-agent's default per-call confirmation and show a notice."
  (interactive)
  (omy-ai--open-agent))

(defun omy-ai-plan ()
  "Open a read-only planning session (the gptel-plan preset) for the current project.
Same project-root handling and AGENTS.md injection as `omy-ai-agent', but the
preset mounts only read-only tools (Read/Grep/Glob/web plus subagents): the
model explores the codebase and produces an implementation plan without writing
anything.  The session header-line can still toggle back to the full agent
preset mid-session."
  (interactive)
  (omy-ai--open-agent 'gptel-plan))

;;; Workflow commands ------------------------------------------------------
(defvar omy-ai-commit-system
  "你是 commit message 生成器。基于 diff 写一条简洁的 git commit
message：第一行 <=50 字符概括，正文可选说明动机，用 diff 的主要语言。
只输出 message 本身，不要 markdown 代码块。")

(defvar omy-ai-review-system
  "你是资深代码审查者。只报告真实问题（正确性、边界、并发、安全、
测试缺口），每条给出文件/位置与理由，按严重程度排序；没有问题就明确
说 LGTM。用中文。")

(defun omy-ai--staged-diff ()
  "Staged diff; user-error when outside a git repository or with nothing staged."
  (unless (executable-find "git")
    (user-error "omy-ai: git not found"))
  (pcase-let ((`(,ok . ,out) (omy-ai--git '("diff" "--cached"))))
    (cond ((not ok) (user-error "omy-ai: not inside a git repository"))
          ((string-empty-p (string-trim out))
           (user-error "omy-ai: nothing staged (run git add first)"))
          (t (string-trim out)))))

(defun omy-ai--show (buffer-name response info)
  "Show the LLM RESPONSE in BUFFER-NAME; on failure report the status from INFO."
  (if (stringp response)
      (with-current-buffer (get-buffer-create buffer-name)
        (let ((inhibit-read-only t))
          (erase-buffer)
          (insert response))
        (delay-mode-hooks (org-mode))
        (display-buffer (current-buffer)))
    (message "omy-ai: request failed: %s" (plist-get info :status))))

(defun omy-ai--lang ()
  "Language name for the current major-mode, such as python."
  (replace-regexp-in-string "-mode$" "" (symbol-name major-mode)))

(defun omy-ai-commit ()
  "Generate a commit message for staged changes: copy it to the kill-ring and echo it."
  (interactive)
  (let ((diff (omy-ai--staged-diff)))
    (message "omy-ai: generating commit message ...")
    (gptel-request
        (format "为下面的 diff 写一条 commit message：\n\n%s" diff)
      :system omy-ai-commit-system
      :callback (lambda (response info)
                  (if (stringp response)
                      (progn
                        (kill-new response)
                        (message "omy-ai commit message (copied):\n%s" response))
                    (message "omy-ai: request failed: %s" (plist-get info :status)))))))

(defun omy-ai-review ()
  "Review the staged diff, showing the result in *omy-ai review*."
  (interactive)
  (let ((diff (omy-ai--staged-diff)))
    (message "omy-ai: reviewing ...")
    (gptel-request
        (format "审查下面的 diff：\n\n%s" diff)
      :system omy-ai-review-system
      :callback (lambda (response info)
                  (omy-ai--show "*omy-ai review*" response info)))))

(defun omy-ai-explain (begin end)
  "Explain the selected code."
  (interactive "r")
  (let ((code (buffer-substring-no-properties begin end))
        (lang (omy-ai--lang)))
    (gptel-request
        (format "解释这段%s代码的作用、关键逻辑与潜在坑：\n\n%s" lang code)
      :system "你是资深工程师，解释精确简短，用中文。"
      :callback (lambda (response info)
                  (omy-ai--show "*omy-ai explain*" response info)))))

(defun omy-ai-refactor (begin end)
  "Refactor the selected code: the result goes into *omy-ai refactor* for inspection before replacing."
  (interactive "r")
  (let ((code (buffer-substring-no-properties begin end))
        (lang (omy-ai--lang)))
    (gptel-request
        (format "重构这段%s代码，只返回重构后的完整代码，不要解释：\n\n%s" lang code)
      :system "你是资深工程师。保持外部行为不变，提升可读性。只输出代码。"
      :callback (lambda (response info)
                  (omy-ai--show "*omy-ai refactor*" response info)))))

;;; Manual compaction --------------------------------------------------
(defun omy-ai-compact ()
  "Hand the current session to the model to compact into a handoff summary,
resetting it to a fresh start. gptel has no automatic compaction; run this
command manually for long sessions."
  (interactive)
  (unless (bound-and-true-p gptel-mode)
    (user-error "omy-ai: not in a gptel session"))
  (let ((buf (current-buffer))
        (history (buffer-substring-no-properties (point-min) (point-max))))
    (message "omy-ai: compacting session ...")
    (gptel-request
        (format "把下面的 agent 会话记录压缩成简洁的交接摘要：目标、
已做决定、当前状态、下一步。保留关键文件路径与命令。\n\n%s" history)
      :system "你会压缩 agent 会话记录：保留决策与状态，删除冗余过程。用中文。"
      :callback (lambda (response info)
                  (if (and (stringp response) (buffer-live-p buf))
                      (with-current-buffer buf
                        (let ((inhibit-read-only t))
                          (erase-buffer)
                          (insert (format "#+title: compacted %s\n\n%s\n"
                                          (format-time-string "%F %T") response)))
                        (goto-char (point-max))
                        (message "omy-ai: session compacted"))
                    (message "omy-ai: request failed: %s" (plist-get info :status)))))))

(provide 'omy-ai)
;;; omy-ai.el ends here
