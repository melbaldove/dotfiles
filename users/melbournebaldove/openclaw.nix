{
  config, pkgs, lib, inputs, ...
}:
{
  home.activation.installOpenClaw = lib.hm.dag.entryAfter ["writeBoundary"] ''
    if ! command -v openclaw &> /dev/null; then
      ${pkgs.curl}/bin/curl -fsSL https://openclaw.ai/install.sh | ${pkgs.bash}/bin/bash
    fi
  '';
}
