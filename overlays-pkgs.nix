self: super: {
  # final: prev:
  auditbeat9 = (super.callPackages ./beats/9.x.nix { }).auditbeat;
  checkmate = super.callPackage ./checkmate/package.nix { };
  checkmate-capture = super.callPackage ./checkmate-capture/package.nix { };
  filebeat9 = (super.callPackages ./beats/9.x.nix { }).filebeat;
  flame = super.callPackage ./flame/package.nix { };
  graylog-sidecar = super.callPackage ./graylog-sidecar/package.nix { };
  heartbeat9 = (super.callPackages ./beats/9.x.nix { }).heartbeat;
  metricbeat9 = (super.callPackages ./beats/9.x.nix { }).metricbeat;
  packetbeat9 = (super.callPackages ./beats/9.x.nix { }).packetbeat;
}
