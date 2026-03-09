{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib)
    mkIf
    mkEnableOption
    mkOption
    types
    mdDoc
    isStorePath
    ;
  cfg = config.services.flame;
in
{
  options.services.flame = {
    enable = mkEnableOption "Self-hosted startpage for your server";
    openFirewall = mkEnableOption "Opening the flame server port";
    package = lib.mkPackageOption pkgs.oom-base "flame" { };

    http_port = mkOption {
      type = types.port;
      default = 5005;
      description = "The port the flame should listen on.";
    };

    passwordFile = mkOption {
      type = types.path;
      description = mdDoc ''
        Path to the file containing the password.

        ::: {.warning}
        Make sure to use a quoted absolute path instead of a path literal
        to prevent it from being copied to the globally readable Nix
        store.
        :::
      '';
    };

    secretFile = mkOption {
      type = types.path;
      description = mdDoc ''
        Path to the file containing the db secret.

        ::: {.warning}
        Make sure to use a quoted absolute path instead of a path literal
        to prevent it from being copied to the globally readable Nix
        store.
        :::
      '';
    };
  };

  config = mkIf cfg.enable {
    assertions = [
      {
        assertion = !isStorePath cfg.passwordFile;
        message = ''
          <option>services.flame.passwordFile</option> points to
          a file in the Nix store. You should use a quoted absolute
          path to prevent this.
        '';
      }
      {
        assertion = !isStorePath cfg.secretFile;
        message = ''
          <option>services.flame.secretFile</option> points to
          a file in the Nix store. You should use a quoted absolute
          path to prevent this.
        '';
      }
    ];

    systemd.packages = [ cfg.package ];
    systemd.services."flame" = {
      wantedBy = [ "multi-user.target" ];
      unitConfig = {
        ConditionFileNotEmpty = "";
      };
      environment.HOME = "/var/lib/flame";
      environment.PORT = "${toString cfg.http_port}";
      environment.NODE_ENV = "production";
      environment.VERSION = "2.3.1";
      serviceConfig = {
        User = "flame";
        Group = "flame";
        UMask = "0077";
        WorkingDirectory = "${cfg.package}/lib/node_modules/flame";
        LoadCredential = [
          "password:${cfg.passwordFile}"
          "secret:${cfg.secretFile}"
        ];
        DynamicUser = true;
        StateDirectory = "flame";
        # AmbientCapabilities=CAP_NET_BIND_SERVICE;
        # CapabilityBoundingSet=CAP_NET_BIND_SERVICE;
        # LimitNOFILE=20500;
        # MemoryDenyWriteExecute=true;
        NoNewPrivileges = true;
        PrivateDevices = true;
        PrivateTmp = true;
        ProtectControlGroups = true;
        ProtectKernelLogs = true;
        ProtectKernelModules = true;
        ProtectKernelTunables = true;
        ProtectSystem = "full";
        RestrictNamespaces = true;
        RestrictRealtime = true;
        RestrictSUIDSGID = true;
      };
      script = ''
        set -o errexit -o pipefail -o nounset -o errtrace
        shopt -s inherit_errexit

        export PASSWORD="$(<"$CREDENTIALS_DIRECTORY/password")"
        export SECRET="$(<"$CREDENTIALS_DIRECTORY/secret")"
        ${pkgs.nodejs}/bin/node ${cfg.package}/lib/node_modules/flame/server.js
      '';
    };

    users.users.flame = {
      home = "/var/lib/flame";
      group = "flame";
      isSystemUser = true;
    };

    users.groups.flame = { };

    networking.firewall = mkIf cfg.openFirewall { allowedTCPPorts = [ cfg.http_port ]; };
  };
}
