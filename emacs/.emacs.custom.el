;;; -*- lexical-binding: t -*-
(custom-set-variables
 ;; custom-set-variables was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 '(global-org-modern-mode t)
 '(org-agenda-files
   '("/Users/melbournebaldove/journal/20250602"
     "/Users/melbournebaldove/org/journal/20250602.org"))
 '(org-latex-preview-appearance-options
   '(:foreground auto :background "Transparent" :scale 1.25 :zoom 1.25
		 :page-width 0.8 :matchers
		 ("begin" "$1" "$" "$$" "\\(" "\\[")))
 '(org-latex-preview-live t)
 '(org-modern-hide-stars t)
 '(org-modern-keyword "")
 '(org-modern-list '((43 . "◦") (45 . "•") (42 . "•")))
 '(org-modern-replace-stars "")
 '(org-modern-star 'replace)
 '(org-pretty-entities t)
 '(package-selected-packages
   '(company constant-theme direnv eink-theme envrc exec-path-from-shell
	     expand-region f ido-completing-read+ magit
	     monotropic-theme nix-mode nothing-theme org-journal
	     org-mode org-modern org-roam org-superstar smex
	     use-package yasnippet yasnippet-snippets)))
(custom-set-faces
 ;; custom-set-faces was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 '(org-block ((t (:extend t :foreground "#111111"))))
 '(org-default ((t (:inherit default :weight regular :family "Inter Display"))))
 '(org-drawer ((t (:foreground "#d1d1d1")))))
