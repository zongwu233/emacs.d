(package-install 'embark-consult)
(package-install 'wgrep)
(setq wgrep-auto-save-buffer t)

(eval-after-load
    'consult
  '(eval-after-load
       'embark
     '(progn
	(require 'embark-consult)
	(add-hook
	 'embark-collect-mode-hook
	 #'consult-preview-at-point-mode))))

(defun embark-export-write ()
"Export the current vertico results to a writable buffer if possible.
Supports exporting consult-grep to wgrep, file to wdeired, and consult-location to occur-edit"
(interactive)
(require 'embark)
(require 'wgrep)
(pcase-let ((`(,type . ,candidates)
	     (run-hook-with-args-until-success 'embark-candidate-collectors)))
  (pcase type
    ('consult-grep (let ((embark-after-export-hook #'wgrep-change-to-wgrep-mode))
		     (embark-export)))
    ('file (let ((embark-after-export-hook #'wdired-change-to-wdired-mode))
	     (embark-export)))
    ('consult-location (let ((embark-after-export-hook #'occur-edit-mode))
			 (embark-export)))
    (x (user-error "embark category %S doesn't support writable export" x)))))

(define-key minibuffer-local-map (kbd "C-c C-e") 'embark-export-write)


(provide 'init-search)
