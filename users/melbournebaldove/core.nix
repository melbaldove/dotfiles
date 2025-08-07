
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
      history = {
        size = 10000;
        save = 10000;
        share = true;
        ignoreDups = true;
        ignoreSpace = true;
      };
      initContent = ''
        # Custom prompt showing username and current directory
        PROMPT='%n:%~$ '
      '';
    };
    
    home-manager.enable = true;


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
      };
    };
  };

  home.file = {
    ".gitignore".source = config.lib.file.mkOutOfStoreSymlink "${inputs.self}/git/.gitignore-config";
  };
}
