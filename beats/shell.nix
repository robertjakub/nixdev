let
  pkgs = import <nixpkgs> { };

  auditbeat9 = (pkgs.callPackages ./9.x.nix { }).auditbeat;
  filebeat9 = (pkgs.callPackages ./9.x.nix { }).filebeat;
  heartbeat9 = (pkgs.callPackages ./9.x.nix { }).heartbeat;
  metricbeat9 = (pkgs.callPackages ./9.x.nix { }).metricbeat;
  packetbeat9 = (pkgs.callPackages ./9.x.nix { }).packetbeat;

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
