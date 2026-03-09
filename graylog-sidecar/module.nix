{ lib, pkgs, config, ... }:
let
  cfg = config.services.graylog-sidecar;
  yaml-format = pkgs.formats.yaml { };
  settings-yaml = yaml-format.generate "graylog-sidecar.yml" cfg.settings;
  filebeat = pkgs.oom-base.filebeat-9_2;
  auditbeat = pkgs.oom-base.auditbeat-9_2;
in
{
  options.services.graylog-sidecar = {
    enable = lib.mkEnableOption "The Graylog Sidecar is a lightweight configuration management system for log collectors";
    package = lib.mkPackageOption pkgs.oom-base "graylog-sidecar" { example = "graylog-sidecar"; };

    settings = lib.mkOption {
      type = lib.types.submodule {
        freeformType = yaml-format.type;
        options = {
          server_url = lib.mkOption {
            type = lib.types.str;
            description = "The Graylog ingest hostname";
          };
          server_api_token = lib.mkOption {
            type = lib.types.str;
            description = "The API Token for authenticating";
          }; # FIXME
          node_id = lib.mkOption {
            type = lib.types.str;
            default = "file:/var/lib/graylog-sidecar/node-id";
            description = "Path of the file containing the node-id";
          };
          log_path = lib.mkOption {
            type = lib.types.str;
            default = "/var/lib/graylog-sidecar/logs";
          };
          list_log_files = lib.mkOption {
            type = lib.types.listOf lib.types.str;
            default = [ "/var/log" ];
          };
          tls_skip_verify = lib.mkOption {
            type = lib.types.bool;
            default = true;
          };
          cache_path = lib.mkOption {
            type = lib.types.str;
            default = "/var/lib/graylog-sidecar/cache";
          };
          collector_binaries_accesslist = lib.mkOption {
            type = lib.types.listOf lib.types.str;
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
    user = lib.mkOption { type = lib.types.str; default = "graylog"; description = "User account under which graylog-sidecar runs"; };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [ filebeat auditbeat ];

    # reuse graylog user/group
    users.users = lib.mkIf (cfg.user == "graylog") {
      graylog = {
        isSystemUser = true;
        group = "graylog";
        description = "Graylog server daemon user";
      };
    };
    users.groups = lib.mkIf (cfg.user == "graylog") { graylog = { }; };

    systemd.services.graylog-sidecar = {
      description = "Graylog Sidecar";
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        User = "${cfg.user}";
        StateDirectory = "graylog-sidecar";
        ExecStart = "${cfg.package}/bin/graylog-sidecar -c ${settings-yaml}";
        AmbientCapabilities = [ "CAP_AUDIT_CONTROL" "CAP_AUDIT_READ" "CAP_FOWNER" ];
      };
    };
  };
}
