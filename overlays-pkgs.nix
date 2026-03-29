self: super: rec {
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
  graylog-forwarder = super.callPackage ./graylog-forwarder/package.nix { };
  graylog-7_0 = super.callPackage ./graylog/7.0/package.nix { };
  graylog-enterprise-7_0 = super.callPackage ./graylog-enterprise/7.0/package.nix { };
  graylog-6_3 = super.callPackage ./graylog/6.3/package.nix { };
  graylog = super.callPackage ./graylog/current/package.nix { };
  graylogPlugins = super.recurseIntoAttrs (
    super.callPackage ./graylog/plugins/package.nix { graylogPackage = graylog; }
  );

}
