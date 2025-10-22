

{ pkgs, inputs, config, ... }:
let
  # Fixed-output derivation for the entire fkchan repository
  fkchanRepo = pkgs.fetchFromGitHub {
    owner = "fkchang";
    repo = "emacs-keybindings-in-osx";
    rev = "master";
    sha256 = "1fvd440zp1g2rb41z67v0qh1q4bpi0cg6vsrr69qaxzqlycj4p3m";
  };
in
{
  nixpkgs.overlays = [ inputs.emacs-overlay.overlay ];

  # Run the fkchan install script
  system.activationScripts.extraActivation.text = ''
    export HOME="/Users/${config.system.primaryUser}"
    cd ${fkchanRepo}
    ${pkgs.bash}/bin/bash ./install.sh
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
        # Trackpad settings
        "com.apple.trackpad.scaling" = 3.0;  # Maximum tracking speed
      };
      dock = {
        persistent-apps = [
          { app = "/Applications/Safari.app"; }
          { app = "${config.users.users.${config.system.primaryUser}.home}/Applications/Home Manager Apps/Emacs.app"; }
          { app = "/Applications/Kitty.app"; }
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
            # Unicode Hex Input - prevents Option key from producing unicode
            {
              "InputSourceKind" = "Keyboard Layout";
              "KeyboardLayout ID" = "252";
              "KeyboardLayout Name" = "Unicode Hex Input";
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
      "hammerspoon"
      "ghostty"
      "kitty"
      "zed"
    ];
  };
}
