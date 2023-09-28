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

(require 'package)
(setq package-archives '(("gnu"   . "https://mirrors.163.com/elpa/gnu/")

			 ("melpa" . "https://mirrors.163.com/elpa/melpa/")))
(package-initialize)

;;防止反复调用 package-refresh-contents 会影响加载速度
(when (not package-archive-contents)
  (package-refresh-contents))

(package-install 'company)
(global-company-mode 1)

;; company mode 默认选择上一条和下一条候选项命令 M-n M-p
(define-key company-active-map (kbd "C-n") 'company-select-next)
(define-key company-active-map (kbd "C-p") 'company-select-previous)

;;增强 minibuffer 补全
(package-install 'vertico)
(vertico-mode t)
;;在 minibuffer 支持模糊搜索
(package-install 'orderless)
(setq completion-styles '(orderless))

;; 增强 minibuffer 的annotation
(package-install 'marginalia)
(marginalia-mode t)

;; minibuffer action 就类似于在任何内容上右键点击
(package-install 'embark)
(global-set-key (kbd "C-;") 'embark-act)
;;利用这个 可以不用再记忆快捷键，只需要执行 C-x C-h 呼出帮助命令
;;然后输入想执行命令的关键字，既可以出现提示列表，又因为 orderless
;; 可以不用在意关键字单词的顺序 最后直接回车执行即可
(setq prefix-help-command 'embark-prefix-help-command)
;;增强文件内搜索和跳转函数定义
(package-install 'consult)
;;同时使用需要这个
(package-install 'embark-consult)
;;强大的文件内搜索功能，完全替代了 swiper 插件
(global-set-key (kbd "C-s") 'consult-line)
;;文件内函数跳转
;;consult-imenu

;;括号匹配
(show-paren-mode t)

;;添加本地目录插件
(add-to-list 'load-path (expand-file-name "~/.emacs.d/site-lisp/awesome-tab") )
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
(custom-set-variables
 ;; custom-set-variables was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 '(package-selected-packages
   '(consult embark vertico orderless marginalia embark-consult company)))
(custom-set-faces
 ;; custom-set-faces was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 )
