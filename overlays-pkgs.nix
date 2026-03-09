self: super: {
  # final: prev:
  checkmate = super.callPackage ./checkmate/package.nix { };
  checkmate-capture = super.callPackage ./checkmate-capture/package.nix { };
}
