

{ pkgs, inputs, config, ... }:
let
  # Fixed-output derivation for DefaultKeyBinding.dict
  defaultKeyBinding = pkgs.fetchurl {
    url = "https://raw.githubusercontent.com/fkchang/emacs-keybindings-in-osx/refs/heads/master/DefaultKeybinding.dict";
    sha256 = "sha256-IHe7nXGeE1/4WzMDSyyrUBqIZSp6qFc6DGvp1hl9sKA=";
  };
in
{
  nixpkgs.overlays = [ inputs.emacs-overlay.overlay ];

  # Create DefaultKeyBinding.dict symlink for all users
  system.activationScripts.userKeyBindings.text = ''
    echo "Setting up DefaultKeyBinding.dict..."
    USER_HOME="${config.users.users.${config.system.primaryUser}.home}"
    mkdir -p "$USER_HOME/Library/KeyBindings"
    ln -sf ${defaultKeyBinding} "$USER_HOME/Library/KeyBindings/DefaultKeyBinding.dict"
  '';

  system = {
    primaryUser = "melbournebaldove";
    defaults = {
      NSGlobalDomain = {
        InitialKeyRepeat = 15;
        KeyRepeat = 2;
        "com.apple.keyboard.fnState" = true;
        NSAutomaticSpellingCorrectionEnabled = false;
        NSAutomaticCapitalizationEnabled = false;
        NSAutomaticInlinePredictionEnabled = false;        
      };
      dock = {
        persistent-apps = [
          { app = "/Applications/Dia.app"; }
          { app = "${config.users.users.${config.system.primaryUser}.home}/Applications/Home Manager Apps/Emacs.app"; }
          { app = "/Applications/Ghostty.app"; }
          { app = "/System/Applications/Messages.app"; }
          { app = "/System/Applications/Mail.app"; }
          { app = "/System/Applications/Calendar.app"; }
          { app = "/System/Applications/System Settings.app"; }
        ];
      };
      CustomUserPreferences = {
        "com.apple.HIToolbox" = {
          AppleEnabledInputSources = [
            {
              "Bundle ID" = "com.apple.CharacterPaletteIM";
              "InputSourceKind" = "Non Keyboard Input Method";
            }
            # Colemak Entry
            {
              "InputSourceKind" = "Keyboard Layout";
              "KeyboardLayout ID" = "-7379";
              "KeyboardLayout Name" = "Colemak DH ANSI";
            }
          ];
          AppleInputSourceHistory = [
            {
              "InputSourceKind" = "Keyboard Layout";
              "KeyboardLayout ID" = "-7379"; # From your AppleEnabledInputSources
              "KeyboardLayout Name" = "Colemak DH ANSI"; # From your AppleEnabledInputSources
            }
          ];
          AppleSelectedInputSources = [
            {
              "InputSourceKind" = "Keyboard Layout";
              "KeyboardLayout ID" = "-7379"; # From your AppleEnabledInputSources
              "KeyboardLayout Name" = "Colemak DH ANSI"; # From your AppleEnabledInputSources
            }
          ];

          AppleCurrentKeyboardLayoutInputSourceID = "io.github.colemakmods.keyboardlayout.colemakdh.colemakdhansi";
        };
      };
    };
    
    keyboard = {
      enableKeyMapping = true;
      remapCapsLockToControl = true;
    };
    
  };

  homebrew = {
    enable = true;

    casks = [
      "font-sf-mono-nerd-font-ligaturized"
      "colemak-dh"
      "anki"
      "discord"
      "ghostty"
    ];
  };
}
