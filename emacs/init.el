;;; init.el --- My Emacs configuration

;;; Commentary:
;; Organized Emacs configuration with use-package

;;; Code:

;; Performance optimization - increase GC threshold during startup
(setq gc-cons-threshold 100000000)
(add-hook 'after-init-hook (lambda () (setq gc-cons-threshold 800000)))

;; Core settings
(setq custom-file "~/.config/emacs/.emacs.custom.el")

;; Bootstrap straight.el package manager
(defvar bootstrap-version)
(let ((bootstrap-file
       (expand-file-name "straight/repos/straight.el/bootstrap.el"
                         user-emacs-directory))
      (bootstrap-version 7))
  (unless (file-exists-p bootstrap-file)
    (with-current-buffer
        (url-retrieve-synchronously
         "https://raw.githubusercontent.com/radian-software/straight.el/develop/install.el"
         'silent 'inhibit-cookies)
      (goto-char (point-max))
      (eval-print-last-sexp)))
  (load bootstrap-file nil 'nomessage))

;; Install use-package with straight
(straight-use-package 'use-package)

;; Configure use-package to use straight.el by default
(setq straight-use-package-by-default t)

;; Make sure we load our custom org version before anything else
;; This prevents org version mismatch errors
(add-to-list 'load-path "~/.config/emacs/elpa/org-mode/lisp/")
(require 'org)

;; Tell straight.el not to manage org since we're loading it manually
(straight-register-package 'org)

;; Load custom file
(load custom-file)
;; System integration
(use-package exec-path-from-shell
  :if (memq window-system '(mac ns x)) ; Only run on GUI Emacs
  :custom
  (exec-path-from-shell-variables '("PATH" "MANPATH" "LANG")) ; Customize variables to copy if needed
  :config
  (exec-path-from-shell-initialize))

;; Ensure .local/bin is in exec-path for glibtool
(add-to-list 'exec-path (expand-file-name "~/.local/bin"))
(setenv "PATH" (concat (expand-file-name "~/.local/bin") ":" (getenv "PATH")))

;; UI Configuration
(use-package monotropic-theme
  :config
  (load-theme 'monotropic t))

(set-frame-font "Liga SFMono Nerd Font 14")

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
  :after org
  :config
  (global-org-modern-mode))

;; Configure org-mode
(setq org-directory "~/org")
(setq org-hide-emphasis-markers t)
(setq org-agenda-files '("~/org/daily"))

(add-hook 'org-mode-hook (lambda ()
                           (org-latex-preview-auto-mode)
                           (face-remap-add-relative 'default :family "Inter Display" :height 140)
                           (set-face-attribute 'org-modern-symbol nil :family "Inter Display")
                           (setq-local line-spacing 0.2)))

;; Dependencies for org-roam and other packages
(use-package transient)
(use-package dash)
(use-package f)
(use-package s)
(use-package emacsql)
(use-package magit-section)

;; Version control
(use-package magit)

;; Note-taking with org-roam
(use-package org-roam
  :after org
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
  :bind
  (("M-x" . smex)
   ("C-c C-c M-x" . execute-extended-command)))

(use-package expand-region
  :bind ("C-=" . er/expand-region))

(use-package ace-window
  :bind ("M-o" . ace-window)
  :custom
  (aw-keys '(?a ?r ?s ?t ?g ?m ?n ?e ?i)))

(use-package avy
  :bind (("C-;" . avy-goto-char-timer)
         ("M-g f" . avy-goto-line)
         ("M-g w" . avy-goto-word-1)
         ("C-'" . avy-goto-char-2))
  :config
  (setq avy-timeout-seconds 0.2))

(use-package projectile
  :init
  (projectile-mode +1)
  :bind (:map projectile-mode-map
              ("s-p" . projectile-command-map)
              ("C-c p" . projectile-command-map)))

(use-package rg)

(use-package ido-completing-read+
  :config
  (ido-mode 1)
  (ido-everywhere 1)
  (ido-ubiquitous-mode 1))

(use-package direnv
  :config
  (direnv-mode))

(use-package company
  :hook
  (after-init . global-company-mode))

;; Snippet support
(use-package yasnippet
  :config
  (yas-global-mode 1))

(use-package yasnippet-snippets)

;; Writing environment
(use-package visual-fill-column)

(use-package writeroom-mode)

(use-package adaptive-wrap)

;; Development tools

;; Terminal emulator - using eat
(use-package eat
  :config
  (setq eat-kill-buffer-on-exit t)
  (setq eat-enable-shell-prompt-annotation t))

;; Syntax checking
(use-package flycheck
  :init (global-flycheck-mode))

;; Claude Code integration
(use-package claude-code
  :straight (:host github :repo "stevemolitor/claude-code.el")
  :config
  (claude-code-mode)
  ;; Configure Claude to split to the right
  (add-to-list 'display-buffer-alist
               '("^\\*claude"
                 (display-buffer-in-side-window)
                 (side . right)
                 (window-width . 90)))
  ;; Enable notifications
  (setq claude-code-enable-notifications t)
  :bind-keymap ("C-c c" . claude-code-command-map))

;; .editorconfig file support
(use-package editorconfig
  :config 
  (editorconfig-mode +1))

;; Rainbow delimiters makes nested delimiters easier to understand
(use-package rainbow-delimiters
  :hook 
  (prog-mode . rainbow-delimiters-mode))

;; LSP support
(use-package lsp-mode
  :commands lsp)

(use-package lsp-ui
  :after lsp-mode)

;; Swift development configuration
(use-package swift-mode
  :mode "\\.swift\\'"
  :interpreter "swift"
  :hook 
  (swift-mode . lsp))

(use-package lsp-sourcekit
  :after lsp-mode
  :custom
  (lsp-sourcekit-executable 
   (or (executable-find "sourcekit-lsp")
       (and (eq system-type 'darwin)
            (string-trim (shell-command-to-string "xcrun -f sourcekit-lsp")))
       "/usr/local/swift/usr/bin/sourcekit-lsp")))

;; Rust development configuration
(use-package rust-mode
  :mode "\\.rs\\'"
  :hook 
  (rust-mode . lsp))

;; Enable FFAP (Find File At Point)
(ffap-bindings)

;; Global keybindings
(global-set-key (kbd "C-x C-r") 'recentf-open-files)
(global-set-key "\C-ca" 'org-agenda)
;; Claude Code keybindings are now handled by the keymap
(global-set-key "\C-cf" 'org-roam-node-find)
(global-set-key "\C-ci" 'org-roam-node-insert)
(global-set-key "\C-cy" 'org-roam-dailies-goto-yesterday)
(global-set-key "\C-cj" 'org-roam-dailies-goto-today)

;; Registers for quick access to important files
(set-register ?c (cons 'file "~/.config/emacs/init.el"))
(set-register ?n (cons 'file "~/.config/nix/home.nix"))
(set-register ?i (cons 'file (concat org-directory "/ideas.org")))

;; Provide the feature
(provide 'init)
;;; init.el ends here
