let
  pkgs = import <nixpkgs> { };
  package = pkgs.callPackage ./package.nix { };
in
pkgs.mkShell { packages = [ package ]; }
