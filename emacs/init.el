;;; init.el --- My Emacs configuration

;;; Commentary:
;; Organized Emacs configuration with use-package

;;; Code:

;; Performance optimization - increase GC threshold during startup
(setq gc-cons-threshold 100000000)
(add-hook 'after-init-hook (lambda () (setq gc-cons-threshold 800000)))

;; Suppress native compiler warnings
(setq native-comp-async-report-warnings-errors 'silent)

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

;; Use built-in org-mode
(use-package org
  :straight nil  ; Use built-in version
  :defer t)

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
(use-package solarized-theme
  :config
  (load-theme 'solarized-light t))

(set-frame-font "Liga SFMono Nerd Font 14")

;; Basic UI settings
(setq inhibit-splash-screen t)
(setq initial-scratch-message nil)
(tool-bar-mode 0)
(menu-bar-mode 0)
(scroll-bar-mode 0)
(column-number-mode 1)
(show-paren-mode 1)

;; Enable relative line numbers
(setq display-line-numbers-type 'relative)
(global-display-line-numbers-mode 1)
(global-visual-line-mode)
(add-to-list 'default-frame-alist '(fullscreen . maximized))
(setq split-height-threshold 80)
(setq split-width-threshold 160)
(global-visual-wrap-prefix-mode)

;; Disable file backups and auto-save files
(setq make-backup-files nil)
(setq auto-save-default nil)
(setq auto-save-list-file-prefix nil)
(setq create-lockfiles nil)

;; Auto-revert buffers when files change on disk
(global-auto-revert-mode 1)

;; Recent files
(recentf-mode 1)
(setq recentf-max-menu-items 25)        ; Show 25 recent files
(setq recentf-max-saved-items 100)      ; Remember 100 files
(setq recentf-exclude '("/tmp/" "/ssh:")) ; Exclude temporary and remote files

;; Org-mode Configuration

;; Configure org-mode
(setq org-directory "~/org")
(setq org-hide-emphasis-markers t)
(setq org-agenda-files '("~/org/daily"))
(setq org-use-sub-superscripts nil)
(setq org-startup-indented t)  ; Enable org-indent-mode by default

;; Use theme colors for org-mode (inherit from default face)
(add-hook 'org-mode-hook
          (lambda ()
            ;; Make TODO keywords use default text color
            (setq org-todo-keyword-faces
                  '(("TODO" . (:inherit default :weight bold))
                    ("DONE" . (:inherit shadow :weight bold))))
            ;; Make priorities use default text color  
            (setq org-priority-faces
                  '((?A . (:inherit default :weight bold))
                    (?B . (:inherit default))
                    (?C . (:inherit shadow))))))

(add-hook 'org-mode-hook (lambda ()
                           (setq-local line-spacing 0.2)
                           ;; Force all org headings to use default text color
                           (dolist (face '(org-level-1 org-level-2 org-level-3 org-level-4
                                          org-level-5 org-level-6 org-level-7 org-level-8))
                             (set-face-foreground face nil))))

;; Modern indentation for org-mode
(use-package org-modern-indent
  :straight (org-modern-indent :type git :host github :repo "jdtsmith/org-modern-indent")
  :config
  ;; Add late to hook to ensure it runs after org-indent
  (add-hook 'org-mode-hook #'org-modern-indent-mode 90))

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
  (org-roam-db-autosync-mode))

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

(use-package imenu-list
  :bind ("C-c l" . imenu-list-smart-toggle))

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
  (ido-ubiquitous-mode 1)
  ;; Enable flex matching for fuzzy search
  (setq ido-enable-flex-matching t))

(use-package direnv
  :config
  (setq direnv-always-show-summary nil)
  (setq direnv-show-paths-in-summary nil)
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

;; Nix support with tree-sitter
(use-package nix-ts-mode
  :straight (:host github :repo "nix-community/nix-ts-mode")
  :mode "\\.nix\\'")

;; Terminal emulator - using eat
(use-package eat
  :config
  (setq eat-kill-buffer-on-exit t)
  (setq eat-enable-shell-prompt-annotation t)
  (setq eat-term-scrollback-size 500000)
  ;; Bind M-o directly in eat-mode to ace-window
  :bind (:map eat-semi-char-mode-map
              ("M-o" . ace-window)))

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

;; Built-in tree-sitter configuration (Emacs 29+)
(use-package treesit
  :straight nil  ; Built-in package
  :config
  ;; Auto-install tree-sitter grammars
  (setq treesit-language-source-alist
        '((bash "https://github.com/tree-sitter/tree-sitter-bash")
          (cmake "https://github.com/uyha/tree-sitter-cmake")
          (css "https://github.com/tree-sitter/tree-sitter-css")
          (elisp "https://github.com/Wilfred/tree-sitter-elisp")
          (gleam "https://github.com/gleam-lang/tree-sitter-gleam")
          (go "https://github.com/tree-sitter/tree-sitter-go")
          (html "https://github.com/tree-sitter/tree-sitter-html")
          (javascript "https://github.com/tree-sitter/tree-sitter-javascript" "master" "src")
          (json "https://github.com/tree-sitter/tree-sitter-json")
          (make "https://github.com/alemuller/tree-sitter-make")
          (markdown "https://github.com/ikatyang/tree-sitter-markdown")
          (nix "https://github.com/nix-community/tree-sitter-nix")
          (python "https://github.com/tree-sitter/tree-sitter-python")
          (rust "https://github.com/tree-sitter/tree-sitter-rust")
          (swift "https://github.com/alex-pinkus/tree-sitter-swift")
          (toml "https://github.com/tree-sitter/tree-sitter-toml")
          (tsx "https://github.com/tree-sitter/tree-sitter-typescript" "master" "tsx/src")
          (typescript "https://github.com/tree-sitter/tree-sitter-typescript" "master" "typescript/src")
          (yaml "https://github.com/ikatyang/tree-sitter-yaml")))
  
  ;; Auto-remap major modes to their tree-sitter equivalents
  (setq major-mode-remap-alist
        '((bash-mode . bash-ts-mode)
          (css-mode . css-ts-mode)
          (javascript-mode . js-ts-mode)
          (json-mode . json-ts-mode)
          (python-mode . python-ts-mode)
          (rust-mode . rust-ts-mode)
          (typescript-mode . typescript-ts-mode)))
  
  ;; Add file associations for TypeScript
  (add-to-list 'auto-mode-alist '("\\.ts\\'" . typescript-ts-mode))
  (add-to-list 'auto-mode-alist '("\\.tsx\\'" . tsx-ts-mode))
  
  ;; Custom Swift grammar installation
  (defun my/install-swift-grammar ()
    "Install Swift tree-sitter grammar with proper build steps."
    (interactive)
    (let* ((workdir (make-temp-file "treesit-swift-" t))
           (repo-dir (expand-file-name "repo" workdir)))
      (message "Installing Swift tree-sitter grammar...")
      ;; Clone the repository
      (shell-command 
       (format "git clone --depth=1 https://github.com/alex-pinkus/tree-sitter-swift %s" 
               repo-dir))
      ;; Build the grammar
      (let ((default-directory repo-dir))
        (message "Installing npm dependencies...")
        (shell-command "npm install")
        (message "Generating parser.c...")
        (shell-command "npm run generate")
        ;; Now compile and install the grammar
        (let* ((lib-dir (expand-file-name "tree-sitter" user-emacs-directory))
               (lib-ext (if (eq system-type 'darwin) "dylib" "so"))
               (lib-file (expand-file-name (format "libtree-sitter-swift.%s" lib-ext) lib-dir)))
          (make-directory lib-dir t)
          (message "Compiling Swift grammar...")
          (shell-command 
           (format "gcc -shared -o %s -fPIC -I. src/parser.c src/scanner.c" lib-file))
          (message "Swift grammar installed successfully!")))))
  
  ;; Function to install missing grammars
  (defun my/install-treesit-grammars ()
    "Install tree-sitter grammars for configured languages."
    (interactive)
    (dolist (lang (mapcar #'car treesit-language-source-alist))
      (unless (treesit-language-available-p lang)
        (if (eq lang 'swift)
            (my/install-swift-grammar)
          (message "Installing tree-sitter grammar for %s..." lang)
          (treesit-install-language-grammar lang)))))
  
  ;; Auto-install grammars on first use
  (add-hook 'after-init-hook
            (lambda ()
              (run-with-idle-timer 2 nil #'my/install-treesit-grammars))))

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

;; Gleam development configuration
(use-package gleam-ts-mode
  :mode "\\.gleam\\'"
  :hook 
  (gleam-ts-mode . lsp)
  :config
  (with-eval-after-load 'lsp-mode
    (lsp-register-client
     (make-lsp-client :new-connection (lsp-stdio-connection '("gleam" "lsp"))
                      :major-modes '(gleam-ts-mode)
                      :server-id 'gleam-lsp))))

;; Mermaid diagrams support
(use-package mermaid-mode
  :mode ("\\.mmd\\'" "\\.mermaid\\'")
  :config
  (setq mermaid-mmdc-location "mmdc")
  (setenv "PUPPETEER_EXECUTABLE_PATH" "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"))

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

;; Open daily journal on startup
(add-hook 'after-init-hook
          (lambda ()
            (run-with-timer 0.1 nil
                            (lambda ()
                              (org-roam-dailies-goto-today)
                              (delete-other-windows)
                              (end-of-buffer))))
          t)

;; Provide the feature
(provide 'init)
;;; init.el ends here
