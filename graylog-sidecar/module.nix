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
in
{
  options.services.graylog-sidecar = {
    enable = lib.mkEnableOption "the Graylog Sidecar";
    package = lib.mkPackageOption pkgs "graylog-sidecar" { };

    collectors = lib.mkOption {
      type = with lib.types; listOf package;
      default = [ ];
      description = "The list of collector packages that the Sidecar is authorized to execute.";
    };

    settings = lib.mkOption {
      type = lib.types.submodule {
        freeformType = yaml-format.type;
        options = {

          server_url = lib.mkOption {
            type = lib.types.str;
            description = "Specifies the Graylog API endpoint URL.";
            example = "https://<graylogserver>/api/";
          };

          node_id = lib.mkOption {
            type = lib.types.str;
            default = "file:/var/lib/graylog-sidecar/node-id";
            description = "Path of the file containing the unique identifier assigned to the Sidecar.";
          };

          log_path = lib.mkOption {
            type = lib.types.str;
            default = "/var/lib/graylog-sidecar/logs";
            description = "The directory where the Sidecar stores its own log files.";
          };

          list_log_files = lib.mkOption {
            type = with lib.types; listOf str;
            default = [ "/var/log" ];
            description = "Log file paths displayed in the Graylog interface.";
          };

          tls_skip_verify = lib.mkOption {
            type = lib.types.bool;
            default = true;
            description = "Whether TLS certificate validation should be skipped.";
          };

          cache_path = lib.mkOption {
            type = lib.types.str;
            default = "/var/lib/graylog-sidecar/cache";
            description = "The directory where the Sidecar stores runtime cache data.";
          };
        };
      };
    };

    user = lib.mkOption {
      type = lib.types.str;
      default = "graylog";
      description = "User account under which graylog-sidecar runs.";
    };

    APITokenFile = lib.mkOption {
      type = lib.types.path;
      description = ''
        Path to a file that contains the API Token for authenticating with the Graylog Server.
      '';
    };
  };

  config = lib.mkIf cfg.enable {

    services.graylog-sidecar.settings.server_api_token = "\${API_TOKEN}";
    services.graylog-sidecar.settings.collector_binaries_accesslist = (
      map (x: "${lib.getExe x}") cfg.collectors
    );

    environment.systemPackages = cfg.collectors;

    # reuse graylog-server user/group
    users.users = lib.mkIf (cfg.user == "graylog") {
      graylog = {
        isSystemUser = true;
        group = "graylog";
        description = "Graylog server daemon user";
        extraGroups = [ "systemd-journal" ];
      };
    };
    users.groups = lib.mkIf (cfg.user == "graylog") { graylog = { }; };

    systemd.services.graylog-sidecar = {
      description = "Graylog Sidecar";
      wantedBy = [ "multi-user.target" ];
      after = [ "network.target" ];
      startLimitIntervalSec = 60;
      startLimitBurst = 3;
      serviceConfig = {
        LoadCredential = [ "API_TOKEN:${cfg.APITokenFile}" ];
        StateDirectory = "graylog-sidecar";
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
      script = ''
        set -eou pipefail
        shopt -s inherit_errexit

        API_TOKEN="$(<"$CREDENTIALS_DIRECTORY/API_TOKEN")" \
        ${cfg.package}/bin/graylog-sidecar -c ${settings-yaml}
      '';

    };
  };
}
