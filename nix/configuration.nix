{
  pkgs,
  lib,
  inputs,
  self,
  ...
}:
{
  # List packages installed in system profile. To search by name, run:
  # $ nix-env -qaP | grep wget
  environment.etc = {
    nix-darwin.source = "/Users/melbournebaldove/.dotfiles/nix/";
  };
  environment.systemPackages = [
    pkgs.vim
    pkgs.coreutils
    pkgs.findutils
  ];

  nixpkgs.config.allowUnfree = true;
  nixpkgs.overlays = [
    (import (builtins.fetchTarball {
      url = "https://github.com/nix-community/emacs-overlay/archive/master.tar.gz";
    }))
  ];

  # Necessary for using flakes on this system.
  nix.settings.experimental-features = "nix-command flakes";

  # Enable alternative shell support in nix-darwin.
  # programs.fish.enable = true;

  # Set Git commit hash for darwin-version.
  system.configurationRevision = self.rev or self.dirtyRev or null;

  # Used for backwards compatibility, please read the changelog before changing.
  # $ darwin-rebuild changelog
  system.stateVersion = 6;

  # The platform the configuration will be used on.
  nixpkgs.hostPlatform = "aarch64-darwin";

  nix.enable = false;

  users.users.melbournebaldove = {
    name = "melbournebaldove";
    home = "/Users/melbournebaldove";
  };

  system.activationScripts.extraActivation.text =
    ''
      xcode-select --install || true
      softwareupdate --install-rosetta --agree-to-license
      echo "Setting up DefaultKeyBinding.dict..."
      mkdir -p /Users/melbournebaldove/Library/KeyBindings
    
      # Fetch the DefaultKeyBinding.dict from the repository
      curl -fsSL https://raw.githubusercontent.com/fkchang/emacs-keybindings-in-osx/refs/heads/master/DefaultKeybinding.dict \
      -o /Users/melbournebaldove/Library/KeyBindings/DefaultKeyBinding.dict
    
      # Set proper permissions
      chmod 644 /Users/melbournebaldove/Library/KeyBindings/DefaultKeyBinding.dict
      chown melbournebaldove:staff /Users/melbournebaldove/Library/KeyBindings/DefaultKeyBinding.dict

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
          {app = "/Users/melbournebaldove/Applications/Home Manager Apps/Emacs.app"; }
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
