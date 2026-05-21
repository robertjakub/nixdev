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
  cfg = config.services.passcore;
in
{
  options.services.passcore = {
    enable = mkEnableOption "Self-service password change utility for Active Directory";
    openFirewall = mkEnableOption "Opening the passcore server port";

    package = lib.mkPackageOption pkgs.oom-base "passcore" { };

    port = mkOption {
      type = types.port;
      default = 9038;
      description = "The port the passcore should listen on.";
    };

    settings = mkOption {
      type = types.submodule { freeformType = with types; attrsOf str; };
      default = { };
      description = "Additional configuration...";
    };

    settingsFile = mkOption {
      type = types.path;
      default = "${cfg.package}/appsettings.json.default";
      description = "Default config file...";
    };

    LDAPPasswordFile = mkOption {
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
  };

  config = mkIf cfg.enable {
    assertions = [
      {
        assertion = !isStorePath cfg.LDAPPasswordFile;
        message = ''
          <option>services.passcore.passwordFile</option> points to
          a file in the Nix store. You should use a quoted absolute
          path to prevent this.
        '';
      }
    ];

    environment.etc."passcore/appsettings.json" = {
      user = "passcore";
      group = "passcore";
      mode = "0400";
      source = cfg.settingsFile;
    };

    services.passcore.settings = {
      HOME = "/var/lib/passcore";
      Kestrel__Endpoints__MyHttpEndpoint__Url = "http://127.0.0.1:${toString cfg.port}";
      # DATA_DIR = "/var/lib/uptime-kuma/";
      # NODE_ENV = mkDefault "production";
      # HOST = mkDefault "127.0.0.1";
      # PORT = mkDefault "3001";
    };

    systemd.packages = [ cfg.package ];
    systemd.services."passcore" = {
      wantedBy = [ "multi-user.target" ];
      unitConfig = {
        ConditionFileNotEmpty = "";
      };
      environment = cfg.settings;
      serviceConfig = {
        User = "passcore";
        Group = "passcore";
        UMask = "0077";
        WorkingDirectory = "${cfg.package}";
        LoadCredential = [ "password:${cfg.LDAPPasswordFile}" ];
        DynamicUser = true;
        StateDirectory = "passcore";
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

        export AppSettings__LdapPassword="$(<"$CREDENTIALS_DIRECTORY/password")"

        cd $cfg.package}
        ${pkgs.dotnet-sdk_6}/bin/dotnet Unosquare.PassCore.Web.dll
      '';
    };

    users.users.passcore = {
      home = "/var/lib/passcore";
      group = "passcore";
      isSystemUser = true;
    };
    users.groups.passcore = { };

    networking.firewall = mkIf cfg.openFirewall { allowedTCPPorts = [ cfg.port ]; };
  };
}
