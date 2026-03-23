{ system, self, ... }:
let
  pkgs = self.legacyPackages.${system};
in
{
  auditbeat-9 = pkgs.auditbeat-9;
  checkmate = pkgs.checkmate;
  checkmate-capture = pkgs.checkmate-capture;
  filebeat-9 = pkgs.filebeat-9;
  flame = pkgs.flame;
  graylog-sidecar = pkgs.graylog-sidecar;
  heartbeat-9 = pkgs.heartbeat-9;
  metricbeat-9 = pkgs.metricbeat-9;
  packetbeat-9 = pkgs.packetbeat-9;
  graylog-7_0 = pkgs.graylog-7_0;
  graylog-6_3 = pkgs.graylog-6_3;
  graylog = pkgs.graylog;
  graylogPlugins = pkgs.graylogPlugins;
  graylog-forwarder = pkgs.graylog-forwarder;
}
