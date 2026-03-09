let
  pkgs = import <nixpkgs> { };
  python = import ../all-python.nix { inherit pkgs; };
  inherit (python) py;

  package = pkgs.calendar-cli.override (orig: {
    python3 = py;
  });
in
pkgs.mkShell {
  packages = [
    package
  ];
}
