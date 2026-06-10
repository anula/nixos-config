{ pkgs, ... }:

{
  home.packages = with pkgs; [
    # Network/API tools
    httpie
    bind
    
    # Sandboxing/Security
    bubblewrap
    openbao
    
    # Infrastructure as Code
    opentofu
    
    # Static file servers
    miniserve
    (writeShellScriptBin "markserv" ''
      # npx needs node in the PATH
      export PATH="${pkgs.nodejs}/bin:$PATH"
      exec npx markserv "$@"
    '')
  ];
}
