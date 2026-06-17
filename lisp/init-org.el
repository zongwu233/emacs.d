;; -*- coding: utf-8; lexical-binding: t; -*- 
   ;;安装最新版本 org 不使用内置版本
    (use-package org
      :pin gnu
      :ensure t)


    (use-package org-contrib
      :pin nongnu
      :ensure t
      :after org
      (require 'org-checklist))

    (require 'org-tempo)  ;开启easy template

    ;; 需要开启 electric-pair-mode
    ;; 禁用左尖括号
    (setq electric-pair-inhibit-predicate
      `(lambda (c)
         (if (char-equal c ?\<) t (,electric-pair-inhibit-predicate c))))

    (add-hook 'org-mode-hook
          (lambda ()
        (setq-local electric-pair-inhibit-predicate
                `(lambda (c)
                   (if (char-equal c ?\<) t (,electric-pair-inhibit-predicate c))))))
    ;; 更丰富的 TODO 状态
    (setq org-todo-keywords
    (quote ((sequence "TODO(t)" "STARTED(s)" "|" "DONE(d!/!)")
        (sequence "WAITING(w@/!)" "SOMEDAY(S)" "|" "CANCELLED(c@/!)" "MEETING(m)" "PHONE(p)"))))

    ;; need repeat task and properties
    (setq org-log-done t)
    (setq org-log-into-drawer t)

    ;; C-c C-s schedule
    ;; C-c C-d deadline
    (global-set-key (kbd "C-c a") 'org-agenda)
    (setq org-agenda-files '("~/org" ))
    (setq org-agenda-span 'week)
    (setq org-agenda-start-on-weekday nil) ;; 不按照周对齐，这样未来7天能正常显示

    ;; ============================================================================
    ;; Org Agenda Custom Dashboard (UTF-8 + Unicode Icons)
    ;; ============================================================================
   (setq org-agenda-custom-commands
      '(
        ;; d: 统一 Dashboard，三个分类按文件过滤
        ("d" "Dashboard"
         (
          (agenda ""
                  ((org-agenda-span 1)
                   (org-agenda-overriding-header "\uF073 Today")))
          (agenda ""
                  ((org-agenda-span 7)
                   (org-agenda-start-day "+1d") ;; 从明天开始7天
                   (org-agenda-overriding-header "\uF073 Next 7 Days")))
          ;; Work tasks — 限制到 ~/org/work.org
          (alltodo ""
                   ((org-agenda-overriding-header "\uF0B1 Work")
                    (org-agenda-files '("~/org/work.org"))))
          ;; Life tasks — 限制到 ~/org/life.org
          (alltodo ""
                   ((org-agenda-overriding-header "\uF015 Life")
                    (org-agenda-files '("~/org/life.org"))))
          ;; Reading tasks — 限制到 ~/org/reading.org
          (alltodo ""
                   ((org-agenda-overriding-header "\uF02D Reading")
                    (org-agenda-files '("~/org/reading.org"))))
          ;; Waiting / Blocked — 跨所有文件
          (todo "WAITING"
                ((org-agenda-overriding-header "\uF044 Waiting / Blocked")))
          ;; Priority Sorted — 跨所有文件
          (todo ""
                ((org-agenda-overriding-header "\uF005 Priority Sorted")
                 (org-agenda-sorting-strategy '(priority-down))))
          ))
        ;; 单分类视图：C-c a W / L / R
        ("W" "Work only"    agenda "" ((org-agenda-files '("~/org/work.org"))))
        ("L" "Life only"    agenda "" ((org-agenda-files '("~/org/life.org"))))
        ("R" "Reading only" agenda "" ((org-agenda-files '("~/org/reading.org"))))
        ))


    ;; see https://github.com/abo-abo/org-download/issues/131
    (use-package org-download
    :ensure t
    :after org
    :config
    (setq-default
     org-download-image-dir "~/org/images"
     ;; Basename setting seems to be simply ignored.
     org-download-screenshot-basename ".png"
     org-download-timestamp "org_%Y%m%d-%H%M%S_"
     org-image-actual-width 960
     org-download-heading-lvl nil)
    :custom
    (org-download-screenshot-method
     (cond
      ((eq system-type 'gnu/linux)
       "xclip -selection clipboard -t image/png -o > '%s'")
      ((eq system-type 'darwin)
       "pngpaste %s")))
    :bind
    (:map org-mode-map
      (("C-M-y" . org-download-screenshot)
       ("s-y" . org-download-yank))))  

    ;; Drag-and-drop to `dired`
    (add-hook 'dired-mode-hook 'org-download-enable)

  (defun org-apperance-evil-hack ()
    (add-hook 'evil-insert-state-entry-hook #'org-appear-manual-start nil t)
    (add-hook 'evil-insert-state-exit-hook #'org-appear-manual-stop nil t))

  (use-package org-appear
    :ensure t
    :after org
    :hook (org-mode . org-appear-mode)
    :init
    (setq org-appear-trigger 'manual)
    (add-hook 'org-mode-hook 'org-apperance-evil-hack))
  (use-package org-superstar
    :ensure t
    :after org
    :hook (org-mode . org-superstar-mode)
    :config
    (setq org-superstar-special-todo-items t))
  ;; 
  (use-package evil-org
    :ensure t
    ;; 这里会使得 org mode 文件进入 evil-emacs-state ，就是原生 emacs 模式
    :hook (org-mode . evil-org-mode) 
    :after org
    :config
    (setq evil-want-C-i-jump nil)
    (require 'evil-org-agenda)
    (evil-org-agenda-set-keys))
 
;;禁止 orgmode 换行自动缩进
 (setq org-adapt-indentation nil)
;; org mode evil 不要自动缩进
 (add-hook 'org-mode-hook
          (lambda ()
            (electric-indent-local-mode -1)
            (setq-local evil-auto-indent nil)))

  ;; org capture
  (global-set-key (kbd "C-c c") 'org-capture)
  (setq org-default-notes-file "~/org/inbox.org")
  ;;先清空再设置
  (setq org-capture-templates nil)
  ;; === 工作 ===
  (add-to-list 'org-capture-templates
             '("w" "Work Task" entry
               (file+headline "~/org/work.org" "Inbox")
               "* TODO %^{任务名}\n  SCHEDULED: %t\n" ))
  ;; === 生活 ===
  (add-to-list 'org-capture-templates
             '("l" "Life Task" entry
               (file+headline "~/org/life.org" "Inbox")
               "* TODO %^{任务名}\n  SCHEDULED: %t\n" ))
  ;; === 阅读（保留 Book / Articles 细分）===
  (add-to-list 'org-capture-templates
             '("rb" "Book Reading Task" entry
               (file+olp "~/org/reading.org" "Reading" "Book")
               "* TODO %^{书名}\n  SCHEDULED: %t\n" ))
  (add-to-list 'org-capture-templates
             '("ra" "Article Reading Task" entry
               (file+olp "~/org/reading.org" "Reading" "Articles")
               "* TODO %^{文章名}\n  SCHEDULED: %t\n" ))
  (add-to-list 'org-capture-templates
             '("j" "Journal" entry
               (file "~/org/journal.org")
               "* %U - %^{heading}\n  %?"))
  ;;灵感搜集
  (add-to-list 'org-capture-templates
             '("i" "Inbox" entry
               (file "~/org/inbox.org")
               "* %U - %^{heading} %^g\n %?\n"))
  ;; note inbox
  (add-to-list 'org-capture-templates
             '("n" "Notes" entry
               (file "~/org/notes/inbox.org")
               "* %^{heading} %t%^g\n %?\n"))
;; orgmode todo 的归档规则
(setq org-archive-location "~/org/archive/%s_archive::")
;;在 todo 的 buffer 执行归档操作不会生效，在其他 buffer 即可
(defun my/org-archive-done-tasks ()
  (interactive)
  (org-map-entries
   (lambda ()
     (org-archive-subtree)
     (setq org-map-continue-from (outline-previous-heading)))
   "/DONE|CANCELLED" 'agenda))
(global-set-key (kbd "C-c d") 'my/org-archive-done-tasks)

(defun my/org--after-meta ()
  "Return a safe point after planning / meta data under the current heading.
Always returns a valid point. Compatible with older Org versions."
  (
    (org-back-to-heading t)
    (forward-line 1)
    ;; Prefer Org's meta-data API if available, otherwise fall back
    (or (and (fboundp 'org-end-of-meta-data)
             (org-end-of-meta-data t))
        ;; Fallback: directly after the heading
        (point))))

(defun my/org-insert-checkbox-item ()
  "Insert an Org checkbox item, ensuring proper structural separation."
  (interactive)
  (cond
   ;; Case 1: already inside a list ->  just insert a new item
   ((org-at-item-p)
    (org-insert-item)
    (insert "[ ] "))
   ;; Case 2: not in a list -> create a new checklist block
   (t
    (progn
      ;; Go to current headline
      (org-back-to-heading t)
      (forward-line 1)
      ;; Skip planning lines (SCHEDULED, DEADLINE, CLOSED)
      (while (looking-at-p org-planning-line-re)
        (forward-line 1))
      ;; Skip property drawer if present
      (when (looking-at-p ":PROPERTIES:")
        (re-search-forward ":END:" nil t)
        (forward-line 1))

      ;; Ensure blank line before checklist ,disable now
      ;;(unless (looking-at-p "^$")
      ;;  (insert "\n"))

      ;; Insert checklist item,and move cursor
      ;; CRITICAL: ensure blank line after checklist
      ;; so the next headline is not treated as list continuation
      (progn
        (insert "- [ ] \n")
        (insert "\n")
        (forward-line -2)
        (end-of-line))
     ))))




(with-eval-after-load 'org
  (define-key org-mode-map (kbd "C-c C-x i")
    #'my/org-insert-checkbox-item))


  ;; 中文英文混排的时候，自动换行问题
  ;; emacs 28 最新解决方案
  (setq word-wrap-by-category t)

  ;; 只显示标题
  (setq org-startup-folded 'content)
  ;;将列表视为 heading 也可默认折叠
  (setq org-cycle-include-plain-lists 'integrate) 
  ;; 模板出现了中文乱码
  (setq org-capture-templates-coding-system 'utf-8-unix)

  (provide 'init-org)
