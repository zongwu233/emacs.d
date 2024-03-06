;; Windows layout recorder
;;
;; You can still use `winner-mode' on Emacs 26 or early. On Emacs 27, it's
;; preferred over `winner-mode' for better compatibility with `tab-bar-mode'.
(use-package tab-bar
  :ensure nil
  :init  (tab-bar-mode t)
  ;; 图标太丑了
  ;;:hook (after-init . tab-bar-history-mode)
  :custom
  (tabbar-use-images nil)
  (tab-bar-new-button-show nil)
  (tab-bar-close-button-show nil)
  (tab-bar-new-tab-choice "*scratch*")
  (tab-bar-tab-hints t)
 )

(use-package tabspaces
  :ensure t
  :hook (after-init . tabspaces-mode) ;; use this only if you want the minor-mode loaded at startup.
  :commands (tabspaces-switch-or-create-workspace
	     tabspaces-open-or-create-project-and-workspace)
  :custom
  (tabspaces-use-filtered-buffers-as-default t)
  (tabspaces-default-tab "Default")
  (tabspaces-remove-to-default t)
  (tabspaces-include-buffers '("*scratch*"))
  ;; maybe slow 
  ;;(tabspaces-session t)
  ;;(tabspaces-session-auto-restore t)
  :config
  ;; Filter Buffers for Consult-Buffer

  (with-eval-after-load 'consult
    ;; hide full buffer list (still available with "b" prefix)
    (consult-customize consult--source-buffer :hidden nil :default nil)
    ;; set consult-workspace buffer list
    (defvar consult--source-workspace
  (list :name "Workspace Buffers"
	    :narrow ?w
	    :history 'buffer-name-history
	    :category 'buffer
	    :state #'consult--buffer-state
	    :default t
	    :items (lambda () (consult--buffer-query
			   :predicate #'tabspaces--local-buffer-p
			   :sort 'visibility
			   :as #'buffer-name)))

  "Set workspace buffer list for consult-buffer.")
    (add-to-list 'consult-buffer-sources 'consult--source-workspace)))


  (provide 'init-tabs)
