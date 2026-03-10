let
  pkgs = import <nixpkgs> { };
  package = pkgs.callPackage ./7.0.nix { };
in
pkgs.mkShell { packages = [ package ]; }
