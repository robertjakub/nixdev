{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.services.graylog-collector;
in
{
  options.services.graylog-collector = {
    enable = lib.mkEnableOption "Graylog Collector, a log management solution.";
    package = lib.mkPackageOption pkgs "graylog-collector" { };

    user = lib.mkOption {
      type = lib.types.str;
      default = "graylog";
      description = "User account under which graylog runs.";
    };

    enrollmentEndpoint = lib.mkOption {
      type = lib.types.str;
      example = "https://graylog";
    };

    enrollmentTokenFile = lib.mkOption {
      type = lib.types.path;
    };

  };

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

    systemd.services.graylog-collector = {
      description = "Graylog Collector";
      wantedBy = [ "multi-user.target" ];
      after = [ "network.target" ];
      environment.GLC_SERVER__AUTH__ENROLLMENT_ENDPOINT = "${cfg.enrollmentEndpoint}";
      serviceConfig = {
        LoadCredential = [ "enrollmentToken:${cfg.enrollmentTokenFile}" ];
        User = "${cfg.user}";
        StateDirectory = "graylog-collector";
      };
      script = ''
        set -eou pipefail
        shopt -s inherit_errexit

        GLC_SERVER__AUTH__ENROLLMENT_TOKEN="$(<"$CREDENTIALS_DIRECTORY/enrollmentToken")" \
        ${cfg.package}/bin/graylog-collector supervisor
      '';
    };
  };
}
