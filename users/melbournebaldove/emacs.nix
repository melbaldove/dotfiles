{
  config, pkgs, lib, inputs, ...
}:
{
  programs = {
    emacs = {
      enable = true;
      package = pkgs.emacs-unstable;
      extraPackages = epkgs: [
        epkgs.use-package
      ];
    };
  };

  # No launchd daemon: the GUI Emacs runs the server (see init.el), so one
  # Emacs owns both the visible frames and emacsclient.

  # Emacs configuration
  xdg.configFile = {
    "emacs/snippets".source = config.lib.file.mkOutOfStoreSymlink "${inputs.self}/emacs/snippets";
  };

  # Manual activation script to create writable symlinks for Emacs files
  home.activation.linkEmacsFiles = config.lib.dag.entryAfter ["writeBoundary"] ''
    run rm -f ${config.xdg.configHome}/emacs/init.el
    run ln -sf ${config.home.homeDirectory}/.dotfiles/emacs/init.el ${config.xdg.configHome}/emacs/init.el
    run rm -f ${config.xdg.configHome}/emacs/.emacs.custom.el
    run ln -sf ${config.home.homeDirectory}/.dotfiles/emacs/.emacs.custom.el ${config.xdg.configHome}/emacs/.emacs.custom.el
  '';
}