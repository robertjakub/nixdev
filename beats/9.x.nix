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
        version = "9.3.1";

        src = fetchFromGitHub {
          owner = "elastic";
          repo = "beats";
          rev = "v${version}";
          hash = "sha256-YLiTOItRpvSmT2jPnMBMjpey4evus/xDFqXJT6kxoZE=";
        };

        vendorHash = "sha256-cCxa45qhsrQ0K+3SO0H670s2ID6tztyVOEVySh24UHw=";

        subPackages = [ package ];

        meta = {
          homepage = "https://www.elastic.co/products/beats";
          license = lib.licenses.asl20;
        };
      } extraArgs
    );
in
{
  auditbeat9 = beat "auditbeat" {
    pos = __curPos;
    meta.description = "Lightweight shipper for audit data";
  };
  filebeat9 = beat "filebeat" {
    pos = __curPos;
    meta.description = "Tails and ships log files";
  };
  heartbeat9 = beat "heartbeat" {
    pos = __curPos;
    meta.description = "Lightweight shipper for uptime monitoring";
  };
  metricbeat9 = beat "metricbeat" {
    pos = __curPos;
    meta.description = "Lightweight shipper for metrics";
  };
  packetbeat9 = beat "packetbeat" {
    buildInputs = [ libpcap ];
    pos = __curPos;
    meta.description = "Network packet analyzer that ships data";
  };
}
