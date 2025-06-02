(setq custom-file "~/.config/emacs/.emacs.custom.el")
;; Install org-mode with latex preview first
(use-package org :load-path "~/.config/emacs/elpa/org-mode/lisp/")
(load custom-file)
(require 'package)
(add-to-list 'package-archives '("melpa" . "https://melpa.org/packages/") t)
;; Comment/uncomment this line to enable MELPA Stable if desired.  See `package-archive-priorities`
;; and `package-pinned-packages`. Most users will not need or want to do this.
;; (add-to-list 'package-archives '("melpa-stable" . "https://stable.melpa.org/packages/") t)
(package-initialize)
(use-package exec-path-from-shell
  :ensure t
  :if (memq window-system '(mac ns x)) ; Only run on GUI Emacs
  :config
  (setq exec-path-from-shell-variables '("PATH" "MANPATH" "LANG")) ; Customize variables to copy if needed
  (exec-path-from-shell-initialize))

(use-package monotropic-theme
  :ensure t
  :config
  (load-theme 'monotropic t))

(set-frame-font "Liga SFMono Nerd Font 16")

(use-package org-latex-preview
  :config
  (setq org-latex-preview-live t)
  (setq org-latex-preview-live-debounce 0.25))

(use-package org-modern
  :ensure t
  :config
  (with-eval-after-load 'org (global-org-modern-mode)))

(setq org-hide-emphasis-markers t)

(add-hook 'org-mode-hook (lambda ()
  (org-latex-preview-auto-mode)
  (face-remap-add-relative 'default :family "Inter Display")
  (set-face-attribute 'org-modern-symbol nil :family "Inter Display")
  (setq-local line-spacing 0.2)))

(use-package magit
  :ensure t)

(use-package dash
  :ensure t)

(use-package f
  :ensure t)

(use-package s
  :ensure t)

(use-package emacsql
  :ensure t)

(use-package magit-section
  :ensure t)

(use-package org-roam
  :after (org)
  :ensure t
  :config
  (setq org-roam-directory org-directory)
  (org-roam-db-autosync-mode)
  (setq org-roam-dailies-capture-templates
	'(("d" "default" entry
         "* %(format-time-string \"%H:%M\")\n- %?"
         :target (file+head+olp "%<%Y-%m-%d>.org"
				"#+title: %<%Y-%m-%d>" ("%<%A, %d/%m/%Y>"))
	 :empty-lines 1)))
  (org-roam-dailies-goto-today)
  (end-of-buffer))

(use-package smex
  :ensure t)

(use-package ido-completing-read+
  :ensure t)

(use-package direnv
  :ensure t
  :config
  (direnv-mode))

(use-package company
  :ensure t
  :config
  (add-hook 'after-init-hook 'global-company-mode))

(use-package yasnippet
  :ensure t
  :config
  (yas-global-mode 1))

(use-package yasnippet-snippets
  :ensure t)

(setq inhibit-splash-screen t)
(tool-bar-mode 0)
(menu-bar-mode 0)
(scroll-bar-mode 0)
(column-number-mode 1)
(show-paren-mode 1)

(ido-mode 1)
(ido-everywhere 1)
(ido-ubiquitous-mode 1)
(add-to-list 'default-frame-alist '(fullscreen . maximized))

(global-set-key (kbd "M-x") 'smex)
(global-set-key (kbd "C-c C-c M-x") 'execute-extended-command)

;; Global hotkeys
(global-set-key "\C-ca" 'org-agenda)
(global-set-key "\C-cj" (lambda ()
			  (interactive)
			  (split-window-horizontally)
			  (other-window 1)
			  (org-roam-dailies-goto-today)
			  (end-of-buffer)))

;; Registers
(set-register ?c (cons 'file "~/.config/emacs/init.el"))
(set-register ?n (cons 'file "~/.config/nix/home.nix"))
(set-register ?i (cons 'file (concat org-directory "/ideas.org")))
