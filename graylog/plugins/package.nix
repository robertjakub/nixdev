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
        mkdir -p $out/bin
        cp $src $out/bin/${pluginName}-${version}.jar
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
in
{
  output-syslog = (import plugins/output-syslog.nix { inherit glPlugin fetchurl; }).plugin;
}
