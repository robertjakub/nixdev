let
  pkgs = import <nixpkgs> { };
  python = import ../all-python.nix { inherit pkgs; };
  inherit (python) py;

  package = py.pkgs.callPackage ./package.nix { };
  calendar-cli = pkgs.calendar-cli.override (orig: {
    python3 = py;
  });
in
pkgs.mkShell {
  packages = [
    (py.withPackages (ps: [ package ]))
    calendar-cli
  ];
}
