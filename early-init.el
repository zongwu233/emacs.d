;;; early-init.el --- Early initialization. -*- lexical-binding: t -*-

  ;;; Commentary:
  ;;
  ;; Emacs 27 introduces early-init.el, which is run before init.el,
  ;; before package and UI initialization happens.
  ;;

  ;;; Code:

  ;; Defer garbage collection further back in the startup process
  (setq gc-cons-threshold most-positive-fixnum
        gc-cons-percentage 0.5)

  ;; Package initialize occurs automatically, before `user-init-file' is
  ;; loaded, but after `early-init-file'. We handle package
  ;; initialization, so we must prevent Emacs from doing it early!
  (setq package-enable-at-startup nil)

  ;; Prevent unwanted runtime compilation for gccemacs (native-comp) users;
  ;; packages are compiled ahead-of-time when they are installed and site files
  ;; are compiled when gccemacs is installed.
  (setq native-comp-deferred-compilation nil)

  ;; Inhibit resizing frame
  (setq frame-inhibit-implied-resize t)

  ;; Faster to disable these here (before they've been initialized)
  ;; (push '(menu-bar-lines . 0) default-frame-alist)
  (push '(tool-bar-lines . 0) default-frame-alist)
  (push '(vertical-scroll-bars) default-frame-alist)
  (when (featurep 'ns)
    (push '(ns-transparent-titlebar . t) default-frame-alist))

  (add-to-list 'initial-frame-alist '(fullscreen . maximized))
  ;; full screen emacs cannot work here, call toggle fullscreen in init. 

  ;; Resizing the Emacs frame can be a terribly expensive part of changing the
  ;; font. By inhibiting this, we easily halve startup times with fonts that are
  ;; larger than the system default.
  (setq frame-inhibit-implied-resize t)


;; 1. 通用基础编码设置 (适用于所有平台)
(set-language-environment "UTF-8")
(prefer-coding-system 'utf-8-unix)
(set-default-coding-systems 'utf-8-unix)
(set-terminal-coding-system 'utf-8-unix)
(set-keyboard-coding-system 'utf-8-unix)
(set-buffer-file-coding-system 'utf-8-unix)

;; 注意：不要全局设置 coding-system-for-read，这会导致某些系统插件失效
;; (setq coding-system-for-read 'utf-8-unix) ;; 建议注释掉或删除

(setq default-buffer-file-coding-system 'utf-8-unix)
(setq org-capture-templates-coding-system 'utf-8-unix)

;; 2. 针对不同平台的剪贴板（Selection）进行优化
(cond
 ;; Windows 平台
 ((eq system-type 'windows-nt)
  ;; Windows 剪贴板必须用 utf-16 才能支持 Chrome 等外部软件的中文
  (set-selection-coding-system 'utf-16-le-dos)
  ;; 解决 Windows 文件路径或进程名可能的乱码
  (setq file-name-coding-system 'gbk)
  (setq default-process-coding-system '(undecided-dos . utf-8-unix)))
 ;; macOS 平台
 ((eq system-type 'darwin)
  (set-selection-coding-system 'utf-8-unix))
 ;; Linux 平台
 (t
  (set-selection-coding-system 'utf-8-unix)))

  ;; org-capture 模板内容编码
  (setq org-capture-templates-coding-system 'utf-8-unix)


  (provide 'early-init)

  ;;; early-init.el ends here
