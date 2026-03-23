{
  config,
  lib,
  pkgs,
}:
let
  cfg = config.services.graylog-forwarder;

  settings-ini = pkgs.writeText "graylog-forwarder.conf" (
    lib.generators.toINIWithGlobalSection { listsAsDuplicateKeys = true; } {
      globalSection = cfg.settings;
    }
  );
in
{
  options.services.graylog-forwarding = {
    enable = lib.mkEnableOption "Graylog Forwarder, a standalone agent that sends log data to Graylog.";
    package = lib.mkPackageOption pkgs "graylog-forwarder" { };

    enableLocalMongoDB = lib.mkEnableOption "a local MongoDB instance.";

    settings = lib.mkOption {
      default = { };
      type = lib.types.submodule {
        freeformType = lib.types.anything;
        options = {
          is_master = lib.mkOption {
            type = lib.types.bool;
            default = true;
            description = "Whether this is the master instance of your Graylog cluster.";
          };

          node_id_file = lib.mkOption {
            type = lib.types.str;
            default = "/var/lib/graylog/server/node-id";
            description = "Path of the file containing the graylog node-id.";
          };

          root_username = lib.mkOption {
            type = lib.types.str;
            default = "admin";
            description = "Name of the default administrator user.";
          };

          message_journal_dir = lib.mkOption {
            type = lib.types.str;
            default = "/var/lib/graylog/data/journal";
            description = ''
              The directory which will be used to store the message journal.
              The directory must be exclusively used by Graylog and must not contain
              any other files than the ones created by Graylog itself.
            '';
          };

          plugin_dir = lib.mkOption {
            type = lib.types.str;
            default = "/var/lib/graylog/plugins";
            apply = value: if (!cfg.mutablePlugins) then "${cfg.package}/plugin" else value;
            description = "Directory used to store Graylog server plugins.";
          };

          data_dir = lib.mkOption {
            type = lib.types.str;
            default = "/var/lib/graylog/data";
            description = "Directory used to store Graylog server state.";
          };

          mongodb_uri = lib.mkOption {
            type = lib.types.str;
            default = "mongodb://127.0.0.1:27017/graylog";
            description = ''
              MongoDB connection string.
              See http://docs.mongodb.org/manual/reference/connection-string/ for details.
            '';
          };

          elasticsearch_hosts = lib.mkOption {
            type = lib.types.listOf lib.types.str;
            default = [ ];
            apply = lib.concatStringsSep ",";
            example = lib.literalExpression ''[ "http://node1:9200" "http://user:password@node2:19200" ]'';
            description = ''
              List of valid URIs of the http ports of your elastic nodes. If one or more
              of your elasticsearch hosts require authentication, include the credentials
              in each node URI that requires authentication.
            '';
          };
        };
      };
      example = {
        is_master = true;
        http_bind_address = "127.0.0.1:9000";
        http_external_uri = "http://127.0.0.1:9000/";
        mongodb_uri = "mongodb://127.0.0.1:27017/graylog";
      };
      description = ''
        Configuration for Graylog, as a structured Nix attribute set.

        If you specify settings here, they will be used as persistent
        configuration and Graylog will retain the same configuration
        across restarts.

        For a complete list of available options, see:
        https://go2docs.graylog.org/current/getting_in_log_data/forwarder_configuration_options.html
      '';
    };

    user = lib.mkOption {
      type = lib.types.str;
      default = "graylog";
      description = "User account under which graylog runs.";
    };

  };

  # forwarder_grpc_api_token

  config = lib.mkIf cfg.enable {
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

    systemd.services.graylog-forwarder = {
      description = "Graylog Forwarder";
      wantedBy = [ "multi-user.target" ];
      path = with pkgs; [
        which
        procps
      ];
      serviceConfig = {
        User = "${cfg.user}";
        StateDirectory = "graylog-forwarder";
        ExecStart = "${cfg.package}/bin/graylog-forwarder run -f ${settings-ini} ";
      };
    };

  };
}
