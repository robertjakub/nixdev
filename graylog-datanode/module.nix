{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.services.graylog-datanode;
  mongodb-uri = pkgs.writeText "graylog-mongodburi" "mongodb://127.0.0.1:27017/graylog";

  settings-ini = pkgs.writeText "graylog-datanode.conf" (
    lib.generators.toINIWithGlobalSection { listsAsDuplicateKeys = true; } {
      globalSection = cfg.settings;
    }
  );
in
{
  options.services.graylog-datanode = {
    enable = lib.mkEnableOption "Graylog Datanode, a log management solution.";
    package = lib.mkPackageOption pkgs "graylog-datanode";

    enableLocalMongoDB = lib.mkEnableOption "a local MongoDB instance.";

    settings = lib.mkOption {
      default = { };
      type = lib.types.submodule {
        freeformType = lib.types.anything;
        options = {
          node_id_file = lib.mkOption {
            type = lib.types.str;
            default = "/var/lib/graylog-datanode/node-id";
            description = "Path of the file containing the graylog-datanode node-id.";
          };

          root_username = lib.mkOption {
            type = lib.types.str;
            default = "admin";
            description = "Name of the default administrator user.";
          };

          config_location = lib.mkOption {
            type = lib.types.str;
            internal = true;
            default = "/etc/graylog/datanode";
          };

          opensearch_location = lib.mkOption {
            type = lib.types.str;
            internal = true;
            default = "${cfg.package}/dist";
          };

        };
      };
      description = ''
        Configuration for Graylog Datanode, as a structured Nix attribute set.

        If you specify settings here, they will be used as persistent
        configuration and Graylog will retain the same configuration
        across restarts.

        For a complete list of available options, see:
        https://go2docs.graylog.org/current/setting_up_graylog/server_configuration_settings_reference.htm
      '';
    };

    user = lib.mkOption {
      type = lib.types.str;
      default = "graylog";
      description = "User account under which graylog runs.";
    };

    passwordSecretFile = lib.mkOption {
      type = lib.types.path;
      description = ''
        Path of the file containing the secret to secure/pepper the stored user passwords here.

        You MUST set a secret here. Use at least 64 characters.
        Generate one by using for example: pwgen -N 1 -s 96
      '';
    };

    rootPasswordSha2File = lib.mkOption {
      type = lib.types.path;
      description = ''
        Path of the file containing a hash password for the root user.

        You MUST specify a hash password for the root user (which you only need
        to initially set up the system and in case you lose connectivity to your
        authentication backend). This password cannot be changed using the API
        or via the web interface. If you need to change it, modify it here.

        Create one by using for example: echo -n yourpassword | shasum -a 256
        and use the resulting hash value as string for the option.
      '';
    };

    mongodbUriFile = lib.mkOption {
      type = lib.types.path;
      description = ''
        Path to a file that contains the MongoDB connection string.
        See http://docs.mongodb.org/manual/reference/connection-string/ for details.
      '';
    };
    mongodbUriSecret = lib.mkOption {
      type = lib.types.path;
      internal = true;
      default = if cfg.enableLocalMongoDB then mongodb-uri else cfg.mongodbUriFile;
      description = "Internal MongoDB connection string.";
    };
  };

  config = lib.mkIf cfg.enable {
    services.mongodb = lib.mkIf cfg.enableLocalMongoDB { enable = true; };

    users = {
      users = lib.mkIf (cfg.user == "graylog") {
        graylog = {
          isSystemUser = true;
          group = "graylog";
          description = "Graylog server daemon user";
        };
      };
      groups = lib.mkIf (cfg.user == "graylog") { graylog = { }; };
    };

    systemd.tmpfiles.rules = [
      "d /etc/graylog/datanode - ${cfg.user} - - -"
      "d '${dirOf cfg.settings.node_id_file}' 0700 ${cfg.user} - - -"
    ];

    environment.etc."graylog/datanode/datanode.conf".source = "${settings-ini}";
    environment.etc."graylog/datanode/jvm.options".source = "${cfg.package}/config/jvm.options";
    environment.etc."graylog/datanode/log4j2.xml".source = "${cfg.package}/config/log4j2.xml";

    systemd.services.graylog-datanode = {
      description = "Graylog Datanode Server";
      wantedBy = [ "multi-user.target" ];
      after = [ "network.target" ] ++ lib.optionals cfg.enableLocalMongoDB [ "mongodb.service" ];
      # environment.GRAYLOG_CONF = "${settings-ini}";
      serviceConfig = {
        LoadCredential = [
          "passwordSecret:${cfg.passwordSecretFile}"
          "rootSha2:${cfg.rootPasswordSha2File}"
          "mongodburi:${cfg.mongodbUriSecret}"
        ];
        User = "${cfg.user}";
        StateDirectory = "graylog-datanode";
      };
      script = ''
        set -eou pipefail
        shopt -s inherit_errexit

        GRAYLOG_MONGODB_URI="$(<"$CREDENTIALS_DIRECTORY/mongodburi")" \
        GRAYLOG_PASSWORD_SECRET="$(<"$CREDENTIALS_DIRECTORY/passwordSecret")" \
        GRAYLOG_ROOT_PASSWORD_SHA2="$(<"$CREDENTIALS_DIRECTORY/rootSha2")" \
        ${cfg.package}/bin/graylog-datanode datanode -f /etc/graylog/datanode/datanode.conf
      '';
    };
  };
}
