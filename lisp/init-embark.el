;; -*- lexical-binding: t -*-

;; minibuffer action 就类似于在任何内容上右键点击
(package-install 'embark)
(global-set-key (kbd "C-;") 'embark-act)
;;利用这个 可以不用再记忆快捷键，只需要执行 C-x C-h 呼出帮助命令
;;然后输入想执行命令的关键字，既可以出现提示列表，又因为 orderless
;; 可以不用在意关键字单词的顺序 最后直接回车执行即可
(setq prefix-help-command 'embark-prefix-help-command)

(provide 'init-embark)
