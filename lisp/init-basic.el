;; -*- lexical-binding: t -*-

;; emacs >= 26  开启行号可以这么设置
(display-line-numbers-mode 1)

;; 关闭工具栏，tool-bar-mode 即为一个 Minor Mode
(tool-bar-mode -1)
;; 关闭文件滑动控件
(scroll-bar-mode -1)
;; 更改光标的样式
(setq-default cursor-type 'bar)

;;不再需要，下面有更好的补全插件
;;(icomplete-mode 1)

;; 快速打开配置文件
(defun open-init-file()
  (interactive)
  (find-file "~/.emacs.d/init.el"))
;; 这一行代码，将函数 open-init-file 绑定到 <f2> 键上
(global-set-key (kbd "<f2>") 'open-init-file)

;; 更改显示字体大小 16pt
;; http://stackoverflow.com/questions/294664/how-to-set-the-font-size-in-emacs
(set-face-attribute 'default nil :height 160);;

;;让鼠标滚动更好用
(setq mouse-wheel-scroll-amount '(1 ((shift) . 1) ((control) . nil)))
(setq mouse-wheel-progressive-speed nil)

;;括号匹配高亮
(show-paren-mode t)
;;自动补全成对的符号
(electric-pair-mode 1)


;;禁止自动生成备份文件
(setq make-backup-files nil)

;;最近打开文件
(require 'recentf)
(recentf-mode 1)
(setq recentf-max-menu-item 10)
(global-set-key (kbd "C-x b") 'consult-buffer)

(delete-selection-mode 1)

;;高亮当前行
(global-hl-line-mode 1)

;; 自动加载在外部修改的文件
(global-auto-revert-mode 1)

;; close auto save
(setq auto-save-default nil)
;;关闭错误的时候哔哔的警告声音
(setq ring-bell-function 'ignore)
;; simple to y or n
(fset 'yes-or-no-p 'y-or-n-p)

(setq inhibit-splash-screen t)

(setq initial-scratch-message ";; Happy Hacking")


(provide 'init-basic)
