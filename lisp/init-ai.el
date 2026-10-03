;; -*- coding: utf-8; lexical-binding: t; -*-
;;; init-ai.el --- glue for the external ai-agent-in-emacs repo -*- lexical-binding: t; -*-

;; 通用实现在 https://github.com/zongwu233/ai-agent-in-emacs 的 init-ai.el，
;; 本文件不重复其逻辑；仓库 clone 到 site-lisp/ 下，缺失时自动 shallow clone。
(defconst my/ai-repo-url "https://github.com/zongwu233/ai-agent-in-emacs.git"
  "GitHub URL of the standalone AI module.")
(defconst my/ai-repo-dir
  (expand-file-name "site-lisp/ai-agent-in-emacs" user-emacs-directory)
  "Local clone of `my/ai-repo-url'.")

(unless (file-directory-p my/ai-repo-dir)
  (unless (zerop (shell-command
                  (format "git clone --depth 1 %s %s"
                          my/ai-repo-url (shell-quote-argument my/ai-repo-dir))))
    (user-error "init-ai: failed to clone %s; clone it into %s manually"
                my/ai-repo-url my/ai-repo-dir)))
(add-to-list 'load-path my/ai-repo-dir)

;; 仓库模块的 feature 是 init-ai-agent（本文件才是 init-ai），直接 require。
(require 'init-ai-agent)

;; 个人 providers 来自 ~/.authinfo 的自定义字段（provider/models/dmodel/
;; transport），本文件与 git 历史不含任何 host/login/model 信息。
(my/ai-load-authinfo-providers)

;;; AI menu (SPC a)------------------------------------------------
(+general-global-menu! "ai" "a"
  "s" 'gptel
  "o" 'my/gptel-open-session
  "S" 'gptel-menu
  "P" 'my/ai-select-provider
  "a" 'gptel-agent
  "p" 'my/gptel-plan
  "C" 'gptel-agent-compact
  "i" 'minuet-show-suggestion)

(provide 'init-ai)
;;; init-ai.el ends here
