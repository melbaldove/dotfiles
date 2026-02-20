{
  config, pkgs, lib, inputs, ...
}:
{
  home.activation.installOpenClaw = lib.hm.dag.entryAfter ["writeBoundary"] ''
    export PATH="${pkgs.nodejs}/bin:${pkgs.git}/bin:${pkgs.gcc}/bin:${pkgs.gnumake}/bin:${pkgs.cmake}/bin:$PATH"
    ${pkgs.nodejs}/bin/npm config set prefix "$HOME/.npm-global" 2>/dev/null || true
    if ! "$HOME/.npm-global/bin/openclaw" --version &>/dev/null; then
      ${pkgs.nodejs}/bin/npm install -g openclaw@latest 2>&1 || true
    fi
  '';
}
