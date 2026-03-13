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
  collector_binaries = (map (x: "${lib.getExe x}") cfg.collectors);

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
    package = mkPackageOption pkgs "graylog-sidecar" { };

    collectors = mkOption {
      type = with types; listOf package;
      default = [ ];
      description = "The list of collector packages that the Sidecar is authorized to execute.";
    };

    settings = mkOption {
      type = types.submodule {
        freeformType = yaml-format.type;
        options = {

          server_url = mkOption {
            type = types.str;
            description = "Specifies the Graylog API endpoint URL.";
            example = "https://<graylogserver>/api/";
          };

          # server_api_token = mkOption {
          #   type = types.str;
          #   description = "The API Token for authenticating with the Graylog Server.";
          # };

          node_id = mkOption {
            type = types.str;
            default = "file:/var/lib/graylog-sidecar/node-id";
            description = "Path of the file containing the unique identifier assigned to the Sidecar.";
          };

          log_path = mkOption {
            type = types.str;
            default = "/var/lib/graylog-sidecar/logs";
            description = "The directory where the Sidecar stores its own log files.";
          };

          list_log_files = mkOption {
            type = with types; listOf str;
            default = [ "/var/log" ];
            description = "Log file paths displayed in the Graylog interface.";
          };

          tls_skip_verify = mkOption {
            type = types.bool;
            default = true;
            description = "Whether TLS certificate validation should be skipped.";
          };

          cache_path = mkOption {
            type = types.str;
            default = "/var/lib/graylog-sidecar/cache";
            description = "The directory where the Sidecar stores runtime cache data.";
          };

          collector_binaries_accesslist = mkOption {
            type = with types; listOf str;
            default = collector_binaries;
            description = "The list of collector binaries that the Sidecar is authorized to execute.";
          };
        };
      };
    };

    user = mkOption {
      type = types.str;
      default = "graylog";
      description = "User account under which graylog-sidecar runs.";
    };

    APITokenFile = mkOption { type = types.path; };

  };

  config = mkIf cfg.enable {

    services.graylog-sidecar.settings.server_api_token = "\${API_TOKEN}";

    environment.systemPackages = cfg.collectors;

    # reuse graylog-server user/group
    users.users = mkIf (cfg.user == "graylog") {
      graylog = {
        isSystemUser = true;
        group = "graylog";
        description = "Graylog server daemon user";
        extraGroups = [ "systemd-journal" ];
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
