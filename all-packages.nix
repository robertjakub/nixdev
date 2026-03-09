{ system, self, ... }:
let
  pkgs = self.legacyPackages.${system};
in
{
  auditbeat9 = pkgs.auditbeat9;
  checkmate = pkgs.checkmate;
  checkmate-capture = pkgs.checkmate-capture;
  filebeat9 = pkgs.filebeat9;
  flame = pkgs.flame;
  graylog-sidecar = pkgs.graylog-sidecar;
  heartbeat9 = pkgs.heartbeat9;
  metricbeat9 = pkgs.metricbeat9;
  packetbeat9 = pkgs.packetbeat9;
}
