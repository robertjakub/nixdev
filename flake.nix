{
  description = "Flake for oom's nix base";
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };
  outputs =
    { self, nixpkgs, ... }@inputs:
    let
      systems = [
        "x86_64-linux"
        "x86_64-darwin"
        "aarch64-darwin"
        "aarch64-linux"
      ];
      allSystems = inputs.nixpkgs.lib.systems.flakeExposed;
      forSystems = systems: f: nixpkgs.lib.genAttrs systems (system: f system);
      mkPkgs =
        nixpkgs: system:
        import nixpkgs {
          inherit system;
          overlays = [ self.overlays.pkgs ];
        };
      mkLegacyPackagesFor = nixpkgs: forSystems systems (mkPkgs nixpkgs);
    in
    {
      devShells = forSystems allSystems (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
        in
        {
          default = pkgs.mkShell {
            buildInputs = with pkgs; [
              nixfmt
              nixpkgs-fmt
            ];
          };
        }
      );

      nixosModules = {
        nixpkgs =
          {
            config,
            lib,
            pkgs,
            ...
          }:
          import ./nixpkgs.nix {
            inherit
              config
              lib
              pkgs
              self
              ;
          };
        modules = import ./all-modules.nix;
        python = import ./all-python.nix;
      };

      overlays = {
        pkgs = import ./overlays-pkgs.nix;
      };

      legacyPackages = mkLegacyPackagesFor nixpkgs;

      packages = forSystems systems (system: import ./all-packages.nix { inherit system self; });
    };
}
