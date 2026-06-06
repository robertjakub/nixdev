# Run this test with NIXPKGS_ALLOW_UNFREE=1
{ lib, pkgs, ... }:
{
  name = "tpa";
  meta.maintainers = with lib.maintainers; [ robertjakub ];

  nodes.machine =
    { pkgs, ... }:
    {
      virtualisation.memorySize = 4096;
      virtualisation.diskSize = 1024 * 6;

      services.postgresql = {
        enable = true;
        package = pkgs.postgresql_17;
        ensureUsers = [
          {
            name = "tpa";
            ensureDBOwnership = true;
          }
        ];
        ensureDatabases = [ "tpa" ];
      };

      services.tpa = {
        enable = true;
        package = pkgs.nixdev.traefik-proxy-admin;
        # databaseURIFile = config.sops.secrets."tpa/db".path;
        adminAuthSecretFile = /run/tpa-adminsecret;
        settings = {
          PORT = 3133;
          HOSTNAME = "127.0.0.1";
          ADMIN_COOKIE_SECURE = "false";
          ADMIN_AUTH_ENABLED = "false";
          TRAEFIK_API_URL = "http://127.0.0.1:3134/";
        };
      };

      systemd.services.graylog.path = [ pkgs.netcat ];
      systemd.services.graylog.preStart = ''
        until nc -z 127.0.0.1 9200; do
          sleep 2
        done
      '';
    };

  testScript =
    let
      # openssl rand -base64 48
      adminSecret = "Q8ORxYlk+Gu3+ctF0UTsgUd4EQU1IK6h32EFywWICPfXMMVUD+YQWbNKTBnpvMM2";
      dbURL = "postgresql://tpa@/tpa?host=/run/postgresql";
    in
    ''
      machine.start()
      machine.execute("echo \"${adminSecret}\" > /run/tpa-adminsecret && chmod 400 /run/tpa-adminsecret")
      machine.execute("echo \"${dbURL}\" > /run/tpa-dburl && chmod 400 /run/tpa-dburl")

      machine.wait_for_unit("postgresql.target")
      machine.wait_for_unit("tpa.service")

      machine.wait_for_open_port(9000)
      machine.succeed("curl -sSfL http://127.0.0.1:3113/")

      # machine.wait_until_succeeds(
      #   "journalctl -o cat -u graylog.service | grep 'Graylog server up and running'"
      # )

      machine.shutdown()
    '';
}
