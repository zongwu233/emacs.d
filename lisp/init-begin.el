;; hidden menu-bar tool-bar scroll-bar, not nil ,not negative, specially apply in client mode.

(push '(menu-bar-lines . 0) default-frame-alist)
(push '(tool-bar-lines . 0) default-frame-alist)
(push '(vertical-scroll-bars) default-frame-alist)

;; full screen emacs
(toggle-frame-fullscreen)
(provide 'init-begin)
