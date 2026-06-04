{
  config,
  lib,
  pkgs,
  nodejs_24,
  ...
}:
let
  cfg = config.services.tpa;
in
{
  options.services.graylog = {
    enable = lib.mkEnableOption "Traefik Proxy Admin.";
    package = lib.mkPackageOption pkgs "traefik-proxy-admin" { };
  };

  config = lib.mkIf cfg.enable {

    systemd.services.tpa = {
      description = "Traefik Proxy Admin";
      wantedBy = [ "multi-user.target" ];
      after = [ "network.target" ];
      environment.NEXT_TELEMETRY_DISABLED = 1;
      path = [
        pkgs.which
        pkgs.procps
      ];
      serviceConfig = {
        StateDirectory = "traefik-proxy-admin";
      };
      script = ''
        set -eou pipefail
        shopt -s inherit_errexit

        DATABASE_URL=postgresql://admin:password@localhost:5432/traefik_share2 \
        ${nodejs_24}/bin/node ${cfg.package}/server.js
      '';
    };
  };
}
