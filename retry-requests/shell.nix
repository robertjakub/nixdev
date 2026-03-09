let
  pkgs = import <nixpkgs> { };
  python = import ../all-python.nix { inherit pkgs; };
  inherit (python) py;

  package = py.pkgs.callPackage ./package.nix { };
in
pkgs.mkShell {
  packages = [
    (py.withPackages (ps: [ package ]))
  ];
}
