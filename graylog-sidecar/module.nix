{
  lib,
  pkgs,
  config,
  ...
}:
let
  cfg = config.services.graylog-sidecar;
  yaml-format = pkgs.formats.yaml { };
  settings-yaml = yaml-format.generate "graylog-sidecar.yml" cfg.settings;
  # collectors
  filebeat = pkgs.nixdev.filebeat9;
  auditbeat = pkgs.nixdev.auditbeat9;

  inherit (lib)
    mkEnableOption
    mkPackageOption
    mkIf
    mkOption
    types
    ;

in
{
  options.services.graylog-sidecar = {
    enable = mkEnableOption "the Graylog Sidecar";
    package = mkPackageOption pkgs.nixdev "graylog-sidecar";

    settings = mkOption {
      type = types.submodule {
        freeformType = yaml-format.type;
        options = {

          server_url = mkOption {
            type = types.str;
            description = "The Graylog ingest URL.";
            example = "https://<graylogserver>/api";
          };

          server_api_token = mkOption {
            # should be "secure file";
            type = types.str;
            description = "The API Token for authenticating.";
          }; # FIXME

          node_id = mkOption {
            type = types.str;
            default = "file:/var/lib/graylog-sidecar/node-id";
            description = "Path of the file containing the node-id";
          };

          log_path = mkOption {
            type = types.str;
            default = "/var/lib/graylog-sidecar/logs";
          };

          list_log_files = mkOption {
            type = with types; listOf str;
            default = [ "/var/log" ];
          };

          tls_skip_verify = mkOption {
            type = types.bool;
            default = true;
          };

          cache_path = mkOption {
            type = types.str;
            default = "/var/lib/graylog-sidecar/cache";
          };

          collector_binaries_accesslist = mkOption {
            type = with types; listOf str;
            default = [
              "${filebeat}/bin/filebeat"
              "/run/current-system/sw/bin/filebeat"
              "${auditbeat}/bin/auditbeat"
              "/run/current-system/sw/bin/auditbeat"
            ];
          };

        };
      };
    };

    user = mkOption {
      type = types.str;
      default = "graylog";
      description = "User account under which graylog-sidecar runs.";
    };
  };

  config = mkIf cfg.enable {

    environment.systemPackages = [
      filebeat
      auditbeat
    ];

    # reuse graylog user/group
    users.users = mkIf (cfg.user == "graylog") {
      graylog = {
        isSystemUser = true;
        group = "graylog";
        description = "Graylog server daemon user";
      };
    };
    users.groups = mkIf (cfg.user == "graylog") { graylog = { }; };

    systemd.services.graylog-sidecar = {
      description = "Graylog Sidecar";
      wantedBy = [ "multi-user.target" ];
      after = [ "network.target" ];
      startLimitIntervalSec = 60;
      startLimitBurst = 3;
      serviceConfig = {
        StateDirectory = "graylog-sidecar";
        ExecStart = "${cfg.package}/bin/graylog-sidecar -c ${settings-yaml}";
        AmbientCapabilities = [
          "CAP_AUDIT_CONTROL"
          "CAP_AUDIT_READ"
          "CAP_FOWNER"
        ];
        User = "${cfg.user}";
        LimitCORE = 0;
        KillSignal = "SIGINT";
        TimeoutStopSec = "30s";
        Restart = "on-failure";
      };

    };
  };
}
