{
  config, pkgs, lib, inputs, ...
}:
{
  home.packages = [
    (pkgs.writeShellScriptBin "openclaw" ''
      exec ${pkgs.nodejs}/bin/npx openclaw@latest "$@"
    '')
  ];
}
