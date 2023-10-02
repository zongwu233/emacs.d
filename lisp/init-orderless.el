;; -*- lexical-binding: t -*-
;;在 minibuffer 支持模糊搜索
(package-install 'orderless)
(setq completion-styles '(orderless))

(provide 'init-orderless)
