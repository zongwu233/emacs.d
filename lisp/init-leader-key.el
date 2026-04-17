;; -*- coding: utf-8; lexical-binding: t; -*-
  
    (use-package general
      :ensure t
      :init
      (with-eval-after-load 'evil
        (general-add-hook 'after-init-hook
                          (lambda (&rest _)
                            (when-let ((messages-buffer (get-buffer "*Messages*")))
                              (with-current-buffer messages-buffer
                                (evil-normalize-keymaps))))
                          nil
                          nil
                          t))


      (general-create-definer global-definer
        :keymaps 'override
        :states '(insert emacs normal hybrid motion visual operator)
        :prefix "SPC"
        :non-normal-prefix "C-SPC")
 
     (global-definer
       "" '(:ignore t :which-key "leader"))


      (defmacro +general-global-menu! (name infix-key &rest body)
        "Create a definer named +general-global-NAME wrapping global-definer.
            Create prefix map: +general-global-NAME. Prefix bindings in BODY with INFIX-KEY."
        (declare (indent 2))
        `(progn
           (general-create-definer ,(intern (concat "+general-global-" name))
             :wrapping global-definer
             :prefix-map ',(intern (concat "+general-global-" name "-map"))
             :infix ,infix-key
             :wk-full-keys nil
             "" '(:ignore t :which-key ,name))
           (,(intern (concat "+general-global-" name))
            ,@body)))


      (general-create-definer global-leader
        :keymaps 'override
        :states '(emacs normal hybrid motion visual operator)
        :prefix ","
        "" '(:ignore t :which-key (lambda (arg) 
                                    `(,(cadr (split-string (car arg) " ")) . 
                                      ,(replace-regexp-in-string "-mode$" "" 
                                       (symbol-name major-mode))))))

   )

 ;; file 
  (+general-global-menu! "file" "f"
    "f" 'find-file
    "s" 'save-buffer
    "S" 'save-some-buffers
    "r" 'consult-recent-file
    "R" 'rename-visited-file
    "d" 'my-open-current-directory     ;;  xdg-open 
    "y" 'copy-file-name                ;;  need (defun copy-file-name ...)
    "D" 'delete-file)

  ;; buffer 
  (+general-global-menu! "buffer" "b"
    "b" 'consult-buffer                 ;;  C-x b
    "B" 'consult-buffer-other-window
    "d" 'kill-buffer
    "D" 'kill-current-buffer
    "s" 'save-buffer
    "r" 'revert-buffer
    "i" 'ibuffer
    "k" 'kill-matching-buffers
    "[" 'previous-buffer                ;; 
    "]" 'next-buffer)

;; window 
(+general-global-menu! "window" "w"
  "d" 'delete-window
  "D" 'delete-other-windows
  "s" 'split-window-below
  "v" 'split-window-right
  "u" 'winner-undo                    ;;  winner-mode
  "U" 'winner-redo
  "m" 'maximize-window
  "b" 'buf-move-left                  ;;  buffer-move
  "f" 'buf-move-right
  "p" 'buf-move-up
  "n" 'buf-move-down
  "r" 'resize-window)                 ;;  resize-window 

;; Project 
(+general-global-menu! "project" "p"
  "f" 'projectile-find-file
  "b" 'projectile-switch-to-buffer
  "d" 'projectile-find-dir
  "g" 'projectile-grep
  "r" 'projectile-replace
  "R" 'projectile-run-project
  "s" 'projectile-switch-project
  "k" 'projectile-kill-buffers
  "p" 'projectile-commander)

;;  Search 
(+general-global-menu! "search" "s"
  "s" 'consult-line                   ;;  C-s
  "f" 'consult-ripgrep                ;; 项目内搜索
  "i" 'consult-imenu                  ;; 函数/符号跳转
  "I" 'consult-imenu-multi            ;; 多buffer imenu
  "o" 'consult-outline                ;; 大纲跳转
  "g" 'consult-grep
  "r" 'consult-register
  "m" 'consult-mark
  "k" 'consult-yank-from-kill-ring
  "p" 'avy-goto-char-timer            ;; avy
  "l" 'avy-goto-line)
;; Git
(+general-global-menu! "git" "g"
  "g" 'magit-status                   ;;  magit 的 C-x g
  "d" 'magit-dispatch
  "f" 'magit-file-dispatch
  "b" 'magit-blame
  "l" 'magit-log
  "L" 'magit-log-buffer-file
  "D" 'magit-diff-buffer-file
  "n" 'diff-hl-next-hunk              ;;  diff-hl
  "p" 'diff-hl-previous-hunk
  "r" 'diff-hl-revert-hunk)

;;  Misc 
(global-definer
  "SPC" 'execute-extended-command     ;; SPC SPC = M-x
  "u"   'universal-argument           ;; C-u 替代
  "`"   'popper-toggle-latest         ;;  popper  s-`
  "TAB" 'popper-cycle)                ;; popper 循环

  (provide 'init-leader-key)
