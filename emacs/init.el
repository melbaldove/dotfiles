(setq custom-file "~/.config/emacs/.emacs.custom.el")
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

;; Install org-mode with latex preview first
(use-package org :load-path "~/.config/emacs/elpa/org-mode/lisp/")

(use-package org-latex-preview
  :config
  (add-hook 'org-mode-hook 'org-latex-preview-auto-mode)
  (setq org-latex-preview-live t)

  (setq org-latex-preview-live-debounce 0.25))

(use-package org-journal
  :ensure t
  :init
  :config
  (setq org-journal-dir "~/journal")
  (defun my-display-org-journal-on-startup ()
    "Open today's Org Journal file without a new entry item and return its buffer."
    (interactive)
    (org-journal-new-entry t)
    (delete-other-windows)
    (current-buffer))

  (setq initial-buffer-choice #'my-display-org-journal-on-startup)
)

(use-package org-roam
  :ensure t)

(use-package smex
  :ensure t)

(use-package ido-completing-read+
  :ensure t)

(use-package direnv
  :ensure t
  :config
  (direnv-mode))

(tool-bar-mode 0)
(menu-bar-mode 0)
(scroll-bar-mode 0)
(column-number-mode 1)
(show-paren-mode 1)

(ido-mode 1)
(ido-everywhere 1)
(ido-ubiquitous-mode 1)

(global-set-key (kbd "M-x") 'smex)
(global-set-key (kbd "C-c C-c M-x") 'execute-extended-command)
