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
    (find-file "~/.emacs.d/init-v2.org"))
  ;; 这一行代码，将函数 open-init-file 绑定到 <f2> 键上
  (global-set-key (kbd "<f2>") 'open-init-file)

  ;; 更改显示字体大小 16pt
  ;; http://stackoverflow.com/questions/294664/how-to-set-the-font-size-in-emacs
  (set-face-attribute 'default nil :height 160);;

  ;;让鼠标滚动更好用
  (setq mouse-wheel-scroll-amount '(1 ((shift) . 1) ((control) . nil)))
  (setq mouse-wheel-progressive-speed nil)

  ;; orgmode 进行文学编程的时候， < 会匹配 ) 导致影响匹配的高亮提示
  ;; 参见 https://www.reddit.com/r/orgmode/comments/s869jc/matching_parentheses_in_orgmode/
  ;; 可以使用 org-edit-special 在 minibuffer 里面进行 code 的校验
  ;;括号匹配高亮
  (show-paren-mode t)
  ;;自动补全成对的符号
  (electric-pair-mode 1)

  ;;禁止自动生成备份文件
  (setq make-backup-files nil)
  ;;禁止在文件末尾添加一个换行符
  (setq require-final-newline nil) 

  ;;最近打开文件
  (require 'recentf)
  (recentf-mode 1)
  (setq recentf-max-menu-item 8)
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
  (setq initial-scratch-message ";; Happy Hacking! Emacs loves you!")



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


  ;;内置 package
  ;;保存命令历史，在emacs重启之后，能够智能提示最近的操作命令，否则重启之后都清空了
  (use-package savehist
    :hook (after-init . savehist-mode)
    :init (setq enable-recursive-minibuffers t ; Allow commands in minibuffers
	      history-length 1000
	      savehist-additional-variables '(mark-ring
					      global-mark-ring
					      search-ring
					      regexp-search-ring
					      extended-command-history)
	      savehist-autosave-interval 300)
  )

;; 重启命令
(use-package restart-emacs
   :ensure t)

  
  ;;内置package
  (use-package saveplace
    :hook (after-init . save-place-mode))

;; Workaround with minified source files
(use-package so-long
  :ensure nil
  :hook (after-init . global-so-long-mode))  

  (provide 'init-basic)
