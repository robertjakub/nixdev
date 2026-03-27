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

    settings = lib.mkOption {
      default = { };
      type = lib.types.submodule {
        freeformType = lib.types.anything;
        options = {

          # forwarder_server_hostname = ${cfg.forwarderServerHostname}
          # forwarder_configuration_port = ${toString cfg.forwarderConfigPort}
          # forwarder_message_transmission_port = ${toString cfg.forwarderMessagesPort}
          # forwarder_grpc_enable_tls = false

          node_id_file = lib.mkOption {
            type = lib.types.str;
            default = "/var/lib/graylog-forwarder/server/node-id";
            description = "Path of the file containing the graylog-forwarder node-id.";
          };

          data_dir = lib.mkOption {
            type = lib.types.str;
            default = "/var/lib/graylog-forwarder/data";
            description = "Directory used to store Graylog server state.";
          };

        };
      };
      example = { };
      description = ''
        Configuration for Graylog Forwarder, as a structured Nix attribute set.

        If you specify settings here, they will be used as persistent configuration
        and Graylog Forwarder will retain the same configuration across restarts.

        For a complete list of available options, see:
        https://go2docs.graylog.org/current/getting_in_log_data/forwarder_configuration_options.html
      '';
    };

    user = lib.mkOption {
      type = lib.types.str;
      default = "graylog";
      description = "User account under which graylog-forwarder runs.";
    };

    grpcAPITokenFile = lib.mkOption {
      type = lib.types.path;
      description = ''
        Path of the file containing the GRPC API Token.

        This token is REQUIRED and must be created in the Graylog web interface
        and copied into this configuration.
      '';
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
        LoadCredential = [ "api_token:${cfg.grpcAPITokenFile}" ];
        User = "${cfg.user}";
        StateDirectory = "graylog-forwarder";
      };
      script = ''
        set -eou pipefail
        shopt -s inherit_errexit

        GRAYLOG_FORWARDER_GRPC_API_TOKEN ="$(<"$CREDENTIALS_DIRECTORY/api_token")" \
        ${cfg.package}/bin/graylog-forwarder run -f ${settings-ini}
      '';
    };

  };
}
