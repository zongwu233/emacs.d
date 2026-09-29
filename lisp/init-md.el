;;; init-md.el  -*- lexical-binding: t -*-

;; Pixel alignment for org/markdown tables
;; 注意：valign 只给 markdown-mode 用。Emacs 29 内置的 Org 9.6 中
;; `org-flag-region' 是 `org-fold-region' 的别名，org 的 font-lock matcher
;; （links/emphasis/src block）每匹配一次就调一次它；valign 对该函数的 advice
;; 会在展开时把 `fontified' 置 nil，令 jit-lock 无限重字体化——GUI 下打开含
;; 较多 block/link 的 org 文件直接卡死（org-superstar 的全量字体化会立即触发）。
;; org 表格需要时仍可手动 `M-x valign-region'。
(use-package valign
  :ensure t
  :hook (markdown-mode . valign-mode))

;; The markdown mode 
(use-package markdown-mode
  :ensure t
  :mode ("README\\(?:\\.md\\)?\\'" . gfm-mode)
  :hook (markdown-mode . visual-line-mode)
  :config
  :custom
  (markdown-header-scaling t)
  (markdown-enable-wiki-links t)
  (markdown-italic-underscore t)
  (markdown-asymmetric-header t)
  (markdown-gfm-uppercase-checkbox t)
  (markdown-enable-prefix-prompts nil)
  (markdown-fontify-code-blocks-natively t))

;; ReStructuredText
(use-package rst
  :ensure nil
  :hook ((rst-mode . visual-line-mode)
         (rst-adjust . rst-toc-update)))


(with-eval-after-load 'markdown-mode
  ;; ===============================
  ;; Headings: inherit org levels
  ;; ===============================
  (dolist (pair '((markdown-header-face-1 . org-level-1)
                  (markdown-header-face-2 . org-level-2)
                  (markdown-header-face-3 . org-level-3)
                  (markdown-header-face-4 . org-level-4)
                  (markdown-header-face-5 . org-level-5)
                  (markdown-header-face-6 . org-level-6)))
    (set-face-attribute (car pair) nil
                        :inherit (cdr pair)
                        :height 1.0
                        :weight 'bold))

  ;; ===============================
  ;; Lists
  ;; ===============================
  (when (facep 'markdown-list-face)
    (set-face-attribute 'markdown-list-face nil
                        :inherit 'org-list-dt
                        :weight 'normal))

  ;; ===============================
  ;; Code: inline & block
  ;; ===============================
  (when (facep 'markdown-inline-code-face)
    (set-face-attribute 'markdown-inline-code-face nil
                        :inherit 'org-code))

 (with-eval-after-load 'markdown-mode
  (setq markdown-fontify-code-blocks-natively nil
        markdown-enable-math nil
        markdown-fontify-whole-buffer nil))

  ;; ===============================
  ;; Quote
  ;; ===============================
  (when (facep 'markdown-blockquote-face)
    (set-face-attribute 'markdown-blockquote-face nil
                        :inherit 'org-quote))

  ;; ===============================
  ;; Links & emphasis
  ;; ===============================
  (when (facep 'markdown-link-face)
    (set-face-attribute 'markdown-link-face nil
                        :inherit 'org-link))

  (when (facep 'markdown-bold-face)
    (set-face-attribute 'markdown-bold-face nil
                        :weight 'bold))

  (when (facep 'markdown-italic-face)
    (set-face-attribute 'markdown-italic-face nil
                        :slant 'italic)))



(provide 'init-md)
