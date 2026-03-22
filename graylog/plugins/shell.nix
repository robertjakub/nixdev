let
  pkgs = import <nixpkgs> { };
  graylog = pkgs.callPackage ../7.0/package.nix { };
  package = pkgs.callPackage ./package.nix { graylogPackage = graylog; };
in
pkgs.mkShell { packages = [ package.output-syslog ]; }
