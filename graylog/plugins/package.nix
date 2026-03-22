{
  lib,
  stdenv,
  fetchurl,
  unzip,
  graylogPackage,
}:
let
  glPlugin =
    a@{
      pluginName,
      version,
      installPhase ? ''
        mkdir -p $out/plugin
        cp $src $out/plugin/${pluginName}-${version}.jar
      '',
      ...
    }:
    stdenv.mkDerivation (
      a
      // {
        inherit installPhase;
        dontUnpack = true;
        nativeBuildInputs = [ unzip ];
        meta = a.meta // {
          platforms = graylogPackage.meta.platforms;
          maintainers = (a.meta.maintainers or [ ]);
          sourceProvenance = with lib.sourceTypes; [ binaryBytecode ];
        };
      }
    );

  files = lib.filterAttrs (_name: _type: _type == "regular" && lib.hasSuffix ".nix" _name) (
    builtins.readDir ./plugins
  );

  graylogPlugins = lib.mapAttrs' (
    name: _:
    lib.nameValuePair (lib.removeSuffix ".nix" name) (
      import (./plugins + "/${name}") { inherit lib glPlugin fetchurl; }
    )
  ) files;
in
graylogPlugins
