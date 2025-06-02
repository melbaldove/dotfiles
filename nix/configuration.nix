

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
  environment.systemPackages = [
    pkgs.vim
    pkgs.coreutils
    pkgs.findutils
  ];

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
    '';

  system = {
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
          { app = "/Applications/Google Chrome.app"; }
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
