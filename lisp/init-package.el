;; -*- coding: utf-8; lexical-binding: t; -*-

(require 'package)
    (setq package-archives '(("gnu"    . "https://mirrors.tuna.tsinghua.edu.cn/elpa/gnu/")
                             ("nongnu" . "https://mirrors.tuna.tsinghua.edu.cn/elpa/nongnu/")
                             ("melpa"  . "https://mirrors.tuna.tsinghua.edu.cn/elpa/melpa/")))
(package-initialize)


;;防止反复调用 package-refresh-contents 会影响加载速度
(when (not package-archive-contents)
      (package-refresh-contents))


;;; 安装最新 org 需要，这个配置一定要配置在 use-package 的初始化之前，否则无法正常安装
;;(assq-delete-all 'org package--builtins)
;;(assq-delete-all 'org package--builtin-versions)


;; Bootstrap `use-package'
(unless (package-installed-p 'use-package)
  (package-refresh-contents)
  (package-install 'use-package))
(eval-and-compile
  (setq use-package-always-ensure nil)
  (setq use-package-always-defer nil)
  (setq use-package-always-demand nil)
  (setq use-package-expand-minimally nil)
  (setq use-package-enable-imenu-support t))
(eval-when-compile
  (require 'use-package))

;; 按需刷新 package archive-contents：当 use-package :ensure 检测到「包未装」时，
;; 本会话首次自动 refresh 一次。已装的包走 fast path 无开销；同一会话多个新包只刷一次。
;; 解决：archive-contents 落盘后不再自动刷新，MELPA 轮到新版本号、旧版本号 404 的问题。
(defvar my/package-refreshed-this-session nil
  "本会话是否已触发过 `package-refresh-contents'。")

(defun my/use-package-refresh-on-missing (orig-fn name &rest args)
  "Advice around `use-package-ensure-elpa'.
NAME 未装且本会话尚未刷新过 archive → 先刷新一次再交给 ORIG-FN。"
  (unless (or (package-installed-p name)
              my/package-refreshed-this-session)
    (setq my/package-refreshed-this-session t)
    (package-refresh-contents))
  (apply orig-fn name args))

(advice-add 'use-package-ensure-elpa :around
            #'my/use-package-refresh-on-missing)

;; quelpa is a package manager, which can build and install emacs lisp package directly from source code
;; Bootstrap `quelpa'.
(use-package quelpa
  :ensure t
  :commands quelpa
  :custom
  (quelpa-git-clone-depth 1)
  (quelpa-self-upgrade-p nil)
  (quelpa-update-melpa-p nil)
  (quelpa-checkout-melpa-p nil))

(unless (package-installed-p 'quelpa-use-package)
      (quelpa
       '(quelpa-use-package
	 :fetcher git
	 :url "https://github.com/quelpa/quelpa-use-package.git")))

(use-package quelpa-use-package
      :init
      (setq quelpa-use-package-inhibit-loading-quelpa t)
      :demand t)

(provide 'init-package)
