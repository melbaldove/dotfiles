
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
      matchBlocks = {
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
      };
    };

    git = {
      enable = true;
      extraConfig = {
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
