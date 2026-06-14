self: super: rec {
  # final: prev:
  JRECaCerts = super.callPackage ./javacerts/package.nix { };
  auditbeat-9 = (super.callPackages ./beats/9.x.nix { }).auditbeat;
  checkmate = super.callPackage ./checkmate/package.nix { };
  checkmate-capture = super.callPackage ./checkmate-capture/package.nix { };
  filebeat-9 = (super.callPackages ./beats/9.x.nix { }).filebeat;
  flame = super.callPackage ./flame/package.nix { };
  graylog-sidecar = super.callPackage ./graylog-sidecar/package.nix { };
  heartbeat-9 = (super.callPackages ./beats/9.x.nix { }).heartbeat;
  metricbeat-9 = (super.callPackages ./beats/9.x.nix { }).metricbeat;
  packetbeat-9 = (super.callPackages ./beats/9.x.nix { }).packetbeat;

  graylog-forwarder-7 = super.callPackage ./graylog-forwarder/7/package.nix { };
  graylog-forwarder = graylog-forwarder-7;

  graylog-6_3 = super.callPackage ./graylog/6.3/package.nix { };
  graylog-7_0 = super.callPackage ./graylog/7.0/package.nix { };
  graylog-7_1 = super.callPackage ./graylog/7.1/package.nix { };
  graylog = graylog-7_1;

  graylog-enterprise-7_0 = super.callPackage ./graylog-enterprise/7.0/package.nix { };
  graylog-enterprise-7_1 = super.callPackage ./graylog-enterprise/7.1/package.nix { };
  graylog-enterprise = graylog-enterprise-7_1;

  graylog-datanode-7_1 = super.callPackage ./graylog-datanode/7.1/package.nix { };
  graylog-datanode = graylog-datanode-7_1;

  graylogPlugins = super.recurseIntoAttrs (
    super.callPackage ./graylog/plugins/package.nix { graylogPackage = graylog; }
  );
  passcore = super.callPackage ./passcore/package.nix { };
  crowdsec = super.callPackage ./crowdsec/package.nix { };
  traefik-proxy-admin = super.callPackage ./tpa/package.nix { };
}
