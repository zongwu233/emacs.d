;; -*- lexical-binding: t -*-


;; Suppress GUI features and more
(setq use-file-dialog nil
      use-dialog-box nil
      inhibit-x-resources t
      inhibit-default-init t
      inhibit-startup-screen t
      inhibit-startup-message t
      inhibit-startup-buffer-menu t)

;; Pixelwise resize
(setq window-resize-pixelwise t
      frame-resize-pixelwise t)

;; Linux specific
(setq x-gtk-use-system-tooltips nil
      x-gtk-use-native-input nil  ;; 不要随意设置为t,采用Fcitx5 输入法时这里要设置nil
      x-underline-at-descent-line t)

;; With GPG 2.1+, this forces gpg-agent to use the Emacs minibuffer to prompt
;; for the key passphrase.
(setq epg-pinentry-mode 'loopback)

;; emacs >= 26  开启行号可以这么设置
(global-display-line-numbers-mode 1)
(setq-default display-line-numbers-width-start t)

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

;; 更改显示字体大小 
;; 这里设置了英文字体（ASCII ）
;; http://stackoverflow.com/questions/294664/how-to-set-the-font-size-in-emacs
(set-face-attribute 'default nil :family "Hack Nerd Font Mono" :height 170);;

;;根据系统选择合适字体
(cond
 ((eq system-type 'windows-nt)
  (setq my-cjk-font "Microsoft YaHei"))
 ((eq system-type 'darwin)
  (setq my-cjk-font "PingFang SC"))
 ((eq system-type 'gnu/linux)
  (setq my-cjk-font "Noto Sans CJK SC"))
 (t
  (setq my-cjk-font "Microsoft YaHei"))) 

;; 设置中文字体
(dolist (charset '(kana han cjk-misc bopomofo))
  (set-fontset-font t charset
                    (font-spec :family my-cjk-font
                               :height 17)))

;;设置 emoji 或者特殊字符的字体
(dolist (charset '(symbol emoji))
  (set-fontset-font t charset
                    (font-spec :family "Hack Nerd Font Mono"
                               :height 17)))

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

;; No lock files
(setq create-lockfiles nil)

;; Always load the newest file
(setq load-prefer-newer t)

;; Cutting and pasting use primary/clipboard
(setq select-enable-primary t
      select-enable-clipboard t)

;; No gc for font caches
(setq inhibit-compacting-font-caches t)

;; Improve display
(setq display-raw-bytes-as-hex t
      redisplay-skip-fontification-on-input t)

;; No eyes distraction
(setq blink-cursor-mode nil)

;; The nano style for truncated long lines.
(setq auto-hscroll-mode 'current-line)

;; Treats the `_' as a word constituent
(add-hook 'after-change-major-mode-hook
          (lambda ()
            (modify-syntax-entry ?_ "w")))

;; No tabs
(setq-default indent-tabs-mode nil)
(setq-default tab-width 4)

;; Sane defaults
(setq use-short-answers t)
;; Inhibit switching out from `y-or-n-p' and `read-char-choice'
(setq y-or-n-p-use-read-key t
      read-char-choice-use-read-key t)

;; Enable the disabled dired commands
(put 'dired-find-alternate-file 'disabled nil)



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
(when (eq system-type 'darwin)
  (setq mac-option-modifier 'meta
        mac-command-modifier 'super))


;; window下用 AutoHotkey 改键了LWin 到 Application 健
;; Application 按键在 Emacs下是 menu 按键??实测没绑定，这里绑定到 super键
(when (eq system-type 'windows-nt)
  (global-set-key (kbd "<apps>") nil)
  (define-key key-translation-map (kbd "<apps>") 'event-apply-super-modifier))

(global-set-key (kbd "s-a") 'mark-whole-buffer) ;;对应Windows上面的Ctrl-a 全选
(global-set-key (kbd "s-c") 'kill-ring-save) ;;对应Windows上面的Ctrl-c 复制
(global-set-key (kbd "s-s") 'save-buffer) ;; 对应Windows上面的Ctrl-s 保存
(global-set-key (kbd "s-v") 'yank) ;对应Windows上面的Ctrl-v 粘贴
(global-set-key (kbd "s-z") 'undo) ;对应Windows上面的Ctrol-z 撤销
(global-set-key (kbd "s-x") 'kill-region) ;对应Windows上面的Ctrol-x 剪切
(global-unset-key (kbd "C-SPC"))  ; input method key 
(global-set-key (kbd "M-SPC") 'set-mark-command)   ; replace to m-space

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
              savehist-autosave-interval 300))

;; MacOS specific
(use-package exec-path-from-shell
  :ensure t
  :when (eq system-type 'darwin)
  :hook (after-init . exec-path-from-shell-initialize))

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
    "" '(:ignore t :which-key (lambda (arg) `(,(cadr (split-string (car arg) " ")) . ,(replace-regexp-in-string "-mode$" "" (symbol-name major-mode)))))))




(provide 'init-basic)
