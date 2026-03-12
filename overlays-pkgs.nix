self: super: {
  # final: prev:
  auditbeat-9 = (super.callPackages ./beats/9.x.nix { }).auditbeat;
  checkmate = super.callPackage ./checkmate/package.nix { };
  checkmate-capture = super.callPackage ./checkmate-capture/package.nix { };
  filebeat-9 = (super.callPackages ./beats/9.x.nix { }).filebeat;
  flame = super.callPackage ./flame/package.nix { };
  graylog-sidecar = super.callPackage ./graylog-sidecar/package.nix { };
  heartbeat-9 = (super.callPackages ./beats/9.x.nix { }).heartbeat;
  metricbeat-9 = (super.callPackages ./beats/9.x.nix { }).metricbeat;
  packetbeat-9 = (super.callPackages ./beats/9.x.nix { }).packetbeat;
  graylog-7_0 = super.callPackage ./graylog/7.0.nix { };
  graylog-6_3 = super.callPackage ./graylog/6.3.nix { };
}
