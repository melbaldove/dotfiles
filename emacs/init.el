;;; init.el --- My Emacs configuration

;;; Commentary:
;; Organized Emacs configuration with use-package

;;; Code:

;; Performance optimization - increase GC threshold during startup
(setq gc-cons-threshold 100000000)
(add-hook 'after-init-hook (lambda () (setq gc-cons-threshold 800000)))

;; Core settings
(setq custom-file "~/.config/emacs/.emacs.custom.el")

;; Make sure we load our custom org version before anything else
;; This prevents org version mismatch errors
(add-to-list 'load-path "~/.config/emacs/elpa/org-mode/lisp/")
(require 'org)

;; Package management setup
(require 'package)
(add-to-list 'package-archives '("melpa" . "https://melpa.org/packages/") t)
;; Comment/uncomment this line to enable MELPA Stable if desired.  See `package-archive-priorities`
;; and `package-pinned-packages`. Most users will not need or want to do this.
;; (add-to-list 'package-archives '("melpa-stable" . "https://stable.melpa.org/packages/") t)
(package-initialize)

;; Load custom file
(load custom-file)
;; System integration
(use-package exec-path-from-shell
  :ensure t
  :if (memq window-system '(mac ns x)) ; Only run on GUI Emacs
  :custom
  (exec-path-from-shell-variables '("PATH" "MANPATH" "LANG")) ; Customize variables to copy if needed
  :config
  (exec-path-from-shell-initialize))

;; UI Configuration
(use-package monotropic-theme
  :ensure t
  :config
  (load-theme 'monotropic t))

(set-frame-font "Liga SFMono Nerd Font 16")

;; Basic UI settings
(setq inhibit-splash-screen t)
(tool-bar-mode 0)
(menu-bar-mode 0)
(scroll-bar-mode 0)
(column-number-mode 1)
(show-paren-mode 1)
(global-visual-line-mode)
(add-to-list 'default-frame-alist '(fullscreen . maximized))
(setq split-height-threshold nil)
(setq split-width-threshold 0)
(global-visual-wrap-prefix-mode)

;; Disable file backups
(setq make-backup-files nil)
(setq auto-save-default nil)

;; Auto-revert buffers when files change on disk
(global-auto-revert-mode 1)

;; Recent files
(recentf-mode 1)
(setq recentf-max-menu-items 25)        ; Show 25 recent files
(setq recentf-max-saved-items 100)      ; Remember 100 files
(setq recentf-exclude '("/tmp/" "/ssh:")) ; Exclude temporary and remote files

;; Org-mode Configuration
(use-package org-modern
  :ensure t
  :config
  (with-eval-after-load 'org (global-org-modern-mode)))

;; Configure org-mode
(setq org-hide-emphasis-markers t)
(setq org-agenda-files '("~/org/daily"))

(add-hook 'org-mode-hook (lambda ()
                           (org-latex-preview-auto-mode)
                           (face-remap-add-relative 'default :family "Inter Display")
                           (set-face-attribute 'org-modern-symbol nil :family "Inter Display")
                           (setq-local line-spacing 0.2)))

;; Dependencies for org-roam and other packages
(use-package transient :ensure t)
(use-package dash :ensure t)
(use-package f :ensure t)
(use-package s :ensure t)
(use-package emacsql :ensure t)
(use-package magit-section :ensure t)

;; Version control
(use-package magit :ensure t)

;; Note-taking with org-roam
(use-package org-roam
  :after org
  :ensure t
  :custom
  (org-roam-directory org-directory)
  (org-roam-dailies-capture-templates
   '(("d" "default" entry
      "* %(format-time-string \"%H:%M\")\n- %?"
      :target (file+head "%<%Y-%m-%d>.org"
                         "#+title: %<%A, %d/%m/%Y>")
      :empty-lines 1)))
  :config
  (org-roam-db-autosync-mode)
  :hook
  (after-init . (lambda ()
                  (org-roam-dailies-goto-today)
                  (end-of-buffer))))

;; Completion and editing tools
(use-package smex
  :ensure t
  :bind
  (("M-x" . smex)
   ("C-c C-c M-x" . execute-extended-command)))

(use-package expand-region
  :ensure t
  :bind ("C-=" . er/expand-region))

(use-package ace-window
  :ensure t
  :bind ("M-o" . ace-window)
  :custom
  (aw-keys '(?a ?r ?s ?t ?g ?m ?n ?e ?i)))

(use-package avy
  :ensure t
  :bind (("C-;" . avy-goto-char-timer)
         ("M-g f" . avy-goto-line)
         ("M-g w" . avy-goto-word-1)
         ("C-'" . avy-goto-char-2)))

(use-package projectile
  :ensure t
  :init
  (projectile-mode +1)
  :bind (:map projectile-mode-map
              ("s-p" . projectile-command-map)
              ("C-c p" . projectile-command-map)))

(use-package ido-completing-read+
  :ensure t
  :config
  (ido-mode 1)
  (ido-everywhere 1)
  (ido-ubiquitous-mode 1))

(use-package direnv
  :ensure t
  :config
  (direnv-mode))

(use-package company
  :ensure t
  :hook
  (after-init . global-company-mode))

;; Snippet support
(use-package yasnippet
  :ensure t
  :config
  (yas-global-mode 1))

(use-package yasnippet-snippets
  :ensure t)

;; Writing environment
(use-package visual-fill-column
  :ensure t)

(use-package writeroom-mode
  :ensure t)

(use-package adaptive-wrap
  :ensure t)

;; Development tools

;; .editorconfig file support
(use-package editorconfig
  :ensure t
  :config 
  (editorconfig-mode +1))

;; Rainbow delimiters makes nested delimiters easier to understand
(use-package rainbow-delimiters
  :ensure t
  :hook 
  (prog-mode . rainbow-delimiters-mode))

;; LSP support
(use-package lsp-mode
  :ensure t
  :commands lsp)

(use-package lsp-ui
  :ensure t
  :after lsp-mode)

;; Swift development configuration
(use-package swift-mode
  :ensure t
  :mode "\\.swift\\'"
  :interpreter "swift"
  :hook 
  (swift-mode . lsp))

(use-package lsp-sourcekit
  :ensure t
  :after lsp-mode
  :custom
  (lsp-sourcekit-executable 
   (or (executable-find "sourcekit-lsp")
       (and (eq system-type 'darwin)
            (string-trim (shell-command-to-string "xcrun -f sourcekit-lsp")))
       "/usr/local/swift/usr/bin/sourcekit-lsp")))

;; Rust development configuration
(use-package rust-mode
  :ensure t
  :mode "\\.rs\\'"
  :hook 
  (rust-mode . lsp))

;; Enable FFAP (Find File At Point)
(ffap-bindings)

;; Global keybindings
(global-set-key (kbd "C-x C-r") 'recentf-open-files)
(global-set-key "\C-ca" 'org-agenda)
(global-set-key "\C-cf" 'org-roam-node-find)
(global-set-key "\C-ci" 'org-roam-node-insert)
(global-set-key "\C-cy" 'org-roam-dailies-goto-yesterday)
(global-set-key "\C-cj" (lambda ()
                          (interactive)
                          (split-window-horizontally)
                          (other-window 1)
                          (org-roam-dailies-goto-today)
                          (end-of-buffer)))

;; Registers for quick access to important files
(set-register ?c (cons 'file "~/.config/emacs/init.el"))
(set-register ?n (cons 'file "~/.config/nix/home.nix"))
(set-register ?i (cons 'file (concat org-directory "/ideas.org")))

;; Provide the feature
(provide 'init)
;;; init.el ends here
