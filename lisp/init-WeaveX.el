;; -*- coding: utf-8; lexical-binding: t; -*-

(use-package plz
  :ensure t)

(require 'plz)

(require 'json)
(require 'url)

(setq ai-org-api-key (getenv "NVIDIA_API_KEY"))
(setq ai-org-api-url
  "https://integrate.api.nvidia.com/v1/chat/completions")
(setq ai-org-model "z-ai/glm4.7")

;; -----------------------
;; 工具函数
;; -----------------------

(defun ai-org--get-heading-text ()
  (nth 4 (org-heading-components)))

(defun ai-org--subtree-text ()
  (buffer-substring-no-properties
   (org-entry-beginning-position)
   (org-entry-end-position)))

(defun ai-org--has-plan? ()
  (save-excursion
    (org-map-entries
     (lambda () t)
     "LEVEL=2+PLAN" 'tree)))

(defun ai-org--has-todo? ()
  (save-excursion
    (org-map-entries
     (lambda () t)
     "TODO=\"TODO\"" 'tree)))

;; -----------------------
;; AI 调用（同步最小版）
;; -----------------------

(defun ai-org--call (prompt)
  (let* ((body
          (json-encode
           `(("model" . ,ai-org-model)
             ("stream" . :json-false)
             ("messages"
              .
              [(("role" . "user")
                 ("content" . ,prompt))]))))

         (response
          (plz 'post
            ai-org-api-url
            :headers
            `(("Content-Type" . "application/json")
              ("Authorization"
               . ,(concat "Bearer " ai-org-api-key)))

            :body body
            :as #'json-read)))
   ;; debug
    (message "RAW RESPONSE: %S" response)

    (let* ((choices
            (alist-get 'choices response))
           (first-choice
            (aref choices 0))
           (message-obj
            (alist-get 'message first-choice))
           (content
            (alist-get 'content message-obj)))
      content)))

;; -----------------------
;; PLAN 生成
;; -----------------------

(defun ai-org-generate-plan ()
  (interactive)

  (let* ((origin-buffer (current-buffer))

         (goal
          (ai-org--get-heading-text))

         (prompt
          (format
           "将这个目标拆成3-5个关键模块，每行一个短语：\n%s"
           goal))

         (result
          (ai-org--call prompt)))

    (message "AI RESULT:\n%s" result)

 (with-current-buffer origin-buffer
  (save-excursion
    ;; 跳到 subtree 末尾
    (org-end-of-subtree t t)
    ;; 确保换行
    (unless (bolp)
      (insert "\n"))
    ;; 插入 PLAN
    (insert "\n** PLAN\n")
    ;; 插入 task
    (dolist (line
             (split-string result "\n" t))
      (insert
       (format "- %s\n" line)))))

;; -----------------------
;; TODO 生成
;; -----------------------

(defun ai-org-generate-todo ()
  (interactive)
  (let* ((context (ai-org--subtree-text))
         (prompt (format
                  "根据下面PLAN拆分成具体TODO（5-8个），每行一句：\n%s" context))
         (result (ai-org--call prompt)))
    (save-excursion
      (org-end-of-subtree)
      (dolist (line (split-string result "\n" t))
        (insert (format "\n** TODO %s" line))))))

;; -----------------------
;; 执行 TODO（简化版）
;; -----------------------

(defun ai-org-execute-todo ()
  (interactive)
  (let (todo-pos todo-text)
    (save-excursion
      (org-map-entries
       (lambda ()
         (unless todo-pos
           (setq todo-pos (point))
           (setq todo-text (ai-org--get-heading-text))))
       "TODO=\"TODO\"" 'tree))
    (if (not todo-pos)
        (message "没有待执行 TODO")
      (save-excursion
        (goto-char todo-pos)
        (let* ((prompt (format
                        "给出这个任务的实现思路（简洁）：\n%s" todo-text))
               (result (ai-org--call prompt)))
          (org-end-of-subtree)
          (insert (format "\n*** RESULT\n%s\n" result))
          (org-todo 'done))))))

;; -----------------------
;; 决策逻辑
;; -----------------------

(defun ai-org-decide-next-step ()
  (cond
   ((not (ai-org--has-plan?)) 'plan)
   ((not (ai-org--has-todo?)) 'todo)
   (t 'execute)))

;; -----------------------
;; 主入口
;; -----------------------

(defun ai-org-run-step ()
  (interactive)
  (pcase (ai-org-decide-next-step)
    ('plan (ai-org-generate-plan))
    ('todo (ai-org-generate-todo))
    ('execute (ai-org-execute-todo))))


(provide 'init-WeaveX)
