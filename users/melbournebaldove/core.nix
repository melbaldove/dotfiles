
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

  programs = {
    bash = {
      enable = true;
      bashrcExtra = ''
        # Custom prompt showing username and current directory
        export PS1="\u:\w$ "
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
