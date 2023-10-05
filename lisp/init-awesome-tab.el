;; 使用本地文件安装的 package
(require 'awesome-tab)
(awesome-tab-mode t)

  (defun awesome-tab-buffer-groups ()
    "`awesome-tab-buffer-groups' control buffers' group rules.

  Group awesome-tab with mode if buffer is derived from `eshell-mode' `emacs-lisp-mode' `dired-mode' `org-mode' `magit-mode'.
  All buffer name start with * will group to \"Emacs\".
  Other buffer group by `awesome-tab-get-group-name' with project name."
    (list
     (cond
      ((or (string-equal "*" (substring (buffer-name) 0 1))
	   (memq major-mode '(magit-process-mode
			      magit-status-mode
			      magit-diff-mode
			      magit-log-mode
			      magit-file-mode
			      magit-blob-mode
			      magit-blame-mode
			      )))
       "Emacs")
      ((derived-mode-p 'eshell-mode)
       "EShell")
      ((derived-mode-p 'emacs-lisp-mode)
       "Elisp")
      ((derived-mode-p 'dired-mode)
       "Dired")
      ((memq major-mode '(org-mode org-agenda-mode diary-mode))
       "OrgMode")
      (t
       (awesome-tab-get-group-name (current-buffer))))))


  (provide 'init-awesome-tab)
