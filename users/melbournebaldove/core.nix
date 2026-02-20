
{
  config, pkgs, inputs, ...
}:
{
  home.username = "melbournebaldove";
  home.homeDirectory = 
    if pkgs.stdenv.isDarwin 
    then "/Users/melbournebaldove"
    else "/home/melbournebaldove";
  home.stateVersion = "24.11";

  home.shell.enableShellIntegration = true;
  
  home.sessionPath = [
    "$HOME/.local/bin"
    "$HOME/.npm-global/bin"
  ];

  home.sessionVariables = {
    EDITOR = "vim";
    TERM = "xterm-256color";
  };

  programs = {
    zsh = {
      enable = true;
      autosuggestion.enable = true;
      enableCompletion = true;
      syntaxHighlighting.enable = true;
      oh-my-zsh = {
        enable = true;
        theme = "lambda";
        plugins = [
          "git"
          "docker"
          "kubectl"
          "terraform"
          "aws"
          "npm"
          "python"
          "golang"
          "rust"
          "direnv"
        ];
      };
      history = {
        size = 10000;
        save = 10000;
        share = true;
        ignoreDups = true;
        ignoreSpace = true;
      };
    };
    
    home-manager.enable = true;


    ssh = {
      enable = true;
      enableDefaultConfig = false;  # Explicitly disable default config
      matchBlocks = {
        # Preserve default behavior for all hosts
        "*" = {
          forwardAgent = false;
          forwardX11 = false;
          forwardX11Trusted = false;
          serverAliveInterval = 0;
          serverAliveCountMax = 3;
          sendEnv = [];
        };
        "github.com" = {
          hostname = "github.com";
          user = "git";
          identityFile = "~/.ssh/id_ed25519";
          identitiesOnly = true;
        };
        "github-cmsquared" = {
          hostname = "github.com";
          user = "git";
          identityFile = "~/.ssh/id_ed25519_cmsquared";
          identitiesOnly = true;
        };
        "github-ios-certs" = {
          hostname = "github.com";
          user = "git";
          identityFile = "~/.ssh/ios-certificates-deploy-key";
          identitiesOnly = true;
        };
      };
    };

    tmux = {
      enable = true;
      terminal = "screen-256color";
      baseIndex = 1;  # Start windows and panes at 1, not 0
      clock24 = true;
      keyMode = "emacs";  # Emacs key bindings
      mouse = true;  # Enable mouse support for scrolling and pane selection
      historyLimit = 50000;
      escapeTime = 0;  # No delay for escape key press
      
      extraConfig = ''
        # Enable mouse scrolling
        set -g mouse on
        
        # Easy pane switching with Alt+Arrow
        bind -n M-Left select-pane -L
        bind -n M-Right select-pane -R
        bind -n M-Up select-pane -U
        bind -n M-Down select-pane -D
        
        # Easy pane splitting
        bind | split-window -h -c "#{pane_current_path}"
        bind - split-window -v -c "#{pane_current_path}"
        
        # Reload config
        bind r source-file ~/.config/tmux/tmux.conf \; display "Config reloaded!"
        
        # Copy mode (Emacs style)
        bind-key -T copy-mode MouseDragEnd1Pane send-keys -X copy-selection-and-cancel
        
        # Status bar styling
        set -g status-style bg=colour235,fg=white
        set -g window-status-current-style bg=colour39,fg=colour235,bold
        set -g status-left '#[fg=colour39]#S '
        set -g status-right '#[fg=colour39]%H:%M %d-%b-%y'
        
        # Pane border styling
        set -g pane-border-style fg=colour235
        set -g pane-active-border-style fg=colour39
        
        # Enable true color support
        set -sa terminal-features ',xterm-256color:RGB'
        set -ga terminal-overrides ',xterm-256color:Tc'
        
        # Activity monitoring
        setw -g monitor-activity on
        set -g visual-activity off
        
        # Renumber windows when one is closed
        set -g renumber-windows on
        
        # Increase pane display time
        set -g display-panes-time 2000
        
        # Focus events (for emacs)
        set -g focus-events on
        
        # Preserve current path when creating new windows
        bind c new-window -c "#{pane_current_path}"
      '';
      
      plugins = with pkgs.tmuxPlugins; [
        sensible
        yank
        {
          plugin = resurrect;
          extraConfig = ''
            set -g @resurrect-capture-pane-contents 'on'
          '';
        }
        {
          plugin = continuum;
          extraConfig = ''
            set -g @continuum-restore 'on'
            set -g @continuum-save-interval '10'
          '';
        }
      ];
    };

    git = {
      enable = true;
      settings = {
        core = {
          editor = "vim";
          excludesfile = "~/.gitignore";
        };
        user = {
          name = "Melbourne Baldove";
          email = "melbournebaldove@gmail.com";
        };
        push = {
          autosetupremote = true;
        };
        pull = {
          rebase = true;
        };
        rebase = {
          autoStash = true;
        };
        fetch = {
          prune = true;
        };
        rerere = {
          enabled = true;
        };
        gc = {
          worktreePrune = true;
        };
        branch = {
          autoSetupRebase = "always";
        };
      };
    };
  };

  home.file = {
    ".gitignore".source = config.lib.file.mkOutOfStoreSymlink "${inputs.self}/git/.gitignore-config";
  };
}
