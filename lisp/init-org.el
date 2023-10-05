;;安装最新版本 org 不使用内置版本
(use-package org
  :pin gnu
  :ensure t)

(use-package org-contrib
  :pin nongnu
  :ensure t)

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
(require 'org-checklist)
;; need repeat task and properties
(setq org-log-done t)
(setq org-log-into-drawer t)

;; C-c C-s schedule
;; C-c C-d deadline
(global-set-key (kbd "C-c a") 'org-agenda)
(setq org-agenda-files '("~/org/gtd.org"))
(setq org-agenda-span 'day)

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


(provide 'init-org)
