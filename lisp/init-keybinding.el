;; -*- lexical-binding: t -*-

  ;; mac option key ->  meta
  ;; mac commad key -> super
  (setq mac-option-modifier 'meta
	mac-command-modifier 'super)

  (global-set-key (kbd "s-a") 'mark-whole-buffer) ;;对应Windows上面的Ctrl-a 全选
  (global-set-key (kbd "s-c") 'kill-ring-save) ;;对应Windows上面的Ctrl-c 复制
  (global-set-key (kbd "s-s") 'save-buffer) ;; 对应Windows上面的Ctrl-s 保存
  (global-set-key (kbd "s-v") 'yank) ;对应Windows上面的Ctrl-v 粘贴
  (global-set-key (kbd "s-z") 'undo) ;对应Windows上面的Ctrol-z 撤销
  (global-set-key (kbd "s-x") 'kill-region) ;对应Windows上面的Ctrol-x 剪切

  (provide 'init-keybinding)
