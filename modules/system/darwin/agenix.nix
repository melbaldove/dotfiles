{ pkgs, inputs, ... }:

{
  # Agenix may not have a darwinModules, so we'll just add the package
  environment.systemPackages = with pkgs; [
    inputs.agenix.packages.${pkgs.system}.default
  ];
  
  # We'll manage secrets manually on Darwin since agenix primarily targets NixOS
}