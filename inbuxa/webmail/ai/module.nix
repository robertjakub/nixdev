{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.inbuxa-webmail;
in {
  options.services.inbuxa-webmail = {
    enable = mkEnableOption "INBUXA webmail service";

    package = mkOption {
      type = types.package;
      default = pkgs.callPackage ./derivation.nix {};
      description = "The INBUXA webmail package to use.";
    };

    port = mkOption {
      type = types.port;
      default = 8080;
      description = "Internal port for the webmail server to bind to.";
    };

    mailServerUrl = mkOption {
      type = types.str;
      description = "How this webmail reaches the JMAP mail server.";
    };

    publicUrl = mkOption {
      type = types.str;
      description = "The external URL where browsers reach the webmail application.";
    };

    appSecretFile = mkOption {
      type = types.path;
      description = "Path to a file containing a long random secret for sealing sessions.";
    };

    oauthClientSecretFile = mkOption {
      type = types.nullOr types.path;
      default = null;
      description = "Path to a file containing the confidential OAuth client secret matching the server.";
    };

    oauthClientId = mkOption {
      type = types.str;
      default = "ihasmail-inbuxa";
      description = "The client id registered on the server.";
    };
  };

  config = mkIf cfg.enable {
    systemd.services.inbuxa-webmail = {
      description = "INBUXA webmail application daemon";
      after = [ "network.target" ];
      wantedBy = [ "multi-user.target" ];

      serviceConfig = {
        Type = "simple";
        Restart = "always";
        User = "inbuxa-webmail";
        Group = "inbuxa-webmail";
        Port = cfg.port;

        # Load secrets safely into environment
        ExecStartPre = pkgs.writeShellScript "inbuxa-env-setup" ''
          mkdir -p /run/inbuxa-webmail
          echo "MAIL_SERVER_URL=${cfg.mailServerUrl}" > /run/inbuxa-webmail/env
          echo "PUBLIC_URL=${cfg.publicUrl}" >> /run/inbuxa-webmail/env
          echo "OAUTH_CLIENT_ID=${cfg.oauthClientId}" >> /run/inbuxa-webmail/env
          echo "PORT=${toString cfg.port}" >> /run/inbuxa-webmail/env
          echo "APP_SECRET=$(cat ${cfg.appSecretFile})" >> /run/inbuxa-webmail/env
          if [ -f "${toString cfg.oauthClientSecretFile}" ]; then
            echo "OAUTH_CLIENT_SECRET=$(cat ${cfg.oauthClientSecretFile})" >> /run/inbuxa-webmail/env
          fi
        '';

        EnvironmentFile = "/run/inbuxa-webmail/env";
        ExecStart = "${cfg.package}/bin/inbuxa-webmail";

        # Sandboxing elements
        RuntimeDirectory = "inbuxa-webmail";
        PrivateTmp = true;
        ProtectSystem = "full";
        NoNewPrivileges = true;
      };
    };

    users.users.inbuxa-webmail = {
      isSystemUser = true;
      group = "inbuxa-webmail";
    };

    users.groups.inbuxa-webmail = {};
  };
}
