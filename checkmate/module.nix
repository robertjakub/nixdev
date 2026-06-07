{
  config,
  pkgs,
  lib,
  ...
}:
let
  cfg = config.services.checkmate-server;
  checkmate-env = pkgs.writeText "checkmate-env" (lib.generators.toKeyValue { } cfg.settings);
  mongodb-uri = pkgs.writeText "checkmate-mongodburi" "mongodb://127.0.0.1:27017/uptime_db";

  assertStringPath =
    optionName: value:
    if lib.isPath value then
      throw ''
        services.checkmate-server.${optionName}:
          ${toString value}
          is a Nix path, but should be a string, since Nix
          paths are copied into the world-readable Nix store.
      ''
    else
      value;
in
{
  options = {
    services.checkmate-server = {
      enable = lib.mkEnableOption "the Checkmate monitoring server";
      package = lib.mkPackageOption pkgs "checkmate-server" { };

      vhostName = lib.mkOption {
        type = lib.types.str;
        default = "checkmate-vhost";
        description = "Name of the nginx vhost.";
      };

      enableLocalDB = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Whether to enable a local MongoDB instance";
      };

      JWTSecretFile = lib.mkOption {
        type = lib.types.path;
        apply = assertStringPath "JWTSecretFile";
        description = ''
          Path to a file that contains the secret to sign web requests using JSON Web Tokens.
        '';
      };
      MongoDBURIFile = lib.mkOption {
        type = lib.types.path;
        default = mongodb-uri;
        description = ''
          Path to a file that contains the MongoDB connection string.
          See http://docs.mongodb.org/manual/reference/connection-string/ for details.
        '';
      };
      environmentFile = lib.mkOption {
        type = lib.types.nullOr lib.types.path;
        default = null;
        description = ''
          An optional path to an environment file that will be used in the service.
        '';
        example = "secrets.env";
      };

      settings = lib.mkOption {
        type = lib.types.submodule {
          freeformType = with lib.types; (attrsOf (oneOf [ anything ]));
          options = {
            CLIENT_HOST = lib.mkOption {
              type = lib.types.str;
              default = "http://127.0.0.1";
              description = "Frontend Host URI.";
            };
            LOG_LEVEL = lib.mkOption {
              type = lib.types.enum [
                "debug"
                "info"
                "warn"
                "error"
              ];
              default = "info";
              description = "Debug level, can be one of: debug, info, warn, error.";
            };
            ORIGIN = lib.mkOption {
              type = lib.types.str;
              default = "localhost";
              description = ''
                Origin where requests to server originate from, for CORS purposes.
              '';
            };
            PORT = lib.mkOption {
              type = lib.types.port;
              default = 52345;
              description = "Port the Checkmate backend should listen on.";
            };
            TOKEN_TTL = lib.mkOption {
              type = lib.types.str;
              default = "1h";
              description = ''
                Time for token to live in vercel/ms format, see: https://github.com/vercel/ms.
              '';
            };
          };
        };
      };
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = !((cfg.enableLocalDB != true) || (!lib.isStorePath cfg.MongoDBURIFile));
        message = ''
          <option>services.checkmate-server.MongoDBURIFile</option> points to
          a file in the Nix store. You should use a quoted absolute path to prevent this.
        '';
      }
    ];

    services.mongodb = lib.mkIf cfg.enableLocalDB { enable = true; };

    systemd.services.checkmate-backend = {
      description = "Checkmate backend daemon";
      wantedBy = [ "multi-user.target" ];
      after = [ "network.target" ] ++ lib.optionals cfg.enableLocalDB [ "mongodb.service" ];
      startLimitIntervalSec = 60;
      startLimitBurst = 3;
      serviceConfig = {
        EnvironmentFile = [
          (lib.optional (cfg.environmentFile != null) cfg.environmentFile)
          checkmate-env
        ];
        LoadCredential = [
          "JWT_SECRET:${cfg.settings.JWTSecretFile}"
          "MONGO_DB:${cfg.MongoDBURIFile}"
        ];
        PrivateDevices = true;
        LimitCORE = 0;
        KillSignal = "SIGINT";
        TimeoutStopSec = "30s";
        Restart = "on-failure";
        DynamicUser = true;
      };
      script = ''
        set -eou pipefail
        shopt -s inherit_errexit

        DB_CONNECTION_STRING="$(<"$CREDENTIALS_DIRECTORY/MONGO_DB")" \
        JWT_SECRET="$(<"$CREDENTIALS_DIRECTORY/JWT_SECRET")" \
        ${cfg.package}/startserver ${cfg.package}/backend/index.js
      '';
    };

    services.nginx.virtualHosts.${cfg.vhostName} = {
      locations."/" = {
        root = "${cfg.package}/public";
        index = "index.html index.htm";
        tryFiles = "$uri $uri/ /index.html";
      };
      locations."/api/" = {
        proxyPass = "http://127.0.0.1:${toString cfg.settings.port}/api/";
        proxyWebsockets = true;
      };
      locations."/api-docs/" = {
        proxyPass = "http://127.0.0.1:${toString cfg.settings.port}/api-docs/";
        proxyWebsockets = true;
      };
    };

  };
}
