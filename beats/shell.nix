let
  pkgs = import <nixpkgs> { };

  inherit (pkgs.callPackages ./9.x.nix { })
    auditbeat9
    filebeat9
    heartbeat9
    metricbeat9
    packetbeat9
    ;

in
pkgs.mkShell {
  packages = [
    auditbeat9
    filebeat9
    heartbeat9
    metricbeat9
    packetbeat9
  ];
}
