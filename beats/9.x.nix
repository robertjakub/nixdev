{
  lib,
  fetchFromGitHub,
  buildGoModule,
  libpcap,
  versionCheckHook,
  nix-update-script,
  ...
}:
let
  beat =
    package: extraArgs:
    buildGoModule (
      lib.attrsets.recursiveUpdate rec {
        pname = package;
        version = "9.3.1";

        src = fetchFromGitHub {
          owner = "elastic";
          repo = "beats";
          rev = "v${version}";
          hash = "sha256-YLiTOItRpvSmT2jPnMBMjpey4evus/xDFqXJT6kxoZE=";
        };

        vendorHash = "sha256-cCxa45qhsrQ0K+3SO0H670s2ID6tztyVOEVySh24UHw=";

        subPackages = [ package ];

        nativeInstallCheckInputs = [
          versionCheckHook
        ];

        versionCheckProgramArg = "version";
        doInstallCheck = true;

        passthru = {
          updateScript = nix-update-script { extraArgs = [ "--version-regex=v(9\\..*)" ]; };
        };

        meta = {
          homepage = "https://www.elastic.co/products/beats";
          changelog = "https://www.elastic.co/docs/release-notes/beats#beats-release-notes-${version}";
          license = lib.licenses.asl20;
          maintainers = with lib.maintainers; [ robertjakub ];
        };
      } extraArgs
    );
in
{
  auditbeat = beat "auditbeat" {
    pos = __curPos;
    meta.mainProgram = "auditbeat";
    meta.description = "Lightweight shipper for audit data";
    meta.longDescription = ''
      Auditbeat is the Elastic Stack's lightweight shipper for audit data
      and file integrity monitoring.

      Collect your Linux audit framework data and monitor the integrity
      of your files. Auditbeat ships these events in real time to
      the rest of the Elastic Stack for further analysis.
    '';
  };
  filebeat = beat "filebeat" {
    pos = __curPos;
    meta.mainProgram = "filebeat";
    meta.description = "Tails and ships log files";
    meta.longDescription = ''
      Filebeat is a lightweight, open-source log shipper for the Elastic Stack.

      Whether you’re collecting from security devices, cloud, containers, hosts,
      or OT, Filebeat helps you keep the simple things simple by offering
      a lightweight way to forward and centralize logs and files.
    '';
  };
  heartbeat = beat "heartbeat" {
    pos = __curPos;
    meta.mainProgram = "heartbeat";
    meta.description = "Lightweight shipper for uptime monitoring";
    meta.longDescription = ''
      Heartbeat is a lightweight daemon used for uptime monitoring.

      Monitor services for their availability with active probing.
      Given a list of URLs, asks the simple question: Are you alive?
      Heartbeat ships this information and response time to the
      rest of the Elastic Stack for further analysis.
    '';
  };
  metricbeat = beat "metricbeat" {
    pos = __curPos;
    meta.mainProgram = "metricbeat";
    meta.description = "Lightweight shipper for metrics";
    meta.longDescription = ''
      Collect metrics from your systems and services. From CPU to memory,
      Redis to NGINX, and much more, Metricbeat is a lightweight way to
      send system and service statistics.
    '';
  };
  packetbeat = beat "packetbeat" {
    buildInputs = [ libpcap ];
    pos = __curPos;
    meta.mainProgram = "packetbeat";
    meta.description = "Network packet analyzer that ships data";
    meta.longDescription = ''
      Packetbeat is an open source network packet analyzer that ships the
      data to Elasticsearch.

      It captures network traffic directly from your hosts or containers,
      decodes application-layer protocols, and sends the data to Elasticsearch
    '';
  };
}
