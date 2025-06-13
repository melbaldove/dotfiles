;;; -*- lexical-binding: t -*-
(custom-set-variables
 ;; custom-set-variables was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 '(global-org-modern-mode t)
 '(org-agenda-files nil)
 '(org-indent-indentation-per-level 4)
 '(org-latex-preview-appearance-options
   '(:foreground auto :background "Transparent" :scale 1.25 :zoom 1.25
		 :page-width 0.8 :matchers
		 ("begin" "$1" "$" "$$" "\\(" "\\[")))
 '(org-list-indent-offset 2)
 '(org-modern-hide-stars t)
 '(org-modern-keyword "")
 '(org-modern-list '((43 . "◦") (45 . "•") (42 . "•")))
 '(org-modern-replace-stars "")
 '(org-modern-star 'replace)
 '(org-pretty-entities t)
 '(package-selected-packages
   '(adaptive-wrap company constant-theme direnv eink-theme envrc
		   exec-path-from-shell expand-region
		   ido-completing-read+ lsp-sourcekit lsp-ui magit
		   monotropic-theme nix-mode nothing-theme org-journal
		   org-mode org-modern org-roam org-superstar
		   rainbow-delimiters smex swift-mode use-package
		   writeroom-mode yasnippet-snippets))
 '(writeroom-fullscreen-effect 'maximized))
(custom-set-faces
 ;; custom-set-faces was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 '(org-block ((t (:extend t :foreground "#111111" :family "Liga SFMono Nerd Font"))))
 '(org-default ((t (:inherit default :weight regular :family "Inter Display"))))
 '(org-document-title ((t (:foreground "headerTextColor" :weight bold :height 1.3))))
 '(org-drawer ((t (:foreground "#d1d1d1")))))
