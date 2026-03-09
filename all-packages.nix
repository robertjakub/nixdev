{ system, self, ... }:
let
  pkgs = self.legacyPackages.${system};
in
{
  flame = pkgs.flame;
  checkmate = pkgs.checkmate;
  checkmate-capture = pkgs.checkmate-capture;
}
