
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
      history = {
        size = 10000;
        save = 10000;
        share = true;
        ignoreDups = true;
        ignoreSpace = true;
      };
      initExtra = ''
        # Lambda prompt (replicates oh-my-zsh lambda theme)
        autoload -Uz vcs_info
        precmd() { vcs_info }
        zstyle ':vcs_info:git:*' formats '%F{green}%b%f '
        setopt PROMPT_SUBST
        PROMPT='λ %~/ ''${vcs_info_msg_0_}'

        # Git helper functions (used by aliases below)
        function git_current_branch() {
          local ref
          ref=$(command git symbolic-ref --quiet HEAD 2>/dev/null)
          local ret=$?
          if [[ $ret != 0 ]]; then
            [[ $ret == 128 ]] && return
            ref=$(command git rev-parse --short HEAD 2>/dev/null) || return
          fi
          echo ''${ref#refs/heads/}
        }
        function git_main_branch() {
          command git rev-parse --git-dir &>/dev/null || return
          local ref
          for ref in refs/{heads,remotes/{origin,upstream}}/{main,trunk,mainline,default,stable,master}; do
            if command git show-ref -q --verify $ref; then
              echo ''${ref:t}; return 0
            fi
          done
          echo master; return 1
        }
        function git_develop_branch() {
          command git rev-parse --git-dir &>/dev/null || return
          local branch
          for branch in dev devel develop development; do
            if command git show-ref -q --verify refs/heads/$branch; then
              echo $branch; return 0
            fi
          done
          echo develop; return 1
        }

        # Git aliases (from oh-my-zsh git plugin)
        alias g='git'
        alias ga='git add'
        alias gaa='git add --all'
        alias gapa='git add --patch'
        alias gau='git add --update'
        alias gb='git branch'
        alias gba='git branch --all'
        alias gbd='git branch --delete'
        alias gbD='git branch --delete --force'
        alias gbl='git blame -w'
        alias gbm='git branch --move'
        alias gbnm='git branch --no-merged'
        alias gbr='git branch --remote'
        alias gbs='git bisect'
        alias gbsb='git bisect bad'
        alias gbsg='git bisect good'
        alias gbsr='git bisect reset'
        alias gbss='git bisect start'
        alias gc='git commit --verbose'
        alias gc!='git commit --verbose --amend'
        alias gca='git commit --verbose --all'
        alias gca!='git commit --verbose --all --amend'
        alias gcam='git commit --all --message'
        alias gcan!='git commit --verbose --all --no-edit --amend'
        alias gcb='git checkout -b'
        alias gcl='git clone --recurse-submodules'
        alias gclean='git clean --interactive -d'
        alias gcm='git checkout $(git_main_branch)'
        alias gcmsg='git commit --message'
        alias gcn!='git commit --verbose --no-edit --amend'
        alias gco='git checkout'
        alias gcp='git cherry-pick'
        alias gcpa='git cherry-pick --abort'
        alias gcpc='git cherry-pick --continue'
        alias gcsm='git commit --signoff --message'
        alias gd='git diff'
        alias gdca='git diff --cached'
        alias gds='git diff --staged'
        alias gdw='git diff --word-diff'
        alias gf='git fetch'
        alias gfo='git fetch origin'
        alias ggpull='git pull origin "$(git_current_branch)"'
        alias ggpush='git push origin "$(git_current_branch)"'
        alias ggsup='git branch --set-upstream-to=origin/$(git_current_branch)'
        alias gl='git pull'
        alias glg='git log --stat'
        alias glgp='git log --stat --patch'
        alias glgg='git log --graph'
        alias glgga='git log --graph --decorate --all'
        alias glo='git log --oneline --decorate'
        alias glog='git log --oneline --decorate --graph'
        alias gloga='git log --oneline --decorate --graph --all'
        alias glol='git log --graph --pretty="%Cred%h%Creset -%C(auto)%d%Creset %s %Cgreen(%ar) %C(bold blue)<%an>%Creset"'
        alias glola='git log --graph --pretty="%Cred%h%Creset -%C(auto)%d%Creset %s %Cgreen(%ar) %C(bold blue)<%an>%Creset" --all'
        alias gm='git merge'
        alias gma='git merge --abort'
        alias gmc='git merge --continue'
        alias gmff='git merge --ff-only'
        alias gmom='git merge origin/$(git_main_branch)'
        alias gms='git merge --squash'
        alias gp='git push'
        alias gpd='git push --dry-run'
        alias gpf!='git push --force'
        alias gpoat='git push origin --all && git push origin --tags'
        alias gpr='git pull --rebase'
        alias gpra='git pull --rebase --autostash'
        alias gpristine='git reset --hard && git clean --force -dfx'
        alias gprom='git pull --rebase origin $(git_main_branch)'
        alias gpsup='git push --set-upstream origin $(git_current_branch)'
        alias gpv='git push --verbose'
        alias gr='git remote'
        alias gra='git remote add'
        alias grb='git rebase'
        alias grba='git rebase --abort'
        alias grbc='git rebase --continue'
        alias grbd='git rebase $(git_develop_branch)'
        alias grbi='git rebase --interactive'
        alias grbm='git rebase $(git_main_branch)'
        alias grbom='git rebase origin/$(git_main_branch)'
        alias grbs='git rebase --skip'
        alias grev='git revert'
        alias grh='git reset'
        alias grhh='git reset --hard'
        alias grhs='git reset --soft'
        alias grm='git rm'
        alias grmc='git rm --cached'
        alias groh='git reset origin/$(git_current_branch) --hard'
        alias grrm='git remote remove'
        alias grs='git restore'
        alias grset='git remote set-url'
        alias grss='git restore --source'
        alias grst='git restore --staged'
        alias grt='cd "$(git rev-parse --show-toplevel || echo .)"'
        alias gru='git reset --'
        alias grup='git remote update'
        alias grv='git remote --verbose'
        alias gsb='git status --short --branch'
        alias gsh='git show'
        alias gss='git status --short'
        alias gst='git status'
        alias gsta='git stash'
        alias gstaa='git stash apply'
        alias gstall='git stash --all'
        alias gstc='git stash clear'
        alias gstd='git stash drop'
        alias gstl='git stash list'
        alias gstp='git stash pop'
        alias gsts='git stash show --patch'
        alias gsw='git switch'
        alias gswc='git switch --create'
        alias gswm='git switch $(git_main_branch)'
        alias gta='git tag --annotate'
        alias gtv='git tag | sort -V'
        alias gwt='git worktree'
        alias gwta='git worktree add'
        alias gwtls='git worktree list'
        alias gwtrm='git worktree remove'
      '';
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
