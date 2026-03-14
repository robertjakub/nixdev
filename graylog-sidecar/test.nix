{ pkgs, ... }:
{
  name = "graylog-sidecar";
  meta.maintainers = [ ];

  nodes.machine =
    { pkgs, ... }:
    {
      virtualisation.memorySize = 4096;
      virtualisation.diskSize = 1024 * 6;

      services.mongodb = {
        enable = true;
        package = pkgs.mongodb-ce;
      };

      services.opensearch = {
        enable = true;
        extraJavaOptions = [ "-Djava.net.preferIPv4Stack=true" ];
        settings.network.host = "127.0.0.1";
      };

      services.graylog = {
        enable = true;
        passwordSecret = "YGhZ59wXMrYOojx5xdgEpBpDw2N6FbhM4lTtaJ1KPxxmKrUvSlDbtWArwAWMQ5LKx1ojHEVrQrBMVRdXbRyZLqffoUzHfssc";
        elasticsearchHosts = [ "http://127.0.0.1:9200" ];
        # `echo -n "nixos" | shasum -a 256`
        rootPasswordSha2 = "6ed332bcfa615381511d4d5ba44a293bb476f368f7e9e304f0dff50230d1a85b";
      };

      environment.systemPackages = [ pkgs.jq ];

      systemd.services.graylog.path = [ pkgs.netcat ];
      systemd.services.graylog.preStart = ''
        until nc -z localhost 9200; do
          sleep 2
        done
      '';
    };

  testScript =
    let
      payloads.login = pkgs.writeText "login.json" (
        builtins.toJSON {
          host = "127.0.0.1:9000";
          username = "admin";
          password = "nixos";
        }
      );
    in
    ''
      machine.start()
      machine.wait_for_unit("graylog.service")
      machine.wait_until_succeeds(
        "journalctl -o cat -u graylog.service | grep 'Started REST API at <127.0.0.1:9000>'"
      )
      machine.wait_for_open_port(9000)
      machine.succeed("curl -sSfL http://127.0.0.1:9000/")
      machine.wait_until_succeeds(
        "journalctl -o cat -u graylog.service | grep 'Graylog server up and running'"
      )

      session = machine.succeed(
          "curl -X POST "
          + "-sSfL http://127.0.0.1:9000/api/system/sessions "
          + "-d $(cat ${payloads.login}) "
          + "-H 'Content-Type: application/json' "
          + "-H 'Accept: application/json' "
          + "-H 'x-requested-by: cli' "
          + "| jq .session_id | xargs echo"
      ).rstrip()

      machine.succeed('fail_always')
      machine.shutdown()
    '';
}
