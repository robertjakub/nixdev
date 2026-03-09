{
  lib,
  fetchFromGitHub,
  buildGoModule,
  libpcap,
  ...
}:
let
  beat =
    package: extraArgs:
    buildGoModule (
      lib.attrsets.recursiveUpdate rec {
        pname = package;
        version = "9.2.1";

        src = fetchFromGitHub {
          owner = "elastic";
          repo = "beats";
          rev = "v${version}";
          hash = "sha256-QJRzM/0t9Ono/qOdEhaXoKLgBaWMU9Ndi8dNUKEp1mo=";
        };

        vendorHash = "sha256-k65OURmEbY1s2VtqWtgzYld7l9T/1NZBIp1gB3Z3spI=";

        subPackages = [ package ];

        meta = with lib; {
          homepage = "https://www.elastic.co/products/beats";
          license = licenses.asl20;
          platforms = platforms.linux;
        };
      } extraArgs
    );
in
{
  auditbeat = beat "auditbeat" {
    pos = __curPos;
    meta.description = "Lightweight shipper for audit data";
  };
  filebeat = beat "filebeat" {
    pos = __curPos;
    meta.description = "Tails and ships log files";
  };
  heartbeat = beat "heartbeat" {
    pos = __curPos;
    meta.description = "Lightweight shipper for uptime monitoring";
  };
  metricbeat = beat "metricbeat" {
    pos = __curPos;
    meta.description = "Lightweight shipper for metrics";
  };
  packetbeat = beat "packetbeat" {
    buildInputs = [ libpcap ];
    pos = __curPos;
    meta.description = "Network packet analyzer that ships data";
  };
}
