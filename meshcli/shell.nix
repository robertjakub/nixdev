let
  pkgs = import <nixpkgs> { };
  python = import ../all-python.nix { inherit pkgs; };
  inherit (python) py;

  package = pkgs.callPackage ./package.nix { };
in
pkgs.mkShell { packages = [ package ]; }
