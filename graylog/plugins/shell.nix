let
  pkgs = import <nixpkgs> { };
  graylog = pkgs.callPackage ../7.0/package.nix { };
  package = pkgs.callPackage ./package.nix { graylogPackage = graylog; };
in
pkgs.mkShell {
  packages = with package; [
    output-syslog
    correlation-count
    logging-alert
    alert-wizard
  ];
}
