{ config, pkgs, ... }:

let
  # Imports your local derivation configuration file
  inbuxaAdmin = import ./derivation.nix { inherit pkgs; };
in
{
  # 1. Open the networking stack for web traffic
  networking.firewall.allowedTCPPorts = [ 80 443 ];

  # 2. Configure Caddy with the Native Templates flag
  services.caddy = {
    enable = true;

    # Injects the runtime configurations directly into the daemon environment context
    environment = {
      INBUXA_API_URL = "https://yourdomain.com"; # Change to your actual mail backend
    };

    virtualHosts."admin.inbuxa.local" = {
      extraConfig = ''
        # Set web root directly to the immutable Nix store path
        root * ${inbuxaAdmin}/share/inbuxa-admin
        
        # Enable Caddy's real-time Go-text template compiler parsing engine
        templates
        
        # Compress responses on the fly
        encode gzip zstd
        
        # Static file routing with fallback configuration for SPAs
        try_files {path} {path}/ /index.html
        file_server
      '';
    };
  };
}

