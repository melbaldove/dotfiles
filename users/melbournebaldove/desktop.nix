{
  config, self, ...
}:
{
  # macOS-specific home directory
  home.homeDirectory = "/Users/melbournebaldove";

  # macOS-specific bash aliases
  programs.bash.bashrcExtra = ''
    # Alias for darwin-rebuild
    alias rebuild='sudo darwin-rebuild switch'
  '';

  # macOS desktop applications
  home.file = {
    ".hammerspoon/init.lua".source = config.lib.file.mkOutOfStoreSymlink "${self}/hammerspoon/init.lua";
  };

  # Kitty terminal configuration
  xdg.configFile = {
    "kitty".source = config.lib.file.mkOutOfStoreSymlink "${self}/kitty";
  };

}
