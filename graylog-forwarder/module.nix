{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (builtins) toString;
  cfg = config.services.graylog-forwarder;

  confFile = pkgs.writeText "graylog.conf" ''
    forwarder_server_hostname = ${cfg.forwarderServerHostname}
    forwarder_grpc_api_token = ${cfg.forwarderAPIToken}
    forwarder_configuration_port = ${toString cfg.forwarderConfigPort}
    forwarder_message_transmission_port = ${toString cfg.forwarderMessagesPort}
    forwarder_grpc_enable_tls = false
    data_dir = ${cfg.dataDir}
    ${cfg.extraConfig}
  '';

in
{
  ###### interface

  options = {

    services.graylog-forwarder = {

      enable = lib.mkEnableOption "The Graylog Forwarder is a standalone agent that sends log data to Graylog";

      package = lib.mkPackageOption pkgs.oom-base "graylog-forwarder-7_0" {
        example = "graylog-forwarder-7_0";
      };

      forwarderServerHostname = lib.mkOption {
        type = lib.types.str;
        description = "The Graylog Forwarder ingest hostname";
      };

      # FIXME
      forwarderAPIToken = lib.mkOption {
        type = lib.types.str;
        description = "The API Token for authenticating the forwarder";
      };

      forwarderConfigPort = lib.mkOption {
        type = lib.types.int;
        description = "Port on which the Forwarder receives configuration updates";
        default = 13302;
      };

      forwarderMessagesPort = lib.mkOption {
        type = lib.types.int;
        description = "Port used by the Forwarder to send log messages to Graylog";
        default = 13301;
      };

      user = lib.mkOption {
        type = lib.types.str;
        default = "graylog";
        description = "User account under which graylog runs";
      };

      dataDir = lib.mkOption {
        type = lib.types.str;
        default = "/var/lib/graylog-forwarder/data";
        description = "Directory used to store Graylog Forwarder state.";
      };

      extraConfig = lib.mkOption {
        type = lib.types.lines;
        default = "";
        description = "Any other configuration options you might want to add";
      };

    };
  };

  ###### implementation

  config = lib.mkIf cfg.enable {
    services.graylog-forwarder.package = lib.mkDefault pkgs.graylog-forwarder-7_0;

    # reuse graylog user/group
    users.users = lib.mkIf (cfg.user == "graylog") {
      graylog = {
        isSystemUser = true;
        group = "graylog";
        description = "Graylog server daemon user";
      };
    };
    users.groups = lib.mkIf (cfg.user == "graylog") { graylog = { }; };

    systemd.services.graylog-forwarder = {
      description = "Graylog Forwarder";
      wantedBy = [ "multi-user.target" ];
      path = [
        pkgs.which
        pkgs.procps
      ];
      serviceConfig = {
        User = "${cfg.user}";
        StateDirectory = "graylog-forwarder";
        ExecStart = "${cfg.package}/bin/graylog-forwarder run -f ${confFile} ";
      };
    };
  };
}
