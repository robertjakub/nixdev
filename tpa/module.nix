{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.services.tpa;
in
{
  options.services.tpa = {
    enable = lib.mkEnableOption "Traefik Proxy Admin.";
    package = lib.mkPackageOption pkgs "traefik-proxy-admin" { };

    environmentFile = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = null;
      description = ''
        An optional path to an environment file that will be used in the service.
      '';
      example = "secrets.env";
    };

    databaseURIFile = lib.mkOption {
      type = lib.types.path;
      description = ''
        Path to a file that contains the postgreSQL URI for connecting to the database.
      '';
    };

    adminAuthSecretFile = lib.mkOption {
      type = lib.types.path;
      description = ''
        Path to a file that contains the random generated admin secret.
        Generate with: openssl rand -base64 48
      '';
    };

    user = lib.mkOption {
      type = lib.types.str;
      default = "tpa";
      description = "User account under which Traefik Proxy Admin runs.";
    };

    settings = {
      port = lib.mkOption {
        type = lib.types.port;
        default = 4321;
        description = "Port the Traefik Proxy Admin should listen on.";
      };
      bind = lib.mkOption {
        type = lib.types.str;
        default = "0.0.0.0";
        description = "IP the Traefik Proxy Admin should listen on.";
      };
    };
  };

  config = lib.mkIf cfg.enable {

    users = {
      users = lib.mkIf (cfg.user == "tpa") {
        tpa = {
          isSystemUser = true;
          group = "tpa";
          description = "Traefik Proxy Admin daemon user";
          extraGroups = [ "systemd-journal" ];
        };
      };
      groups = lib.mkIf (cfg.user == "tpa") { tpa = { }; };
    };

    systemd.services.tpa = {
      description = "Traefik Proxy Admin";
      wantedBy = [ "multi-user.target" ];
      after = [ "network.target" ];
      environment = {
        NEXT_TELEMETRY_DISABLED = "1";
        PORT = toString cfg.settings.port;
        HOSTNAME = toString cfg.settings.bind;
        # KEEP_ALIVE_TIMEOUT = "10";
      };
      startLimitIntervalSec = 60;
      startLimitBurst = 3;
      serviceConfig = {
        EnvironmentFile = lib.optional (cfg.environmentFile != null) cfg.environmentFile;
        LoadCredential = [
          "DB_URI:${cfg.databaseURIFile}"
          "ADMIN_SECRET:${cfg.adminAuthSecretFile}"
        ];
        StateDirectory = "traefik-proxy-admin";
        Restart = "on-failure";
        User = "${cfg.user}";
      };
      script = ''
        set -eou pipefail
        shopt -s inherit_errexit

        cd ${cfg.package}/
        ADMIN_AUTH_SECRET="$(<"$CREDENTIALS_DIRECTORY/ADMIN_SECRET")" \
        DATABASE_URL="$(<"$CREDENTIALS_DIRECTORY/DB_URI")" \
        ${cfg.package}/startserver  ${cfg.package}/server.js
      '';
    };
  };
}
